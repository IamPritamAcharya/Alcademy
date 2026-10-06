import 'package:flutter/material.dart';

class PrivateNoteDialog extends StatefulWidget {
  final Future<void> Function(String title, String content) onSave;
  const PrivateNoteDialog({super.key, required this.onSave});
  @override
  State<PrivateNoteDialog> createState() => _PrivateNoteDialogState();
}

class _PrivateNoteDialogState extends State<PrivateNoteDialog> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New note'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Untitled note',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _content,
          minLines: 4,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Note',
            hintText: 'Start writing…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving || _content.text.isEmpty
            ? null
            : () async {
                setState(() => _saving = true);
                await widget.onSave(_title.text, _content.text);
                if (context.mounted) Navigator.pop(context);
              },
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}
