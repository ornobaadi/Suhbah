import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/brand.dart';
import '../../core/member_colors.dart';
import '../../core/prayer_times.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../../data/models.dart';
import '../../data/today_provider.dart';
import '../home/widgets/star_pattern.dart';
import '../home/widgets/deed_cards.dart';
import 'account_actions.dart';

class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myProfileProvider).value;
    final day = ref.watch(todayProvider);
    if (me == null || day == null) return const SizedBox.shrink();
    final user = ref.watch(authUserProvider).value;
    final guest = user?.isAnonymous ?? true;
    final partner = day.partner;
    final waiting = me.pairId != null && partner == null;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final a = AccountActions(context, ref);

    return PatternPage(
      children: [
        const TabHeader(title: 'Me'),
        const SizedBox(height: 16),
        _SuhbahHero(
          me: day.me,
          partner: partner,
          waitingCode: waiting ? me.pairId : null,
          togetherPct: day.togetherPct,
          accountLabel: guest ? 'Guest · this device only' : (user?.email ?? 'Google account'),
          guest: guest,
          onEditName: a.editNickname,
          onInvite: a.pair,
        ),
        if (guest) ...[const SizedBox(height: 10), _GuestCard(onLink: a.linkGoogle)],
        const SectionLabel('Prayer times'),
        _PrayerTimesCard(
          city: me.city,
          times: day.prayerTimes,
          next: day.nextPrayer(now),
          color: day.me.color,
          method: '${calcMethods[me.method] ?? me.method} · ${me.asr == 'hanafi' ? 'Hanafi Asr' : 'Standard Asr'}',
          onEdit: a.prayerSettings,
        ),
        const SectionLabel('Profile'),
        SettingsGroup(
          children: [
            SettingsTile(icon: Icons.badge_outlined, title: 'Nickname', value: me.nickname, onTap: a.editNickname),
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Color',
              value: colorName(day.me.color) ?? 'Your half of the arc',
              onTap: a.editColor,
              trailing: swatch(day.me.color),
            ),
            SettingsTile(
              icon: Icons.dashboard_customize_outlined,
              title: 'Home cards',
              value: me.deedCards.isEmpty ? 'Add fasting, sadaqah and more' : me.deedCards.map((d) => d.title).join(', '),
              onTap: () => showDeedSheet(context),
            ),
          ],
        ),
        if (partner != null || waiting) ...[
          const SectionLabel('Partner'),
          SettingsGroup(
            children: [
              if (partner != null)
                SettingsTile(icon: Icons.logout_rounded, title: 'Leave pair', value: 'Go back to solo. Your logs stay.', onTap: () => a.leavePair()),
              if (waiting)
                SettingsTile(
                  icon: Icons.close_rounded,
                  title: 'Cancel invite',
                  value: 'The code ${me.pairId} stops working',
                  onTap: () => a.leavePair(pendingInvite: true),
                ),
            ],
          ),
        ],
        const SectionLabel('Account'),
        SettingsGroup(
          children: [
            if (guest) SettingsTile(icon: Icons.login_rounded, title: 'Sign in with Google', value: 'Back up and sync your logs', onTap: a.linkGoogle),
            SettingsTile(icon: Icons.logout_rounded, title: 'Sign out', onTap: a.signOut),
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.sub,
              title: 'Delete account',
              value: 'Removes your profile and every log',
              onTap: a.deleteAccount,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsGroup(
          children: [
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              value: 'What Suhbah stores and why',
              onTap: () => launchUrl(Uri.parse('https://ornobaadi.github.io/Suhbah/privacy/'), mode: LaunchMode.externalApplication),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              const SuhbahMark(size: 30),
              const SizedBox(height: 8),
              Text('suhbah', style: AppText.display(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Companionship in worship', style: AppText.body(size: 11, color: AppColors.sub)),
            ],
          ),
        ),
      ],
    );
  }
}

