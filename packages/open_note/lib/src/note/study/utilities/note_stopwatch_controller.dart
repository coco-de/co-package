import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/utilities/note_periodic_ticker.dart';
import 'package:open_note/src/note/study/utilities/note_stopwatch_lap.dart';
import 'package:open_note/src/note/study/utilities/note_ticker.dart';

/// Where a [NoteStopwatchController] is.
enum NoteStopwatchStatus {
  /// At zero, not started.
  idle,

  /// Counting up.
  running,

  /// Stopped at a time; starting again continues from it.
  paused,
}

/// A stopwatch with laps.
///
/// Time passes only through [tick], which the [NoteTicker] calls while running
/// (tests call it directly). Calls that do not apply to the current state do
/// nothing, as does every method after [dispose].
class NoteStopwatchController extends ChangeNotifier {
  /// Keeps at most [maxLaps] laps. The controller drives [ticker] (a
  /// [NotePeriodicTicker] when omitted) and stops it on [dispose].
  NoteStopwatchController({NoteTicker? ticker, this.maxLaps = 999})
    : assert(maxLaps > 0),
      _ticker = ticker ?? NotePeriodicTicker();

  /// [lap] is ignored once this many laps exist.
  final int maxLaps;

  final NoteTicker _ticker;
  final List<NoteStopwatchLap> _laps = [];
  Duration _elapsed = Duration.zero;
  NoteStopwatchStatus _status = NoteStopwatchStatus.idle;
  bool _disposed = false;

  /// Time counted so far.
  Duration get elapsed => _elapsed;

  /// Where the stopwatch is.
  NoteStopwatchStatus get status => _status;

  /// Whether time is being counted.
  bool get isRunning => _status == NoteStopwatchStatus.running;

  /// Recorded laps, oldest first.
  List<NoteStopwatchLap> get laps => UnmodifiableListView(_laps);

  /// Starts from zero, or continues after [pause].
  void start() {
    if (_disposed || isRunning) return;
    _status = NoteStopwatchStatus.running;
    _ticker.start(tick);
    notifyListeners();
  }

  /// Stops counting, keeping the time that already passed.
  void pause() {
    if (_disposed || !isRunning) return;
    tick(_ticker.drain());
    _ticker.stop();
    _status = NoteStopwatchStatus.paused;
    notifyListeners();
  }

  /// Returns to zero and forgets the laps.
  void reset() {
    if (_disposed) return;
    if (_status == NoteStopwatchStatus.idle) return;
    _ticker.stop();
    _status = NoteStopwatchStatus.idle;
    _elapsed = Duration.zero;
    _laps.clear();
    notifyListeners();
  }

  /// Records a lap at the current time; only while running.
  void lap() {
    if (_disposed || !isRunning || _laps.length >= maxLaps) return;
    tick(_ticker.drain());
    final previous = _laps.isEmpty ? Duration.zero : _laps.last.total;
    _laps.add(
      NoteStopwatchLap(
        number: _laps.length + 1,
        total: _elapsed,
        split: _elapsed - previous,
      ),
    );
    notifyListeners();
  }

  /// Adds [elapsed] time. Only a running stopwatch reacts; zero and negative
  /// values are ignored.
  void tick(Duration elapsed) {
    if (_disposed || !isRunning || elapsed <= Duration.zero) return;
    _elapsed += elapsed;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker.stop();
    super.dispose();
  }
}
