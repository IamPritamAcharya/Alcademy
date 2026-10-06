import 'package:flutter/material.dart';

class NoteFormattingSheet extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onInsert;
  const NoteFormattingSheet(
      {super.key,
      required this.fontSize,
      required this.onFontSizeChanged,
      required this.onInsert});

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
                color: Colors.white.withValues(alpha: 0.3),
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
                const Text('Font Size:', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    activeColor: Colors.teal,
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                      widget.onFontSizeChanged(value);
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
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
