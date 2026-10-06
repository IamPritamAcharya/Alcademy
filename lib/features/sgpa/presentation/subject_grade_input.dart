import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/features/sgpa/data/data.dart';
import 'package:port/features/sgpa/presentation/sgpa_calculator.dart';

class SubjectGradeInput extends StatefulWidget {
  final String branch;
  final String semester;
  const SubjectGradeInput({
    super.key,
    required this.branch,
    required this.semester,
  });
  @override
  State<SubjectGradeInput> createState() => _SubjectGradeInputState();
}

class _SubjectGradeInputState extends State<SubjectGradeInput> {
  static const _grades = ['O', 'E', 'A', 'B', 'C', 'D', 'M'];
  final Map<String, String> _selected = {};

  void _showResult(List<Map<String, dynamic>> subjects) {
    final sgpa = calculateSGPA(_selected, subjects);
    final credits = subjects.fold<int>(
      0,
      (sum, subject) => sum + (subject['credit'] as int),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SEMESTER RESULT', style: AppStyle.eyebrow),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      sgpa.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -3,
                        height: 1.1,
                        color: AppStyle.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '/ 10',
                      style: TextStyle(fontSize: 22, color: AppStyle.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${widget.semester} · ${subjects.length} subjects · $credits credits',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                widget.branch,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppStyle.muted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = subjectCreditMap[widget.branch]?[widget.semester] ?? [];
    final complete =
        subjects.isNotEmpty &&
        subjects.every((subject) => _selected.containsKey(subject['subject']));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your grades'),
        bottom: const AppBarDivider(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          CollectionIntro(
            eyebrow: '02 / GRADE SHEET',
            title: widget.semester,
            detail: widget.branch,
          ),
          const Text(
            'O 10 · E 9 · A 8 · B 7 · C 6 · D 5 · M 0',
            style: TextStyle(fontSize: 12, height: 1.6, color: AppStyle.muted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < subjects.length; i++)
            _subject(subjects[i], i + 1),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selected.length} of ${subjects.length} graded',
                    style: const TextStyle(fontSize: 12, color: AppStyle.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  complete ? 'Ready' : 'Select every grade',
                  style: const TextStyle(fontSize: 11, color: AppStyle.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: subjects.isEmpty ? 0 : _selected.length / subjects.length,
              backgroundColor: AppStyle.rule,
              color: AppStyle.lilac,
              minHeight: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: complete ? () => _showResult(subjects) : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Calculate SGPA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subject(Map<String, dynamic> data, int index) {
    final name = data['subject'] as String;
    final credit = data['credit'] as int;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppStyle.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index.toString().padLeft(2, '0')} / $credit ${credit == 1 ? 'CREDIT' : 'CREDITS'}',
            style: AppStyle.eyebrow,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final grade in _grades)
                Semantics(
                  label: '$name: grade $grade',
                  selected: _selected[name] == grade,
                  child: ChoiceChip(
                    key: ValueKey('grade-$name-$grade'),
                    label: Text(grade),
                    selected: _selected[name] == grade,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selected[name] = grade),
                    selectedColor: AppStyle.paper,
                    backgroundColor: AppStyle.surface,
                    side: BorderSide(
                      color: _selected[name] == grade
                          ? AppStyle.paper
                          : AppStyle.rule,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selected[name] == grade
                          ? AppStyle.background
                          : AppStyle.muted,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 8,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
