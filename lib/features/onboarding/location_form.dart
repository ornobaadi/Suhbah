import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/prayer_times.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';

/// Where the user prays and how times are calculated.
@immutable
class LocationChoice {
  const LocationChoice({this.lat, this.lng, this.city, required this.method, required this.asr});
  final double? lat, lng;
  final String? city;
  final String method, asr;

  bool get complete => lat != null && lng != null;

  LocationChoice copyWith({double? lat, double? lng, String? city, String? method, String? asr}) =>
      LocationChoice(lat: lat ?? this.lat, lng: lng ?? this.lng, city: city ?? this.city, method: method ?? this.method, asr: asr ?? this.asr);

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'city': city, 'method': method, 'asr': asr};
}

/// "Use my location" or city search, calculation method, Asr school and a
/// live preview of today's times. Used in onboarding and in settings.
class LocationForm extends StatefulWidget {
  const LocationForm({super.key, required this.value, required this.onChanged, this.showAdvanced = true});
  final LocationChoice value;

  /// Method and Asr pickers. Onboarding hides them and uses the suggestions.
  final bool showAdvanced;
  final ValueChanged<LocationChoice> onChanged;

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  bool _busy = false;
  String? _error;

  LocationChoice get v => widget.value;

  Future<void> _useMyLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _error = 'Location is off for Suhbah. Search your city instead.';
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      // ~1km precision: enough for prayer times, avoids storing an exact location
      widget.onChanged(
        v.copyWith(lat: double.parse(pos.latitude.toStringAsFixed(2)), lng: double.parse(pos.longitude.toStringAsFixed(2)), city: 'My location'),
      );
    } catch (_) {
      _error = "Couldn't get your location. Search your city instead.";
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pickCity(City c) {
    setState(() => _error = null);
    widget.onChanged(LocationChoice(lat: c.lat, lng: c.lng, city: c.name, method: suggestMethod(c.country), asr: suggestAsr(c.country)));
  }

  @override
  Widget build(BuildContext context) {
    final usingGps = v.city == 'My location';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _useMyLocation,
          icon: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(usingGps ? Icons.check_circle_rounded : Icons.my_location_rounded, color: usingGps ? AppColors.pillInk : null),
          label: Text(usingGps ? 'Using my location' : 'Use my location'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: usingGps ? AppColors.pill : AppColors.card,
            side: BorderSide(color: usingGps ? AppColors.pillInk.withValues(alpha: .4) : AppColors.line),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: AppText.body(size: 12, color: AppColors.sub)),
          ),
        const SizedBox(height: 12),
        Autocomplete<City>(
          displayStringForOption: (c) => c.name,
          optionsBuilder: (t) =>
              t.text.isEmpty ? const Iterable<City>.empty() : cities.where((c) => c.name.toLowerCase().startsWith(t.text.toLowerCase())),
          onSelected: _pickCity,
          // tap region keeps the field focused so a tap on an option isn't swallowed
          optionsViewBuilder: (context, onSelect, options) => TextFieldTapRegion(
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppColors.card,
                elevation: 10,
                shadowColor: AppColors.shadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    children: [
                      for (final c in options)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.sub),
                          title: Text(c.name, style: AppText.body(size: 14, weight: FontWeight.w600)),
                          trailing: Text(c.country, style: AppText.label(size: 10)),
                          onTap: () => onSelect(c),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          fieldViewBuilder: (context, ctrl, focus, onSubmit) => TextField(
            controller: ctrl,
            focusNode: focus,
            decoration: const InputDecoration(hintText: 'Or search your city', prefixIcon: Icon(Icons.search_rounded)),
          ),
        ),
        if (v.city != null && !usingGps)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.pillInk),
                const SizedBox(width: 6),
                Text(
                  v.city!,
                  style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.pillInk),
                ),
              ],
            ),
          ),
        if (widget.showAdvanced) ...[
          const SizedBox(height: 22),
          Text(
            'Calculation method',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.sub),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: v.method,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            dropdownColor: AppColors.card,
            icon: const Icon(Icons.expand_more_rounded),
            style: AppText.body(size: 14, weight: FontWeight.w600),
            items: [for (final e in calcMethods.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (m) => widget.onChanged(v.copyWith(method: m)),
          ),
          const SizedBox(height: 16),
          Text(
            'Asr time',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.sub),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'shafi', label: Text('Standard')),
              ButtonSegment(value: 'hanafi', label: Text('Hanafi')),
            ],
            selected: {v.asr},
            onSelectionChanged: (s) => widget.onChanged(v.copyWith(asr: s.first)),
          ),
          const SizedBox(height: 4),
          Text("Standard is Shafi'i, Maliki and Hanbali.", style: AppText.body(size: 11, color: AppColors.sub)),
        ],
        const SizedBox(height: 22),
        Text(v.complete ? 'YOUR PRAYER TIMES TODAY' : 'YOUR TIMES WILL APPEAR HERE', style: AppText.label(size: 10.5, spacing: 1.5)),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: TimesPreview(key: ValueKey('${v.lat}${v.lng}${v.method}${v.asr}'), lat: v.lat, lng: v.lng, method: v.method, asr: v.asr),
        ),
        if (v.complete && !widget.showAdvanced) ...[
          const SizedBox(height: 10),
          Text(
            '${calcMethods[v.method] ?? v.method} · ${v.asr == 'hanafi' ? 'Hanafi' : 'Standard'} Asr. You can change this anytime in Me.',
            style: AppText.body(size: 11.5, color: AppColors.sub, height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// Today's five times as arch-topped waqt tiles. Without a location they show
/// as pale placeholders so people can see what they are about to get.
class TimesPreview extends StatelessWidget {
  const TimesPreview({super.key, required this.lat, required this.lng, required this.method, required this.asr, this.highlight});
  final double? lat, lng;
  final String method, asr;
  final Prayer? highlight;

  @override
  Widget build(BuildContext context) {
    final t = lat == null || lng == null ? null : prayerTimesFor(lat: lat!, lng: lng!, method: method, asr: asr);
    return Row(
      children: [
        for (final p in Prayer.values) ...[
          if (p != Prayer.fajr) const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: p == highlight ? AppColors.memberA : (t == null ? AppColors.bg : AppColors.card),
                border: Border.all(color: p == highlight ? AppColors.memberA : AppColors.line),
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
                    p.label,
                    style: AppText.body(size: 10.5, weight: FontWeight.w600, color: p == highlight ? Colors.white : AppColors.sub),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    child: Text(
                      t == null ? '--:--' : TimeOfDay.fromDateTime(t[p]!).format(context).replaceAll(' AM', '').replaceAll(' PM', ''),
                      style: AppText.display(size: 16, color: p == highlight ? Colors.white : (t == null ? AppColors.line : AppColors.ink)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
