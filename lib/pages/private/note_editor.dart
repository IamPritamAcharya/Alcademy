import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

class EditorState {
  final String title;
  final String content;
  final int titleCursorPosition;
  final int contentCursorPosition;

  EditorState({
    required this.title,
    required this.content,
    required this.titleCursorPosition,
    required this.contentCursorPosition,
  });

  EditorState copy() {
    return EditorState(
      title: title,
      content: content,
      titleCursorPosition: titleCursorPosition,
      contentCursorPosition: contentCursorPosition,
    );
  }
}

class NoteEditor extends StatefulWidget {
  final String? filePath;
  final Function(String)? onSave;

  const NoteEditor({
    Key? key,
    this.filePath,
    this.onSave,
  }) : super(key: key);

  @override
  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  bool _isEditing = false;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  String? _originalTitle;
  String? _originalContent;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 16.0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<EditorState> _history = [];
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
    final hasChanges = _titleController.text != (_originalTitle ?? '') ||
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
        offset: state.titleCursorPosition.clamp(0, state.title.length));
    _contentController.selection = TextSelection.collapsed(
        offset: state.contentCursorPosition.clamp(0, state.content.length));

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
        offset: state.titleCursorPosition.clamp(0, state.title.length));
    _contentController.selection = TextSelection.collapsed(
        offset: state.contentCursorPosition.clamp(0, state.content.length));

    _isUndoRedoOperation = false;
    setState(() {});
  }

  bool _canUndo() => _historyIndex > 0;
  bool _canRedo() => _historyIndex < _history.length - 1;

  Future<void> _loadNote() async {
    if (widget.filePath != null) {
      try {
        final file = File(widget.filePath!);
        if (await file.exists()) {
          final content = await file.readAsString();
          final noteData = jsonDecode(content) as Map<String, dynamic>;

          setState(() {
            _originalTitle = noteData['title'] ?? '';
            _originalContent = noteData['content'] ?? '';
            _titleController.text = _originalTitle!;
            _contentController.text = _originalContent!;
          });
        }
      } catch (e) {
        _showErrorSnackBar('Failed to load note: $e');
      }
    }

    _saveStateToHistory();

    setState(() {
      _isLoading = false;
    });
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
            backgroundColor: Colors.grey[900],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Unsaved Changes',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'You have unsaved changes. Do you want to discard them?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Discard', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () async {
                  await _saveNote();
                  Navigator.pop(context, true);
                },
                child: const Text('Save', style: TextStyle(color: Colors.teal)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveNote() async {
    try {
      final title = _titleController.text.trim();
      final content = _contentController.text;

      if (content.isEmpty) {
        _showErrorSnackBar('Note content cannot be empty');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final noteData = {
        'title': title.isEmpty ? 'Untitled Note' : title,
        'content': content,
        'createdAt': widget.filePath != null
            ? (jsonDecode(await File(widget.filePath!).readAsString()))[
                    'createdAt'] ??
                now
            : now,
        'modifiedAt': now,
        'fontSize': _fontSize,
        'formatting': {
          'bold': _isBold,
          'italic': _isItalic,
          'underline': _isUnderline,
        },
      };

      String filePath;
      if (widget.filePath != null) {
        filePath = widget.filePath!;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final privateDir = Directory('${appDir.path}/private_space/notes');
        await privateDir.create(recursive: true);

        final fileName = 'note_$now.json';
        filePath = '${privateDir.path}/$fileName';
      }

      await File(filePath).writeAsString(jsonEncode(noteData));

      setState(() {
        _originalTitle = title;
        _originalContent = content;
        _hasUnsavedChanges = false;
      });

      if (widget.onSave != null) {
        widget.onSave!(filePath);
      }

      _showSuccessSnackBar('Note saved successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to save note: $e');
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (_isEditing) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _contentFocusNode.requestFocus();
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
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Text Formatting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Font Size:',
                      style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setModalState(() => _fontSize = value);
                        setState(() => _fontSize = value);
                      },
                    ),
                  ),
                  Text(
                    '${_fontSize.round()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Insert',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickInsertChip('• ', 'Bullet Point'),
                  _buildQuickInsertChip('□ ', 'Checkbox'),
                  _buildQuickInsertChip('→ ', 'Arrow'),
                  _buildQuickInsertChip('★ ', 'Star'),
                  _buildQuickInsertChip('❤ ', 'Heart'),
                  _buildQuickInsertChip('✓ ', 'Checkmark'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInsertChip(String symbol, String label) {
    return GestureDetector(
      onTap: () {
        _insertText(symbol);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Note Statistics',
            style: TextStyle(color: Colors.white)),
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
            child: const Text('Close', style: TextStyle(color: Colors.teal)),
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
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Edit Note' : 'View Note',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(
                  Icons.circle,
                  color: Colors.orange,
                  size: 12,
                ),
              ),
            IconButton(
              icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
              onPressed: _toggleEditing,
            ),
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.text_fields),
                onPressed: _formatText,
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: _showWordCount,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black87,
                Colors.grey[900]!,
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      enabled: _isEditing,
                      maxLines: null,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            _isEditing ? 'Note title...' : 'Untitled Note',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(right: 15),
                          child: const Icon(
                            Icons.title,
                            color: Colors.teal,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        enabled: _isEditing,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: _isEditing
                              ? 'Start writing your note...\n\n• Use bullet points\n• Add checkboxes □\n• Include important details'
                              : 'No content',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: _fontSize,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildToolbarButton(
                            icon: Icons.undo,
                            onPressed: _canUndo() ? _undo : null,
                            isEnabled: _canUndo(),
                          ),
                          _buildToolbarButton(
                            icon: Icons.redo,
                            onPressed: _canRedo() ? _redo : null,
                            isEnabled: _canRedo(),
                          ),
                          const SizedBox(width: 20),
                          _buildToolbarButton(
                            icon: Icons.content_copy,
                            onPressed: () {
                              if (_contentController.text.isNotEmpty) {
                                Clipboard.setData(ClipboardData(
                                    text: _contentController.text));
                                _showSuccessSnackBar(
                                    'Content copied to clipboard');
                              }
                            },
                          ),
                          _buildToolbarButton(
                            icon: Icons.content_paste,
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData('text/plain');
                              if (data != null && data.text != null) {
                                _insertText(data.text!);
                                _showSuccessSnackBar('Content pasted');
                              }
                            },
                          ),
                          const Spacer(),
                          Text(
                            '${_contentController.text.length} chars',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? Colors.white.withOpacity(0.8)
              : Colors.white.withOpacity(0.3),
          size: 18,
        ),
      ),
    );
  }
}
