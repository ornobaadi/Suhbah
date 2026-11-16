import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/member_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../home/widgets/star_pattern.dart';

/// Shared frame for onboarding steps: star pattern on top, big heading, content, primary button.
class StepFrame extends StatelessWidget {
  const StepFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.primaryLabel,
    this.onPrimary,
    this.busy = false,
    this.onBack,
    this.secondary,
    this.footer,
    this.leading,
    this.step,
    this.steps = 4,
    this.eyebrow,
  });

  /// Small friendly line above the title ("ASSALAMU ALAIKUM").
  final String? eyebrow;

  /// 0-based position in onboarding; shows progress dots when set.
  final int? step;
  final int steps;

  final String title;
  final String? subtitle;
  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final VoidCallback? onBack;
  final Widget? secondary;

  /// Shown under the primary button (a quieter alternative).
  final Widget? footer;

  /// Icon at the start of the primary button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const StarPatternBackground(height: 120),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back'),
                            const Spacer(),
                            if (step != null) StepDots(step: step!, steps: steps),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (eyebrow != null)
                        Entrance(
                          order: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const EightPointStar(size: 7),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(eyebrow!.toUpperCase(), style: AppText.label(size: 11, color: AppColors.pillInk, spacing: 1.6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Entrance(order: 1, child: Text(title, style: AppText.display(size: 30, spacing: -0.8, height: 1.08))),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Entrance(
                          order: 2,
                          child: Text(subtitle!, style: AppText.body(size: 14, color: AppColors.sub, height: 1.45)),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Expanded(child: Entrance(order: 3, child: child)),
                      if (secondary != null) ...[secondary!, const SizedBox(height: 8)],
                      if (primaryLabel != null) PrimaryButton(label: primaryLabel!, onPressed: onPrimary, busy: busy, leading: leading),
                      if (footer != null) ...[const SizedBox(height: 6), footer!],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed, this.busy = false, this.leading});
  final String label;
  final Widget? leading;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: AppText.body(size: 15, weight: FontWeight.w700, color: Colors.white),
        ),
        child: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : leading == null
            ? Text(label)
            : Row(mainAxisSize: MainAxisSize.min, children: [leading!, const SizedBox(width: 12), Text(label)]),
      ),
    );
  }
}

/// Google's "G" as a single-colour glyph, so it sits cleanly on the dark button.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18, this.color = Colors.white});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _GPainter(color));
}

class _GPainter extends CustomPainter {
  _GPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width * .2;
    final r = Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = color;
    const d = 3.14159265 / 180;
    // Open on the upper right, closing into the bar at the middle.
    canvas.drawArc(r, -45 * d, -270 * d, false, p);
    canvas.drawArc(r, 0, -12 * d, false, p);
    canvas.drawRect(Rect.fromLTWH(s.width * .5, s.height / 2 - w / 2, s.width * .5, w), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GPainter old) => old.color != color;
}

/// Palette as rounded-square swatches with their names. The chosen one gets
/// a white inner ring and an ink outer ring. Colors too close to the
/// partner's are shown faded with the partner's initial.
class ColorGrid extends StatelessWidget {
  const ColorGrid({super.key, required this.selected, required this.onSelect, this.takenBy});

  final Color selected;
  final ValueChanged<Color> onSelect;

