import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/today_provider.dart';
import '../home/widgets/together_arc.dart';
import 'widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _guest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).signInAsGuest();
    } on FirebaseAuthException catch (e) {
      _error = "Couldn't start as a guest (${e.code}). Check your connection and try again.";
    } catch (_) {
      _error = "Couldn't start as a guest. Check your connection and try again.";
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user' && e.code != 'web-context-canceled' && e.code != 'canceled') {
        _error = e.code == 'network-request-failed'
            ? "You're offline. Connect to the internet and try again."
            : "Google sign-in didn't work (${e.code}). Try again, or start without an account.";
      }
    } catch (_) {
      _error = 'Sign-in didn\'t work. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepFrame(
      eyebrow: 'Assalamu alaikum',
      title: 'Pray together,\neven when apart.',
      subtitle: 'Two people, one arc. Every prayer, ayah and istighfar fills it from both sides.',
      primaryLabel: 'Continue with Google',
      onPrimary: _signIn,
      busy: _busy,
      leading: const GoogleLogo(),
      footer: TextButton(onPressed: _busy ? null : _guest, child: const Text('Try it first, no account')),
      child: Column(
        children: [
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const TogetherArc(
              left: .72,
              right: .58,
              colorLeft: AppColors.memberA,
              colorRight: AppColors.memberB,
              percent: 65,
              label: 'TOGETHER TODAY',
            ),
          ),
          const Spacer(),
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.sub),
            ),
        ],
      ),
    );
  }
}
