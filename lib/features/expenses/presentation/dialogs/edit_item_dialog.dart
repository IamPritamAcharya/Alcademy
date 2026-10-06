import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';

class EditItemDialog extends StatefulWidget {
  final String initialItem;
  final double initialValue;
  final DateTime initialDate;

  const EditItemDialog({
    super.key,
    required this.initialItem,
    required this.initialValue,
    required this.initialDate,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _itemController;
  late TextEditingController _valueController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.initialItem);
    _valueController = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppStyle.accent,
              onPrimary: Colors.black,
              surface: AppStyle.background,
              onSurface: AppStyle.text,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppStyle.accent),
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppStyle.background),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppStyle.rule, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Expense',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppStyle.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _itemController,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 18,
                        color: AppStyle.text,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        labelStyle: TextStyle(
                          fontFamily: 'ProductSans',
                          color: AppStyle.muted,
                        ),
                        filled: true,
                        fillColor: AppStyle.rule.withValues(alpha: 0.2),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppStyle.rule),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppStyle.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 18,
                        color: AppStyle.text,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(
                          fontFamily: 'ProductSans',
                          color: AppStyle.muted,
                        ),
                        filled: true,
                        fillColor: AppStyle.rule.withValues(alpha: 0.2),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppStyle.rule),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppStyle.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Date: ',
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            color: AppStyle.text,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              color: AppStyle.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: AppStyle.muted,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyle.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final item = _itemController.text.trim();
                            final value = double.tryParse(
                              _valueController.text.trim(),
                            );
                            if (item.isNotEmpty && value != null) {
                              Navigator.pop(context, {
                                'item': item,
                                'value': value,
                                'date': _selectedDate.toIso8601String(),
                              });
                            }
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: AppStyle.onAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
