import 'package:flutter/material.dart';

class FirstPageBackground extends StatelessWidget {
  const FirstPageBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
      ),
      child: CustomPaint(
        painter: CircuitPatternPainter(),
        child: Container(),
      ),
    );
  }
}

class CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    const nodeRadius = 1.5;

    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final offset = Offset(x, y);

        canvas.drawCircle(offset, nodeRadius, dotPaint);

        if ((y / spacing) % 2 == 0 && x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + nodeRadius, y),
            Offset(x + spacing - nodeRadius, y),
            paint,
          );
        }

        if ((x / spacing) % 2 == 0 && y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y + nodeRadius),
            Offset(x, y + spacing - nodeRadius),
            paint,
          );
        }

        if ((x / spacing + y / spacing) % 4 == 0) {
          if (x + spacing < size.width && y + spacing < size.height) {
            canvas.drawLine(
              Offset(x + nodeRadius, y + nodeRadius),
              Offset(x + spacing - nodeRadius, y + spacing - nodeRadius),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
