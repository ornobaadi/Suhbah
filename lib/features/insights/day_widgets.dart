import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A day as a round dot split down the middle: your half and your partner's,
/// each deepening with that day's progress. Solo days fill the whole dot.
class SplitDot extends StatelessWidget {
  const SplitDot({super.key, required this.mine, this.theirs, required this.myColor, this.theirColor, this.size = 34, this.ring = false, this.label});
  final double mine;
  final double? theirs;
  final Color myColor;
  final Color? theirColor;
  final double size;
  final bool ring;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final avg = theirs == null ? mine : (mine + theirs!) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SplitDotPainter(a: mine, b: theirs, ca: myColor, cb: theirColor ?? myColor, ring: ring),
        child: label == null
            ? null
            : Center(child: Text(label!, style: AppText.body(size: size * .3, weight: FontWeight.w700, color: avg > .55 ? Colors.white : AppColors.sub))),
      ),
    );
  }
}

class _SplitDotPainter extends CustomPainter {
  _SplitDotPainter({required this.a, this.b, required this.ca, required this.cb, required this.ring});
  final double a;
  final double? b;
  final Color ca, cb;
  final bool ring;

  Color _fill(Color c, double v) => v <= 0 ? AppColors.pale(c).withValues(alpha: .1) : Color.lerp(AppColors.pale(c), c, v.clamp(0.0, 1.0))!;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    if (b == null) {
      canvas.drawCircle(c, r, Paint()..color = _fill(ca, a));
    } else {
      canvas.drawArc(rect, math.pi / 2, math.pi, true, Paint()..color = _fill(ca, a));
      canvas.drawArc(rect, -math.pi / 2, math.pi, true, Paint()..color = _fill(cb, b!));
    }
    if (ring) {
      canvas.drawCircle(c, r + 1.5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.ink);
    }
  }

  @override
  bool shouldRepaint(_SplitDotPainter o) => o.a != a || o.b != b || o.ca != ca || o.cb != cb || o.ring != ring;
}

/// One skewed waqt shape, as on the Salah card: solid when prayed, pale when not.
class WaqtMark extends StatelessWidget {
  const WaqtMark({super.key, required this.done, required this.color, this.mirror = false, this.width = 18, this.height = 14});
  final bool done;
  final Color color;
  final bool mirror;
  final double width, height;

  @override
  Widget build(BuildContext context) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.skewX(mirror ? .17 : -.17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          height: height,
          decoration: BoxDecoration(color: done ? color : AppColors.pale(color), borderRadius: BorderRadius.circular(4)),
        ),
      );
}
