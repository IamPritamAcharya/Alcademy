import 'dart:math' as math;
import 'package:flutter/material.dart';

class SmoothWavesPainter extends CustomPainter {
  final int seed;

  SmoothWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final thickness = 0.8 + i * 0.4 + random.nextDouble() * 0.6;
      paint.strokeWidth = thickness;

      final baseOpacity = 0.15 - (i * 0.02);
      paint.color = Colors.white
          .withOpacity(baseOpacity * (0.7 + random.nextDouble() * 0.6));

      final path = Path();
      final baseY = size.height * (0.25 + random.nextDouble() * 0.5);
      final amplitude = 20 + random.nextDouble() * 45;
      final frequency = 0.006 + random.nextDouble() * 0.014;
      final phase = random.nextDouble() * math.pi * 2;
      final secondaryFreq = frequency * (2.5 + random.nextDouble() * 2);
      final secondaryAmp = amplitude * (0.2 + random.nextDouble() * 0.3);

      path.moveTo(-60, baseY);
      for (double x = -60; x <= size.width + 60; x += 2.5) {
        final primaryWave = math.sin(x * frequency + phase) * amplitude;
        final secondaryWave =
            math.sin(x * secondaryFreq + phase * 1.7) * secondaryAmp;
        final y = baseY + primaryWave + secondaryWave;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RippleWavesPainter extends CustomPainter {
  final int seed;

  RippleWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centers = [
      Offset(size.width * (0.3 + random.nextDouble() * 0.4),
          size.height * (0.3 + random.nextDouble() * 0.4)),
    ];

    for (int centerIndex = 0; centerIndex < centers.length; centerIndex++) {
      final center = centers[centerIndex];

      for (int i = 0; i < 4; i++) {
        paint.strokeWidth = 1.0 + random.nextDouble() * 0.8;
        paint.color = Colors.white
            .withOpacity((random.nextDouble() * 0.06 + 0.03) * (1 - i * 0.15));

        final baseRadius = 80 + i * 50 + random.nextDouble() * 30;
        final waveFrequency = 3 + random.nextDouble() * 3;
        final waveAmplitude = 6 + random.nextDouble() * 8;

        final path = Path();
        bool started = false;

        for (double angle = 0; angle < math.pi * 2; angle += 0.12) {
          final waveOffset = math.sin(angle * waveFrequency) * waveAmplitude;
          final radius = baseRadius + waveOffset;
          final x = center.dx + radius * math.cos(angle);
          final y = center.dy + radius * math.sin(angle);

          if (!started) {
            path.moveTo(x, y);
            started = true;
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlowingWavesPainter extends CustomPainter {
  final int seed;

  FlowingWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      paint.strokeWidth = 1.8 + random.nextDouble() * 1.2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.12 + 0.04);

      final path = Path();
      final startX = size.width * (0.1 + random.nextDouble() * 0.2);
      final startY = size.height * (0.3 + random.nextDouble() * 0.4);
      final endX = size.width * (0.7 + random.nextDouble() * 0.2);
      final endY = size.height * (0.3 + random.nextDouble() * 0.4);

      path.moveTo(startX, startY);

      final segments = 50;
      for (int j = 0; j <= segments; j++) {
        final t = j / segments;
        final baseX = startX + (endX - startX) * t;
        final baseY = startY + (endY - startY) * t;

        final waveAmplitude =
            (25 + random.nextDouble() * 35) * math.sin(math.pi * t);
        final waveFreq = 4 + random.nextDouble() * 6;
        final perpOffset = math.sin(t * math.pi * waveFreq) * waveAmplitude;

        final angle = math.atan2(endY - startY, endX - startX) + math.pi / 2;
        final waveX = baseX + math.cos(angle) * perpOffset;
        final waveY = baseY + math.sin(angle) * perpOffset;

        path.lineTo(waveX, waveY);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DoubleWavesPainter extends CustomPainter {
  final int seed;

  DoubleWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      paint.strokeWidth = 1.6 + random.nextDouble() * 0.8;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.09 + 0.04);

      final baseY = size.height * (0.25 + random.nextDouble() * 0.5);
      final amplitude = 20 + random.nextDouble() * 30;
      final frequency = 0.01 + random.nextDouble() * 0.012;
      final offset = 15 + random.nextDouble() * 20;

      final path1 = Path();
      path1.moveTo(-30, baseY);
      for (double x = -30; x <= size.width + 30; x += 3) {
        final y = baseY + math.sin(x * frequency) * amplitude;
        path1.lineTo(x, y);
      }

      final path2 = Path();
      path2.moveTo(-30, baseY + offset);
      for (double x = -30; x <= size.width + 30; x += 3) {
        final y =
            baseY + offset + math.sin(x * frequency + math.pi) * amplitude;
        path2.lineTo(x, y);
      }

      canvas.drawPath(path1, paint);
      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiagonalWavesPainter extends CustomPainter {
  final int seed;

  DiagonalWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      paint.strokeWidth = 1.3 + random.nextDouble() * 1.2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.1 + 0.03);

      final path = Path();
      final angle = math.pi / 6 + random.nextDouble() * math.pi / 3;
      final amplitude = 25 + random.nextDouble() * 35;
      final frequency = 0.015 + random.nextDouble() * 0.01;

      final startX = random.nextDouble() * size.width * 0.3;
      final startY = random.nextDouble() * size.height * 0.3;

      path.moveTo(startX, startY);

      for (double t = 0; t <= 300; t += 3) {
        final baseX = startX + t * math.cos(angle);
        final baseY = startY + t * math.sin(angle);
        final waveX = baseX +
            math.sin(t * frequency) * amplitude * math.cos(angle + math.pi / 2);
        final waveY = baseY +
            math.sin(t * frequency) * amplitude * math.sin(angle + math.pi / 2);
        path.lineTo(waveX, waveY);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MultiFrequencyWavesPainter extends CustomPainter {
  final int seed;

  MultiFrequencyWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      paint.strokeWidth = 1.5 + random.nextDouble() * 0.8;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.1 + 0.04);

      final path = Path();
      final baseY = size.height * (0.3 + random.nextDouble() * 0.4);
      final amp1 = 15 + random.nextDouble() * 20;
      final amp2 = 8 + random.nextDouble() * 15;
      final freq1 = 0.008 + random.nextDouble() * 0.01;
      final freq2 = 0.02 + random.nextDouble() * 0.015;
      final phase = random.nextDouble() * math.pi * 2;

      path.moveTo(-40, baseY);
      for (double x = -40; x <= size.width + 40; x += 2) {
        final wave1 = math.sin(x * freq1 + phase) * amp1;
        final wave2 = math.sin(x * freq2 + phase * 0.7) * amp2;
        final y = baseY + wave1 + wave2;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulseWavesPainter extends CustomPainter {
  final int seed;

  PulseWavesPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      paint.strokeWidth = 1.2 + random.nextDouble() * 1.0;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.08 + 0.03);

      final path = Path();
      final baseY = size.height * (0.25 + random.nextDouble() * 0.5);
      final maxAmplitude = 30 + random.nextDouble() * 25;
      final frequency = 0.012 + random.nextDouble() * 0.008;
      final pulseFreq = 0.003 + random.nextDouble() * 0.002;

      path.moveTo(-30, baseY);
      for (double x = -30; x <= size.width + 30; x += 3) {
        final pulse = (math.sin(x * pulseFreq) + 1) * 0.5;
        final amplitude = maxAmplitude * pulse;
        final y = baseY + math.sin(x * frequency) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

CustomPainter getRandomPainter(int storyIndex) {
  final patterns = [
    RippleWavesPainter(storyIndex),
    FlowingWavesPainter(storyIndex),
    DoubleWavesPainter(storyIndex),
    DiagonalWavesPainter(storyIndex),
    MultiFrequencyWavesPainter(storyIndex),
    PulseWavesPainter(storyIndex),
  ];

  return patterns[storyIndex % patterns.length];
}
