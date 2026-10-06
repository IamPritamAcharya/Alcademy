import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

/// The three opening spreads share typography, but each has its own artwork.
class OnboardingIntro extends StatelessWidget {
  final String title;
  final String description;
  final String buttonLabel;
  final Color accent;
  final VoidCallback onNext;
  final int spread;
  final String kicker;

  const OnboardingIntro({
    super.key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.accent,
    required this.onNext,
    this.spread = 0,
    this.kicker = 'MADE FOR YOUR CAMPUS',
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey(spread),
                        tween: Tween(begin: 0, end: 1),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: Transform.rotate(
                              angle: (1 - value) * -.04,
                              child: child,
                            ),
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: AspectRatio(
                            aspectRatio: constraints.maxHeight < 650
                                ? 1.65
                                : 1.2,
                            child: CustomPaint(
                              painter: _SpreadPainter(spread, accent),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Container(width: 22, height: 2, color: accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              kicker,
                              style: AppStyle.eyebrow.copyWith(color: accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppStyle.text,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.8,
                          height: 1.06,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          OnboardingFooter(
            label: buttonLabel,
            onPressed: onNext,
            color: accent,
          ),
        ],
      ),
    ),
  );
}

/// Kept outside the scroll view so the next action is always within reach.
class OnboardingFooter extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final String? helper;
  final Color helperColor;
  const OnboardingFooter({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppStyle.paper,
    this.helper,
    this.helperColor = AppStyle.muted,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(26, 14, 26, 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (helper != null) ...[
              Text(
                helper!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: helperColor, height: 1.5),
              ),
              const SizedBox(height: 14),
            ],
            OnboardingButton(label: label, onPressed: onPressed, color: color),
          ],
        ),
      ),
    ),
  );
}

class OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppStyle.paper,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppStyle.background,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward_rounded, size: 22),
      ],
    ),
  );
}

/// Drawn like an editorial cover: paper, rules and typography, rather than an icon tile.
class _SpreadPainter extends CustomPainter {
  final int spread;
  final Color accent;
  const _SpreadPainter(this.spread, this.accent);

  void _text(
    Canvas canvas,
    String text,
    Offset point,
    double size,
    Color color, {
    FontWeight weight = FontWeight.bold,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: size,
          color: color,
          fontWeight: weight,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, point);
  }

