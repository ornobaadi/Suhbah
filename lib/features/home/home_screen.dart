import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/prayer_times.dart';
import '../../core/ramadan.dart';
import '../../core/reminders.dart';
import '../../core/confetti.dart';
import '../../core/member_colors.dart';
import '../../core/brand.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../../data/models.dart';
import '../../data/today_provider.dart';
import '../insights/insights_tab.dart';
import '../me/account_actions.dart';
import '../me/me_tab.dart';
import 'widgets/deed_cards.dart';
import 'widgets/progress_cards.dart';
import 'widgets/star_pattern.dart';
import 'widgets/streak_strip.dart';
import 'widgets/together_arc.dart';

typedef GoTo = void Function(int tab);

/// Three tabs in a floating dock: Today, Journey, Me.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _tab = 0;

  /// Plays each time the tab changes: the new tab fades and rises in.
  late final AnimationController _swap = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);

  /// Colors for the one-time "partner joined" confetti, null when not showing.
  List<Color>? _celebrate;

  /// Celebrates a partner the first time this person sees them on Today,
  /// even if they joined while the app was closed.
  void _maybeCelebrate(UserProfile? me, UserProfile? partner) {
    if (me == null || partner == null || me.metPartner == partner.uid || _celebrate != null) return;
    final uid = me.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Haptics.success();
      setState(() => _celebrate = [me.color, displayPartnerColor(me.color, partner.color), AppColors.flameTop]);
      toast(context, '${partner.nickname} joined you. Your arc now fills together');
      ref.read(repositoryProvider).saveProfile(uid, {'metPartner': partner.uid});
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _celebrate = null);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _swap.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // write batched taps before the app goes to the background
    if (state != AppLifecycleState.resumed) ref.read(todayActionsProvider).flush();
  }

  void _go(int tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
    if (!MediaQuery.disableAnimationsOf(context)) _swap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(todayProvider);
    if (day == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _maybeCelebrate(ref.watch(myProfileProvider).value, ref.watch(partnerProfileProvider).value);
    // Feel it when your partner logs something while you're looking.
    ref.listen<TogetherDay?>(todayProvider, (prev, next) {
      final a = prev?.partner, b = next?.partner;
      if (a == null || b == null || a.name != b.name) return;
      final more = b.prayed.length > a.prayed.length || b.ayat > a.ayat || b.istighfar > a.istighfar || b.deeds.length > a.deeds.length;
      if (more) Haptics.partner();
    });
    // Back from Journey or Me goes to Today; only Today lets back leave the app.
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _tab != 0) _go(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _swap,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_swap.value);
                return Opacity(
                  opacity: .25 + .75 * t,
                  child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
                );
              },
              child: IndexedStack(
                index: _tab,
                children: [
                  _TogetherView(day: day, onGo: _go),
                  const InsightsTab(),
                  const MeTab(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dock(index: _tab, onTap: _go),
                    // the + sits beside the dock on Today only
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: _tab == 0
                          ? Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: _LogButton(
                                onTap: () => showAppSheet<void>(
                                  context,
                                  title: 'Log a deed',
                                  subtitle: 'Saved instantly, even offline.',
                                  child: const _QuickLog(),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            if (_celebrate != null) Positioned.fill(child: ConfettiBurst(colors: _celebrate!)),
          ],
        ),
      ),
    );
  }
}