  /// Partner's color and name; colors too close to it are disabled.
  final (Color, String)? takenBy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const perRow = 5, gap = 12.0;
        final w = ((box.maxWidth - gap * (perRow - 1)) / perRow).clamp(44.0, 64.0);
        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: [
            for (final m in memberColors)
              Builder(
                builder: (context) {
                  final c = m.color;
                  final taken = takenBy != null && isTooSimilar(c, takenBy!.$1);
                  final sel = c.toARGB32() == selected.toARGB32();
                  return Semantics(
                    button: true,
                    selected: sel,
                    enabled: !taken,
                    label: taken ? '${m.name}, taken by ${takenBy!.$2}' : m.name,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: taken
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              onSelect(c);
                            },
                      child: SizedBox(
                        width: w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: w,
                              height: w,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: sel ? AppColors.ink : Colors.transparent, width: 2),
                              ),
                              child: Container(
                                decoration: BoxDecoration(color: taken ? c.withValues(alpha: .16) : c, borderRadius: BorderRadius.circular(13)),
                                alignment: Alignment.center,
                                child: taken
                                    ? Text(takenBy!.$2.characters.first.toUpperCase(), style: AppText.display(size: 16, color: c))
                                    : AnimatedScale(
                                        scale: sel ? 1 : 0,
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOutBack,
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                taken ? takenBy!.$2 : m.name,
                                maxLines: 1,
                                style: AppText.body(
                                  size: 11,
                                  weight: sel ? FontWeight.w800 : FontWeight.w600,
                                  color: sel ? AppColors.ink : AppColors.sub,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// Onboarding progress: small arches, like the waqt shapes on Today, that
/// fill from the bottom as you go. The current one is wider.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.step, required this.steps});
  final int step, steps;

  static const _arch = BorderRadius.only(
    topLeft: Radius.elliptical(10, 8),
    topRight: Radius.elliptical(10, 8),
    bottomLeft: Radius.circular(3),
    bottomRight: Radius.circular(3),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${step + 1} of $steps',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(left: 5),
            width: i == step ? 28 : 16,
            height: 10,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: AppColors.line, borderRadius: _arch),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: i < step ? 1 : (i == step ? .5 : 0)),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, t, _) => FractionallySizedBox(
                  heightFactor: t,
                  widthFactor: 1,
                  child: const ColoredBox(color: AppColors.pillInk),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Today's sky: a dotted path from sunrise to night with a marker for each
/// prayer. The sun walks along it to now and each prayer lights up as it
/// passes. Times come from [times] (fajr..isha).
class SunPath extends StatelessWidget {
  const SunPath({super.key, required this.times, required this.now});
  final List<DateTime> times;
  final DateTime now;

  static const _names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  Widget build(BuildContext context) {
    final start = times.first.subtract(const Duration(hours: 1));
    final end = times.last.add(const Duration(hours: 1));
    double at(DateTime d) => (d.difference(start).inSeconds / end.difference(start).inSeconds).clamp(0.0, 1.0);
    final marks = [for (final t in times) at(t)];
    final labels = [
      for (var i = 0; i < times.length; i++)
        (i < _names.length ? _names[i] : '', MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(times[i]))),
    ];
    // Always drawn whole: the full day's path with every prayer on it, whatever the time now.
    return Semantics(
      label: 'Your prayer times along the path of the sun',
      child: SizedBox(
        height: 132,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1600),
          curve: Curves.easeInOutCubic,
          builder: (_, t, _) => CustomPaint(painter: _SunPainter(t, marks, labels), size: Size.infinite),
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  _SunPainter(this.t, this.marks, this.labels);
  final double t;
  final List<double> marks;
  final List<(String, String)> labels;

  static const sun = Color(0xFFE9A21B);
  static const top = 22.0, bottom = 40.0;

  Offset _pt(Size s, double u) {
    final x = 28 + (s.width - 56) * u;
    final h = s.height - bottom;
    final y = h - math.sin(u * math.pi) * (h - top);
    return Offset(x, y);
  }

  void _text(Canvas c, String s, Offset at, TextStyle st) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - bottom;
    canvas.drawLine(Offset(0, base), Offset(size.width, base), Paint()..color = AppColors.line);
    final trail = Path()..moveTo(_pt(size, 0).dx, _pt(size, 0).dy);
    for (var u = 0.0; u <= t; u += .01) {
      final o = _pt(size, u);
      trail.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = sun.withValues(alpha: .55),
    );
    // The sun at its height, over the middle of the day.
    final peak = _pt(size, .5);
    final glow = Curves.easeOut.transform(t);
    canvas.drawCircle(peak, 15 * glow, Paint()..color = sun.withValues(alpha: .18));
    canvas.drawCircle(peak, 8 * glow, Paint()..color = sun);
    for (var i = 0; i < marks.length; i++) {
      final shown = marks[i] <= t + .001;
      final o = _pt(size, marks[i]);
      canvas.drawCircle(o, shown ? 5 : 3.4, Paint()..color = shown ? AppColors.memberA : const Color(0xFFC9D6D0));
      if (!shown || i >= labels.length) continue;
      // Labels sit in one even row under the horizon so close prayers (Asr, Maghrib, Isha) never collide.
      final (name, time) = labels[i];
      final x = size.width * (i + .5) / labels.length;
      _text(canvas, name, Offset(x, base + 5), AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.ink));
      _text(canvas, time, Offset(x, base + 19), AppText.body(size: 10.5, color: AppColors.sub));
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) => old.t != t;
}

/// Two seats: yours, filled with your color, and theirs, a dashed circle
/// that breathes while it waits. When [partner] arrives it fills with their
/// color and the two slide together with a link between them.
class Seats extends StatefulWidget {
  const Seats({super.key, required this.myName, required this.myColor, this.partner, this.size = 84});
  final String myName;
  final Color myColor;
  final (String, Color)? partner;
  final double size;

  @override
  State<Seats> createState() => _SeatsState();
}

class _SeatsState extends State<Seats> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breathe.stop();
    } else if (!_breathe.isAnimating) {
      _breathe.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final p = widget.partner;
    final joined = p != null;
    const d = Duration(milliseconds: 650);
    const curve = Curves.easeOutBack;
    final gap = joined ? s * .36 : s * .62;
    return SizedBox(
      height: s + 8,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedSlide(
            offset: Offset(-gap / s, 0),
            duration: d,
            curve: curve,
            child: MemberAvatar(name: widget.myName, color: widget.myColor, size: s),
          ),
          AnimatedSlide(
            offset: Offset(gap / s, 0),
            duration: d,
            curve: curve,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (c, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                child: c,
              ),
              child: joined
                  ? MemberAvatar(key: const ValueKey('them'), name: p.$1, color: p.$2, size: s)
                  : AnimatedBuilder(
                      key: const ValueKey('empty'),
                      animation: _breathe,
                      builder: (_, _) {
                        final c = Color.lerp(const Color(0xFFB9C7C1), AppColors.pillInk, _breathe.value)!;
                        return CustomPaint(
                          painter: _DashedCircle(c),
                          child: SizedBox(
                            width: s,
                            height: s,
                            child: Icon(Icons.add_rounded, size: s * .38, color: c),
                          ),
                        );
                      },
                    ),
            ),
          ),
          AnimatedScale(
            scale: joined ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.link_rounded, size: 18, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  _DashedCircle(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 1.5;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const n = 22;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi / n, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircle old) => old.color != color;
}

/// An invite code shown as separate tiles that flip in one after another.
class FlipCode extends StatelessWidget {
  const FlipCode({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Code ${code.split('').join(' ')}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < code.length; i++)
              TweenAnimationBuilder<double>(
                key: ValueKey('$code$i'),
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: Duration(milliseconds: 420 + i * 80),
                curve: Interval(i * .1, 1, curve: Curves.easeOutBack),
                builder: (_, t, child) => Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .002)
                    ..rotateX((1 - t) * math.pi / 2),
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                ),
                child: Container(
                  width: 42,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(code[i], style: AppText.display(size: 27)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
