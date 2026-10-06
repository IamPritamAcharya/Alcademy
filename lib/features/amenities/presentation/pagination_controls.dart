import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  const PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous amenities',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
        ),
        Expanded(
          child: Text(
            '$currentPage / $totalPages',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppStyle.muted),
          ),
        ),
        IconButton(
          tooltip: 'Next amenities',
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    ),
  );
}
