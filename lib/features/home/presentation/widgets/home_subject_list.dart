import 'package:flutter/material.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';

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
        final tint = AppStyle.highlights[index % AppStyle.highlights.length];
        return HomePressable(
          entranceOrder: index,
          color: AppStyle.background,
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSubjectTap(context, subject),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppStyle.rule)),
            ),
            child: Row(
              children: [
                _BookCover(tint: tint, number: index + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          color: AppStyle.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${subject.items.length} ${subject.items.length == 1 ? 'resource' : 'resources'}',
                        style: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east_rounded,
                  color: AppStyle.text,
                  size: 19,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _BookCover extends StatelessWidget {
  final Color tint;
  final int number;
  const _BookCover({required this.tint, required this.number});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: number.isEven ? .025 : -.025,
      child: CustomPaint(
        painter: _BookCoverPainter(tint),
        child: SizedBox(
          width: 44,
          height: 58,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
            child: Center(
              child: Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: AppStyle.background,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BookCoverPainter extends CustomPainter {
  final Color tint;
  const _BookCoverPainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 4, size.width - 2, size.height - 4),
        const Radius.circular(3),
      ),
      Paint()..color = AppStyle.text,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height - 5),
        const Radius.circular(3),
      ),
      Paint()..color = tint,
    );
    canvas.drawLine(
      const Offset(6, 0),
      Offset(6, size.height - 5),
      Paint()
        ..color = AppStyle.background.withValues(alpha: .35)
        ..strokeWidth = .8,
    );
    canvas.drawLine(
      Offset(7, size.height - 2),
      Offset(size.width - 3, size.height - 2),
      Paint()
        ..color = AppStyle.background.withValues(alpha: .2)
        ..strokeWidth = .6,
    );
  }

  @override
  bool shouldRepaint(_BookCoverPainter oldDelegate) => tint != oldDelegate.tint;
}
