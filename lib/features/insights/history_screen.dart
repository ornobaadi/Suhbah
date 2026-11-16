import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../home/widgets/deed_cards.dart';
import '../../core/ui.dart';
import '../../data/models.dart';
import '../../data/today_provider.dart';
import '../home/widgets/star_pattern.dart';
import 'day_widgets.dart';

/// Every past month as a calendar. Tap a day to see who prayed what.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  String _mk(DateTime m) => DateFormat('yyyy-MM').format(m);

  void _shift(int by) {
    HapticFeedback.selectionClick();
    final m = DateTime(_month.year, _month.month + by);
    final now = DateTime.now();
    final last = DateTime(m.year, m.month + 1, 0).day;
    setState(() {
      _month = m;
      _selected = (m.year == now.year && m.month == now.month) ? DateTime(now.year, now.month, now.day) : DateTime(m.year, m.month, last);
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(todayProvider);
    final me = ref.watch(myProfileProvider).value;
    if (day == null || me == null) return const Scaffold(backgroundColor: AppColors.bg);
    final partner = ref.watch(partnerProfileProvider).value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mine = ref.watch(monthProvider('${me.uid}|${_mk(_month)}')).value ?? const <String, DayLog>{};
    final theirs = partner == null ? null : ref.watch(monthProvider('${partner.uid}|${_mk(_month)}')).value ?? const <String, DayLog>{};
    final todayKey = dayKey(today);
    DayLog mineOn(DateTime d) => dayKey(d) == todayKey ? DayLog(prayed: day.me.prayed, ayat: day.me.ayat, istighfar: day.me.istighfar) : mine[dayKey(d)] ?? DayLog.empty;
    DayLog? theirsOn(DateTime d) => theirs == null
        ? null
        : dayKey(d) == todayKey && day.partner != null
            ? DayLog(prayed: day.partner!.prayed, ayat: day.partner!.ayat, istighfar: day.partner!.istighfar)
            : theirs[dayKey(d)] ?? DayLog.empty;

    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1; // Monday first
    final isCurrent = _month.year == today.year && _month.month == today.month;
    final earliest = DateTime(today.year - 1, today.month);
    final monthDays = [for (var i = 1; i <= days; i++) DateTime(_month.year, _month.month, i)].where((d) => !d.isAfter(today)).toList();
    final full = monthDays.where((d) => togetherScoreOf(mineOn(d), theirsOn(d)) >= .999).length;
    final avg = monthDays.isEmpty ? 0 : (monthDays.fold(0.0, (s, d) => s + togetherScoreOf(mineOn(d), theirsOn(d))) / monthDays.length * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        const StarPatternBackground(height: 120),
        SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back'),
            ]),
            TabHeader(title: 'History', subtitle: partner == null ? 'Every day you have logged' : 'Every day, you and ${partner.nickname}'),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              child: Column(children: [
                Row(children: [
                  IconButton(onPressed: _month.isAfter(earliest) ? () => _shift(-1) : null, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous month'),
                  Expanded(
                    child: Column(children: [
                      Text(DateFormat('MMMM y').format(_month), style: AppText.display(size: 18)),
                      Text('$avg% average · $full full ${full == 1 ? 'day' : 'days'}', style: AppText.body(size: 11.5, color: AppColors.sub)),
                    ]),
                  ),
                  IconButton(onPressed: isCurrent ? null : () => _shift(1), icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next month'),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (final l in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(l, style: AppText.label(size: 10, spacing: .5)))),
                ]),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  children: [
                    for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                    for (var i = 1; i <= days; i++)
                      Builder(builder: (context) {
                        final d = DateTime(_month.year, _month.month, i);
                        final future = d.isAfter(today);
                        final sel = d == _selected;
                        return Center(
                          child: Semantics(
                            button: !future,
                            selected: sel,
                            label: DateFormat('d MMMM').format(d),
                            child: GestureDetector(
                              onTap: future
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selected = d);
                                    },
                              child: Opacity(
                                opacity: future ? .35 : 1,
                                child: AnimatedScale(
                                  scale: sel ? 1.08 : 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: SplitDot(
                                    mine: future ? 0 : mineOn(d).score,
                                    theirs: future ? (theirs == null ? null : 0) : theirsOn(d)?.score,
                                    myColor: day.me.color,
                                    theirColor: day.partner?.color,
                                    ring: sel,
                                    size: 36,
                                    label: '$i',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: DayDetail(
                key: ValueKey(_selected),
                date: _selected,
                isToday: _selected == today,
                me: mineOn(_selected),
                partner: theirsOn(_selected),
                myName: day.me.name,
                partnerName: day.partner?.name,
                myColor: day.me.color,
                partnerColor: day.partner?.color,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// One day in full: each prayer for each person, Quran and istighfar, and who
/// completed the day.
class DayDetail extends StatelessWidget {
  const DayDetail({
    super.key,
    required this.date,
    required this.isToday,
    required this.me,
    required this.partner,
    required this.myName,
    required this.partnerName,
    required this.myColor,
    required this.partnerColor,
  });
  final DateTime date;
  final bool isToday;
  final DayLog me;
  final DayLog? partner;
  final String myName;
  final String? partnerName;
  final Color myColor;
  final Color? partnerColor;

  @override
  Widget build(BuildContext context) {
    final p = partner;
    final pct = (togetherScoreOf(me, p) * 100).round();
    Widget who(String name, Color c, DayLog d) => Expanded(
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12.5, weight: FontWeight.w700))),
            if (d.score >= .999) ...[const SizedBox(width: 6), Icon(Icons.verified_rounded, size: 15, color: c)],
          ]),
        );
    Widget count(String label, int a, int? b, int goal) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.sub)),
              const SizedBox(height: 3),
              Text.rich(TextSpan(children: [
                TextSpan(text: '$a', style: AppText.display(size: 18, color: myColor)),
                if (b != null) ...[
                  TextSpan(text: '  ·  ', style: AppText.body(size: 12, color: AppColors.sub)),
                  TextSpan(text: '$b', style: AppText.display(size: 18, color: partnerColor ?? myColor)),
                ],
                TextSpan(text: '  of $goal', style: AppText.body(size: 11, color: AppColors.sub)),
              ])),
            ]),
          ),
        );

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((isToday ? 'Today' : DateFormat('EEEE').format(date)).toUpperCase(), style: AppText.label(size: 10)),
              const SizedBox(height: 4),
              Text(DateFormat('d MMMM').format(date), style: AppText.display(size: 22, spacing: -.5)),
            ]),
          ),
          Text('$pct%', style: AppText.display(size: 30, spacing: -1)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(p == null ? 'done' : 'together', style: AppText.body(size: 11.5, color: AppColors.sub))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          who(myName, myColor, me),
          if (p != null) who(partnerName ?? 'Partner', partnerColor!, p),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final pr in Prayer.values)
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  WaqtMark(done: me.prayed.contains(pr), color: myColor),
                  if (p != null) ...[const SizedBox(width: 3), WaqtMark(done: p.prayed.contains(pr), color: partnerColor!, mirror: true)],
                ]),
                const SizedBox(height: 5),
                Text(pr.label, style: AppText.body(size: 10.5, weight: FontWeight.w600, color: AppColors.sub)),
              ]),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          count('Ayat', me.ayat, p?.ayat, Goals.ayat),
          const SizedBox(width: 8),
          count('Istighfar', me.istighfar, p?.istighfar, Goals.istighfar),
        ]),
        if (me.deeds.isNotEmpty || (p?.deeds.isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          Text('GOOD DEEDS', style: AppText.label(size: 10)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final d in Deed.values)
              if (me.deeds.contains(d) || (p?.deeds.contains(d) ?? false))
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(deedIcon(d), size: 15, color: AppColors.sub),
                    const SizedBox(width: 5),
                    Text(d.title, style: AppText.body(size: 12, weight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    // who did it: a dot in each person's color, pale if not
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: me.deeds.contains(d) ? myColor : AppColors.pale(myColor), shape: BoxShape.circle)),
                    if (p != null) ...[
                      const SizedBox(width: 3),
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: p.deeds.contains(d) ? partnerColor! : AppColors.pale(partnerColor!), shape: BoxShape.circle)),
                    ],
                  ]),
                ),
          ]),
        ],
      ]),
    );
  }
}
