import 'package:port/shared/theme/app_style.dart';
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppStyle.radius,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: DropdownButtonFormField2(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppStyle.muted),
            filled: true,
            fillColor: AppStyle.surface,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppStyle.muted, width: 1),
              borderRadius: AppStyle.radius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppStyle.accent, width: 1.5),
              borderRadius: AppStyle.radius,
            ),
            border: OutlineInputBorder(borderRadius: AppStyle.radius),
          ),
          buttonStyleData: ButtonStyleData(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: AppStyle.radius,
              color: Colors.transparent,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              borderRadius: AppStyle.radius,
              color: AppStyle.surface,
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down, color: AppStyle.text),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppStyle.text,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }
}
