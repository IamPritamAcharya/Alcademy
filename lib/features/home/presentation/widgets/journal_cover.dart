import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints the journal's ink gradient without rebuilding its text each frame.
class JournalCover extends StatefulWidget {
  final Widget child;
  const JournalCover({super.key, required this.child});
  @override
  State<JournalCover> createState() => _JournalCoverState();
}

class _JournalCoverState extends State<JournalCover>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _InkPainter(_controller)),
            ),
          ),
        ),
        RepaintBoundary(child: widget.child),
      ],
    ),
  );
}

class _InkPainter extends CustomPainter {
  final Animation<double> motion;
  _InkPainter(this.motion) : super(repaint: motion);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    const palettes = [
      [Color(0xFF62616C), Color(0xFF3B3B43), Color(0xFF272727)],
      [Color(0xFF8A3F55), Color(0xFF592C3B), Color(0xFF302429)],
      [Color(0xFF694695), Color(0xFF422F5D), Color(0xFF2A2533)],
      [Color(0xFF326F82), Color(0xFF284A56), Color(0xFF242D30)],
    ];
    final cycle = motion.value * palettes.length;
    final index = cycle.floor() % palettes.length;
    final next = (index + 1) % palettes.length;
    final blend = Curves.easeInOut.transform(cycle - cycle.floor());
    final colors = [
      for (var i = 0; i < 3; i++)
        Color.lerp(palettes[index][i], palettes[next][i], blend)!,
    ];
    final phase = motion.value * 2 * math.pi;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * (.15 + math.sin(phase) * .15), 0),
          Offset(size.width * (.9 + math.cos(phase) * .1), size.height),
          colors,
          [0, .55, 1],
        ),
    );
    final center = Offset(
      size.width * .78 + math.sin(phase) * 25,
      size.height * .15 + math.cos(phase) * 18,
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.radial(center, size.width * .75, [
          const Color(0xFFFFFFFF).withValues(alpha: .14),
          Colors.transparent,
        ]),
    );
    // A brief angled reflection crosses the cover, then rests for most of the loop.
    final sweep = (motion.value / .32).clamp(0.0, 1.0);
    if (sweep > 0 && sweep < 1) {
      final x = -size.width + sweep * size.width * 3;
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x - 40, 0),
            Offset(x + 40, size.height),
            [
              Colors.transparent,
              const Color(0xFFFFFFFF).withValues(alpha: .045),
              Colors.transparent,
            ],
            [0, .5, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_InkPainter oldDelegate) => oldDelegate.motion != motion;
}
