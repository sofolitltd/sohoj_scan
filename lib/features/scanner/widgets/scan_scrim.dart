import 'package:flutter/material.dart';

import 'scan_frame.dart';

/// Darkens the camera image outside the scan box so the box reads first.
class ScanScrim extends StatelessWidget {
  const ScanScrim({super.key, required this.color, required this.boxCenter});

  final Color color;

  /// Centre of the scan box, in this widget's own coordinate space.
  final Offset boxCenter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ScrimPainter(color: color, boxCenter: boxCenter),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.color, required this.boxCenter});

  final Color color;
  final Offset boxCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: boxCenter, width: scanBoxWidth, height: scanBoxHeight),
        const Radius.circular(20),
      ));
    final diff = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(diff, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.boxCenter != boxCenter;
}
