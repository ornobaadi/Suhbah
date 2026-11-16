import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.title, required this.meta, required this.child, this.onTap, this.onLongPress});

  final String title;
  final String meta;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(title, style: AppText.body(size: 12, weight: FontWeight.w700)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      meta,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 10.5, color: AppColors.sub),
                    ),
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Five skewed "waqt shapes" per member, mirrored around a crescent.
class SalahCard extends StatelessWidget {
  const SalahCard({super.key, required this.day, required this.now, required this.onToggle, this.onOpen});

  /// Hold the card: today's prayer times. Taps go to the prayers themselves.
  final VoidCallback? onOpen;

  final TogetherDay day;
  final DateTime now;
  final ValueChanged<Prayer> onToggle;

  @override
  Widget build(BuildContext context) {
    final next = day.nextPrayer(now);
    final meta = day.prayerTimes.isEmpty
        ? 'Set location for times'
        : next == null
        ? 'All five times have come in'
        : '${next.label} at ${_fmt(day.prayerTimes[next]!)}';
    final partner = day.partner;
    if (partner == null) {
      return ProgressCard(
        onLongPress: onOpen,
        title: 'Salah',
        meta: meta,
        child: Padding(padding: const EdgeInsets.only(top: 3), child: _columns(day.me, mirrored: false, tappable: true)),
      );
    }
    return ProgressCard(
      onLongPress: onOpen,
      title: 'Salah',
      meta: meta,
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _columns(day.me, mirrored: false, tappable: true)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: AppColors.pill, shape: BoxShape.circle),
                child: const Icon(Icons.nightlight_round, size: 14, color: AppColors.memberA),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(child: _columns(partner, mirrored: true, tappable: false)),
          ],
        ),
      ),
    );
  }

  /// One column per prayer: the shape and its letter. The whole column is the
  /// tap target, so it's easy to hit and never opens the sheet by mistake.
  Widget _columns(MemberDay m, {required bool mirrored, required bool tappable}) {
    final items = [
      for (final p in Prayer.values)
        Expanded(
          child: Semantics(
            button: tappable,
            label: '${m.name} ${p.label} ${day.statusOf(m, p, now).name}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tappable ? () => onToggle(p) : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1.5, 6, 1.5, 2),
                child: Column(
                  children: [
                    _WaqtShape(status: day.statusOf(m, p, now), color: m.color, mirrored: mirrored),
                    const SizedBox(height: 5),
                    Text(
                      p.letter,
                      style: AppText.body(size: 9, weight: FontWeight.w700, color: AppColors.sub, spacing: .4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
    return Row(children: mirrored ? items.reversed.toList() : items);
  }

  static String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _WaqtShape extends StatelessWidget {
  const _WaqtShape({required this.status, required this.color, required this.mirrored});
  final PrayerStatus status;
  final Color color;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final deco = switch (status) {
      PrayerStatus.done => BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      PrayerStatus.open => BoxDecoration(color: AppColors.pale(color), borderRadius: BorderRadius.circular(5)),
      PrayerStatus.upcoming => BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .6), width: 1.5),
      ),
    };
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.skewX(mirrored ? 0.176 : -0.176),
      child: AnimatedContainer(duration: const Duration(milliseconds: 250), height: 22, decoration: deco),
    );
  }
}

/// Shared skeleton for the two half-width cards so they line up row by row:
/// header, a 58px picture, the counts, then the action pill.
class _HalfCard extends StatelessWidget {
  const _HalfCard({
    required this.title,
    required this.meta,
    required this.picture,
    required this.me,
    required this.partner,
    required this.goal,
    required this.count,
    required this.action,
    this.onTap,
    this.onHold,
  });
  final String title, meta, action;

  /// Long press opens the adjust sheet.
  final VoidCallback? onHold;
  final Widget picture;
  final MemberDay me;
  final MemberDay? partner;
  final int goal;
  final int Function(MemberDay) count;
  final VoidCallback? onTap;

  // The number pops when it changes.
  Widget _val(MemberDay m) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        reverseDuration: const Duration(milliseconds: 80),
        transitionBuilder: (c, a) => ScaleTransition(
          scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: a, child: c),
        ),
        child: Text(
          '${count(m)}',
          key: ValueKey(count(m)),
          style: AppText.display(size: 14, color: m.color),
        ),
      ),
      Text(
        '/$goal',
        style: AppText.body(size: 10.5, weight: FontWeight.w600, color: AppColors.sub),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      onLongPress: onHold == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onHold!();
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 12, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 10.5, color: AppColors.sub),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 58,
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: picture),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _val(me),
                    if (partner != null) ...[const SizedBox(width: 16), _val(partner!)],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Material(
                    color: AppColors.pill,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: onTap,
                      onLongPress: onHold,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.pillInk),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Open book: left page me, right page partner, filling toward 10 ayat.
