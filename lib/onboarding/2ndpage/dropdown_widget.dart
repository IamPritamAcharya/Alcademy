import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class DropdownWidget extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;

  const DropdownWidget({
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: DropdownButtonFormField2(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white70, width: 1),
              borderRadius: BorderRadius.circular(30),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: Colors.pinkAccent, width: 1.5),
              borderRadius: BorderRadius.circular(30),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          buttonStyleData: ButtonStyleData(
            height: 30, // Keep the reduced height you originally intended
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.transparent,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight:
                MediaQuery.of(context).size.height * 0.3, // Scrolling enabled
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.black87,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'ProductSans',
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          isExpanded: true, // Ensure the dropdown expands to the full width.
        ),
      ),
    );
  }
}
