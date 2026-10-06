import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/theme/app_style.dart';
import '../models/editor_state.dart';
import 'widgets/note_formatting_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:port/features/private_space/data/note_repository.dart';

class NoteEditor extends StatefulWidget {
  final String? filePath;
  final Function(String)? onSave;

  const NoteEditor({super.key, this.filePath, this.onSave});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  final _notes = NoteRepository();
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  String? _originalTitle;
  String? _originalContent;

  final bool _isBold = false;
  final bool _isItalic = false;
  final bool _isUnderline = false;
  double _fontSize = 16.0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<EditorState> _history = [];
  int _historyIndex = -1;
  bool _isUndoRedoOperation = false;
  static const int _maxHistorySize = 50;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadNote();
    _setupListeners();
  }

  void _setupListeners() {
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasChanges =
        _titleController.text != (_originalTitle ?? '') ||
        _contentController.text != (_originalContent ?? '');

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }

    if (!_isUndoRedoOperation && _isEditing) {
      _saveStateToHistory();
    }
  }

  void _saveStateToHistory() {
    final currentState = EditorState(
      title: _titleController.text,
      content: _contentController.text,
      titleCursorPosition: _titleController.selection.baseOffset,
      contentCursorPosition: _contentController.selection.baseOffset,
    );

    if (_history.isNotEmpty && _historyIndex >= 0) {
      final lastState = _history[_historyIndex];
      if (lastState.title == currentState.title &&
          lastState.content == currentState.content) {
        return;
      }
    }

    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(currentState);
    _historyIndex = _history.length - 1;

    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (!_canUndo()) return;

    _isUndoRedoOperation = true;
    _historyIndex--;

    final state = _history[_historyIndex];
    _titleController.text = state.title;
    _contentController.text = state.content;

    _titleController.selection = TextSelection.collapsed(
      offset: state.titleCursorPosition.clamp(0, state.title.length),
    );
    _contentController.selection = TextSelection.collapsed(
      offset: state.contentCursorPosition.clamp(0, state.content.length),
    );

    _isUndoRedoOperation = false;
    setState(() {});
  }

  void _redo() {
    if (!_canRedo()) return;

    _isUndoRedoOperation = true;
    _historyIndex++;

    final state = _history[_historyIndex];
    _titleController.text = state.title;
    _contentController.text = state.content;

    _titleController.selection = TextSelection.collapsed(
      offset: state.titleCursorPosition.clamp(0, state.title.length),
    );
    _contentController.selection = TextSelection.collapsed(
      offset: state.contentCursorPosition.clamp(0, state.content.length),
    );

    _isUndoRedoOperation = false;
    setState(() {});
  }

  bool _canUndo() => _historyIndex > 0;
  bool _canRedo() => _historyIndex < _history.length - 1;

  Future<void> _loadNote() async {
    if (widget.filePath != null) {
      try {
        final note = await _notes.read(widget.filePath!);
        if (!mounted) return;
        if (note != null) {
          if (mounted) {
            setState(() {
              _originalTitle = note.title;
              _originalContent = note.content;
              _titleController.text = _originalTitle!;
              _contentController.text = _originalContent!;
            });
          }
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Failed to load note: $e');
      }
    }

    if (!mounted) return;
    _saveStateToHistory();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    _fadeController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppStyle.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Unsaved Changes',
              style: TextStyle(color: AppStyle.text),
            ),
            content: const Text(
              'You have unsaved changes. Do you want to discard them?',
              style: TextStyle(color: AppStyle.muted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppStyle.muted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final saved = await _saveNote();
                  if (!context.mounted || !saved) return;
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: AppStyle.blue),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _allowPop = false;
  bool _checkingPop = false;

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || _checkingPop) return;
    _checkingPop = true;
    try {
      final shouldPop = await _onWillPop();
      if (!mounted || !shouldPop) return;
      if (mounted) {
        setState(() => _allowPop = true);
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } finally {
      _checkingPop = false;
    }
  }

  Future<bool> _saveNote() async {
    try {
      final title = _titleController.text.trim();
      final content = _contentController.text;

      if (content.isEmpty) {
        _showErrorSnackBar('Note content cannot be empty');
        return false;
      }

      final filePath = await _notes.save(
        title: title,
        content: content,
        filePath: widget.filePath,
        metadata: {
          'fontSize': _fontSize,
          'formatting': {
            'bold': _isBold,
            'italic': _isItalic,
            'underline': _isUnderline,
          },
        },
      );
      if (!mounted) return false;

      setState(() {
        _originalTitle = title;
        _originalContent = content;
        _hasUnsavedChanges = false;
      });

      if (widget.onSave != null) {
        widget.onSave!(filePath);
      }

      _showSuccessSnackBar('Note saved successfully');
      return true;
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to save note: $e');
      return false;
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _contentFocusNode.requestFocus();
      });

      _saveStateToHistory();
    } else {
      _titleFocusNode.unfocus();
      _contentFocusNode.unfocus();
    }
  }

  void _insertText(String text) {
    TextEditingController controller = _contentController;

    if (_titleFocusNode.hasFocus) {
      controller = _titleController;
    } else if (_contentFocusNode.hasFocus) {
      controller = _contentController;
    }

    final selection = controller.selection;
    int start = selection.start;
    int end = selection.end;

    if (start < 0 ||
        end < 0 ||
        start > controller.text.length ||
        end > controller.text.length) {
      start = controller.text.length;
      end = controller.text.length;
    }

    final currentText = controller.text;
    final newText =
        currentText.substring(0, start) + text + currentText.substring(end);

    controller.text = newText;

    final newCursorPos = start + text.length;
    controller.selection = TextSelection.collapsed(
      offset: newCursorPos.clamp(0, newText.length),
    );

    if (controller == _titleController && !_titleFocusNode.hasFocus) {
      _titleFocusNode.requestFocus();
    } else if (controller == _contentController &&
        !_contentFocusNode.hasFocus) {
      _contentFocusNode.requestFocus();
    }
  }

  void _formatText() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyle.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NoteFormattingSheet(
        fontSize: _fontSize,
        onFontSizeChanged: (value) {
          if (mounted) setState(() => _fontSize = value);
        },
        onInsert: _insertText,
      ),
    );
  }

  void _showWordCount() {
    final titleWords = _titleController.text
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .length;
    final contentWords = _contentController.text
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .length;
    final totalWords = titleWords + contentWords;
    final characters =
        _titleController.text.length + _contentController.text.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyle.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Note Statistics',
          style: TextStyle(color: AppStyle.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Words', '$totalWords'),
            _buildStatRow('Characters', '$characters'),
            _buildStatRow('Title Words', '$titleWords'),
            _buildStatRow('Content Words', '$contentWords'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppStyle.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppStyle.text.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppStyle.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyle.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyle.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    const fieldBorder = InputBorder.none;
    const fieldDecoration = InputDecoration(
      filled: false,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder,
      disabledBorder: fieldBorder,
      contentPadding: EdgeInsets.zero,
    );
    return PopScope<Object?>(
      canPop: !_hasUnsavedChanges || _allowPop,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            _isEditing ? 'Write a note' : 'Notebook',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: const AppBarDivider(),
          actions: [
            IconButton(
              tooltip: _isEditing ? 'Read note' : 'Edit note',
              icon: Icon(
                _isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
              ),
              onPressed: _toggleEditing,
            ),
            IconButton(
              tooltip: 'Save note',
              icon: Icon(
                _hasUnsavedChanges ? Icons.save : Icons.save_outlined,
                color: _hasUnsavedChanges ? AppStyle.accent : AppStyle.muted,
              ),
              onPressed: _saveNote,
            ),
            PopupMenuButton<String>(
              tooltip: 'Note options',
              onSelected: (value) {
                if (value == 'format') {
                  _formatText();
                } else if (value == 'statistics') {
                  _showWordCount();
                }
              },
              itemBuilder: (_) => [
                if (_isEditing)
                  const PopupMenuItem(
                    value: 'format',
                    child: Text('Formatting'),
                  ),
                const PopupMenuItem(
                  value: 'statistics',
                  child: Text('Word count'),
                ),
              ],
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                _isEditing
                    ? 'DRAFT / ${_hasUnsavedChanges ? 'UNSAVED' : 'SAVED'}'
                    : 'PERSONAL ARCHIVE / NOTE',
                style: AppStyle.eyebrow,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                readOnly: !_isEditing,
                maxLines: null,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -.8,
                ),
                decoration: fieldDecoration.copyWith(hintText: 'Untitled note'),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppStyle.rule),
              const SizedBox(height: 24),
              TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                readOnly: !_isEditing,
                minLines: 12,
                maxLines: null,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.7,
                  color: AppStyle.text,
                ),
                decoration: fieldDecoration.copyWith(
                  hintText: _isEditing ? 'Start writing…' : 'No content',
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !_isEditing
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Undo',
                      icon: const Icon(Icons.undo_rounded, size: 21),
                      onPressed: _canUndo() ? _undo : null,
                    ),
                    IconButton(
                      tooltip: 'Redo',
                      icon: const Icon(Icons.redo_rounded, size: 21),
                      onPressed: _canRedo() ? _redo : null,
                    ),
                    IconButton(
                      tooltip: 'Copy content',
                      icon: const Icon(Icons.content_copy_rounded, size: 19),
                      onPressed: () {
                        if (_contentController.text.isNotEmpty) {
                          Clipboard.setData(
                            ClipboardData(text: _contentController.text),
                          );
                          _showSuccessSnackBar('Content copied to clipboard');
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste_rounded, size: 19),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (!mounted) return;
                        if (data?.text != null) {
                          _insertText(data!.text!);
                          _showSuccessSnackBar('Content pasted');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _contentController,
                        builder: (_, value, __) => Text(
                          '${value.text.length} chars',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppStyle.muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
