import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color tokens from DESIGN.md.
abstract final class AppColors {
  static const bg = Color(0xFFFCFDFC);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE4EBE8);
  static const ink = Color(0xFF11201B);
  static const sub = Color(0xFF6B7C75);
  static const pill = Color(0xFFE8F2EE);
  static const pillInk = Color(0xFF0B6F63);

  /// Default member colors. Users pick their own at onboarding.
  static const memberA = Color(0xFF0B7D5E);
  static const memberB = Color(0xFFC7224F);

  /// Streak flame: one warm hue for everyone, so it never fights the member colors.
  static const flameTop = Color(0xFFFFB524);
  static const flameBottom = Color(0xFFFF6B1A);
  static const flameBg = Color(0xFFFFF3E3);
  static const flameInk = Color(0xFFB4470B);

  /// Soft shadow for floating surfaces (menus, sheets).
  static const shadow = Color(0x1F11201B);

  /// "Not done yet" is the member's own color, faded. Never a warning color.
  static Color pale(Color c) => c.withValues(alpha: 0.2);
}

abstract final class AppText {
  static TextStyle display({double size = 17, FontWeight weight = FontWeight.w800, Color color = AppColors.ink, double? spacing, double? height}) =>
      GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);

  static TextStyle body({double size = 12, FontWeight weight = FontWeight.w500, Color color = AppColors.ink, double? spacing, double? height}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);

  /// Uppercase labels like PERCENT and YESTERDAY.
  static TextStyle label({double size = 11, Color color = AppColors.sub, double spacing = 1.6}) =>
      GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: spacing);
}

ThemeData buildTheme() {
  RoundedRectangleBorder r(double v, {BorderSide side = BorderSide.none}) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(v), side: side);
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.memberA, primary: AppColors.pillInk, surface: AppColors.bg),
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.card,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: AppColors.shadow,
      position: PopupMenuPosition.under,
      shape: r(18, side: const BorderSide(color: AppColors.line)),
      textStyle: AppText.body(size: 14, weight: FontWeight.w600),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: r(26),
      titleTextStyle: AppText.display(size: 21, spacing: -0.3),
      contentTextStyle: AppText.body(size: 14, color: AppColors.sub, height: 1.45),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.card,
      showDragHandle: true,
      dragHandleColor: AppColors.line,
      dragHandleSize: Size(38, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(size: 13, weight: FontWeight.w600, color: Colors.white),
      actionTextColor: const Color(0xFF7FE0D2),
      shape: r(14),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.line,
        minimumSize: const Size(64, 46),
        shape: r(14),
        textStyle: AppText.body(size: 14, weight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.pillInk, minimumSize: const Size(48, 44), shape: r(12), textStyle: AppText.body(size: 14, weight: FontWeight.w700)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        minimumSize: const Size(64, 46),
        shape: r(14),
        textStyle: AppText.body(size: 14, weight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: field(AppColors.line),
      enabledBorder: field(AppColors.line),
      focusedBorder: field(AppColors.pillInk, 1.6),
      hintStyle: AppText.body(size: 14, color: AppColors.sub),
      helperStyle: AppText.body(size: 12, color: AppColors.sub),
      counterStyle: AppText.body(size: 11, color: AppColors.sub),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.pill,
        selectedForegroundColor: AppColors.pillInk,
        foregroundColor: AppColors.sub,
        side: const BorderSide(color: AppColors.line),
        textStyle: AppText.body(size: 13, weight: FontWeight.w700),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: AppText.body(size: 12, weight: FontWeight.w600, color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.pillInk),
  );
}