/// You, and your partner (or an empty seat for them), joined by a two-color star.
class _SuhbahHero extends StatelessWidget {
  const _SuhbahHero({
    required this.me,
    required this.partner,
    required this.waitingCode,
    required this.togetherPct,
    required this.accountLabel,
    required this.guest,
    required this.onEditName,
    required this.onInvite,
  });
  final MemberDay me;
  final MemberDay? partner;
  final String? waitingCode;
  final int togetherPct;
  final String accountLabel;
  final bool guest;
  final VoidCallback onEditName;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final p = partner;
    final title = p != null ? '${me.name} & ${p.name}' : me.name;
    final subtitle = p != null
        ? 'Your suhbah · $togetherPct% together today'
        : waitingCode != null
        ? 'Waiting for your partner to join'
        : 'Solo for now';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: [
          SizedBox(
            height: 84,
            width: 158,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: GestureDetector(
                    onTap: onEditName,
                    child: _Ring(
                      child: MemberAvatar(name: me.name, color: me.color, size: 76),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: p != null
                      ? _Ring(
                          child: MemberAvatar(name: p.name, color: p.color, size: 76),
                        )
                      : GestureDetector(
                          onTap: waitingCode == null ? onInvite : null,
                          child: _EmptySeat(waiting: waitingCode != null, color: me.color),
                        ),
                ),
                // the seal sits exactly where the two seats meet
                if (p != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
                    ),
                    child: SizedBox(width: 18, height: 18, child: CustomPaint(painter: _SplitStar(me.color, p.color))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(title, overflow: TextOverflow.ellipsis, style: AppText.display(size: 22, spacing: -.5)),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onEditName,
                borderRadius: BorderRadius.circular(99),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16, color: AppColors.sub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.body(size: 12.5, color: AppColors.sub)),
          const SizedBox(height: 12),
          if (waitingCode != null)
            _CodeChip(code: waitingCode!)
          else if (p == null)
            FilledButton.icon(onPressed: onInvite, icon: const Icon(Icons.favorite_border_rounded, size: 18), label: const Text('Pair with someone')),
          if (waitingCode != null || p == null) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: guest ? AppColors.bg : AppColors.pill,
              borderRadius: BorderRadius.circular(99),
              border: guest ? Border.all(color: AppColors.line) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(guest ? Icons.phone_android_rounded : Icons.verified_user_outlined, size: 13, color: guest ? AppColors.sub : AppColors.pillInk),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    accountLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 11, weight: FontWeight.w700, color: guest ? AppColors.sub : AppColors.pillInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White ring around an avatar so overlapping avatars stay separate.
class _Ring extends StatelessWidget {
  const _Ring({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
    child: child,
  );
}

/// The partner's seat before anyone sits in it: a dashed circle.
class _EmptySeat extends StatelessWidget {
  const _EmptySeat({required this.waiting, required this.color});
  final bool waiting;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 82,
    height: 82,
    decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
    child: CustomPaint(
      painter: _DashedCircle(color: color.withValues(alpha: .55)),
      child: Center(child: Icon(waiting ? Icons.hourglass_top_rounded : Icons.add_rounded, color: color, size: 26)),
    ),
  );
}

class _DashedCircle extends CustomPainter {
  _DashedCircle({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const n = 22;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 2 * math.pi / n * .5, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle o) => o.color != color;
}

class _SplitStar extends CustomPainter {
  _SplitStar(this.a, this.b);
  final Color a, b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final side = size.width * .7;
    final sq = Rect.fromCenter(center: Offset.zero, width: side, height: side);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [a, a, b, b],
        stops: const [0, .5, .5, 1],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawRect(sq, paint);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(sq, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplitStar o) => o.a != a || o.b != b;
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.pill,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: 'Join me on Suhbah so we can pray together. My code: $code'));
        HapticFeedback.lightImpact();
        if (context.mounted) toast(context, 'Invite message copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code, style: AppText.display(size: 20, spacing: 4, color: AppColors.pillInk)),
            const SizedBox(width: 10),
            const Icon(Icons.copy_rounded, size: 16, color: AppColors.pillInk),
          ],
        ),
      ),
    ),
  );
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onLink});
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
    child: Stack(
      children: [
        Positioned(
          right: -14,
          top: -14,
          child: Opacity(
            opacity: .12,
            child: Transform.rotate(angle: .2, child: const EightPointStar(size: 70, color: Colors.white)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keep your progress safe', style: AppText.display(size: 17, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                "Sign in with Google to back up your logs and use Suhbah on another phone. Nothing you've logged is lost.",
                style: AppText.body(size: 12.5, color: Colors.white.withValues(alpha: .72), height: 1.45),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onLink,
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Today's five times as arch-topped waqt tiles; the next one fills with your color.
class _PrayerTimesCard extends StatelessWidget {
  const _PrayerTimesCard({required this.city, required this.times, required this.next, required this.color, required this.method, required this.onEdit});
  final String? city;
  final Map<Prayer, DateTime> times;
  final Prayer? next;
  final Color color;
  final String method;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onEdit,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: AppColors.pillInk),
            const SizedBox(width: 4),
            Expanded(
              child: Text(city ?? 'Location not set', style: AppText.body(size: 14, weight: FontWeight.w700)),
            ),
            Text(
              'Edit',
              style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.pillInk),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            method,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 11.5, color: AppColors.sub),
          ),
        ),
        if (times.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (final p in Prayer.values) ...[
                if (p != Prayer.fajr) const SizedBox(width: 6),
                Expanded(
                  child: _WaqtTile(prayer: p, time: times[p]!, isNext: p == next, color: color),
                ),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

class _WaqtTile extends StatelessWidget {
  const _WaqtTile({required this.prayer, required this.time, required this.isNext, required this.color});
  final Prayer prayer;
  final DateTime time;
  final bool isNext;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: isNext ? color : AppColors.bg,
      border: Border.all(color: isNext ? color : AppColors.line),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.elliptical(18, 16),
        topRight: Radius.elliptical(18, 16),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
    ),
    child: Column(
      children: [
        Text(
          prayer.label,
          style: AppText.body(size: 10.5, weight: FontWeight.w600, color: isNext ? Colors.white.withValues(alpha: .85) : AppColors.sub),
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(
            TimeOfDay.fromDateTime(time).format(context).replaceAll(' AM', '').replaceAll(' PM', ''),
            style: AppText.display(size: 15, color: isNext ? Colors.white : AppColors.ink),
          ),
        ),
      ],
    ),
  );
}
