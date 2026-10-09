import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

/// Each style has its own geometry and arrangement, rather than just swapping
/// a symbol on one grid. The seeded detail stays still while reading.
class StoryPatternPainter extends CustomPainter {
  static const variantCount = 10;
  final int seed;
  final int? variant;
  const StoryPatternPainter(this.seed, {this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(seed);
    final style = (variant ?? seed).abs() % variantCount;
    final spacing = switch (style) {
      3 => 17.0,
      4 => 18.0,
      5 => 14.0,
      6 => 16.0,
      8 => 18.0,
      _ => 22.0,
    };
    final stepY = switch (style) {
      3 => spacing * .866,
      4 => spacing * .65,
      8 => spacing * 1.3,
      _ => spacing,
    };
    final offset = random.nextDouble() * spacing;
    final paint = Paint()..isAntiAlias = true;
    final glint = Path()
      ..moveTo(0, -3)
      ..quadraticBezierTo(.65, -.65, 3, 0)
      ..quadraticBezierTo(.65, .65, 0, 3)
      ..quadraticBezierTo(-.65, .65, -3, 0)
      ..quadraticBezierTo(-.65, -.65, 0, -3)
      ..close();
    final leaf = Path()
      ..moveTo(-3, 0)
      ..quadraticBezierTo(0, -3.5, 3, 0)
      ..quadraticBezierTo(0, 3.5, -3, 0)
      ..close();
    final hexagon = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final point = Offset(math.cos(angle) * 7, math.sin(angle) * 7);
      if (i == 0) {
        hexagon.moveTo(point.dx, point.dy);
      } else {
        hexagon.lineTo(point.dx, point.dy);
      }
    }
    hexagon.close();

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var row = -1; row * stepY < size.height + spacing; row++) {
      for (var column = -1; column * spacing < size.width + spacing; column++) {
        final variation = random.nextDouble();
        final scatter = style == 0 || style == 6;
        final stagger = style == 3 || style == 4 || style == 8 || style == 9;
        final x =
            column * spacing +
            (stagger && row.isOdd ? spacing / 2 : 0) +
            offset +
            (scatter ? (variation - .5) * spacing * .8 : 0);
        final y =
            row * stepY +
            offset +
            (scatter ? (random.nextDouble() - .5) * stepY * .8 : 0);
        final nx = (x - size.width / 2) / (size.width / 2);
        final ny = (y - size.height / 2) / (size.height / 2);
        final edge = (math.sqrt(nx * nx + ny * ny) / 1.2).clamp(0.0, 1.0);
        paint
          ..style = PaintingStyle.fill
          ..strokeWidth = .65
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(
            alpha: (.028 + .065 * edge) * (.8 + variation * .2),
          );
        canvas.save();
        canvas.translate(x, y);
        switch (style) {
          case 0:
            // Star dust: irregular glints and single specks.
            if (variation > .48) {
              canvas.scale(.65 + variation * .4);
              canvas.drawPath(glint, paint);
            } else {
              canvas.drawCircle(Offset.zero, .8, paint);
            }
          case 1:
            // Halftone: rolling bands of changing dot sizes.
            final radius = .65 + (math.sin(column * .45 + row * .3) + 1) * .7;
            canvas.drawCircle(Offset.zero, radius, paint);
          case 2:
            // Herringbone: pairs of alternating little woven stitches.
            canvas.rotate((column + row).isEven ? math.pi / 4 : -math.pi / 4);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(-4, -1, 8, 2),
                const Radius.circular(1),
              ),
              paint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(-4, 3, 8, 2),
                const Radius.circular(1),
              ),
              paint,
            );
          case 3:
            // Honeycomb: close-packed, fine hexagonal cells.
            paint.style = PaintingStyle.stroke;
            canvas.drawPath(hexagon, paint);
          case 4:
            // Scales: overlapping rows of miniature shells.
            paint.style = PaintingStyle.stroke;
            canvas.drawArc(
              const Rect.fromLTWH(-9, -9, 18, 18),
              0,
              math.pi,
              false,
              paint,
            );
            canvas.drawArc(
              const Rect.fromLTWH(-5, -5, 10, 10),
              0,
              math.pi,
              false,
              paint,
            );
          case 5:
            // Mosaic: a diagonal checker of small rounded tiles.
            if ((row + column).isEven) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTWH(-3, -3, 6, 6),
                  const Radius.circular(1.2),
                ),
                paint,
              );
            } else {
              canvas.drawCircle(Offset.zero, .75, paint);
            }
          case 6:
            // Seed paper: organically scattered grains at varied angles.
            canvas.rotate(variation * math.pi);
            canvas.drawOval(const Rect.fromLTWH(-.8, -2.5, 1.6, 5), paint);
          case 7:
            // Deco fans: three nested quarter circles in alternating corners.
            canvas.rotate(((row + column) % 4) * math.pi / 2);
            paint.style = PaintingStyle.stroke;
            for (final radius in [2.5, 5.0, 7.5]) {
              canvas.drawArc(
                Rect.fromCircle(center: Offset.zero, radius: radius),
                0,
                math.pi / 2,
                false,
                paint,
              );
            }
          case 8:
            // Chain mail: interlocking, paired miniature rings.
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(const Offset(-3, 0), 4.5, paint);
            canvas.drawCircle(const Offset(3, 0), 4.5, paint);
          case 9:
            // Botanical quilt: four small leaves around an empty centre.
            for (var i = 0; i < 4; i++) {
              canvas.save();
              canvas.rotate(i * math.pi / 2);
              canvas.translate(4, 0);
              canvas.drawPath(leaf, paint);
              canvas.restore();
            }
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StoryPatternPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.variant != variant;
}

/// Stable variation avoids changing the colors whenever story progress rebuilds.
int storyPatternSeed(String value) =>
    value.codeUnits.fold(17, (seed, unit) => (seed * 31 + unit) & 0x7fffffff);

class StoryBackdrop extends StatelessWidget {
  final int seed;
  final Widget child;
  const StoryBackdrop({super.key, required this.seed, required this.child});

  @override
  Widget build(BuildContext context) {
    final tint = AppStyle.highlights[seed % AppStyle.highlights.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(tint.withValues(alpha: .24), AppStyle.background),
            Color.alphaBlend(tint.withValues(alpha: .06), AppStyle.background),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: StoryPatternPainter(seed)),
          ),
          child,
        ],
      ),
    );
  }
}
