import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A member color with a name people remember.
@immutable
class MemberColor {
  const MemberColor(this.name, this.color, [this.note = '']);
  final String name;
  final Color color;

  /// One short line shown when the color is picked in onboarding.
  final String note;
}

/// Suggestion palette: deep, mineral and spice tones from the Muslim world
/// (tilework, stones, spices). Every pair stays easy to tell apart on the arc.
/// Emerald and Pomegranate are the defaults.
const memberColors = <MemberColor>[
  MemberColor('Emerald', Color(0xFF0B7D5E), 'Like the tiles of an old masjid'),
  MemberColor('Pomegranate', Color(0xFFC7224F), 'A fruit of Jannah'),
  MemberColor('Saffron', Color(0xFFE9A21B), 'Warm as the spice markets'),
  MemberColor('Lapis', Color(0xFF2445B8), 'The blue of Samarkand domes'),
  MemberColor('Amethyst', Color(0xFFA040A8), 'Deep and quiet'),
  MemberColor('Turquoise', Color(0xFF3CC2C4), 'Isfahan at noon'),
  MemberColor('Olive', Color(0xFF7F8F2A), 'From a blessed tree'),
  MemberColor('Rosewater', Color(0xFFE58BB0), 'Soft as Damascus roses'),
  MemberColor('Midnight', Color(0xFF1C2A4D), 'The sky at tahajjud'),
  MemberColor('Oud', Color(0xFF743C0A), 'Rich like oud wood'),
  MemberColor('Teal', Color(0xFF0E8C8C), 'The glaze of Iznik tiles'),
  MemberColor('Terracotta', Color(0xFFD2603A), 'The clay walls of the Alhambra'),
  MemberColor('Ajwa', Color(0xFF7A2E6E), 'Dark as the dates of Madinah'),
  MemberColor('Dusk', Color(0xFF6A35C9), 'The sky just after Maghrib'),
  MemberColor('Sidr', Color(0xFF8FB996), 'Leaves of the lote tree'),
];

/// Colors from the first palette, mapped to their replacement in this one so
/// existing people keep the same spot in the grid.
const _legacy = <int, int>{
  0xFF0E9F8E: 0xFF0B7D5E, 0xFFFF355E: 0xFFC7224F, 0xFFF2A20C: 0xFFE9A21B, 0xFF2A55C9: 0xFF2445B8, 0xFF9B4DCA: 0xFFA040A8,
  0xFF8FA33A: 0xFF7F8F2A, 0xFFF08CC0: 0xFFE58BB0, 0xFF4AA8F0: 0xFF3CC2C4, 0xFF182447: 0xFF1C2A4D, 0xFF7A4A2C: 0xFF743C0A,
};

/// A stored color value, upgraded from the old palette when needed.
Color storedColor(int? v) => Color(_legacy[v] ?? v ?? 0xFF0B7D5E);

final memberPalette = [for (final m in memberColors) m.color];

/// The palette entry for a color, or null for a color outside the palette.
MemberColor? memberColorOf(Color c) {
  for (final m in memberColors) {
    if (m.color.toARGB32() == c.toARGB32()) return m;
  }
  return null;
}

/// The palette name for a color, or null for a color outside the palette.
String? colorName(Color c) {
  for (final m in memberColors) {
    if (m.color.toARGB32() == c.toARGB32()) return m.name;
  }
  return null;
}

/// Rough perceptual distance between two colors (redmean formula), 0..~765.
double colorDistance(Color a, Color b) {
  final r1 = a.r * 255, g1 = a.g * 255, b1 = a.b * 255;
  final r2 = b.r * 255, g2 = b.g * 255, b2 = b.b * 255;
  final rm = (r1 + r2) / 2;
  final dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
  return math.sqrt((2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db);
}

/// Colors closer than this look like "the same" on the arc.
const tooSimilar = 150.0;

bool isTooSimilar(Color a, Color b) => colorDistance(a, b) < tooSimilar;

/// The partner's color as shown on *my* screen: their own choice, unless it
/// clashes with mine, then the palette color most different from mine.
Color displayPartnerColor(Color mine, Color partner) {
  if (!isTooSimilar(mine, partner)) return partner;
  return memberPalette.reduce((best, c) => colorDistance(mine, c) > colorDistance(mine, best) ? c : best);
}

int colorToInt(Color c) => c.toARGB32();
