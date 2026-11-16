import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/haptics.dart';

import '../../../core/theme/app_theme.dart';
import 'star_pattern.dart';

/// The three-row split arc. Left = me, right = partner, each fills from the base up.
class TogetherArc extends StatefulWidget {
  const TogetherArc({super.key, required this.left, required this.right, required this.colorLeft, required this.colorRight, required this.percent, this.label = 'TOGETHER TODAY'});

  final String label;
  final double left;
  final double right;
  final Color colorLeft;
  final Color colorRight;
  final int percent;

  @override
  State<TogetherArc> createState() => _TogetherArcState();
}

/// The dimmed arc is always drawn. On open, both sides fill at the same time
/// from 0 up to their own progress and finish together. Later changes animate
/// from the old value to the new one the same way.
class _TogetherArcState extends State<TogetherArc> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..addListener(_feel)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _rising && widget.left >= .999 && widget.right >= .999) Haptics.success();
    });
  double _fromL = 0, _fromR = 0;
  bool _started = false;

  // Haptics: one tick per few dots lit while the arc fills, never while it empties.
  int _lastStep = -1;
  DateTime _lastTick = DateTime(0);
  bool get _rising => widget.left + widget.right > _fromL + _fromR + .001;

  void _feel() {
    if (!_rising) return;
    final t = Curves.easeInOutCubic.transform(_c.value);
    final l = _fromL + (widget.left - _fromL) * t;
    final r = _fromR + (widget.right - _fromR) * t;
    final step = ((l + r) / 2 * 24).floor(); // about one tick per two dots
    final now = DateTime.now();
    if (step > _lastStep && now.difference(_lastTick).inMilliseconds >= 45) {
      if (_lastStep >= 0) Haptics.tick();
      _lastStep = step;
      _lastTick = now;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 250), () {
        _lastStep = 0;
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(TogetherArc old) {
    super.didUpdateWidget(old);
    if (old.left != widget.left || old.right != widget.right) {
      // continue from whatever is currently shown
      final t = Curves.easeInOutCubic.transform(_c.value);
      _fromL = _fromL + (old.left - _fromL) * t;
      _fromR = _fromR + (old.right - _fromR) * t;
      _lastStep = ((_fromL + _fromR) / 2 * 24).floor();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 300 / 186,
      child: LayoutBuilder(builder: (context, box) {
        final k = box.maxWidth / 300;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(
                painter: _ArcPainter(
                  fromLeft: _fromL,
                  fromRight: _fromR,
                  left: widget.left,
                  right: widget.right,
                  colorLeft: widget.colorLeft,
                  colorRight: widget.colorRight,
                  t: Curves.easeInOutCubic.transform(_c.value),
                  label: widget.label,
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, top: 4 * k, child: Center(child: EightPointStar(size: 7 * k, color: widget.colorLeft))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.percent.toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text('${v.round()}', style: AppText.display(size: 78 * k, spacing: -3 * k, height: 0.9)),
              ),
              Text('PERCENT', style: AppText.label(size: 13 * k, color: AppColors.ink, spacing: 1.8 * k)),
            ]),
          ),
        ]);
      }),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.fromLeft, required this.fromRight, required this.left, required this.right, required this.colorLeft, required this.colorRight, required this.t, required this.label});

  final String label;
  final double fromLeft, fromRight, left, right, t;

  /// How "filled" a dot at [pos] (0 = base, 1 = top) is right now, 0..1.
  double _fill(double pos, double from, double to) {
    final cur = from + (to - from) * t; // the fill front moves smoothly
    const soft = 0.06; // dots just behind the front fade in, just ahead stay dim
    return ((cur - pos) / soft + 1).clamp(0.0, 1.0);
  }
  final Color colorLeft, colorRight;

  static const rings = [(132.0, 23), (115.0, 20), (98.0, 17)];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 300;
    canvas.scale(k);
    // viewBox is 0,-26 .. 300,160 in the mockup; shift so y=-26 maps to 0
    canvas.translate(0, 26);
    const cx = 150.0, cy = 154.0, r = 6.6;
    for (final (radius, n) in rings) {
      for (var i = 0; i < n; i++) {
        final u = i / (n - 1);
        final a = math.pi * (1 - u);
        final p = Offset(cx + radius * math.cos(a), cy - radius * math.sin(a));
        final isLeft = u < 0.5;
        final isTop = (u - 0.5).abs() < 1e-6;
        final base = isLeft || isTop ? colorLeft : colorRight;
        // k-th dot from its side's base fills once progress reaches (k+1)/dotsPerSide
        final k = isLeft ? i : n - 1 - i;
        final pos = (k + 1) / ((n + 1) / 2);
        final f = isTop
            ? math.min(_fill(1, fromLeft, left), _fill(1, fromRight, right))
            : isLeft
                ? _fill(pos, fromLeft, left)
                : _fill(pos, fromRight, right);
        // dim layout is always there; the solid color fades in with a small pop
        canvas.drawCircle(p, r, Paint()..color = AppColors.pale(base));
        if (f > 0) {
          final pop = 1 + 0.25 * math.sin(f * math.pi);
          canvas.drawCircle(p, r * pop * (0.6 + 0.4 * f), Paint()..color = base.withValues(alpha: f));
        }
      }
    }
    _curvedLabel(canvas, label, const Offset(cx, cy), 147);
  }

  void _curvedLabel(Canvas canvas, String text, Offset c, double radius) {
    final style = AppText.label(size: 10, spacing: 0);
    const spacing = 2.5;
    final painters = text.split('').map((ch) => TextPainter(text: TextSpan(text: ch, style: style), textDirection: TextDirection.ltr)..layout()).toList();
    final total = painters.fold<double>(0, (s, p) => s + p.width + spacing) - spacing;
    var angle = math.pi / 2 + (total / 2) / radius; // start left of top
    for (final tp in painters) {
      final half = (tp.width / 2) / radius;
      angle -= half;
      final pos = Offset(c.dx + radius * math.cos(angle), c.dy - radius * math.sin(angle));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.pi / 2 - angle);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height));
      canvas.restore();
      angle -= half + spacing / radius;
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.t != t || old.fromLeft != fromLeft || old.fromRight != fromRight || old.left != left || old.right != right || old.colorLeft != colorLeft || old.colorRight != colorRight || old.label != label;
}
