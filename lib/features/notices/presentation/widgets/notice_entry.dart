import 'package:flutter/material.dart';
import 'package:port/features/notices/models/notice.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/editorial_list_row.dart';

class NoticeEntry extends StatelessWidget {
  final Notice notice;
  final int number;
  final bool featured;
  final VoidCallback onTap;
  const NoticeEntry({
    super.key,
    required this.notice,
    required this.number,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final kind = notice.downloadLink.toLowerCase().endsWith('.pdf')
        ? 'PDF'
        : 'LINK';
    if (!featured) {
      return EditorialListRow(
        number: number,
        title: notice.title,
        category: kind == 'PDF' ? 'College circular / PDF' : 'College circular',
        subtitle: notice.date,
        onTap: onTap,
      );
    }
    return Material(
      color: AppStyle.surface,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppStyle.gold, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CIRCULAR / ${number.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppStyle.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kind,
                    style: const TextStyle(
                      color: AppStyle.muted,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                notice.title,
                style: const TextStyle(
                  color: AppStyle.text,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.date,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.north_east_rounded,
                    color: AppStyle.gold,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
