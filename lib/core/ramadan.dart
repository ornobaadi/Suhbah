/// Expected Ramadan dates (Umm al-Qura). Local moon sighting can shift them by
/// a day, which is fine here: this only decides when to suggest fasting.
final _ramadan = <(DateTime, DateTime)>[
  (DateTime(2026, 2, 18), DateTime(2026, 3, 19)),
  (DateTime(2027, 2, 8), DateTime(2027, 3, 9)),
  (DateTime(2028, 1, 28), DateTime(2028, 2, 25)),
  (DateTime(2029, 1, 16), DateTime(2029, 2, 13)),
  (DateTime(2030, 1, 6), DateTime(2030, 2, 4)),
];

/// True when [d] falls in Ramadan (inclusive of first and last day).
bool isRamadan(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return _ramadan.any((r) => !day.isBefore(r.$1) && !day.isAfter(r.$2));
}
