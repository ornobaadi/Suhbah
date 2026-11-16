import 'package:flutter/material.dart';

import '../core/member_colors.dart';

enum Prayer { fajr, dhuhr, asr, maghrib, isha }

extension PrayerX on Prayer {
  String get label => const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'][index];
  String get letter => const ['F', 'D', 'A', 'M', 'I'][index];
}

/// Optional good deeds a person can add to their home. Bonus only: they
/// never change the daily 100%.
enum Deed { fasting, sadaqah, dua, family }

extension DeedX on Deed {
  String get title => const ['Fasting', 'Sadaqah', 'Dua for each other', 'Call family & friends'][index];

  /// One word for tight rows like Journey.
  String get shortTitle => const ['Fasting', 'Sadaqah', 'Dua', 'Family'][index];

  /// Short line on the card, e.g. "Gave sadaqah".
  String doneLabel(String? partner) => switch (this) {
        Deed.fasting => 'Fasting today',
        Deed.sadaqah => 'Gave sadaqah',
        Deed.dua => partner == null ? 'Made dua' : 'Made dua for $partner',
        Deed.family => 'Kept in touch',
      };

  /// Why it matters, shown in the add sheet.
  String get reason => const [
        "Fast together and see each other's day. Suggested in Ramadan.",
        'Any amount, any kindness. Charity does not decrease wealth.',
        'A dua made for someone in their absence is answered, and an angel says: and for you the same.',
        'Keeping ties of kinship brings blessing in life and provision.',
      ][index];

  /// Dua for each other only makes sense with a partner.
  bool get pairedOnly => this == Deed.dua;
}

/// done = prayed, open = due or passed but not logged (shown pale), upcoming = not yet due.
enum PrayerStatus { done, open, upcoming }

/// Daily goals that make up a person's 100%.
abstract final class Goals {
  static const ayat = 10;
  static const istighfar = 100;
  static const total = 7; // 5 prayers + Quran + istighfar
  static const streakThreshold = 0.6;
}

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// One person's logged deeds for one day, as stored in Firestore.
@immutable
class DayLog {
  const DayLog({this.prayed = const {}, this.ayat = 0, this.istighfar = 0, this.deeds = const {}});

  final Set<Prayer> prayed;

  /// Bonus deeds ticked that day. Not part of [score].
  final Set<Deed> deeds;
  final int ayat;
  final int istighfar;

  static const empty = DayLog();

  double get score {
    final q = (ayat / Goals.ayat).clamp(0.0, 1.0);
    final i = (istighfar / Goals.istighfar).clamp(0.0, 1.0);
    return (prayed.length + q + i) / Goals.total;
  }

  Map<String, dynamic> toMap() => {
        'prayed': [for (final p in Prayer.values) if (prayed.contains(p)) p.name],
        'ayat': ayat,
        'istighfar': istighfar,
        'deeds': [for (final d in Deed.values) if (deeds.contains(d)) d.name],
      };

