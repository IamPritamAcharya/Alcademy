import 'package:flutter/material.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:port/features/home/presentation/widgets/home_style.dart';

class HomeSubjectList extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(BuildContext, Subject) onSubjectTap;
  const HomeSubjectList({
    super.key,
    required this.subjects,
    required this.onSubjectTap,
  });

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    sliver: SliverList.builder(
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Material(
          color: HomeStyle.background,
          child: InkWell(
            onTap: () => onSubjectTap(context, subject),
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: HomeStyle.rule)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? HomeStyle.surface
                          : HomeStyle.warmSurface,
                      border: const Border(
                        left: BorderSide(color: HomeStyle.sage, width: 3),
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: HomeStyle.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: const TextStyle(
                            color: HomeStyle.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${subject.items.length} ${subject.items.length == 1 ? 'resource' : 'resources'}',
                          style: const TextStyle(
                            color: HomeStyle.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.north_east_rounded,
                    color: HomeStyle.text,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
