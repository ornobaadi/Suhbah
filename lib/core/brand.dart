import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Suhbah's brand mark: three arcs split into two halves, one per companion.
/// Same geometry as the launcher icon (design/brand/final).
abstract final class Brand {
  static const left = Color(0xFF12A679); // Ink Emerald
  static const right = Color(0xFFC7224F); // Pomegranate
  static const light = Color(0xFFFFFFFF);
  static const dark = Color(0xFF0C1814);
}

class SuhbahMark extends StatelessWidget {
  const SuhbahMark({super.key, this.size = 40, this.left = Brand.left, this.right = Brand.right});

  /// Width of the mark; height is about 0.55 of it.
  final double size;
  final Color left, right;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Suhbah',
        child: CustomPaint(size: Size(size, size * 80 / 146), painter: _MarkPainter(left, right)),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.l, this.r);
  final Color l, r;

  // 108-unit icon grid: radii 33 / 23.5 / 14, stroke 7, 3.2 gap at the top.
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 73;
    final c = Offset(s.width / 2, s.height - 3.5 * k);
    for (final rad in const [33.0, 23.5, 14.0]) {
      final g = math.asin(3.2 / rad);
      final rect = Rect.fromCircle(center: c, radius: rad * k);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * k
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, math.pi, math.pi / 2 - g, false, p..color = l);
      canvas.drawArc(rect, 1.5 * math.pi + g, math.pi / 2 - g, false, p..color = r);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter o) => o.l != l || o.r != r;
}