  factory DayLog.fromMap(Map<String, dynamic>? m) {
    if (m == null) return empty;
    final names = (m['prayed'] as List?)?.cast<String>() ?? const [];
    final deedNames = (m['deeds'] as List?)?.cast<String>() ?? const [];
    return DayLog(
      deeds: {for (final d in Deed.values) if (deedNames.contains(d.name)) d},
      prayed: {for (final p in Prayer.values) if (names.contains(p.name)) p},
      ayat: (m['ayat'] as num?)?.toInt() ?? 0,
      istighfar: (m['istighfar'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.color,
    this.pairId,
    this.lat,
    this.lng,
    this.city,
    this.method = 'muslim_world_league',
    this.asr = 'shafi',
    this.onboarded = false,
    this.deedCards = const [],
    this.ramadanHidden,
    this.metPartner,
  });

  /// uid of the partner whose arrival this person has already celebrated.
  final String? metPartner;

  /// Year the Ramadan fasting suggestion was dismissed.
  final int? ramadanHidden;

  final bool onboarded;

  /// Bonus deed cards this person added to their home, in their order.
  final List<Deed> deedCards;
  final String uid;
  final String nickname;
  final Color color;
  final String? pairId;
  final double? lat, lng;
  final String? city;
  final String method;
  final String asr;

  bool get hasLocation => lat != null && lng != null;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) => UserProfile(
        uid: uid,
        nickname: (m['nickname'] as String?) ?? '',
        color: storedColor((m['color'] as num?)?.toInt()),
        pairId: m['pairId'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        city: m['city'] as String?,
        method: (m['method'] as String?) ?? 'muslim_world_league',
        asr: (m['asr'] as String?) ?? 'shafi',
        onboarded: (m['onboarded'] as bool?) ?? false,
        ramadanHidden: (m['ramadanHidden'] as num?)?.toInt(),
        metPartner: m['metPartner'] as String?,
        deedCards: [
          for (final n in (m['deedCards'] as List?)?.cast<String>() ?? const <String>[]) ...Deed.values.where((d) => d.name == n),
        ],
      );
}

/// A member as shown on the home screen: who they are plus today's log.
@immutable
class MemberDay {
  const MemberDay({required this.name, required this.color, required this.prayed, this.ayat = 0, this.istighfar = 0, this.deeds = const {}});

  factory MemberDay.of(String name, Color color, DayLog d) =>
      MemberDay(name: name, color: color, prayed: d.prayed, ayat: d.ayat, istighfar: d.istighfar, deeds: d.deeds);

  final Set<Deed> deeds;

  final String name;
  final Color color;
  final Set<Prayer> prayed;
  final int ayat;
  final int istighfar;

  double get score => DayLog(prayed: prayed, ayat: ayat, istighfar: istighfar).score;
}

@immutable
class TogetherDay {
  const TogetherDay({
    required this.me,
    this.partner,
    required this.yesterdayPct,
    required this.streak,
    required this.prayerTimes,
    this.deedCards = const [],
    this.best = 0,
  });

  /// Bonus cards shown on my home (Dua only while paired).
  final List<Deed> deedCards;

  /// Best streak in the loaded history.
  final int best;

  final MemberDay me;

  /// Null when solo.
  final MemberDay? partner;
  final int yesterdayPct;
  final int streak;

  /// Start time of each prayer today. Empty until the user's location is known.
  final Map<Prayer, DateTime> prayerTimes;

  bool get solo => partner == null;

  double get togetherScore => partner == null ? me.score : (me.score + partner!.score) / 2;

  int get togetherPct => (togetherScore * 100).round();

  PrayerStatus statusOf(MemberDay m, Prayer p, DateTime now) {
    if (m.prayed.contains(p)) return PrayerStatus.done;
    final t = prayerTimes[p];
    if (t != null && now.isBefore(t)) return PrayerStatus.upcoming;
    return PrayerStatus.open;
  }

  /// First prayer whose time hasn't come yet, or null after Isha.
  Prayer? nextPrayer(DateTime now) {
    for (final p in Prayer.values) {
      final t = prayerTimes[p];
      if (t != null && now.isBefore(t)) return p;
    }
    return null;
  }
}

/// Together score for a day from both people's logs (or just mine when solo).
double togetherScoreOf(DayLog mine, DayLog? partner) => partner == null ? mine.score : (mine.score + partner.score) / 2;

/// Consecutive days, ending yesterday (or today if already over the bar), at or above the threshold.
int streakFrom(Map<String, DayLog> mine, Map<String, DayLog>? partner, DateTime today) {
  var streak = 0;
  final todayScore = togetherScoreOf(mine[dayKey(today)] ?? DayLog.empty, partner == null ? null : partner[dayKey(today)] ?? DayLog.empty);
  if (todayScore >= Goals.streakThreshold) streak++;
  for (var i = 1; i <= 365; i++) {
    final k = dayKey(today.subtract(Duration(days: i)));
    final s = togetherScoreOf(mine[k] ?? DayLog.empty, partner == null ? null : partner[k] ?? DayLog.empty);
    if (s < Goals.streakThreshold) break;
    streak++;
  }
  return streak;
}

/// Longest run of days at or above the streak threshold. [scores] oldest first.
int bestStreakOf(Iterable<double> scores) {
  var best = 0, run = 0;
  for (final s in scores) {
    run = s >= Goals.streakThreshold ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

/// Limits a counter change so the count never drops below zero.
int clampDelta(int current, int delta) => current + delta < 0 ? -current : delta;

/// Next istighfar tap: 33, 33, then 34 so the day lands exactly on 100.
/// Past the goal it keeps adding 33.
/// How much the undo button takes back: the last tap's worth.
int ayatUndo(int count) {
  if (count <= 0) return 0;
  final r = count % ayatStep;
  return r == 0 ? ayatStep : r;
}

/// Undo for istighfar walks back through 100, 66, 33, then 33 at a time.
int istighfarUndo(int count) {
  if (count <= 0) return 0;
  if (count <= Goals.istighfar) {
    final prev = [66, 33, 0].firstWhere((m) => m < count);
    return count - prev;
  }
  final r = (count - Goals.istighfar) % 33;
  return r == 0 ? 33 : r;
}

int istighfarStep(int count) {
  if (count >= Goals.istighfar) return 33;
  final left = Goals.istighfar - count;
  return left <= 34 ? left : 33;
}

/// Ayat added per tap on the Quran card.
const ayatStep = 5;
