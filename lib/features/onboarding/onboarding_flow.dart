import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/member_colors.dart';
import '../../core/prayer_times.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui.dart';
import '../../data/today_provider.dart';
import '../home/widgets/together_arc.dart';
import 'location_form.dart';
import 'pair_screen.dart';
import 'widgets.dart';

/// Name → color → location → partner or solo. Saves to Firestore before pairing.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;
  bool _forward = true;
  late final TextEditingController _name;
  Color _color = memberPalette.first;
  late LocationChoice _loc;
  bool _saving = false;

  String get _nick => _name.text.trim();

  @override
  void initState() {
    super.initState();
    final display = ref.read(authUserProvider).value?.displayName ?? '';
    _name = TextEditingController(text: display.trim().split(RegExp(r'\s+')).first);
    final country = ui.PlatformDispatcher.instance.locale.countryCode;
    _loc = LocationChoice(method: suggestMethod(country), asr: suggestAsr(country));
    _restore();
  }

  // Progress is kept on the device, so closing the app mid-way resumes at the same step.
  String get _key => 'onboarding.${ref.read(authUserProvider).value?.uid}';

  Future<void> _restore() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || !mounted) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        if (m['nick'] is String && (m['nick'] as String).isNotEmpty) _name.text = m['nick'] as String;
        if (m['color'] is int) _color = storedColor(m['color'] as int);
        final step = (m['step'] as int? ?? 0).clamp(0, 3);
        // Step 3 needs the saved profile; only resume there if we got that far.
        _step = step;
      });
    } catch (_) {}
  }

  Future<void> _remember() async {
    try {
      (await SharedPreferences.getInstance()).setString(_key, jsonEncode({'step': _step, 'nick': _nick, 'color': _color.toARGB32()}));
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _go(int step) {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
    });
    _remember();
  }

  Future<void> _saveProfile() async {
    final uid = ref.read(authUserProvider).value!.uid;
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveProfile(uid, {'nickname': _nick, 'color': _color.toARGB32(), ..._loc.toMap()});
      if (mounted) _go(3);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_step) {
      0 => _nameStep(),
      1 => _colorStep(),
      2 => _locationStep(),
      _ => PairScreen(onBack: () => _go(2), onboarding: true),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) {
        final incoming = child.key == ValueKey(_step);
        final dx = (incoming == _forward) ? .18 : -.18;
        return FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: page),
    );
  }

  Widget _nameStep() {
    final multi = _nick.contains(' ');
    return StepFrame(
      step: 0,
      eyebrow: 'Step 1 · You',
      title: 'What should\nthey call you?',
      subtitle: 'This is how your partner sees you on the arc.',
      primaryLabel: _nick.isEmpty ? 'Type a name to continue' : "That's me",
      onPrimary: _nick.isEmpty ? null : () => _go(1),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (c, a) => ScaleTransition(
                scale: Tween(begin: .6, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                child: c,
              ),
              child: MemberAvatar(key: ValueKey(_nick.isEmpty ? '?' : _nick.characters.first.toUpperCase()), name: _nick, color: _color, size: 92),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 16,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _nick.isEmpty ? null : _go(1),
            style: AppText.display(size: 26, weight: FontWeight.w800, spacing: -.5),
            decoration: const InputDecoration(hintText: 'Your name', counterText: ''),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            reverseDuration: const Duration(milliseconds: 60),
            child: multi
                ? Center(
                    key: const ValueKey('tip'),
                    child: ActionChip(
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.pillInk),
                      label: Text('Use "${_nick.split(' ').first}"? One word fits best'),
                      labelStyle: AppText.body(size: 12.5, weight: FontWeight.w700, color: AppColors.pillInk),
                      backgroundColor: AppColors.pill,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onPressed: () => setState(() => _name.text = _nick.split(' ').first),
                    ),
                  )
                : Text(
                    _nick.isEmpty ? 'Short and sweet looks best' : 'Assalamu alaikum, $_nick!',
                    key: ValueKey(_nick.isEmpty),
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 13,
                      weight: _nick.isEmpty ? FontWeight.w500 : FontWeight.w700,
                      color: _nick.isEmpty ? AppColors.sub : AppColors.ink,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _colorStep() {
    final mc = memberColorOf(_color);
    final name = mc?.name ?? 'That';
    return StepFrame(
      step: 1,
      eyebrow: 'Step 2 · Your half',
      title: 'Pick the color\nof your half',
      onBack: () => _go(0),
      primaryLabel: '$name it is',
      onPrimary: () => _go(2),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              // re-keyed so the arc fills again with every pick
              child: TogetherArc(
                key: ValueKey(_color.toARGB32()),
                left: 1,
                right: 0,
                colorLeft: _color,
                colorRight: AppColors.line,
                percent: 50,
                label: 'YOUR HALF',
              ),
            ),
          ),
          const SizedBox(height: 18),
          ColorGrid(selected: _color, onSelect: (c) => setState(() => _color = c)),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            reverseDuration: const Duration(milliseconds: 60),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a),
                child: c,
              ),
            ),
            child: Column(
              key: ValueKey(name),
              children: [
                Text(name, style: AppText.display(size: 22, color: _color, spacing: -.4)),
                if (mc != null && mc.note.isNotEmpty) Text(mc.note, style: AppText.body(size: 12.5, color: AppColors.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationStep() {
    return StepFrame(
      step: 2,
      eyebrow: 'Step 3 · Prayer times',
      title: 'Where do you pray?',
      subtitle: 'Your five times are worked out on your phone for where you are. Change the method anytime in Me.',
      onBack: () => _go(1),
      primaryLabel: _loc.complete ? 'Looks right' : 'Set your location to continue',
      busy: _saving,
      onPrimary: _loc.complete ? _saveProfile : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: _loc.complete
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SunPath(
                      key: ValueKey('${_loc.lat}${_loc.lng}'),
                      now: DateTime.now(),
                      times: [for (final t in prayerTimesFor(lat: _loc.lat!, lng: _loc.lng!, method: _loc.method, asr: _loc.asr).values) t],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Expanded(
            child: LocationForm(value: _loc, showAdvanced: false, onChanged: (v) => setState(() => _loc = v)),
          ),
        ],
      ),
    );
  }
}