  void _card(Canvas canvas, Rect rect, Color color, {double radius = 12}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  void _rule(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, {
    double width = 1,
  }) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 340, size.height / 280);
    final bounds = const Rect.fromLTWH(0, 0, 340, 280);
    _card(canvas, bounds, AppStyle.surface, radius: 24);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(24)),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withValues(alpha: .19),
            AppStyle.surface,
            AppStyle.surface,
          ],
        ).createShader(bounds),
    );
    for (var x = 18.0; x < 340; x += 22) {
      for (var y = 18.0; y < 280; y += 22) {
        canvas.drawCircle(
          Offset(x, y),
          .7,
          Paint()..color = AppStyle.paper.withValues(alpha: .12),
        );
      }
    }
    if (spread == 0) {
      canvas.save();
      canvas.translate(35, 38);
      canvas.rotate(-.10);
      _card(canvas, const Rect.fromLTWH(0, 0, 174, 208), AppStyle.blue);
      _text(canvas, 'NOTES', const Offset(17, 22), 12, AppStyle.background);
      for (var y = 60.0; y < 185; y += 18) {
        _rule(
          canvas,
          Offset(17, y),
          Offset(151, y),
          AppStyle.background.withValues(alpha: .17),
        );
      }
      canvas.restore();
      canvas.save();
      canvas.translate(127, 27);
      canvas.rotate(.10);
      _card(canvas, const Rect.fromLTWH(0, 0, 177, 224), AppStyle.paper);
      _card(canvas, const Rect.fromLTWH(0, 0, 9, 224), accent, radius: 3);
      _text(
        canvas,
        'ALCADEMY / 01',
        const Offset(24, 22),
        10,
        AppStyle.background,
      );
      _text(
        canvas,
        'Less\nsearch.\nMore\nlearning.',
        const Offset(23, 62),
        31,
        AppStyle.background,
      );
      _rule(
        canvas,
        const Offset(24, 196),
        const Offset(150, 196),
        AppStyle.background.withValues(alpha: .3),
      );
      canvas.restore();
      _card(
        canvas,
        const Rect.fromLTWH(18, 218, 100, 33),
        AppStyle.background,
        radius: 17,
      );
      _text(canvas, 'ALL IN REACH', const Offset(30, 230), 10, AppStyle.paper);
    } else if (spread == 1) {
      _text(
        canvas,
        'THE CAMPUS EDIT',
        const Offset(24, 24),
        11,
        AppStyle.paper,
      );
      _text(canvas, 'What’s new?', const Offset(24, 47), 27, AppStyle.text);
      _card(canvas, const Rect.fromLTWH(24, 93, 292, 81), AppStyle.paper);
      _card(canvas, const Rect.fromLTWH(36, 106, 49, 55), accent, radius: 8);
      _text(canvas, 'MON', const Offset(45, 114), 10, AppStyle.background);
      _text(canvas, '12', const Offset(43, 128), 26, AppStyle.background);
      _text(
        canvas,
        'Campus notices',
        const Offset(99, 110),
        19,
        AppStyle.background,
      );
      _text(
        canvas,
        'The details that matter.',
        const Offset(99, 140),
        12,
        AppStyle.cover,
        weight: FontWeight.normal,
      );
      _card(canvas, const Rect.fromLTWH(24, 184, 140, 70), AppStyle.cover);
      _text(canvas, 'ACADEMICS', const Offset(37, 198), 9, AppStyle.blue);
      _text(canvas, 'Plan ahead', const Offset(37, 222), 17, AppStyle.text);
      _rule(
        canvas,
        const Offset(144, 235),
        const Offset(152, 227),
        AppStyle.paper,
        width: 1.5,
      );
      _rule(
        canvas,
        const Offset(145, 227),
        const Offset(152, 227),
        AppStyle.paper,
        width: 1.5,
      );
      _rule(
        canvas,
        const Offset(152, 227),
        const Offset(152, 234),
        AppStyle.paper,
        width: 1.5,
      );
      _card(canvas, const Rect.fromLTWH(174, 184, 142, 70), accent);
      _text(
        canvas,
        'YOUR CAMPUS',
        const Offset(188, 198),
        9,
        AppStyle.background,
      );
      _text(
        canvas,
        'Stay in sync',
        const Offset(188, 222),
        17,
        AppStyle.background,
      );
    } else {
      final ring = Paint()
        ..color = accent.withValues(alpha: .23)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final radius in [70.0, 105.0, 145.0]) {
        canvas.drawCircle(const Offset(170, 140), radius, ring);
      }
      const colors = [
        AppStyle.accent,
        AppStyle.blue,
        AppStyle.gold,
        AppStyle.lilac,
      ];
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 - .5;
        final point = Offset(
          170 + math.cos(angle) * 107,
          140 + math.sin(angle) * 92,
        );
        canvas.drawCircle(point, 21, Paint()..color = colors[i]);
        _text(
          canvas,
          ['A', 'S', 'P', 'R'][i],
          point - const Offset(6, 9),
          19,
          AppStyle.background,
        );
      }
      _card(
        canvas,
        const Rect.fromLTWH(89, 100, 162, 79),
        AppStyle.paper,
        radius: 20,
      );
      _text(
        canvas,
        'Real lives.',
        const Offset(111, 112),
        27,
        AppStyle.background,
      );
      _text(
        canvas,
        'Big ideas.',
        const Offset(111, 139),
        27,
        AppStyle.background,
      );
      _card(
        canvas,
        const Rect.fromLTWH(85, 229, 171, 29),
        AppStyle.background,
        radius: 15,
      );
      _text(
        canvas,
        'STORIES WORTH EXPLORING',
        const Offset(101, 239),
        9,
        AppStyle.lilac,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpreadPainter oldDelegate) =>
      oldDelegate.spread != spread || oldDelegate.accent != accent;
}
