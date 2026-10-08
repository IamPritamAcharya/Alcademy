import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:port/shared/theme/app_style.dart';

enum _LoadingLayout { fees, holidays }

/// Page-specific silhouettes; only the placeholder ink animates.
class ErpLoadingPanel extends StatelessWidget {
  final String status;
  final _LoadingLayout _layout;
  const ErpLoadingPanel.fees({super.key, required this.status})
    : _layout = _LoadingLayout.fees;
  const ErpLoadingPanel.holidays({super.key, required this.status})
    : _layout = _LoadingLayout.holidays;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _layout == _LoadingLayout.fees
            ? const EdgeInsets.all(24)
            : const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          ExcludeSemantics(
            child: _layout == _LoadingLayout.fees
                ? _fees(context)
                : _holidays(context),
          ),
        ],
      ),
      Positioned(
        left: 24,
        right: 24,
        bottom: 16,
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: AppStyle.background.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                status,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppStyle.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _shimmer(BuildContext context, Widget child) => RepaintBoundary(
    child: Shimmer.fromColors(
      baseColor: AppStyle.cover,
      highlightColor: AppStyle.rule,
      period: const Duration(milliseconds: 2600),
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: child,
    ),
  );

  Widget _fees(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // The loaded page's summary shell stays visible; its contents shimmer.
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppStyle.surface, Color(0xFF302C36)],
          ),
          border: Border.all(color: AppStyle.rule.withValues(alpha: .5)),
        ),
        child: _shimmer(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text(context, 10, 80),
              const SizedBox(height: 12),
              _text(context, 34, 200),
              const SizedBox(height: 6),
              _text(context, 12, 135),
              const SizedBox(height: 18),
              _line(double.infinity, 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [_text(context, 12, 55), _text(context, 12, 125)],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      _shimmer(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(context, 10, 75),
            const SizedBox(height: 20),
            _text(context, 10, 40),
            const SizedBox(height: 8),
            for (var index = 0; index < 3; index++) _feeRow(context),
          ],
        ),
      ),
    ],
  );

  Widget _feeRow(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white, width: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              _text(context, 24, 30),
              const SizedBox(height: 4),
              _text(context, 10, 28),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _text(context, 24, double.infinity)),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: Center(child: _line(12, 14)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _text(context, 14, 140, height: 1.4),
              const SizedBox(height: 7),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [_text(context, 11, 55), _text(context, 11, 45)],
              ),
              const SizedBox(height: 10),
              _text(context, 12, 100),
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    _text(context, 12, 80),
                    const Spacer(),
                    _line(10, 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _holidays(BuildContext context) => _shimmer(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text(context, 10, 110),
        const SizedBox(height: 12),
        _text(context, 12, 80),
        const SizedBox(height: 6),
        _text(context, 26, 240),
        const SizedBox(height: 8),
        _text(context, 14, 160),
        const SizedBox(height: 26),
        _text(context, 10, 125),
        const SizedBox(height: 10),
        for (var index = 0; index < 4; index++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white, width: .5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [_text(context, 24, 30), _text(context, 10, 25)],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(
                        context,
                        16,
                        index.isEven ? 190 : 130,
                        height: 1.35,
                      ),
                      const SizedBox(height: 5),
                      _text(context, 12, index.isEven ? 115 : 150, height: 1.5),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _text(
    BuildContext context,
    double fontSize,
    double width, {
    double? height,
  }) => _line(
    width,
    MediaQuery.textScalerOf(context).scale(fontSize) *
        (height ?? DefaultTextStyle.of(context).style.height ?? 1.2),
  );

  Widget _line(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
