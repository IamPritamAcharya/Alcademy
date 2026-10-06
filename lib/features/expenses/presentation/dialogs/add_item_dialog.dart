import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

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
                      'Add Expense',
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
                          borderSide: BorderSide(color: AppStyle.text),
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
                          borderSide: BorderSide(color: AppStyle.text),
                        ),
                      ),
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
                                'date': DateTime.now().toIso8601String(),
                              });
                            }
                          },
                          child: const Text(
                            'Add',
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
