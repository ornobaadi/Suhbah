/// One short ayah or hadith a day, the same for everyone on a given date.
/// Every entry carries its source. Founder: review before release.
typedef Reminder = ({String text, String source});

const reminders = <Reminder>[
  (text: 'Indeed, with hardship comes ease.', source: 'Quran 94:6'),
  (text: 'So remember Me; I will remember you.', source: 'Quran 2:152'),
  (text: 'Verily, in the remembrance of Allah do hearts find rest.', source: 'Quran 13:28'),
  (text: 'The most beloved deeds to Allah are those done consistently, even if they are small.', source: 'Sahih al-Bukhari, Sahih Muslim'),
  (text: 'And seek help through patience and prayer.', source: 'Quran 2:45'),
  (text: 'Allah does not burden a soul beyond what it can bear.', source: 'Quran 2:286'),
  (text: 'None of you truly believes until he loves for his brother what he loves for himself.', source: 'Sahih al-Bukhari, Sahih Muslim'),
  (text: 'And He is with you wherever you are.', source: 'Quran 57:4'),
  (text: 'Call upon Me; I will respond to you.', source: 'Quran 40:60'),
  (text: 'A good word is charity.', source: 'Sahih al-Bukhari, Sahih Muslim'),
  (text: 'And cooperate in righteousness and piety.', source: 'Quran 5:2'),
  (text: 'Do not despair of the mercy of Allah.', source: 'Quran 39:53'),
  (text: 'Whoever puts their trust in Allah, He is sufficient for them.', source: 'Quran 65:3'),
  (text: 'Smiling in the face of your brother is charity.', source: "Jami' at-Tirmidhi"),
  (text: 'Ask forgiveness of your Lord. Indeed, He is ever Forgiving.', source: 'Quran 71:10'),
  (text: 'Hold firmly to the rope of Allah, all together, and do not be divided.', source: 'Quran 3:103'),
  (text: 'Indeed, prayer keeps one away from immorality and wrongdoing.', source: 'Quran 29:45'),
  (text: 'And He found you lost and guided you.', source: 'Quran 93:7'),
];

/// Today's reminder, picked by day of the year so everyone sees the same one.
Reminder reminderFor(DateTime d) {
  final dayOfYear = DateTime(d.year, d.month, d.day).difference(DateTime(d.year)).inDays;
  return reminders[(dayOfYear + d.year) % reminders.length];
}
