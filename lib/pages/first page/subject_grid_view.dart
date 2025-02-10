import 'dart:ui';
import 'package:flutter/material.dart';
import 'subject_model.dart';

class SubjectGridView extends StatelessWidget {
  final List<Subject> subjects;
  final Function(BuildContext, Subject) onSubjectTap;

  const SubjectGridView({
    Key? key,
    required this.subjects,
    required this.onSubjectTap,
  }) : super(key: key);

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
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 0,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subject = subjects[index];
            return GestureDetector(
              onTap: () => onSubjectTap(context, subject),
              child: SubjectCard(subject: subject),
            );
          },
          childCount: subjects.length,
        ),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_rounded, // Default subject icon
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              subject.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
