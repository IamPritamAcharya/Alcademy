import 'package:flutter/material.dart';

class TagFilterBar extends StatelessWidget {
  final List<String> tags;
  final String selectedTag;
  final Function(String) onTagSelected;

  const TagFilterBar({
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            ChoiceChip(
              label: Text(
                'All',
                style: TextStyle(
                    fontFamily: 'ProductSans',
                    color: selectedTag.isEmpty ? Colors.black : Colors.white),
              ),
              selected: selectedTag.isEmpty,
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFF1A1D1E),
              onSelected: (isSelected) => onTagSelected(''),
            ),
            SizedBox(
              width: 4,
            ),
            ...tags.map((tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                          fontFamily: 'ProductSans',
                          color:
                              selectedTag == tag ? Colors.black : Colors.white),
                    ),
                    selected: selectedTag == tag,
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF1A1D1E),
                    onSelected: (isSelected) => onTagSelected(tag),
                    
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
