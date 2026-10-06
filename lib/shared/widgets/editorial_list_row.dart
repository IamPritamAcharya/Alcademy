import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

/// A quiet, numbered index row shared by reading and study lists.
class EditorialListRow extends StatelessWidget {
  final int number;
  final String title;
  final String category;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color accent;
  const EditorialListRow({
    super.key,
    required this.number,
    required this.title,
    required this.category,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.accent = AppStyle.gold,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppStyle.rule)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                SizedBox(
                  width: 28,
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: AppStyle.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppStyle.text,
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.3,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: AppStyle.muted,
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
