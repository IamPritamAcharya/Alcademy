import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String branch;
  final VoidCallback onEditName;
  const ProfileCard({
    super.key,
    required this.userName,
    required this.branch,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppStyle.surface,
      borderRadius: AppStyle.radius,
      border: Border.all(color: AppStyle.rule),
    ),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 72,
          decoration: const BoxDecoration(
            color: AppStyle.accent,
            borderRadius: AppStyle.radius,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOUR PROFILE', style: AppStyle.eyebrow),
              const SizedBox(height: 10),
              AutoSizeText(
                userName,
                maxLines: 2,
                minFontSize: 16,
                style: const TextStyle(
                  color: AppStyle.text,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                branch,
                style: const TextStyle(
                  color: AppStyle.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Edit name',
          onPressed: onEditName,
          icon: const Icon(
            Icons.edit_note_outlined,
            color: AppStyle.paper,
            size: 26,
          ),
        ),
      ],
    ),
  );
}
