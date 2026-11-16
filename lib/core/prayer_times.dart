import 'package:adhan/adhan.dart' as adhan;

import '../data/models.dart';

/// Calculation methods offered in onboarding. Keys are stored in Firestore.
const calcMethods = <String, String>{
  'karachi': 'University of Karachi',
  'muslim_world_league': 'Muslim World League',
  'egyptian': 'Egyptian General Authority',
  'umm_al_qura': 'Umm al-Qura (Makkah)',
  'north_america': 'ISNA (North America)',
  'dubai': 'Dubai',
  'kuwait': 'Kuwait',
  'qatar': 'Qatar',
  'singapore': 'Singapore / Malaysia / Indonesia',
  'turkey': 'Diyanet (Turkey)',
  'moon_sighting_committee': 'Moonsighting Committee',
};

/// Suggest a method from a 2-letter country code (device locale).
String suggestMethod(String? country) {
  switch ((country ?? '').toUpperCase()) {
    case 'BD' || 'PK' || 'IN' || 'AF':
      return 'karachi';
    case 'SA' || 'YE':
      return 'umm_al_qura';
    case 'EG' || 'SD' || 'LY' || 'SY' || 'LB' || 'IQ' || 'JO':
      return 'egyptian';
    case 'US' || 'CA':
      return 'north_america';
    case 'AE':
      return 'dubai';
    case 'KW':
      return 'kuwait';
    case 'QA':
      return 'qatar';
    case 'SG' || 'MY' || 'ID' || 'BN':
      return 'singapore';
    case 'TR':
      return 'turkey';
    case 'GB':
      return 'moon_sighting_committee';
    default:
      return 'muslim_world_league';
  }
}

/// Hanafi Asr is the default in South Asia and Turkey.
String suggestAsr(String? country) =>
    const {'BD', 'PK', 'IN', 'AF', 'TR'}.contains((country ?? '').toUpperCase()) ? 'hanafi' : 'shafi';

/// Today's five prayer start times in the device's local timezone.
Map<Prayer, DateTime> prayerTimesFor({
  required double lat,
  required double lng,
  required String method,
  required String asr,
  DateTime? date,
}) {
  final m = adhan.CalculationMethod.values.firstWhere((e) => e.name == method, orElse: () => adhan.CalculationMethod.muslim_world_league);
  final params = m.getParameters()..madhab = asr == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
  final d = date ?? DateTime.now();
  final t = adhan.PrayerTimes(adhan.Coordinates(lat, lng), adhan.DateComponents(d.year, d.month, d.day), params);
  return {
    Prayer.fajr: t.fajr.toLocal(),
    Prayer.dhuhr: t.dhuhr.toLocal(),
    Prayer.asr: t.asr.toLocal(),
    Prayer.maghrib: t.maghrib.toLocal(),
    Prayer.isha: t.isha.toLocal(),
  };
}

/// The next prayer from [now]: later today, or tomorrow's Fajr after Isha.
({Prayer prayer, DateTime at, bool tomorrow}) nextPrayerAfter({
  required double lat,
  required double lng,
  required String method,
  required String asr,
  required DateTime now,
}) {
  final today = prayerTimesFor(lat: lat, lng: lng, method: method, asr: asr, date: now);
  for (final p in Prayer.values) {
    if (now.isBefore(today[p]!)) return (prayer: p, at: today[p]!, tomorrow: false);
  }
  final t = prayerTimesFor(lat: lat, lng: lng, method: method, asr: asr, date: now.add(const Duration(days: 1)));
  return (prayer: Prayer.fajr, at: t[Prayer.fajr]!, tomorrow: true);
}

/// "in 1h 12m", "in 9m" or "now".
String countdownLabel(Duration d) {
  final m = d.inMinutes;
  if (m < 1) return 'now';
  if (m < 60) return 'in ${m}m';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? 'in ${h}h' : 'in ${h}h ${r}m';
}

/// Fallback cities for manual selection when location permission is denied.
class City {
  const City(this.name, this.country, this.lat, this.lng);
  final String name, country;
  final double lat, lng;
}

const cities = <City>[
  City('Dhaka', 'BD', 23.8103, 90.4125),
  City('Chattogram', 'BD', 22.3569, 91.7832),
  City('Sylhet', 'BD', 24.8949, 91.8687),
  City('Rajshahi', 'BD', 24.3745, 88.6042),
  City('Khulna', 'BD', 22.8456, 89.5403),
  City('Karachi', 'PK', 24.8607, 67.0011),
  City('Lahore', 'PK', 31.5204, 74.3587),
  City('Islamabad', 'PK', 33.6844, 73.0479),
  City('Delhi', 'IN', 28.6139, 77.2090),
  City('Mumbai', 'IN', 19.0760, 72.8777),
  City('Hyderabad', 'IN', 17.3850, 78.4867),
  City('Kolkata', 'IN', 22.5726, 88.3639),
  City('Jakarta', 'ID', -6.2088, 106.8456),
  City('Kuala Lumpur', 'MY', 3.1390, 101.6869),
  City('Singapore', 'SG', 1.3521, 103.8198),
  City('Istanbul', 'TR', 41.0082, 28.9784),
  City('Cairo', 'EG', 30.0444, 31.2357),
  City('Makkah', 'SA', 21.3891, 39.8579),
  City('Madinah', 'SA', 24.5247, 39.5692),
  City('Riyadh', 'SA', 24.7136, 46.6753),
  City('Dubai', 'AE', 25.2048, 55.2708),
  City('Doha', 'QA', 25.2854, 51.5310),
  City('Kuwait City', 'KW', 29.3759, 47.9774),
  City('Lagos', 'NG', 6.5244, 3.3792),
  City('Kano', 'NG', 12.0022, 8.5920),
  City('London', 'GB', 51.5072, -0.1276),
  City('Birmingham', 'GB', 52.4862, -1.8904),
  City('Manchester', 'GB', 53.4808, -2.2426),
  City('New York', 'US', 40.7128, -74.0060),
  City('Chicago', 'US', 41.8781, -87.6298),
  City('Houston', 'US', 29.7604, -95.3698),
  City('Toronto', 'CA', 43.6532, -79.3832),
  City('Sydney', 'AU', -33.8688, 151.2093),
  City('Paris', 'FR', 48.8566, 2.3522),
  City('Berlin', 'DE', 52.5200, 13.4050),
];
