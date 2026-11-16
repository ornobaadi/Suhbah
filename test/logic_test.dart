import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suhbah/features/onboarding/pair_screen.dart' show codeFromScan;
import 'package:google_fonts/google_fonts.dart';
import 'package:suhbah/core/member_colors.dart';
import 'package:suhbah/core/prayer_times.dart';
import 'package:suhbah/data/models.dart';
import 'package:suhbah/data/today_provider.dart';
import 'package:suhbah/core/ramadan.dart';
import 'package:suhbah/core/reminders.dart';
import 'package:suhbah/data/insights.dart';
import 'package:suhbah/features/home/widgets/streak_strip.dart';
import 'package:suhbah/features/onboarding/location_form.dart';
import 'package:suhbah/features/onboarding/widgets.dart';

void main() {
  // no network in tests: fonts fall back to the default
  GoogleFonts.config.allowRuntimeFetching = false;

  group('scoring edges', () {
    test('ayat and istighfar cap at their goal, prayers count once', () {
      const over = DayLog(prayed: {Prayer.fajr}, ayat: 50, istighfar: 1000);
      expect(over.score, closeTo(3 / 7, 1e-9));
      const full = DayLog(prayed: {...Prayer.values}, ayat: 10, istighfar: 100);
      expect(full.score, 1.0);
    });

    test('a broken Firestore doc reads as empty, not a crash', () {
      final d = DayLog.fromMap({'prayed': ['fajr', 'bogus'], 'ayat': 2.0});
      expect(d.prayed, {Prayer.fajr});
      expect(d.ayat, 2);
      expect(d.istighfar, 0);
    });

    test('together needs both people at 100% for a full day', () {
      const full = DayLog(prayed: {...Prayer.values}, ayat: 10, istighfar: 100);
      expect(togetherScoreOf(full, DayLog.empty), .5);
      expect(togetherScoreOf(full, full), 1.0);
    });
  });

  group('streaks', () {
    test('best streak finds the longest run', () {
      expect(bestStreakOf([.7, .7, .1, .9, .9, .9, .2]), 3);
      expect(bestStreakOf([]), 0);
      expect(bestStreakOf([.6]), 1); // threshold is inclusive
      expect(bestStreakOf([.59]), 0);
    });

    test('a missed day in a pair breaks the together streak', () {
      final today = DateTime(2026, 11, 15);
      const good = DayLog(prayed: {...Prayer.values});
      final mine = {dayKey(DateTime(2026, 11, 14)): good, dayKey(DateTime(2026, 11, 13)): good};
      final theirs = {dayKey(DateTime(2026, 11, 14)): good}; // partner skipped the 13th
      expect(streakFrom(mine, null, today), 2);
      expect(streakFrom(mine, theirs, today), 1);
    });

    test('streak counts across a month boundary', () {
      const good = DayLog(prayed: {...Prayer.values});
      final hist = {dayKey(DateTime(2026, 11, 1)): good, dayKey(DateTime(2026, 10, 31)): good, dayKey(DateTime(2026, 10, 30)): good};
      expect(streakFrom(hist, null, DateTime(2026, 11, 2)), 3);
    });
  });

  group('tap steps', () {
    test('istighfar goes 33, 66, 100 and never stops at 99', () {
      var c = 0;
      final seen = <int>[];
      for (var i = 0; i < 3; i++) {
        c += istighfarStep(c);
        seen.add(c);
      }
      expect(seen, [33, 66, 100]);
      expect(istighfarStep(99), 1);
      expect(istighfarStep(50), 33);
      expect(istighfarStep(83), 17);
      expect(istighfarStep(100), 33); // past the goal keeps counting in 33s
    });

    test('quran adds 5 ayat a tap', () => expect(ayatStep, 5));
  });

  group('worth knowing', () {
    final dates = [for (var i = 0; i < 30; i++) DateTime(2026, 10, 18).add(Duration(days: i))];
    const fajrOnly = DayLog(prayed: {Prayer.fajr, Prayer.dhuhr});
    const dhuhrOnly = DayLog(prayed: {Prayer.dhuhr});

    test('says nothing with too little data', () {
      final mine = [for (var i = 0; i < 30; i++) i < 2 ? fajrOnly : DayLog.empty];
      expect(worthKnowing(mine: mine, dates: dates), isEmpty);
    });

    test('counts only prayers both kept when paired', () {
      final mine = List.filled(30, fajrOnly);
      final theirs = List.filled(30, dhuhrOnly);
      final kept = keptCounts(mine, theirs);
      expect(kept[Prayer.fajr], 0);
      expect(kept[Prayer.dhuhr], 30);
      final notes = worthKnowing(mine: mine, theirs: theirs, dates: dates);
      expect(notes.first, 'You both prayed Dhuhr on 30 of the last 30 days.');
      expect(notes.length, lessThanOrEqualTo(3));
      for (final n in notes) {
        expect(n.toLowerCase(), isNot(contains('miss')));
      }
    });

    test('names the fullest weekday once there are two weeks of data', () {
      final mine = [for (final d in dates) d.weekday == DateTime.thursday ? const DayLog(prayed: {...Prayer.values}, ayat: 10, istighfar: 100) : fajrOnly];
      final notes = worthKnowing(mine: mine, dates: dates);
      expect(notes.any((n) => n.startsWith('Thursdays are your fullest day, 100%')), isTrue);
    });
  });

  group('palette', () {
    test('every color has a unique name and no two swatches look alike', () {
      expect(memberColors.map((m) => m.name).toSet().length, memberColors.length);
      for (var i = 0; i < memberPalette.length; i++) {
        for (var j = i + 1; j < memberPalette.length; j++) {
          // Swatches must be told apart (partners are kept further apart by isTooSimilar).
          expect(colorDistance(memberPalette[i], memberPalette[j]), greaterThan(80), reason: '${memberColors[i].name} vs ${memberColors[j].name}');
        }
      }
      expect(colorName(const Color(0xFFE9A21B)), 'Saffron');
      expect(storedColor(0xFFF2A20C), const Color(0xFFE9A21B)); // old palette upgrades
      expect(storedColor(null), memberPalette.first);
      expect(colorName(const Color(0xFF123456)), isNull);
    });
  });

  group('home', () {
    test('bonus deeds round-trip and never change the score', () {
      const d = DayLog(prayed: {Prayer.fajr}, ayat: 5, deeds: {Deed.sadaqah, Deed.family});
      final back = DayLog.fromMap(d.toMap());
      expect(back.deeds, {Deed.sadaqah, Deed.family});
      expect(back.score, const DayLog(prayed: {Prayer.fajr}, ayat: 5).score);
      expect(DayLog.fromMap({'deeds': ['nonsense', 'fasting']}).deeds, {Deed.fasting});
    });

    test('deed cards keep their order and skip unknown names', () {
      final p = UserProfile.fromMap('u', {'deedCards': ['family', 'bogus', 'sadaqah']});
      expect(p.deedCards, [Deed.family, Deed.sadaqah]);
      expect(Deed.dua.pairedOnly, isTrue);
      expect(Deed.dua.doneLabel('Rafeed'), 'Made dua for Rafeed');
    });

    test('Ramadan edges', () {
      expect(isRamadan(DateTime(2027, 2, 7)), isFalse);
      expect(isRamadan(DateTime(2027, 2, 8, 23)), isTrue);
      expect(isRamadan(DateTime(2027, 3, 9)), isTrue);
      expect(isRamadan(DateTime(2027, 3, 10)), isFalse);
      expect(isRamadan(DateTime(2026, 11, 16)), isFalse);
    });

    test('reminder is stable for a day and changes the next day', () {
      final a = reminderFor(DateTime(2026, 11, 16, 6));
      expect(reminderFor(DateTime(2026, 11, 16, 23)), a);
      expect(reminderFor(DateTime(2026, 11, 17)), isNot(a));
      for (final r in reminders) {
        expect(r.source, isNotEmpty);
      }
    });

    test("after Isha the next prayer is tomorrow's Fajr", () {
      final late = nextPrayerAfter(lat: 23.81, lng: 90.41, method: 'karachi', asr: 'hanafi', now: DateTime(2026, 11, 16, 23, 30));
      expect(late.prayer, Prayer.fajr);
      expect(late.tomorrow, isTrue);
      expect(late.at.day, 17);
      final noon = nextPrayerAfter(lat: 23.81, lng: 90.41, method: 'karachi', asr: 'hanafi', now: DateTime(2026, 11, 16, 13));
      expect(noon.prayer, Prayer.asr);
      expect(noon.tomorrow, isFalse);
    });

    test('countdown and streak copy', () {
      expect(countdownLabel(const Duration(minutes: 72)), 'in 1h 12m');
      expect(countdownLabel(const Duration(minutes: 9)), 'in 9m');
      expect(countdownLabel(const Duration(seconds: 20)), 'now');
      expect(StreakStrip.message(streak: 12, today: .3), 'Reach 60% today to make it 13');
      expect(StreakStrip.message(streak: 13, today: .7), startsWith('Today counts'));
      expect(StreakStrip.message(streak: 0, today: 0), startsWith('Today can be day one'));
    });
  });

  group('undo clamp', () {
    test('never goes below zero', () {
      expect(clampDelta(0, -1), 0);
      expect(clampDelta(5, -1), -1);
      expect(clampDelta(5, -33), -5);
      expect(clampDelta(5, 33), 33);
    });
  });

  group('batched taps', () {
    test('pending counts add up and clear', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(pendingCountsProvider.notifier);
      n.add(istighfar: 1);
      n.add(istighfar: 1);
      n.add(ayat: 5);
      expect(c.read(pendingCountsProvider), (ayat: 5, istighfar: 2));
      n.clear();
      expect(c.read(pendingCountsProvider), (ayat: 0, istighfar: 0));
    });
  });

  group('day keys', () {
    test('zero padded and sortable', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      final keys = [DateTime(2026, 12, 1), DateTime(2026, 2, 28), DateTime(2026, 11, 9)].map(dayKey).toList()..sort();
      expect(keys, ['2026-02-28', '2026-11-09', '2026-12-01']);
    });
  });

  group('location', () {
    test('choice is complete only with coordinates and serializes all fields', () {
      const c = LocationChoice(method: 'karachi', asr: 'hanafi');
      expect(c.complete, isFalse);
      final d = c.copyWith(lat: 23.81, lng: 90.41, city: 'Dhaka');
      expect(d.complete, isTrue);
      expect(d.toMap(), {'lat': 23.81, 'lng': 90.41, 'city': 'Dhaka', 'method': 'karachi', 'asr': 'hanafi'});
      expect(d.copyWith(asr: 'shafi').method, 'karachi');
    });

    test('every offered method computes ordered times', () {
      for (final m in calcMethods.keys) {
        final t = prayerTimesFor(lat: 51.5, lng: -0.12, method: m, asr: 'shafi', date: DateTime(2026, 6, 21));
        final list = Prayer.values.map((p) => t[p]!).toList();
        for (var i = 1; i < list.length; i++) {
          expect(list[i].isAfter(list[i - 1]), isTrue, reason: '$m: ${Prayer.values[i]}');
        }
      }
    });

    test('every listed city has a suggested method that exists', () {
      for (final c in cities) {
        expect(calcMethods.containsKey(suggestMethod(c.country)), isTrue, reason: c.name);
      }
    });

    test('hanafi Asr is later than standard', () {
      final s = prayerTimesFor(lat: 23.81, lng: 90.41, method: 'karachi', asr: 'shafi', date: DateTime(2026, 11, 15));
      final h = prayerTimesFor(lat: 23.81, lng: 90.41, method: 'karachi', asr: 'hanafi', date: DateTime(2026, 11, 15));
      expect(h[Prayer.asr]!.isAfter(s[Prayer.asr]!), isTrue);
    });
  });

  group('colors', () {
    test('fallback partner color is always distinct, for every palette pair', () {
      for (final a in memberPalette) {
        for (final b in memberPalette) {
          expect(isTooSimilar(a, displayPartnerColor(a, b)), isFalse, reason: '$a vs $b');
        }
      }
    });

    test('a joiner can always find a free color', () {
      for (final taken in memberPalette) {
        expect(memberPalette.where((c) => !isTooSimilar(c, taken)), isNotEmpty);
      }
    });
  });

  group('widgets', () {
    testWidgets('a color too close to the partner\'s cannot be picked', (t) async {
      Color? picked;
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: ColorGrid(selected: memberPalette[2], onSelect: (c) => picked = c, takenBy: (memberPalette[0], 'Ayesha'))),
      ));
      expect(find.text('Ayesha'), findsWidgets);
      final swatches = find.byType(GestureDetector);
      await t.tap(swatches.at(0)); // the partner's own color
      expect(picked, isNull);
      await t.tap(swatches.at(1));
      expect(picked, memberPalette[1]);
    });
  });

  test('undo takes back exactly the last tap', () {
    expect(ayatUndo(0), 0);
    expect(ayatUndo(5), 5);
    expect(ayatUndo(12), 2); // after a manual +2
    for (final c in [0, 33, 66, 100, 133, 166]) {
      // tapping then undoing lands back where you were
      expect(c + istighfarStep(c) - istighfarUndo(c + istighfarStep(c)), c, reason: 'from $c');
    }
    expect(istighfarUndo(40), 7);
    expect(istighfarUndo(101), 1);
  });

  group('invite QR', () {
    test('reads the code from the Play link, a bare code, or the invite text', () {
      expect(codeFromScan('https://play.google.com/store/apps/details?id=com.ornobaadi.suhbah&referrer=code%3DXA4F6Q'), 'XA4F6Q');
      expect(codeFromScan(' xa4f6q '), 'XA4F6Q');
      expect(codeFromScan('2. Open it, tap "I have a code" and enter: XA4F6Q'), 'XA4F6Q');
      expect(codeFromScan('https://example.com'), isNull);
    });
  });
}
