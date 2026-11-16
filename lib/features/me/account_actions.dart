import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/member_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../../data/today_provider.dart';
import '../home/widgets/together_arc.dart';
import '../onboarding/pair_screen.dart';
import '../onboarding/widgets.dart';
import 'prayer_settings_screen.dart';

/// Every account and settings action, shared by the Me tab and the header menu.
class AccountActions {
  AccountActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  bool _cancelled(FirebaseAuthException e) => const {'popup-closed-by-user', 'web-context-canceled', 'canceled', 'cancelled-popup-request'}.contains(e.code);

  Future<void> editNickname() async {
    final me = ref.read(myProfileProvider).value;
    if (me == null) return;
    final name = await textDialog(context, title: 'Your nickname', initial: me.nickname, helper: 'Short one-word names look best');
    if (name != null && name.isNotEmpty && name != me.nickname) {
      await ref.read(repositoryProvider).saveProfile(me.uid, {'nickname': name});
      if (context.mounted) toast(context, 'Nickname updated');
    }
  }

  /// Tap a color and it's yours: saved at once, with the arc previewing it live.
  Future<void> editColor() async {
    final me = ref.read(myProfileProvider).value;
    if (me == null) return;
    final partner = ref.read(partnerProfileProvider).value;
    var picked = me.color;
    await showAppSheet<void>(
      context,
      title: 'Your color',
      subtitle: partner == null
          ? 'Tap a color to use it. Your half of the arc fills in it.'
          : "Tap a color to use it. Colors close to ${partner.nickname}'s are taken so your halves stay easy to tell apart.",
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: TogetherArc(
                left: 1,
                right: partner == null ? 0 : 1,
                colorLeft: picked,
                colorRight: partner?.color ?? AppColors.line,
                percent: partner == null ? 50 : 100,
                label: 'YOUR HALF',
              ),
            ),
          ),
          const SizedBox(height: 14),
          ColorGrid(
            selected: picked,
            takenBy: partner == null ? null : (partner.color, partner.nickname),
            onSelect: (c) {
              if (c.toARGB32() == picked.toARGB32()) return;
              setSheet(() => picked = c);
              ref.read(repositoryProvider).saveProfile(me.uid, {'color': colorToInt(c)});
            },
          ),
        ]),
      ),
    );
  }

  Future<void> prayerSettings() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrayerSettingsScreen()));

  Future<void> pair() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PairScreen()));

  Future<void> leavePair({bool pendingInvite = false}) async {
    final me = ref.read(myProfileProvider).value;
    if (me?.pairId == null) return;
    final ok = pendingInvite
        ? await confirmDialog(context, title: 'Cancel this invite?', body: 'The code ${me!.pairId} will stop working. You can make a new one anytime.', confirm: 'Cancel invite', cancel: 'Keep it')
        : await confirmDialog(context,
            title: 'Leave this pair?',
            body: 'You\'ll go back to solo. Your own logs stay saved, and you can pair again with a new code.',
            confirm: 'Leave pair',
            cancel: 'Stay');
    if (!ok) return;
    await ref.read(repositoryProvider).leavePair(me!.uid, me.pairId!);
    if (context.mounted) toast(context, pendingInvite ? 'Invite cancelled' : 'You\'re solo now');
  }

  Future<void> linkGoogle() async {
    try {
      await ref.read(repositoryProvider).linkGoogle();
      if (context.mounted) toast(context, 'Saved to your Google account');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted || _cancelled(e)) return;
      toast(
        context,
        e.code == 'credential-already-in-use' || e.code == 'email-already-in-use'
            ? 'That Google account already has a Suhbah profile. Sign out, then sign in with it.'
            : "Couldn't sign in (${e.code}).",
      );
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(repositoryProvider);
    ref.read(todayActionsProvider).flush();
    final ok = repo.isGuest
        ? await confirmDialog(context,
            title: 'Sign out as guest?',
            body: 'Guest data lives only on this device and will be lost. Sign in with Google first to keep it.',
            confirm: 'Sign out anyway')
        : await confirmDialog(context, title: 'Sign out?', body: 'Your logs stay saved to your Google account.', confirm: 'Sign out');
    if (ok) await repo.signOut();
  }

  Future<void> deleteAccount() async {
    final me = ref.read(myProfileProvider).value;
    if (me == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Delete your account?',
      body: 'This permanently deletes your profile and every log, and removes you from your pair. It can\'t be undone.',
      confirm: 'Delete everything',
    );
    if (!ok || !context.mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator(color: Colors.white))),
    );
    try {
      await ref.read(repositoryProvider).deleteAccount(me.uid, me.pairId);
      nav.popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      nav.pop();
      if (!_cancelled(e)) messenger.showSnackBar(SnackBar(content: Text("Couldn't delete (${e.code}). Try again.")));
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text("Couldn't delete. Check your connection and try again.")));
    }
  }
}

/// Small colored dot used as a trailing swatch.
Widget swatch(Color c) => Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: AppColors.card, width: 2), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
    );
