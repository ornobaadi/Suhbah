import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/brand.dart';
import 'core/theme/app_theme.dart';
import 'data/today_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/sign_in_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline cache: logs save instantly and sync when online.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  runApp(const ProviderScope(child: SuhbahApp()));
}

class SuhbahApp extends StatelessWidget {
  const SuhbahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suhbah',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Signed out → sign in. No finished profile → onboarding. Otherwise → home.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    if (user.isLoading && !user.hasValue) return const _Splash();
    if (user.value == null) return const SignInScreen();
    final profile = ref.watch(myProfileProvider);
    if (profile.hasError && !profile.hasValue) {
      // Don't drop an onboarded person back into onboarding because of a hiccup.
      return _Retry(onRetry: () => ref.invalidate(myProfileProvider));
    }
    if (profile.isLoading && !profile.hasValue) return const _Splash();
    final p = profile.value;
    if (p == null || !p.onboarded) return const OnboardingFlow();
    return const HomeScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.bg, body: Center(child: SuhbahMark(size: 64)));
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SuhbahMark(size: 44),
                const SizedBox(height: 18),
                Text("Couldn't load your day", textAlign: TextAlign.center, style: AppText.display(size: 22)),
                const SizedBox(height: 6),
                Text('Check your connection, then try again. Nothing you logged is lost.', textAlign: TextAlign.center, style: AppText.body(size: 14, color: AppColors.sub, height: 1.45)),
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Try again')),
              ]),
            ),
          ),
        ),
      );
}
