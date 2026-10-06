import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

/// A scrollable introduction that shares the app's journal typography.
class OnboardingIntro extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final Color accent;
  final VoidCallback onNext;
  const OnboardingIntro({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.accent,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 100),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 136).clamp(0, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ALCADEMY / THE STUDENT JOURNAL',
                style: AppStyle.eyebrow,
              ),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: .25)),
                ),
                child: Icon(icon, color: accent, size: 40),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  color: AppStyle.text,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                description,
                style: const TextStyle(
                  color: AppStyle.muted,
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppStyle.background,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(buttonLabel),
                      const SizedBox(width: 20),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