class _TogetherView extends ConsumerWidget {
  const _TogetherView({required this.day, required this.onGo});
  final TogetherDay day;
  final GoTo onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(todayActionsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final me = ref.watch(myProfileProvider).value;
    final partnerProfile = ref.watch(partnerProfileProvider).value;
    final partner = day.partner;
    final status = day.togetherPct >= 100
        ? (partner == null ? 'MashaAllah, you completed today' : 'MashaAllah, you completed today together')
        : partner == null
        ? '${day.me.prayed.length} of 5 prayers so far'
        : 'Prayers so far: you ${day.me.prayed.length}, ${partner.name} ${partner.prayed.length} of 5';

    // last seven days for the streak strip, today last
    final myHist = me == null ? const <String, DayLog>{} : ref.watch(historyProvider(me.uid)).value ?? const <String, DayLog>{};
    final pHist = partnerProfile == null ? null : ref.watch(historyProvider(partnerProfile.uid)).value ?? const <String, DayLog>{};
    final today = DateTime(now.year, now.month, now.day);
    final week = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final scores = [
      for (final d in week)
        d == today ? day.togetherScore : togetherScoreOf(myHist[dayKey(d)] ?? DayLog.empty, pHist == null ? null : pHist[dayKey(d)] ?? DayLog.empty),
    ];
    final bonus = day.deedCards.where((d) => day.me.deeds.contains(d)).length;
    final ramadanBanner = isRamadan(now) && me != null && !me.deedCards.contains(Deed.fasting) && me.ramadanHidden != now.year;
    final reminder = reminderFor(now);

    final deedTiles = <Widget>[for (final d in day.deedCards) DeedCard(deed: d, me: day.me, partner: partner, onTap: () => actions.toggleDeed(d))];

    return PatternPage(
      children: [
        _Header(
          now: now,
          streak: day.streak,
          counts: day.togetherScore >= Goals.streakThreshold,
          color: day.me.color,
          partnerColor: partner?.color,
          onStreak: () => showAppSheet<void>(
            context,
            title: 'Your streak',
            subtitle: 'A day counts when you reach ${(Goals.streakThreshold * 100).round()}%${partner == null ? '' : ' together'}.',
            child: StreakStrip(
              streak: day.streak,
              best: day.best < day.streak ? day.streak : day.best,
              days: week,
              scores: scores,
              yesterdayPct: day.yesterdayPct,
              color: day.me.color,
              partnerColor: partner?.color,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // the arc is the hero: as wide as the content column, with breathing room
        Padding(
          padding: EdgeInsets.zero,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: TogetherArc(
                left: day.me.score,
                right: partner?.score ?? day.me.score,
                colorLeft: day.me.color,
                colorRight: partner?.color ?? day.me.color,
                percent: day.togetherPct,
                label: partner == null ? 'MY DAY TODAY' : 'TOGETHER TODAY',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(name: day.me.name, color: day.me.color),
            if (partner != null) ...[const SizedBox(width: 12), _Legend(name: partner.name, color: partner.color)],
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: Text("Today's Progress", style: AppText.display(size: 17))),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: bonus == 0
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(bonus),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(99)),
                      child: Text('+$bonus BONUS', style: AppText.label(size: 10, color: AppColors.pillInk, spacing: 1.2)),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          layoutBuilder: (cur, prev) => Stack(alignment: Alignment.centerLeft, children: [...prev, ?cur]),
          child: Text(
            status,
            key: ValueKey(status),
            style: AppText.body(size: 11, color: AppColors.sub),
          ),
        ),
        const SizedBox(height: 10),
        SalahCard(
          day: day,
          now: now,
          onOpen: () => _showPrayersToday(context),
          onToggle: (p) {
            HapticFeedback.lightImpact();
            actions.togglePrayer(p);
          },
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuranCard(
                  me: day.me,
                  partner: partner,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    actions.addAyat(ayatStep);
                  },
                  onHold: () => _adjust(context, quran: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IstighfarCard(
                  me: day.me,
                  partner: partner,
                  onAdd: () {
                    HapticFeedback.lightImpact();
                    actions.addIstighfar(istighfarStep(day.me.istighfar));
                  },
                  onHold: () => _adjust(context, quran: false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good deeds', style: AppText.display(size: 17)),
                  const SizedBox(height: 2),
                  Text(
                    day.deedCards.isEmpty ? 'Fasting, sadaqah and more. Bonus only.' : 'Bonus. They never change your 100%.',
                    style: AppText.body(size: 11, color: AppColors.sub),
                  ),
                ],
              ),
            ),
            _SmallButton(
              icon: day.deedCards.isEmpty ? Icons.add_rounded : Icons.tune_rounded,
              label: day.deedCards.isEmpty ? 'Add' : 'Edit',
              onTap: () => showDeedSheet(context),
            ),
          ],
        ),
        if (deedTiles.isNotEmpty || ramadanBanner) const SizedBox(height: 10),
        if (ramadanBanner) ...[
          _RamadanBanner(
            onAdd: () => actions.setDeedCard(Deed.fasting, true),
            onHide: () => ref.read(repositoryProvider).saveProfile(me.uid, {'ramadanHidden': now.year}),
          ),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < deedTiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: deedTiles[i]),
                const SizedBox(width: 8),
                Expanded(child: i + 1 < deedTiles.length ? deedTiles[i + 1] : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        _ReminderCard(text: reminder.text, source: reminder.source),
      ],
    );
  }
}

/// One short ayah or hadith a day, with its source.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.text, required this.source});
  final String text, source;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(18)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const EightPointStar(size: 7, color: AppColors.pillInk),
            const SizedBox(width: 8),
            Text("TODAY'S REMINDER", style: AppText.label(size: 10, color: AppColors.pillInk, spacing: 1.4)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: AppText.display(size: 17, weight: FontWeight.w700, color: AppColors.ink, height: 1.3),
        ),
        const SizedBox(height: 6),
        Text(
          source,
          style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.pillInk),
        ),
      ],
    ),
  );
}

