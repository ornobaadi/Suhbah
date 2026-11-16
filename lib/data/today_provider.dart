import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/member_colors.dart';
import '../core/prayer_times.dart';
import 'models.dart';
import 'repository.dart';

final repositoryProvider = Provider<Repository>((ref) => Repository());

final authUserProvider = StreamProvider<User?>((ref) => ref.watch(repositoryProvider).authChanges());

/// Ticks every 30s so the next prayer and the day rollover stay current.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

DateTime _now(Ref ref) => ref.watch(clockProvider).value ?? DateTime.now();

final todayKeyProvider = Provider<String>((ref) => dayKey(_now(ref)));

final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(authUserProvider.select((u) => u.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(repositoryProvider).watchProfile(uid);
});

/// Partner's uid, or null when solo or still waiting for them to join.
final partnerUidProvider = StreamProvider<String?>((ref) {
  final me = ref.watch(myProfileProvider).value;
  if (me == null || me.pairId == null) return Stream.value(null);
  return ref.watch(repositoryProvider).watchPairMembers(me.pairId!).map((m) {
    final others = m.where((u) => u != me.uid);
    return others.isEmpty ? null : others.first;
  });
});

final partnerProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(partnerUidProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(repositoryProvider).watchProfile(uid);
});

/// Last 60 days of logs for a user, keyed yyyy-MM-dd.
final historyProvider = StreamProvider.family<Map<String, DayLog>, String>((ref, uid) => ref.watch(repositoryProvider).watchHistory(uid));

/// One month of logs for a user. Key is "uid|yyyy-MM".
final monthProvider = StreamProvider.family<Map<String, DayLog>, String>((ref, key) {
  final [uid, month] = key.split('|');
  return ref.watch(repositoryProvider).watchRange(uid, '$month-01', '$month-31');
});

/// Counter taps not yet written. Taps are batched into one write so a 100-tap
/// istighfar session costs one or two Firestore writes, not a hundred.
class PendingCounts extends Notifier<({int ayat, int istighfar})> {
  @override
  ({int ayat, int istighfar}) build() => (ayat: 0, istighfar: 0);

  void add({int ayat = 0, int istighfar = 0}) => state = (ayat: state.ayat + ayat, istighfar: state.istighfar + istighfar);
  void clear() => state = (ayat: 0, istighfar: 0);
}

final pendingCountsProvider = NotifierProvider<PendingCounts, ({int ayat, int istighfar})>(PendingCounts.new);

/// Everything the home screen shows. Null while loading.
final todayProvider = Provider<TogetherDay?>((ref) {
  final me = ref.watch(myProfileProvider).value;
  if (me == null) return null;
  final now = _now(ref);
  final key = dayKey(now);
  final partner = ref.watch(partnerProfileProvider).value;

  final myHist = ref.watch(historyProvider(me.uid)).value ?? const {};
  final pHist = partner == null ? null : ref.watch(historyProvider(partner.uid)).value ?? const <String, DayLog>{};

  final pending = ref.watch(pendingCountsProvider);
  final saved = myHist[key] ?? DayLog.empty;
  final myDay = DayLog(prayed: saved.prayed, ayat: saved.ayat + pending.ayat, istighfar: saved.istighfar + pending.istighfar, deeds: saved.deeds);
  final pDay = pHist == null ? null : pHist[key] ?? DayLog.empty;
  final yKey = dayKey(now.subtract(const Duration(days: 1)));
  final yesterday = togetherScoreOf(myHist[yKey] ?? DayLog.empty, pHist == null ? null : pHist[yKey] ?? DayLog.empty);

  return TogetherDay(
    me: MemberDay.of(me.nickname, me.color, myDay),
    partner: partner == null ? null : MemberDay.of(partner.nickname, displayPartnerColor(me.color, partner.color), pDay!),
    yesterdayPct: (yesterday * 100).round(),
    streak: streakFrom(myHist, pHist, now),
    prayerTimes: me.hasLocation ? prayerTimesFor(lat: me.lat!, lng: me.lng!, method: me.method, asr: me.asr, date: now) : const {},
    deedCards: [for (final d in me.deedCards) if (!d.pairedOnly || partner != null) d],
    best: bestStreakOf([
      for (var i = 59; i >= 0; i--)
        togetherScoreOf(
          myHist[dayKey(now.subtract(Duration(days: i)))] ?? DayLog.empty,
          pHist == null ? null : pHist[dayKey(now.subtract(Duration(days: i)))] ?? DayLog.empty,
        ),
    ]),
  );
});

/// Actions on today's log. The UI updates from Firestore's local cache instantly.
class TodayActions {
  TodayActions(this.ref);
  final Ref ref;

  Repository get _repo => ref.read(repositoryProvider);
  String? get _uid => ref.read(authUserProvider).value?.uid;
  String get _key => ref.read(todayKeyProvider);

  void toggleDeed(Deed d) {
    final uid = _uid;
    final day = ref.read(todayProvider);
    if (uid == null || day == null) return;
    unawaited(_repo.setDeed(uid, _key, d, !day.me.deeds.contains(d)));
  }

  /// Adds or removes a bonus card on my home.
  void setDeedCard(Deed d, bool on) {
    final uid = _uid;
    final me = ref.read(myProfileProvider).value;
    if (uid == null || me == null) return;
    final cards = [for (final c in me.deedCards) if (c != d) c, if (on) d];
    unawaited(_repo.saveProfile(uid, {'deedCards': [for (final c in cards) c.name]}));
  }

  void togglePrayer(Prayer p) {
    final uid = _uid;
    final day = ref.read(todayProvider);
    if (uid == null || day == null) return;
    unawaited(_repo.setPrayed(uid, _key, p, !day.me.prayed.contains(p)));
  }

  Timer? _flush;

  /// Adds (or with a negative [n], removes) ayat. Never goes below zero.
  void addAyat(int n) => _count(ayat: n);

  void addIstighfar(int n) => _count(istighfar: n);

  void _count({int ayat = 0, int istighfar = 0}) {
    final day = ref.read(todayProvider);
    if (_uid == null || day == null) return;
    ayat = clampDelta(day.me.ayat, ayat);
    istighfar = clampDelta(day.me.istighfar, istighfar);
    if (ayat == 0 && istighfar == 0) return;
    ref.read(pendingCountsProvider.notifier).add(ayat: ayat, istighfar: istighfar);
    _flush?.cancel();
    _flush = Timer(const Duration(milliseconds: 700), flush);
  }

  /// Writes batched taps now. Firestore's cache shows them instantly.
  void flush() {
    _flush?.cancel();
    final uid = _uid;
    final p = ref.read(pendingCountsProvider);
    if (uid == null || (p.ayat == 0 && p.istighfar == 0)) return;
    unawaited(_repo.addCounts(uid, _key, ayat: p.ayat, istighfar: p.istighfar));
    ref.read(pendingCountsProvider.notifier).clear();
  }
}

final todayActionsProvider = Provider<TodayActions>((ref) => TodayActions(ref));
