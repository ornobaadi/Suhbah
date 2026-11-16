import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suhbah/core/member_colors.dart';
import 'package:suhbah/core/prayer_times.dart';
import 'package:suhbah/data/models.dart';

void main() {
  const me = DayLog(prayed: {Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib}, ayat: 10, istighfar: 100);
  const partner = DayLog(prayed: {Prayer.dhuhr, Prayer.asr, Prayer.maghrib}, ayat: 6, istighfar: 40);

  test('together percent follows 5 prayers + 10 ayat + 100 istighfar', () {
    expect(me.score, closeTo(6 / 7, 1e-9));
    expect(partner.score, closeTo(4 / 7, 1e-9));
    expect((togetherScoreOf(me, partner) * 100).round(), 71);
  });

  test('solo uses only my score', () {
    expect(togetherScoreOf(me, null), me.score);
  });

  test('day log round-trips through a Firestore map', () {
    final back = DayLog.fromMap(me.toMap());
    expect(back.prayed, me.prayed);
    expect(back.ayat, 10);
    expect(back.istighfar, 100);
    expect(DayLog.fromMap(null).score, 0);
  });

  test('streak counts consecutive days at 60% or more', () {
    final today = DateTime(2026, 11, 15);
    final hist = {
      dayKey(today): DayLog.empty, // today not done yet: doesn't break the streak
      dayKey(DateTime(2026, 11, 14)): me,
      dayKey(DateTime(2026, 11, 13)): me,
      dayKey(DateTime(2026, 11, 12)): DayLog.empty,
    };
    expect(streakFrom(hist, null, today), 2);
  });

  test('same colors get a distinct fallback for the partner', () {
    const teal = Color(0xFF0B7D5E);
    expect(displayPartnerColor(teal, const Color(0xFFC7224F)), const Color(0xFFC7224F));
    final shown = displayPartnerColor(teal, teal);
    expect(isTooSimilar(teal, shown), isFalse);
  });

  test('prayer times for Dhaka are in the right order and range', () {
    final t = prayerTimesFor(lat: 23.8103, lng: 90.4125, method: 'karachi', asr: 'hanafi', date: DateTime(2026, 11, 15));
    final list = Prayer.values.map((p) => t[p]!).toList();
    for (var i = 1; i < list.length; i++) {
      expect(list[i].isAfter(list[i - 1]), isTrue);
    }
    // Dhaka, mid-November: Fajr ~04:50, Maghrib ~17:15 local (UTC+6)
    final fajrUtc = t[Prayer.fajr]!.toUtc();
    final maghribUtc = t[Prayer.maghrib]!.toUtc();
    expect(fajrUtc.hour * 60 + fajrUtc.minute, inInclusiveRange(22 * 60 + 35, 23 * 60 + 5)); // previous day UTC
    expect(maghribUtc.hour * 60 + maghribUtc.minute, inInclusiveRange(11 * 60, 11 * 60 + 25));
  });
}
