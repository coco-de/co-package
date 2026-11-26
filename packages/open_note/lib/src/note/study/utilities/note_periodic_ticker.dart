import 'dart:async';

import 'package:open_note/src/note/study/utilities/note_ticker.dart';

/// The production [NoteTicker]: a [Timer.periodic] that reports how much time
/// really passed (measured on a monotonic clock), so a late or skipped
/// callback loses no time.
class NotePeriodicTicker implements NoteTicker {
  /// Reports every [interval] (default 100 ms). [now] is a monotonic clock with
  /// any fixed origin; it exists so tests can drive the ticker.
  NotePeriodicTicker({
    this.interval = const Duration(milliseconds: 100),
    Duration Function()? now,
  }) : _now = now ?? _processTime;

  static final Stopwatch _processClock = Stopwatch()..start();

  /// How often the ticker reports.
  final Duration interval;

  final Duration Function() _now;
  Timer? _timer;
  Duration _reportedAt = Duration.zero;

  /// Whether reports are scheduled.
  bool get isActive => _timer != null;

  static Duration _processTime() => _processClock.elapsed;

  @override
  void start(NoteTickCallback onTick) {
    stop();
    _reportedAt = _now();
    _timer = Timer.periodic(interval, (_) {
      final elapsed = drain();
      if (elapsed > Duration.zero) onTick(elapsed);
    });
  }

  @override
  Duration drain() {
    if (_timer == null) return Duration.zero;
    final now = _now();
    final elapsed = now - _reportedAt;
    _reportedAt = now;

    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
