import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class CollectionIntro extends StatelessWidget {
  final String title;
  final String eyebrow;
  final String? detail;
  const CollectionIntro({
    super.key,
    required this.title,
    required this.eyebrow,
    this.detail,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppStyle.eyebrow),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppStyle.text,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.12,
            letterSpacing: -1,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 10),
          Text(
            detail!,
            style: const TextStyle(
              color: AppStyle.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    ),
  );
}
