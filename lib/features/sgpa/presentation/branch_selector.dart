import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/widgets/study_selection_field.dart';
import 'package:port/features/sgpa/data/data.dart';
import 'package:port/features/sgpa/presentation/subject_grade_input.dart';

class BranchSelector extends StatefulWidget {
  const BranchSelector({super.key});
  @override
  State<BranchSelector> createState() => _BranchSelectorState();
}

class _BranchSelectorState extends State<BranchSelector> {
  String? _branch;
  String? _semester;

  Future<void> _help() async {
    final url = Uri.parse(
      'https://drive.google.com/file/d/1MpOBukzyyM4qUGhZUt0MzV6gmhaA1ppB/view?usp=sharing',
    );
    try {
      if (await launchUrl(url)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn’t open the grading guide. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = subjectCreditMap[_branch]?[_semester] ?? [];
    final credits = subjects.fold<int>(
      0,
      (total, subject) => total + (subject['credit'] as int),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SGPA calculator',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: const AppBarDivider(),
        actions: [
          IconButton(
            tooltip: 'Grading guide',
            onPressed: _help,
            icon: const Icon(Icons.help_outline_rounded, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const CollectionIntro(
            eyebrow: '01 / YOUR SEMESTER',
            title: 'Set up your\nsemester.',
            detail: 'Choose your course, then add the grades you earned.',
          ),
          StudySelectionField(
            label: 'Branch',
            hint: 'Choose your branch',
            value: _branch,
            options: subjectCreditMap.keys.toList(),
            onSelected: (value) => setState(() {
              _branch = value;
              _semester = null;
            }),
          ),
          const SizedBox(height: 12),
          StudySelectionField(
            key: ValueKey(_branch),
            label: 'Semester',
            hint: _branch == null
                ? 'Choose a branch first'
                : 'Choose your semester',
            value: _semester,
            options: subjectCreditMap[_branch]?.keys.toList() ?? [],
            onSelected: (value) => setState(() => _semester = value),
          ),
          const SizedBox(height: 28),
          if (_semester != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppStyle.rule),
                  bottom: BorderSide(color: AppStyle.rule),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: _stat('${subjects.length}', 'SUBJECTS')),
                  Container(width: 1, height: 48, color: AppStyle.rule),
                  const SizedBox(width: 24),
                  Expanded(child: _stat('$credits', 'CREDITS')),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Text('HOW IT WORKS', style: AppStyle.eyebrow),
          const SizedBox(height: 10),
          const Text(
            'Each grade is weighted by its subject’s credits. Your semester score is calculated on a 10-point scale.',
            style: TextStyle(color: AppStyle.muted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: FilledButton(
          onPressed: _branch != null && _semester != null && subjects.isNotEmpty
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectGradeInput(
                      branch: _branch!,
                      semester: _semester!,
                    ),
                  ),
                )
              : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Choose grades',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: AppStyle.eyebrow),
    ],
  );
}
