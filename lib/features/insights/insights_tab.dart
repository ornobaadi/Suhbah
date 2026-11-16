import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../../data/insights.dart';
import '../../data/models.dart';
import '../../data/today_provider.dart';
import '../home/widgets/star_pattern.dart';
import 'day_widgets.dart';
import 'history_screen.dart';

/// Journey: this week first, a few true observations, then the last 30 days
/// side by side, and a door into the full history.
class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayProvider);
    final me = ref.watch(myProfileProvider).value;
    if (day == null || me == null) return const SizedBox.shrink();
    final partner = ref.watch(partnerProfileProvider).value;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final myHist = ref.watch(historyProvider(me.uid)).value ?? const <String, DayLog>{};
    final pHist = partner == null ? null : ref.watch(historyProvider(partner.uid)).value ?? const <String, DayLog>{};

    final today = DateTime(now.year, now.month, now.day);
    final todayKey = dayKey(today);
    final paired = day.partner != null && pHist != null;
    // today includes taps that are still being batched
    DayLog mineOn(DateTime d) =>
        dayKey(d) == todayKey ? DayLog(prayed: day.me.prayed, ayat: day.me.ayat, istighfar: day.me.istighfar, deeds: day.me.deeds) : myHist[dayKey(d)] ?? DayLog.empty;
    DayLog theirsOn(DateTime d) => dayKey(d) == todayKey && day.partner != null
        ? DayLog(prayed: day.partner!.prayed, ayat: day.partner!.ayat, istighfar: day.partner!.istighfar, deeds: day.partner!.deeds)
        : pHist?[dayKey(d)] ?? DayLog.empty;
    double together(DateTime d) => togetherScoreOf(mineOn(d), paired ? theirsOn(d) : null);
    DateTime ago(int i) => today.subtract(Duration(days: i));

    final last30 = [for (var i = 29; i >= 0; i--) ago(i)];
    final mine30 = [for (final d in last30) mineOn(d)];
    final theirs30 = paired ? [for (final d in last30) theirsOn(d)] : null;
    final fullDays = last30.where((d) => together(d) >= .999).length;
    final best = bestStreakOf([for (var i = 59; i >= 0; i--) together(ago(i))]);
    final notes = worthKnowing(mine: mine30, theirs: theirs30, dates: last30);
    final myColor = day.me.color;
    final pColor = day.partner?.color;
    final week = [for (var i = 6; i >= 0; i--) ago(i)];
    final deedRows = [
      for (final d in Deed.values)
        if (me.deedCards.contains(d) || mine30.any((x) => x.deeds.contains(d)) || (theirs30?.any((x) => x.deeds.contains(d)) ?? false)) d,
    ];
    final weekAvg = (week.fold(0.0, (s, d) => s + together(d)) / 7 * 100).round();

    return PatternPage(
      children: [
        TabHeader(title: 'Journey', subtitle: paired ? 'You and ${day.partner!.name}, step by step' : 'Your steps, day by day'),
        const SizedBox(height: 18),
        _StreakHero(streak: day.streak, best: best, fullDays: fullDays, color: myColor, partnerColor: pColor),
        SectionLabel('This week · $weekAvg% ${paired ? 'together' : 'average'}'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _DayDots(
                        label: DateFormat('E').format(week[i]).substring(0, 1),
                        isToday: i == 6,
                        mine: mineOn(week[i]).score,
                        theirs: paired ? theirsOn(week[i]).score : null,
                        myColor: myColor,
                        theirColor: pColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('One dot for each of the 7 daily goals', style: AppText.body(size: 11, color: AppColors.sub)),
            ],
          ),
        ),
        if (notes.isNotEmpty) ...[
          const SectionLabel('Worth knowing'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(
              children: [
                for (var i = 0; i < notes.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: EightPointStar(size: 7, color: i == 0 ? myColor : AppColors.pale(myColor).withValues(alpha: .6)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(notes[i], style: AppText.body(size: 13.5, weight: FontWeight.w600, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        SectionLabel(paired ? 'Last 30 days, side by side' : 'Last 30 days'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            children: [
              if (paired)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        day.me.name,
                        style: AppText.body(size: 12, weight: FontWeight.w800, color: myColor),
                      ),
                      const Spacer(),
                      Text(
                        day.partner!.name,
                        style: AppText.body(size: 12, weight: FontWeight.w800, color: pColor ?? myColor),
                      ),
                    ],
                  ),
                ),
              for (final p in Prayer.values)
                _Mirror(
                  title: p.label,
                  note: paired
                      ? '${[for (var i = 0; i < 30; i++)
                          if (mine30[i].prayed.contains(p) && theirs30![i].prayed.contains(p)) 1].length} together'
                      : null,
                  mine: mine30.where((d) => d.prayed.contains(p)).length,
                  theirs: theirs30?.where((d) => d.prayed.contains(p)).length,
                  max: 30,
                  myColor: myColor,
                  theirColor: pColor,
                ),
              const Divider(height: 14),
              _Mirror(
                title: 'Ayat',
                note: 'read',
                mine: mine30.fold(0, (s, d) => s + d.ayat),
                theirs: theirs30?.fold<int>(0, (s, d) => s + d.ayat),
                max: Goals.ayat * 30,
                myColor: myColor,
                theirColor: pColor,
              ),
              _Mirror(
                title: 'Istighfar',
                note: 'said',
                mine: mine30.fold(0, (s, d) => s + d.istighfar),
                theirs: theirs30?.fold<int>(0, (s, d) => s + d.istighfar),
                max: Goals.istighfar * 30,
                myColor: myColor,
                theirColor: pColor,
              ),
            ],
          ),
        ),
        // Good deeds: only for people who use them (a card on Today, or any
        // deed logged in the last 30 days by either of you).
        if (deedRows.isNotEmpty) ...[
          const SectionLabel('Good deeds · last 30 days'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(children: [
              for (final d in deedRows)
                _Mirror(
                  title: d.shortTitle,
                  note: paired
                      ? '${[for (var i = 0; i < 30; i++) if (mine30[i].deeds.contains(d) && theirs30![i].deeds.contains(d)) 1].length} together'
                      : 'days',
                  mine: mine30.where((x) => x.deeds.contains(d)).length,
                  theirs: theirs30?.where((x) => x.deeds.contains(d)).length,
                  max: 30,
                  myColor: myColor,
                  theirColor: pColor,
                ),
            ]),
          ),
        ],
        const SectionLabel('History'),
        AppCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Every day, every month', style: AppText.body(size: 14, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('Tap any day to see who prayed what', style: AppText.body(size: 12, color: AppColors.sub)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      'Open',
                      style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.pillInk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, box) {
                  const n = 14;
                  final size = math.min(22.0, (box.maxWidth - (n - 1) * 3) / n);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = n - 1; i >= 0; i--)
                        SplitDot(
                          mine: mineOn(ago(i)).score,
                          theirs: paired ? theirsOn(ago(i)).score : null,
                          myColor: myColor,
                          theirColor: pColor,
                          size: size,
                          ring: i == 0,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Streak as a big number beside a two-color star badge; best streak and
/// full days underneath.
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak, required this.best, required this.fullDays, required this.color, this.partnerColor});
  final int streak, best, fullDays;
  final Color color;
  final Color? partnerColor;

  @override
  Widget build(BuildContext context) {
    final line = switch (streak) {
      0 => 'Today can be day one',
      1 => 'Day one is done. Keep going',
      _ => 'in a row at ${(Goals.streakThreshold * 100).round()}% or more',
    };
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                SizedBox(width: 62, height: 62, child: CustomPaint(painter: _StarPainter(color, partnerColor ?? color))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: streak.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${v.round()}', style: AppText.display(size: 46, spacing: -2, height: 1)),
                              TextSpan(
                                text: streak == 1 ? '  day' : '  days',
                                style: AppText.display(size: 16, weight: FontWeight.w700, color: AppColors.sub),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(line, style: AppText.body(size: 12.5, color: AppColors.sub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(value: '$best', label: 'Best streak'),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _MiniStat(value: '$fullDays', label: 'Full days, last 30'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Eight-point star split diagonally in two colors, like the header avatar.
class _StarPainter extends CustomPainter {
  _StarPainter(this.a, this.b);
  final Color a, b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final side = size.width * .68;
    final sq = Rect.fromCenter(center: Offset.zero, width: side, height: side);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, a, b, b],
        stops: const [0, .5, .5, 1],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawRect(sq, paint);
    canvas.save();
    canvas.rotate(math.pi / 4);
    canvas.drawRect(sq, paint);
    canvas.restore();
    canvas.drawCircle(Offset.zero, side * .2, Paint()..color = AppColors.card);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.a != a || o.b != b;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    child: Row(
      children: [
        Text(value, style: AppText.display(size: 22, spacing: -.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.sub),
          ),
        ),
      ],
    ),
  );
}

/// One column of 7 dots per person (one per daily goal), filled from the bottom.
class _DayDots extends StatelessWidget {
  const _DayDots({required this.label, required this.isToday, required this.mine, this.theirs, required this.myColor, this.theirColor});
  final String label;
  final bool isToday;
  final double mine;
  final double? theirs;
  final Color myColor;
  final Color? theirColor;

  Widget _col(double score, Color c) {
    final n = (score * Goals.total).round();
    return Column(
      children: [
        for (var i = Goals.total - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: i < n ? 1 : 0),
              duration: Duration(milliseconds: 300 + i * 70),
              curve: Curves.easeOut,
              builder: (_, t, _) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(AppColors.pale(c).withValues(alpha: .18), c, t)),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _col(mine, myColor),
          if (theirs != null) ...[const SizedBox(width: 3), _col(theirs!, theirColor!)],
        ],
      ),
      const SizedBox(height: 10),
      Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: isToday ? const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle) : null,
        child: Text(
          label,
          style: AppText.body(size: 11, weight: FontWeight.w700, color: isToday ? Colors.white : AppColors.sub),
        ),
      ),
    ],
  );
}

