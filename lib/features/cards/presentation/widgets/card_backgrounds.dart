import 'package:flutter/material.dart';

class VisaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const spacing = 15.0;
    // Draw diagonal lines
    for (double i = -size.height * 2; i < size.width * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MastercardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw large overlapping circles
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), size.height * 0.8, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), size.height * 0.7, paint);
    
    // Fill slightly
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), size.height * 0.8, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