class _RamadanBanner extends StatelessWidget {
  const _RamadanBanner({required this.onAdd, required this.onHide});
  final VoidCallback onAdd, onHide;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ramadan Mubarak', style: AppText.display(size: 16, color: Colors.white)),
              Text('Add Fasting to your day?', style: AppText.body(size: 12, color: Colors.white.withValues(alpha: .75))),
            ],
          ),
        ),
        FilledButton(
          onPressed: onAdd,
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink, minimumSize: const Size(0, 38)),
          child: const Text('Add'),
        ),
        IconButton(
          onPressed: onHide,
          tooltip: 'Not now',
          icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: .7), size: 20),
        ),
      ],
    ),
  );
}

class _QuickLog extends ConsumerWidget {
  const _QuickLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(todayProvider);
    final a = ref.read(todayActionsProvider);
    if (d == null) return const SizedBox.shrink();
    final c = d.me.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Salah',
          style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.sub),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final p in Prayer.values) ...[
              if (p != Prayer.fajr) const SizedBox(width: 6),
              Expanded(
                child: _PrayerChip(
                  prayer: p,
                  time: d.prayerTimes[p],
                  done: d.me.prayed.contains(p),
                  color: c,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    a.togglePrayer(p);
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _StepperRow(
          icon: Icons.menu_book_rounded,
          title: 'Quran',
          count: d.me.ayat,
          goal: Goals.ayat,
          unit: 'ayat',
          color: c,
          step: ayatStep,
          onAdd: a.addAyat,
        ),
        const SizedBox(height: 8),
        _StepperRow(
          icon: Icons.all_inclusive_rounded,
          title: 'Istighfar',
          count: d.me.istighfar,
          goal: Goals.istighfar,
          unit: '',
          color: c,
          step: istighfarStep(d.me.istighfar),
          onAdd: a.addIstighfar,
        ),
        if (d.deedCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Good deeds',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.sub),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final deed in d.deedCards)
                FilterChip(
                  avatar: Icon(deedIcon(deed), size: 16, color: d.me.deeds.contains(deed) ? Colors.white : c),
                  label: Text(deed.title),
                  selected: d.me.deeds.contains(deed),
                  showCheckmark: false,
                  selectedColor: c,
                  backgroundColor: AppColors.card,
                  labelStyle: AppText.body(size: 13, weight: FontWeight.w700, color: d.me.deeds.contains(deed) ? Colors.white : AppColors.ink),
                  side: BorderSide(color: d.me.deeds.contains(deed) ? c : AppColors.line),
                  shape: const StadiumBorder(),
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    a.toggleDeed(deed);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Arch-topped prayer tile: fills with the member's color when prayed.
class _PrayerChip extends StatelessWidget {
  const _PrayerChip({required this.prayer, required this.time, required this.done, required this.color, required this.onTap});
  final Prayer prayer;
  final DateTime? time;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: done,
    label: '${prayer.label}${done ? ', prayed' : ''}',
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: done ? color : AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.elliptical(18, 16),
            topRight: Radius.elliptical(18, 16),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          border: Border.all(color: done ? color : AppColors.line),
        ),
        child: Column(
          children: [
            Icon(done ? Icons.check_rounded : Icons.circle_outlined, size: 18, color: done ? Colors.white : color.withValues(alpha: .35)),
            const SizedBox(height: 4),
            Text(
              prayer.label,
              style: AppText.body(size: 11.5, weight: FontWeight.w700, color: done ? Colors.white : AppColors.ink),
            ),
            if (time != null)
              Text(
                TimeOfDay.fromDateTime(time!).format(context),
                style: AppText.body(size: 9.5, color: done ? Colors.white.withValues(alpha: .85) : AppColors.sub),
              ),
          ],
        ),
      ),
    ),
  );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.goal,
    required this.unit,
    required this.color,
    required this.step,
    required this.onAdd,
  });
  final IconData icon;
  final String title, unit;
  final int count, goal, step;
  final Color color;
  final ValueChanged<int> onAdd;

  Widget _btn(IconData i, String? label, VoidCallback? f, {bool dark = false}) => Material(
    color: dark ? AppColors.ink : AppColors.bg,
    shape: StadiumBorder(side: dark ? BorderSide.none : const BorderSide(color: AppColors.line)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: f == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              f();
            },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 18, color: dark ? Colors.white : (f == null ? AppColors.line : AppColors.ink)),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body(size: 14, weight: FontWeight.w700)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: AppText.body(size: 12.5, weight: FontWeight.w800, color: color),
                    ),
                    TextSpan(
                      text: ' / $goal $unit',
                      style: AppText.body(size: 12, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _btn(Icons.remove_rounded, null, count > 0 ? () => onAdd(-1) : null),
        const SizedBox(width: 6),
        _btn(Icons.add_rounded, '$step', () => onAdd(step), dark: true),
      ],
    ),
  );
}

