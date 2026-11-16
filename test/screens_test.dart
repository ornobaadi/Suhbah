import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suhbah/core/prayer_times.dart';
import 'package:suhbah/core/theme/app_theme.dart';
import 'package:suhbah/data/models.dart';
import 'package:suhbah/data/today_provider.dart';
import 'package:suhbah/features/home/home_screen.dart';
import 'package:suhbah/features/insights/history_screen.dart';
import 'package:suhbah/features/insights/insights_tab.dart';
import 'package:suhbah/features/me/me_tab.dart';

/// Lays out each tab at a small phone size, solo and paired, at the edges of
/// the data (empty day, over-goal day, long names). Any overflow or paint
/// exception fails the test.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final now = DateTime(2026, 11, 15, 14, 0);
  const meProfile = UserProfile(uid: 'me', nickname: 'Abdurrahman', color: Color(0xFF0B7D5E), pairId: 'ABC234', lat: 23.81, lng: 90.41, city: 'Dhaka', method: 'karachi', asr: 'hanafi', onboarded: true, metPartner: 'p');
  const partnerProfile = UserProfile(uid: 'p', nickname: 'Khadijatul', color: Color(0xFFC7224F), pairId: 'ABC234', onboarded: true);

  TogetherDay dayOf({required bool paired, required DayLog mine, DayLog? theirs, List<Deed> cards = const []}) => TogetherDay(
        deedCards: cards,
        best: 20,
        me: MemberDay.of(meProfile.nickname, meProfile.color, mine),
        partner: paired ? MemberDay.of(partnerProfile.nickname, partnerProfile.color, theirs ?? DayLog.empty) : null,
        yesterdayPct: 40,
        streak: 12,
        prayerTimes: prayerTimesFor(lat: 23.81, lng: 90.41, method: 'karachi', asr: 'hanafi', date: now),
      );

  Future<void> pump(WidgetTester t, Widget tab, {required bool paired, required DayLog mine, DayLog? theirs, List<Deed> cards = const []}) async {
    t.view.physicalSize = const Size(360, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final hist = {dayKey(now.subtract(const Duration(days: 1))): mine, dayKey(now.subtract(const Duration(days: 3))): mine};
    await t.pumpWidget(ProviderScope(
      overrides: [
        todayProvider.overrideWithValue(dayOf(paired: paired, mine: mine, theirs: theirs, cards: cards)),
        myProfileProvider.overrideWith((ref) => Stream.value(paired ? meProfile : const UserProfile(uid: 'me', nickname: 'Abdurrahman', color: Color(0xFF0B7D5E), city: 'Dhaka', lat: 23.81, lng: 90.41, onboarded: true))),
        partnerProfileProvider.overrideWith((ref) => Stream.value(paired ? partnerProfile : null)),
        authUserProvider.overrideWith((ref) => Stream.value(null)),
        clockProvider.overrideWith((ref) => Stream.value(now)),
        historyProvider.overrideWith((ref, uid) => Stream.value(hist)),
        monthProvider.overrideWith((ref, key) => Stream.value(hist)),
      ],
      child: MaterialApp(theme: buildTheme(), home: tab is HomeScreen ? tab : Scaffold(body: tab)),
    ));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    // scroll to the bottom so every section is laid out
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await t.drag(list, const Offset(0, -500));
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(t.takeException(), isNull);
  }

  const empty = DayLog.empty;
  const busy = DayLog(prayed: {...Prayer.values}, ayat: 240, istighfar: 1234);


  for (final paired in [false, true]) {
    final who = paired ? 'paired' : 'solo';
    group(who, () {
      testWidgets('Home, no cards, empty day', (t) => pump(t, const HomeScreen(), paired: paired, mine: empty));
      testWidgets('Home, all cards, busy day', (t) => pump(t, const HomeScreen(), paired: paired, mine: busy.copyWithDeeds(Deed.values.toSet()), theirs: busy, cards: Deed.values));
      testWidgets('History, empty month', (t) => pump(t, const HistoryScreen(), paired: paired, mine: empty));
      testWidgets('History, busy month', (t) => pump(t, const HistoryScreen(), paired: paired, mine: busy, theirs: busy));
      testWidgets('Insights, empty history', (t) => pump(t, const InsightsTab(), paired: paired, mine: empty));
      testWidgets('Insights, big numbers', (t) => pump(t, const InsightsTab(), paired: paired, mine: busy, theirs: busy));
      testWidgets('Me', (t) => pump(t, const MeTab(), paired: paired, mine: busy));
    });
  }
}

extension on DayLog {
  DayLog copyWithDeeds(Set<Deed> d) => DayLog(prayed: prayed, ayat: ayat, istighfar: istighfar, deeds: d);
}