/// A row on the center spine: you fill to the left, your partner to the right,
/// like the two halves of the arc. Solo fills one bar.
class _Mirror extends StatelessWidget {
  const _Mirror({required this.title, this.note, required this.mine, this.theirs, required this.max, required this.myColor, this.theirColor});
  final String title;
  final String? note;
  final int mine;
  final int? theirs;
  final int max;
  final Color myColor;
  final Color? theirColor;

  Widget _bar(int v, Color c, {required bool left}) => Expanded(
    child: Container(
      height: 8,
      alignment: left ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(color: AppColors.pale(c).withValues(alpha: .16), borderRadius: BorderRadius.circular(99)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (v / max).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, t, _) => FractionallySizedBox(
          widthFactor: t,
          child: Container(
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.decimalPattern();
    final num = AppText.body(size: 12.5, weight: FontWeight.w800, color: myColor);
    final label = Column(
      crossAxisAlignment: theirs == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(title, style: AppText.body(size: 12.5, weight: FontWeight.w700)),
        if (note != null) Text(note!, style: AppText.body(size: 10.5, color: AppColors.sub)),
      ],
    );
    if (theirs == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Align(alignment: Alignment.centerLeft, child: label),
            ),
            _bar(mine, myColor, left: false),
            SizedBox(
              width: 50,
              child: Text(f.format(mine), textAlign: TextAlign.right, style: num),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(f.format(mine), style: num),
            ),
          ),
          _bar(mine, myColor, left: true),
          SizedBox(width: 84, child: label),
          _bar(theirs!, theirColor!, left: false),
          SizedBox(
            width: 42,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(f.format(theirs), style: num.copyWith(color: theirColor)),
            ),
          ),
        ],
      ),
    );
  }
}
