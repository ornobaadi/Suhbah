import 'package:flutter/material.dart';

import 'haptics.dart';

import '../features/home/widgets/star_pattern.dart';
import 'theme/app_theme.dart';

/// White card with the standard 18px radius and hairline border.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

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
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Small uppercase heading above a group ("PROFILE", "THIS WEEK").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 22});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 8),
    child: Text(text.toUpperCase(), style: AppText.label(size: 10.5, spacing: 1.5)),
  );
}

/// Big page title for a tab, with a one-line subtitle.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.display(size: 30, spacing: -0.8)),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.body(size: 13, color: AppColors.sub))],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A card holding rows separated by inset dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 64), children[i]],
      ],
    ),
  );
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, this.value, this.onTap, this.trailing, this.iconColor});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: (iconColor ?? AppColors.pillInk).withValues(alpha: .1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: iconColor ?? AppColors.pillInk),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(size: 14, weight: FontWeight.w600)),
                if (value != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 12, color: AppColors.sub),
                  ),
                ],
              ],
            ),
          ),
          trailing ?? (onTap == null ? const SizedBox.shrink() : const Icon(Icons.chevron_right_rounded, color: AppColors.sub, size: 20)),
        ],
      ),
    ),
  );
}

/// Round avatar in the member's color with their initial.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, required this.color, this.size = 40});
  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: AppText.display(size: size * .42, color: Colors.white, weight: FontWeight.w800),
    ),
  );
}

/// Popup menu row with a leading icon.
PopupMenuItem<String> menuItem(String value, IconData icon, String label) => PopupMenuItem<String>(
  value: value,
  height: 46,
  child: Row(
    children: [
      Icon(icon, size: 19, color: AppColors.sub),
      const SizedBox(width: 12),
      Text(label, style: AppText.body(size: 14, weight: FontWeight.w600)),
    ],
  ),
);

/// Two-button confirm dialog. Returns true when confirmed.
Future<bool> confirmDialog(BuildContext context, {required String title, required String body, required String confirm, String cancel = 'Cancel'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(title),
      content: SizedBox(width: 400, child: Text(body)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(
          onPressed: () {
            Haptics.press();
            Navigator.pop(ctx, true);
          },
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Single text field dialog (nickname etc.). Returns the trimmed text or null.
Future<String?> textDialog(BuildContext context, {required String title, String? initial, String? helper, int maxLength = 16}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.words,
          style: AppText.display(size: 20, weight: FontWeight.w700),
          decoration: InputDecoration(helperText: helper, helperMaxLines: 2),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}

/// Bottom sheet with the app's shape, scrollable, safe-area aware.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, String? subtitle, required Widget child}) {
  Haptics.tick();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.display(size: 21, spacing: -0.3)),
            if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: AppText.body(size: 13, color: AppColors.sub))],
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    ),
  );
}

void toast(BuildContext context, String message) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
}

/// A tab's scrolling page. The star pattern is part of the page, so it sits
/// behind the top bar and scrolls away with it instead of floating over cards.
class PatternPage extends StatelessWidget {
  const PatternPage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Stack(
        children: [
          const StarPatternBackground(height: 70),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 10, 16, 0),
            // sections rise in one after another the first time the page shows
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = 0; i < children.length; i++) Entrance(order: i < 8 ? i : 8, child: children[i])],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a child in shortly after it appears, staggered by [order].
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + order * 90),
      curve: Interval(order * .12 > .8 ? .8 : order * .12, 1, curve: Curves.easeOutCubic),
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}