/// The app's name with today's date under it, and the streak on the right.
class _Header extends StatelessWidget {
  const _Header({required this.now, required this.streak, required this.counts, required this.color, this.partnerColor, required this.onStreak});
  final DateTime now;
  final int streak;

  /// Today already reached the streak threshold.
  final bool counts;
  final Color color;
  final Color? partnerColor;
  final VoidCallback onStreak;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SuhbahMark(size: 30),
                  const SizedBox(width: 8),
                  Text('suhbah', style: AppText.display(size: 24, weight: FontWeight.w800, spacing: -.6, height: 1.1)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE · d MMMM').format(now),
                style: AppText.body(size: 12.5, weight: FontWeight.w600, color: AppColors.sub),
              ),
            ],
          ),
        ),
        _StreakPill(streak: streak, counts: counts, color: color, partnerColor: partnerColor, onTap: onStreak),
      ],
    ),
  );
}

/// Flame and streak number. Lit while there is a streak; tap for the week.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.counts, required this.color, this.partnerColor, required this.onTap});
  final int streak;

  /// Today already reached the threshold.
  final bool counts;
  final Color color;
  final Color? partnerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lit = streak > 0;
    return Semantics(
      button: true,
      label: '$streak day streak${counts ? ', today counts' : ''}',
      child: Material(
        color: lit ? AppColors.flameBg : AppColors.card,
        shape: StadiumBorder(side: lit ? BorderSide.none : const BorderSide(color: AppColors.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 6, 13, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // a streak still waiting on today shows a softer flame
                AnimatedOpacity(
                  opacity: !lit || counts ? 1 : .55,
                  duration: const Duration(milliseconds: 300),
                  child: StreakFlame(lit: lit, size: 20),
                ),
                const SizedBox(width: 4),
                Text('$streak', style: AppText.display(size: 16, height: 1, color: lit ? AppColors.flameInk : AppColors.sub)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill button for section headers ("Add", "Edit").
class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.pill,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.pillInk),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.pillInk),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(name, style: AppText.body(size: 11, color: AppColors.sub)),
    ],
  );
}

class _Dock extends StatelessWidget {
  const _Dock({required this.index, required this.onTap});
  final int index;
  final GoTo onTap;

  static const items = [(Icons.wb_twilight_rounded, 'Today'), (Icons.auto_graph_rounded, 'Journey'), (Icons.person_rounded, 'Me')];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              label: items[i].$2,
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  padding: EdgeInsets.symmetric(horizontal: i == index ? 18 : 16),
                  decoration: BoxDecoration(color: i == index ? AppColors.ink : AppColors.card, borderRadius: BorderRadius.circular(26)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, size: 22, color: i == index ? Colors.white : AppColors.sub),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: i == index
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  items[i].$2,
                                  style: AppText.body(size: 14, weight: FontWeight.w700, color: Colors.white),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The + beside the dock: opens "Log a deed".
class _LogButton extends StatelessWidget {
  const _LogButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Log a deed',
    child: Material(
      color: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 6,
      shadowColor: AppColors.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: const SizedBox(width: 64, height: 64, child: Icon(Icons.add_rounded, color: Colors.white, size: 30)),
      ),
    ),
  );
}

