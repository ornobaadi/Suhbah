import 'models.dart';

/// Days a prayer was prayed, per prayer. With a partner, only days both prayed it.
Map<Prayer, int> keptCounts(List<DayLog> mine, List<DayLog>? theirs) => {
      for (final p in Prayer.values)
        p: [
          for (var i = 0; i < mine.length; i++)
            if (mine[i].prayed.contains(p) && (theirs == null || theirs[i].prayed.contains(p))) 1,
        ].length,
    };

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Up to three plain sentences about the period, only when there is enough
/// data for them to be true and useful. Never phrased as a failure.
/// [mine], [theirs] and [dates] are aligned, oldest first.
List<String> worthKnowing({required List<DayLog> mine, List<DayLog>? theirs, required List<DateTime> dates}) {
  final paired = theirs != null;
  final n = mine.length;
  final active = [for (var i = 0; i < n; i++) if (mine[i].score > 0 || (theirs?[i].score ?? 0) > 0) i].length;
  if (active < 3) return const [];

  final out = <String>[];
  final kept = keptCounts(mine, theirs);
  final top = kept.entries.reduce((a, b) => b.value > a.value ? b : a);
  final room = kept.entries.reduce((a, b) => b.value < a.value ? b : a);
  if (top.value > 0) {
    out.add('${paired ? 'You both prayed' : 'You prayed'} ${top.key.label} on ${top.value} of the last $n days.');
  }
  if (room.value < top.value) {
    out.add('${room.key.label} has the most room to grow${paired ? ' together' : ''}.');
  }
  if (active >= 14) {
    final sums = List.filled(7, 0.0), counts = List.filled(7, 0);
    for (var i = 0; i < n; i++) {
      final w = dates[i].weekday - 1;
      sums[w] += togetherScoreOf(mine[i], theirs?[i]);
      counts[w]++;
    }
    var best = 0;
    for (var w = 1; w < 7; w++) {
      if (counts[w] > 0 && sums[w] / counts[w] > sums[best] / (counts[best] == 0 ? 1 : counts[best])) best = w;
    }
    if (counts[best] > 0) out.add('${_weekdays[best]}s are your fullest day, ${(sums[best] / counts[best] * 100).round()}% on average.');
  }
  return out.take(3).toList();
}
