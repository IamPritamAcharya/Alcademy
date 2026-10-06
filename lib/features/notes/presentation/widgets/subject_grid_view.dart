import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:port/features/notes/models/subject.dart';

class SubjectGridView extends StatelessWidget {
  final List<Subject> subjects;
  final Function(BuildContext, Subject) onSubjectTap;

  const SubjectGridView({
    super.key,
    required this.subjects,
    required this.onSubjectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            "No subjects found.",
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: AppStyle.text.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final subject = subjects[index];
          return GestureDetector(
            onTap: () => onSubjectTap(context, subject),
            child: SubjectCard(subject: subject),
          );
        }, childCount: subjects.length),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final initials = _getSubjectInitials(subject.name);

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: AppStyle.radius,
        color: AppStyle.surface,

        border: Border.all(color: AppStyle.rule.withValues(alpha: .65)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppStyle.rule.withValues(alpha: .65),
                    border: Border.all(color: AppStyle.rule),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.text,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AutoSizeText(
                    subject.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: AppStyle.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSubjectInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
