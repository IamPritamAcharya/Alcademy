import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/search_results_page.dart';

/// A wrapping selection field with a dedicated searchable option page.
class StudySelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  const StudySelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppStyle.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: AppStyle.rule),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: options.isEmpty
          ? null
          : () async {
              final selected = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsPage<String>(
                    title: 'Choose ${label.toLowerCase()}',
                    hint: 'Find a ${label.toLowerCase()}',
                    items: options,
                    searchableText: (option) => option,
                    resultBuilder: (context, option, index) => Material(
                      color: option == value
                          ? AppStyle.cover
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppStyle.rule),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                option == value
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                                color: option == value
                                    ? AppStyle.lilac
                                    : AppStyle.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              if (context.mounted && selected != null) onSelected(selected);
            },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: AppStyle.eyebrow),
                  const SizedBox(height: 8),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: value == null ? AppStyle.muted : AppStyle.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.unfold_more_rounded,
              color: AppStyle.muted,
              size: 22,
            ),
          ],
        ),
      ),
    ),
  );
}
