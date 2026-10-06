import 'package:port/shared/theme/app_style.dart';

import 'package:flutter/material.dart';

class BudgetDialog extends StatelessWidget {
  final double initialBudget;

  const BudgetDialog({super.key, required this.initialBudget});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: initialBudget.toStringAsFixed(2),
    );

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
                    Hero(
                      tag: 'currentBudget',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          'Current Budget',
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppStyle.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 18,
                        color: AppStyle.text,
                      ),
                      decoration: InputDecoration(
                        labelText: 'New Budget',
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
                            final newBudget = double.tryParse(
                              controller.text.trim(),
                            );
                            if (newBudget != null) {
                              Navigator.pop(context, newBudget);
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
