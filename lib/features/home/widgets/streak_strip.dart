import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui.dart';
import '../../../data/models.dart';

/// The streak flame: warm amber when lit, a pale outline when not.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.lit, this.size = 22});
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!lit) return Icon(Icons.local_fire_department_outlined, size: size, color: AppColors.sub.withValues(alpha: .55));
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.flameTop, AppColors.flameBottom]).createShader(r),
      child: Icon(Icons.local_fire_department_rounded, size: size, color: Colors.white),
    );
  }
}

/// The last seven days as flames: lit at 60% or more, pale otherwise. Today
/// gently pulses until it counts. Never phrased as a loss.
class StreakStrip extends StatelessWidget {
  const StreakStrip({
    super.key,
    required this.streak,
    required this.best,
    required this.days,
    required this.scores,
    required this.yesterdayPct,
    required this.color,
    this.partnerColor,
  });

  final int streak, best, yesterdayPct;

  /// Oldest first, today last; [scores] is aligned with [days].
  final List<DateTime> days;
  final List<double> scores;
  final Color color;
  final Color? partnerColor;

  /// The line under the flames.
  static String message({required int streak, required double today}) {
    final pct = (Goals.streakThreshold * 100).round();
    if (today >= Goals.streakThreshold) return 'Today counts. Your streak is $streak, MashaAllah';
    if (streak > 0) return 'Reach $pct% today to make it ${streak + 1}';
    return 'Today can be day one. Reach $pct% to start';
  }

  @override
  Widget build(BuildContext context) {
    final today = scores.last;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$streak', style: AppText.display(size: 30, spacing: -1, height: 1)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('day streak', style: AppText.body(size: 13, weight: FontWeight.w700)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.flameBg, borderRadius: BorderRadius.circular(99)),
            child: Text('BEST $best', style: AppText.label(size: 10, color: AppColors.flameInk, spacing: 1.2)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: _Flame(
                lit: scores[i] >= Goals.streakThreshold,
                today: i == days.length - 1,
                label: i == days.length - 1 ? 'Today' : DateFormat('E').format(days[i]).substring(0, 1),
                color: color,
                second: partnerColor,
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(message(streak: streak, today: today), style: AppText.body(size: 12.5, weight: FontWeight.w600))),
          Text('Yesterday $yesterdayPct%', style: AppText.body(size: 11.5, color: AppColors.sub)),
        ]),
      ]),
    );
  }
}

class _Flame extends StatefulWidget {
  const _Flame({required this.lit, required this.today, required this.label, required this.color, this.second});
  final bool lit, today;
  final String label;
  final Color color;
  final Color? second;

  @override
  State<_Flame> createState() => _FlameState();
}

class _FlameState extends State<_Flame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  bool get _pulse => widget.today && !widget.lit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Flame old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_pulse && !MediaQuery.disableAnimationsOf(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flame = StreakFlame(lit: widget.lit, size: 28);
    return Column(children: [
      AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(scale: 1 + .08 * Curves.easeInOut.transform(_c.value), child: child),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.lit ? AppColors.flameBg : null,
            border: widget.today ? Border.all(color: widget.lit ? AppColors.flameBottom.withValues(alpha: .5) : AppColors.ink.withValues(alpha: .25), width: 1.5) : null,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (_, s, c) => Transform.scale(scale: s, child: c),
            child: flame,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(widget.label, style: AppText.body(size: 10.5, weight: widget.today ? FontWeight.w800 : FontWeight.w600, color: widget.today ? AppColors.ink : AppColors.sub)),
    ]);
  }
}
