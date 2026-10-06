import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 0,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return Shimmer.fromColors(
            baseColor: AppStyle.surface,
            highlightColor: AppStyle.rule,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyle.surface,
                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: AppStyle.rule.withValues(alpha: .65)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 32, width: 32, color: AppStyle.rule),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 80, color: AppStyle.rule),
                  ],
                ),
              ),
            ),
          );
        }, childCount: 4),
      ),
    );
  }
}
