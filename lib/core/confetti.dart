import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A one-shot burst of small eight-point stars and petals in the given
/// colors, falling from the top. Plays once when it first appears.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.colors, this.count = 70});
  final List<Color> colors;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _bits = List.generate(widget.count, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - .5) * 2.2;
      final speed = .55 + rnd.nextDouble() * .7;
      return _Bit(
        x: .5 + (rnd.nextDouble() - .5) * .3,
        vx: math.cos(angle) * speed * .55,
        vy: math.sin(angle) * speed,
        spin: (rnd.nextDouble() - .5) * 12,
        size: 5 + rnd.nextDouble() * 6,
        color: widget.colors[i % widget.colors.length],
        star: i % 3 == 0,
        delay: rnd.nextDouble() * .12,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_bits, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _Bit {
  _Bit({required this.x, required this.vx, required this.vy, required this.spin, required this.size, required this.color, required this.star, required this.delay});
  final double x, vx, vy, spin, size, delay;
  final Color color;
  final bool star;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bits) {
      final lt = ((t - b.delay) / (1 - b.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final s = lt * 2.4; // seconds-ish
      final dx = (b.x + b.vx * s) * size.width;
      final dy = size.height * (.32 + b.vy * s * .55 + .5 * 1.1 * s * s * .55);
      final fade = lt > .75 ? (1 - lt) / .25 : 1.0;
      final paint = Paint()..color = b.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(b.spin * s);
      if (b.star) {
        final r = Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size);
        canvas.drawRect(r, paint);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(r, paint);
      } else {
        // a petal that flips as it falls
        final squash = math.cos(b.spin * s * 1.3).abs() * .8 + .2;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: b.size * .7, height: b.size * 1.3 * squash), const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
