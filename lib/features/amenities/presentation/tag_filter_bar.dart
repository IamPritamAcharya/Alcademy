import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagSelected;
  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final tag in ['', ...tags])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tag.isEmpty ? 'All places' : tag),
              selected: selectedTag == tag,
              showCheckmark: false,
              selectedColor: AppStyle.paper,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                fontSize: 12,
                color: selectedTag == tag
                    ? AppStyle.background
                    : AppStyle.muted,
              ),
              side: BorderSide(
                color: selectedTag == tag ? AppStyle.paper : AppStyle.rule,
              ),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onSelected: (_) => onTagSelected(tag),
            ),
          ),
      ],
    ),
  );
}
