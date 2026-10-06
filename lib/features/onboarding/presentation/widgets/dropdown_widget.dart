import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:port/shared/theme/app_style.dart';

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
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    child: DropdownButtonFormField2<String>(
      value: value,
      hint: Text(
        label,
        style: const TextStyle(color: AppStyle.muted, fontSize: 14),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppStyle.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppStyle.rule),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppStyle.paper),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      buttonStyleData: const ButtonStyleData(
        padding: EdgeInsets.symmetric(horizontal: 14),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: MediaQuery.sizeOf(context).height * .4,
        offset: const Offset(0, -5),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppStyle.surface,
          border: Border.all(color: AppStyle.rule),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      iconStyleData: const IconStyleData(
        icon: Icon(Icons.unfold_more_rounded, color: AppStyle.muted, size: 20),
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 54,
        padding: EdgeInsets.symmetric(horizontal: 18),
      ),
      selectedItemBuilder: (_) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppStyle.text, fontSize: 14),
              ),
            ),
          )
          .toList(),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppStyle.text, fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    ),
  );
}
