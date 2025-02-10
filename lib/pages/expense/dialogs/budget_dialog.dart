import 'dart:ui';

import 'package:flutter/material.dart';

class BudgetDialog extends StatelessWidget {
  final double initialBudget;

  const BudgetDialog({Key? key, required this.initialBudget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: initialBudget.toStringAsFixed(2));

    return Dialog(
      backgroundColor: Colors.transparent, // Transparent for glass morphism
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          // Glass effect
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800.withOpacity(0.1), // Frosted glass
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero widget for smooth transition
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
                              color: Colors.white,
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
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'New Budget',
                          labelStyle: TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade700.withOpacity(0.2),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blueAccent),
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
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(0, 255, 127, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final newBudget =
                                  double.tryParse(controller.text.trim());
                              if (newBudget != null) {
                                Navigator.pop(context, newBudget);
                              }
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}
