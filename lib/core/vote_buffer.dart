import 'dart:collection';

/// Locks a number only when it is seen in [needed] of the last [window]
/// OCR frames ("৫ frame-এ ৩ বার"). Kills one-frame misreads like 1↔7.
class VoteBuffer {
  VoteBuffer({this.window = 5, this.needed = 3})
      : assert(needed <= window, 'needed must not exceed window');

  final int window;
  final int needed;
  final Queue<Set<String>> _frames = Queue();

  /// Add one frame's numbers; returns the numbers that are now locked,
  /// most-seen first. Empty while still searching.
  List<String> add(Iterable<String> numbers) {
    _frames.addLast(numbers.toSet());
    while (_frames.length > window) {
      _frames.removeFirst();
    }
    final counts = <String, int>{};
    for (final frame in _frames) {
      for (final n in frame) {
        counts[n] = (counts[n] ?? 0) + 1;
      }
    }
    final locked = counts.entries.where((e) => e.value >= needed).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in locked) e.key];
  }

  void reset() => _frames.clear();
}
