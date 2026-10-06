import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';

class NoteFormattingSheet extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onInsert;
  const NoteFormattingSheet({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.onInsert,
  });

  @override
  State<NoteFormattingSheet> createState() => _NoteFormattingSheetState();
}

class _NoteFormattingSheetState extends State<NoteFormattingSheet> {
  late double _fontSize;
  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppStyle.text.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Text Formatting',
          style: TextStyle(
            color: AppStyle.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('Font Size:', style: TextStyle(color: AppStyle.text)),
            Expanded(
              child: Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                activeColor: AppStyle.blue,
                onChanged: (value) {
                  setState(() => _fontSize = value);
                  widget.onFontSizeChanged(value);
                },
              ),
            ),
            Text(
              '${_fontSize.round()}',
              style: const TextStyle(color: AppStyle.text),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Quick Insert',
          style: TextStyle(
            color: AppStyle.text,
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
  );

  Widget _buildQuickInsertChip(String symbol, String label) {
    return GestureDetector(
      onTap: () {
        widget.onInsert(symbol);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppStyle.rule.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppStyle.rule),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: const TextStyle(color: AppStyle.text, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppStyle.text.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
