import 'package:flutter/services.dart';

/// The app's haptic vocabulary, so every touch and every change you can
/// see also has a feel. On Android these map to the system's own touch
/// feedback, so they respect the phone's "Touch feedback" setting.
abstract final class Haptics {
  /// A detent: picking from a list, a dot lighting up, moving a step.
  static void tick() => HapticFeedback.selectionClick();

  /// A normal tap that logs something (a prayer, +5 ayat, a deed).
  static void tap() => HapticFeedback.lightImpact();

  /// A deliberate press: long-press, reset, confirm.
  static void press() => HapticFeedback.mediumImpact();

  /// Something big landed: a partner joined, an arc was completed.
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.mediumImpact();
  }

  /// A soft double knock: your partner just did something.
  static Future<void> partner() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }
}