/// Each tap adds 5 ayat.
class QuranCard extends StatelessWidget {
  const QuranCard({super.key, required this.me, required this.partner, required this.onTap, this.onHold});
  final MemberDay me;
  final MemberDay? partner;
  final VoidCallback onTap;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) => _HalfCard(
    title: 'Quran',
    meta: partner == null ? '${Goals.ayat} ayat' : '${Goals.ayat} each',
    picture: Row(mainAxisSize: MainAxisSize.min, children: [_page(me, left: true), const SizedBox(width: 2), _page(partner ?? me, left: false)]),
    me: me,
    partner: partner,
    goal: Goals.ayat,
    count: (m) => m.ayat,
    action: me.ayat >= Goals.ayat ? '+$ayatStep more' : '+$ayatStep ayat',
    onTap: onTap,
    onHold: onHold,
  );

  Widget _page(MemberDay m, {required bool left}) {
    final f = (m.ayat / Goals.ayat).clamp(0.0, 1.0);
    final r = left
        ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            topRight: Radius.circular(2),
            bottomRight: Radius.circular(2),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
            topLeft: Radius.circular(2),
            bottomLeft: Radius.circular(2),
          );
    return Container(
      width: 36,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: r,
        border: Border.all(color: AppColors.line, width: 1.5),
        color: AppColors.card,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            heightFactor: f,
            widthFactor: 1,
            child: Container(color: m.color),
          ),
        ),
      ),
    );
  }
}

/// Mini version of the main arc for istighfar. Steps 33, 66, then 100.
class IstighfarCard extends StatelessWidget {
  const IstighfarCard({super.key, required this.me, required this.partner, required this.onAdd, this.onHold});
  final MemberDay me;
  final MemberDay? partner;
  final VoidCallback onAdd;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final done = me.istighfar >= Goals.istighfar;
    return _HalfCard(
      title: 'Istighfar',
      meta: partner == null ? '${Goals.istighfar} times' : '${Goals.istighfar} each',
      picture: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tasbih(count: me.istighfar, color: me.color),
          if (partner != null) ...[const SizedBox(width: 10), _Tasbih(count: partner!.istighfar, color: partner!.color)],
        ],
      ),
      me: me,
      partner: partner,
      goal: Goals.istighfar,
      count: (m) => m.istighfar,
      action: done ? 'Done today' : '+${istighfarStep(me.istighfar)} istighfar',
      onTap: done ? null : onAdd,
      onHold: onHold,
    );
  }
}

/// A tasbih: 33 beads on a loop with the leading bead and tassel at the
/// bottom. Beads fill a third per round of 33, so 100 fills the loop.
class _Tasbih extends StatelessWidget {
  const _Tasbih({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: (count / Goals.istighfar).clamp(0.0, 1.0)),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => SizedBox(width: 50, height: 58, child: CustomPaint(painter: _TasbihPainter(v, color))),
  );
}

class _TasbihPainter extends CustomPainter {
  _TasbihPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 33;
    final c = Offset(size.width / 2, 24);
    const r = 21.0;
    final lit = progress * n;
    final string = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .25);
    canvas.drawCircle(c, r, string);
    for (var i = 0; i < n; i++) {
      // start beside the leading bead at the bottom and go round
      final a = math.pi / 2 + 2 * math.pi * (i + 1) / (n + 1);
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      final f = (lit - i).clamp(0.0, 1.0);
      canvas.drawCircle(p, 2.6, Paint()..color = Color.lerp(AppColors.pale(color).withValues(alpha: .35), color, f)!);
    }
    // leading bead and tassel
    final head = c + const Offset(0, r);
    final done = progress >= 1;
    canvas.drawCircle(head, 3.6, Paint()..color = done ? color : AppColors.pale(color).withValues(alpha: .6));
    final tassel = Path()
      ..moveTo(head.dx, head.dy + 3)
      ..lineTo(head.dx - 3.2, head.dy + 12)
      ..lineTo(head.dx + 3.2, head.dy + 12)
      ..close();
    canvas.drawPath(tassel, Paint()..color = done ? color : AppColors.pale(color).withValues(alpha: .6));
  }

  @override
  bool shouldRepaint(_TasbihPainter o) => o.progress != progress || o.color != color;
}
