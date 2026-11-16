import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ramadan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui.dart';
import '../../../data/models.dart';
import '../../../data/today_provider.dart';

IconData deedIcon(Deed d) => switch (d) {
      Deed.fasting => Icons.wb_twilight_outlined,
      Deed.sadaqah => Icons.volunteer_activism_outlined,
      Deed.dua => Icons.front_hand_outlined,
      Deed.family => Icons.phone_outlined,
    };

/// A bonus deed for today. Tap to tick it. When paired, both people's ticks
/// sit side by side like the waqt shapes. Never counts toward the 100%.
class DeedCard extends StatelessWidget {
  const DeedCard({super.key, required this.deed, required this.me, this.partner, required this.onTap});
  final Deed deed;
  final MemberDay me;
  final MemberDay? partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = me.deeds.contains(deed);
    return Semantics(
      button: true,
      selected: done,
      label: '${deed.title}${done ? ', done' : ''}',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: done ? me.color.withValues(alpha: .45) : AppColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(deedIcon(deed), size: 16, color: done ? me.color : AppColors.sub),
                const SizedBox(width: 6),
                Expanded(child: Text(deed.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12, weight: FontWeight.w700))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _DeedMark(deed: deed, done: done, color: me.color)),
                if (partner != null) ...[const SizedBox(width: 6), Expanded(child: _DeedMark(deed: deed, done: partner!.deeds.contains(deed), color: partner!.color))],
              ]),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  done ? deed.doneLabel(partner?.name) : 'Tap when done',
                  key: ValueKey(done),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 11.5, weight: done ? FontWeight.w700 : FontWeight.w500, color: done ? me.color : AppColors.sub),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One person's mark for a deed, shaped by what the deed is: an arch from
/// dawn to dusk for fasting, a coin for sadaqah, open hands for dua and a
/// phone for keeping in touch. Solid when done, a pale outline when not.
class _DeedMark extends StatelessWidget {
  const _DeedMark({required this.deed, required this.done, required this.color});
  final Deed deed;
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fill = done ? color : AppColors.pale(color).withValues(alpha: .14);
    final ink = done ? Colors.white : color.withValues(alpha: .55);
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
      child: Icon(done ? _doneIcon : deedIcon(deed), key: ValueKey(done), size: 18, color: ink),
    );
    final border = Border.all(color: done ? color : color.withValues(alpha: .35), width: 1.4);
    const d = Duration(milliseconds: 260);

    return SizedBox(
      height: 38,
      child: switch (deed) {
        // a pill holding the sunset that ends the fast
        Deed.fasting => AnimatedContainer(
            duration: d,
            decoration: BoxDecoration(color: fill, border: border, borderRadius: BorderRadius.circular(19)),
            alignment: Alignment.center,
            child: icon,
          ),
        // a coin
        Deed.sadaqah => Center(
            child: AnimatedContainer(
              duration: d,
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: border),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        // a soft heart-like pill for a dua
        Deed.dua => AnimatedContainer(
            duration: d,
            decoration: BoxDecoration(color: fill, border: border, borderRadius: BorderRadius.circular(19)),
            alignment: Alignment.center,
            child: icon,
          ),
        // a round tile, like the coin, with a phone
        Deed.family => Center(
            child: AnimatedContainer(
              duration: d,
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle, border: border),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
      },
    );
  }

  IconData get _doneIcon => switch (deed) {
        Deed.fasting => Icons.wb_twilight_rounded,
        Deed.sadaqah => Icons.volunteer_activism_rounded,
        Deed.dua => Icons.front_hand_rounded,
        Deed.family => Icons.phone_in_talk_rounded,
      };
}

/// Pick which bonus cards appear on Today. Used from Today and from Me.
Future<void> showDeedSheet(BuildContext context) => showAppSheet<void>(
      context,
      title: 'Your good deeds',
      subtitle: 'Bonus cards for your home. They never change your 100%.',
      child: Consumer(builder: (context, ref, _) {
        final me = ref.watch(myProfileProvider).value;
        final paired = ref.watch(partnerProfileProvider).value != null;
        final actions = ref.read(todayActionsProvider);
        final ramadan = isRamadan(DateTime.now());
        final order = ramadan ? Deed.values : [...Deed.values.where((d) => d != Deed.fasting), Deed.fasting];
        return Column(children: [
          for (final d in order)
            Builder(builder: (context) {
              final on = me?.deedCards.contains(d) ?? false;
              final blocked = d.pairedOnly && !paired;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  onTap: blocked ? null : () => actions.setDeedCard(d, !on),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.pill, borderRadius: BorderRadius.circular(11)),
                      child: Icon(deedIcon(d), size: 18, color: AppColors.pillInk),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(d.title, style: AppText.body(size: 14, weight: FontWeight.w700))),
                          if (d == Deed.fasting && ramadan) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(99)),
                              child: Text('RAMADAN', style: AppText.label(size: 9, color: Colors.white, spacing: 1)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(blocked ? 'Pair with someone to use this card.' : d.reason, style: AppText.body(size: 12, color: AppColors.sub, height: 1.4)),
                      ]),
                    ),
                    Switch(value: on && !blocked, onChanged: blocked ? null : (v) => actions.setDeedCard(d, v)),
                  ]),
                ),
              );
            }),
        ]);
      }),
    );
