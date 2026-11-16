import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui.dart';
import '../../data/today_provider.dart';
import '../onboarding/location_form.dart';
import '../onboarding/widgets.dart';

/// Change location, calculation method or Asr school after onboarding.
class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  ConsumerState<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen> {
  late LocationChoice _loc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final me = ref.read(myProfileProvider).value!;
    _loc = LocationChoice(lat: me.lat, lng: me.lng, city: me.city, method: me.method, asr: me.asr);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      await ref.read(repositoryProvider).saveProfile(ref.read(myProfileProvider).value!.uid, _loc.toMap());
      if (mounted) toast(context, 'Prayer times updated');
      nav.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StepFrame(
        title: 'Prayer times',
        subtitle: 'Calculated on your phone for your location and timezone.',
        onBack: () => Navigator.of(context).pop(),
        primaryLabel: 'Save',
        busy: _saving,
        onPrimary: _loc.complete ? _save : null,
        child: LocationForm(value: _loc, onChanged: (v) => setState(() => _loc = v)),
      );
}
