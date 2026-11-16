import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The top of every screen: a soft wash of the brand tint with a faint
/// arcade of pointed arches, like the colonnade of a courtyard, fading out
/// before any content starts (DESIGN.md §2). [height] is measured below the
/// status bar.
class StarPatternBackground extends StatelessWidget {
  const StarPatternBackground({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return IgnorePointer(
      child: SizedBox(
        height: top + height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEDF5F1), Color(0x00EDF5F1)],
            ),
          ),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0x00000000)],
              stops: [.2, .9],
            ).createShader(r),
            child: CustomPaint(painter: _ArcadePainter(top: top), size: Size.infinite),
          ),
        ),
      ),
    );
  }
}

class _ArcadePainter extends CustomPainter {
  _ArcadePainter({required this.top});
  final double top;

  static const bay = 46.0; // one arch plus its column

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..color = AppColors.memberA.withValues(alpha: .2);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..isAntiAlias = true
      ..color = AppColors.memberA.withValues(alpha: .1);
    final bays = (size.width / bay).ceil() + 1;
    final x0 = (size.width - (bays - 1) * bay) / 2 - bay / 2;
    final apex = top + 2;
    final spring = apex + bay * .62;
    for (var i = 0; i < bays; i++) {
      final l = x0 + i * bay, r = l + bay;
      canvas.drawPath(_arch(l, r, apex, spring, size.height), line);
      canvas.drawPath(_arch(l + 5, r - 5, apex + 7, spring + 2, size.height), inner);
    }
  }

  /// A pointed arch from [l] to [r]: two arcs meeting at [apex], then
  /// straight jambs from [spring] down to [bottom].
  static Path _arch(double l, double r, double apex, double spring, double bottom) {
    final mid = (l + r) / 2;
    final p = Path()..moveTo(l, bottom);
    p.lineTo(l, spring);
    p.cubicTo(l, spring - (spring - apex) * .55, mid - (r - l) * .18, apex + (spring - apex) * .2, mid, apex);
    p.cubicTo(mid + (r - l) * .18, apex + (spring - apex) * .2, r, spring - (spring - apex) * .55, r, spring);
    p.lineTo(r, bottom);
    return p;
  }

  @override
  bool shouldRepaint(covariant _ArcadePainter old) => old.top != top;
}

/// Small solid eight-point star.
class EightPointStar extends StatelessWidget {
  const EightPointStar({super.key, this.size = 8, this.color = AppColors.memberA});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 1.5,
        height: size * 1.5,
        child: Stack(alignment: Alignment.center, children: [
          Container(width: size, height: size, color: color),
          Transform.rotate(angle: math.pi / 4, child: Container(width: size, height: size, color: color)),
        ]),
      );
}