/// Today's five prayers, opened from the next-prayer strip: times, who has
/// prayed each, what's next, and the partner's times when paired.
void _showPrayersToday(BuildContext context) => showAppSheet<void>(
  context,
  title: 'Prayers today',
  child: Consumer(
    builder: (context, ref, _) {
      final day = ref.watch(todayProvider);
      final me = ref.watch(myProfileProvider).value;
      final partnerProfile = ref.watch(partnerProfileProvider).value;
      if (day == null || me == null) return const SizedBox.shrink();
      final now = ref.watch(clockProvider).value ?? DateTime.now();
      final next = day.nextPrayer(now);
      final theirTimes = partnerProfile != null && partnerProfile.hasLocation
          ? prayerTimesFor(lat: partnerProfile.lat!, lng: partnerProfile.lng!, method: partnerProfile.method, asr: partnerProfile.asr, date: now)
          : null;
      final p = day.partner;
      String t(DateTime d) => TimeOfDay.fromDateTime(d).format(context);
      Widget mark(bool done, Color c) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: done ? c : AppColors.pale(c).withValues(alpha: .15),
          shape: BoxShape.circle,
          border: done ? null : Border.all(color: c.withValues(alpha: .4)),
        ),
        child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
      );
      if (day.prayerTimes.isEmpty) {
        return Text('Set your location to see prayer times.', style: AppText.body(size: 14, color: AppColors.sub));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final pr in Prayer.values) ...[
                  if (pr != Prayer.fajr) const Divider(indent: 16, endIndent: 16),
                  Container(
                    color: pr == next ? day.me.color.withValues(alpha: .07) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            pr.label,
                            style: AppText.body(size: 14.5, weight: FontWeight.w700, color: pr == next ? day.me.color : AppColors.ink),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t(day.prayerTimes[pr]!), style: AppText.body(size: 14, weight: FontWeight.w600)),
                              if (pr == next)
                                Text(
                                  countdownLabel(day.prayerTimes[pr]!.difference(now)),
                                  style: AppText.body(size: 11.5, weight: FontWeight.w700, color: day.me.color),
                                )
                              else if (theirTimes != null && p != null)
                                Text("${p.name}'s ${t(theirTimes[pr]!)}", style: AppText.body(size: 11.5, color: AppColors.sub)),
                            ],
                          ),
                        ),
                        mark(day.me.prayed.contains(pr), day.me.color),
                        if (p != null) ...[const SizedBox(width: 6), mark(p.prayed.contains(pr), p.color)],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${me.city ?? 'Your location'} · ${calcMethods[me.method] ?? me.method} · ${me.asr == 'hanafi' ? 'Hanafi' : 'Standard'} Asr',
            textAlign: TextAlign.center,
            style: AppText.body(size: 11.5, color: AppColors.sub),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                AccountActions(context, ref).prayerSettings();
              },
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Change location or method'),
            ),
          ),
        ],
      );
    },
  ),
);

/// Hold a Quran or Istighfar card: set today's count exactly, or reset it.
Future<void> _adjust(BuildContext context, {required bool quran}) => showAppSheet<void>(
  context,
  title: quran ? 'Quran today' : 'Istighfar today',
  subtitle: 'Fix a count you tapped by mistake. Only your own count changes.',
  child: Consumer(
    builder: (context, ref, _) {
      final day = ref.watch(todayProvider);
      if (day == null) return const SizedBox.shrink();
      final a = ref.read(todayActionsProvider);
      final n = quran ? day.me.ayat : day.me.istighfar;
      final goal = quran ? Goals.ayat : Goals.istighfar;
      final c = day.me.color;
      void add(int d) {
        HapticFeedback.selectionClick();
        quran ? a.addAyat(d) : a.addIstighfar(d);
      }

      Widget step(String label, int d) => Expanded(
        child: OutlinedButton(
          onPressed: n + d < 0 ? null : () => add(d),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), padding: EdgeInsets.zero),
          child: Text(label),
        ),
      );
      const small = 1;
      final big = quran ? ayatStep : 33;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 60),
              transitionBuilder: (w, an) => ScaleTransition(
                scale: Tween(begin: 1.3, end: 1.0).animate(CurvedAnimation(parent: an, curve: Curves.easeOutBack)),
                child: FadeTransition(opacity: an, child: w),
              ),
              child: Text.rich(
                key: ValueKey(n),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$n',
                      style: AppText.display(size: 56, color: c, spacing: -2),
                    ),
                    TextSpan(
                      text: ' / $goal',
                      style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.sub),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Text(quran ? 'ayat read' : 'times said', style: AppText.body(size: 13, color: AppColors.sub)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: n == 0 ? null : () => add(-(quran ? ayatUndo(n) : istighfarUndo(n))),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(n == 0 ? 'Nothing to undo' : 'Undo last tap (−${quran ? ayatUndo(n) : istighfarUndo(n)})'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              step('−$big', -big),
              const SizedBox(width: 8),
              step('−$small', -small),
              const SizedBox(width: 8),
              step('+$small', small),
              const SizedBox(width: 8),
              step('+$big', big),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: n == 0
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    add(-n);
                  },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset to 0'),
          ),
        ],
      );
    },
  ),
);
