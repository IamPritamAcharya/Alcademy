import 'dart:ui';
import 'package:flutter/material.dart';

class EditItemDialog extends StatefulWidget {
  final String initialItem;
  final double initialValue;
  final DateTime initialDate;

  const EditItemDialog({
    Key? key,
    required this.initialItem,
    required this.initialValue,
    required this.initialDate,
  }) : super(key: key);

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
    _valueController =
        TextEditingController(text: widget.initialValue.toStringAsFixed(2));
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
              primary: const Color.fromRGBO(0, 255, 127, 1), // Highlight color
              onPrimary: Colors.black, // Text color for selected date
              surface: const Color(0xFF1A1D1E), // Dialog background color
              onSurface: Colors.white, // Text color for unselected dates
            ),
            dialogBackgroundColor: const Color(0xFF1A1D1E), // Background color
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    const Color.fromRGBO(0, 255, 127, 1), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Glass effect
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
                  color: Colors.grey.shade800.withOpacity(0.1),
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
                      const Text(
                        'Edit Expense',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _itemController,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Item Name',
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Date: ',
                            style: TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text(
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.blueAccent,
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
                              final item = _itemController.text.trim();
                              final value =
                                  double.tryParse(_valueController.text.trim());
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
