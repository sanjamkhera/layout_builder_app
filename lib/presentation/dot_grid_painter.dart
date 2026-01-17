import 'package:flutter/material.dart';

/// Custom painter that draws a dot grid pattern on the canvas.
///
/// Renders a uniform grid of dots with 20px spacing and 1px radius,
/// providing visual alignment guides for widget placement.
class DotGridPainter extends CustomPainter {
  static const double _gridSpacing = 20.0;
  static const double _dotRadius = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += _gridSpacing) {
      for (double y = 0; y < size.height; y += _gridSpacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
