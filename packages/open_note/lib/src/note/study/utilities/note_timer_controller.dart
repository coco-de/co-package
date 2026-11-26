import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/study/utilities/note_periodic_ticker.dart';
import 'package:open_note/src/note/study/utilities/note_ticker.dart';

/// Where a [NoteTimerController] countdown is.
enum NoteTimerStatus {
  /// Not started, or reset: the full length remains.
  idle,

  /// Counting down.
  running,

  /// Stopped part-way; it can resume.
  paused,

  /// The time ran out: nothing remains.
  finished,
}

/// A countdown timer.
///
/// `idle → running ⇄ paused`, and `running → finished` when the time runs out;
/// [reset] returns to idle from anywhere. Time passes only through [tick],
/// which the [NoteTicker] calls while running (tests call it directly). Calls
/// that do not apply to the current state do nothing, as does every method
/// after [dispose].
class NoteTimerController extends ChangeNotifier {
  /// [duration] is clamped to `0`–[maxDuration]. The controller drives [ticker]
  /// (a [NotePeriodicTicker] when omitted) and stops it on [dispose].
  NoteTimerController({
    Duration duration = defaultDuration,
    NoteTicker? ticker,
    this.onFinished,
  }) : _ticker = ticker ?? NotePeriodicTicker(),
       _duration = clampDuration(duration),
       _remaining = clampDuration(duration);

  /// Length of a new timer.
  static const Duration defaultDuration = Duration(minutes: 5);

  /// The longest countdown, `99:59:59`.
  static const Duration maxDuration = Duration(
    hours: 99,
    minutes: 59,
    seconds: 59,
  );

  /// Called once each time a countdown reaches zero, after listeners were
  /// notified: play a sound or vibrate here.
  VoidCallback? onFinished;

  final NoteTicker _ticker;
  Duration _duration;
  Duration _remaining;
  NoteTimerStatus _status = NoteTimerStatus.idle;
  bool _disposed = false;

  /// The configured length.
  Duration get duration => _duration;

  /// Time left; never negative.
  Duration get remaining => _remaining;

  /// Where the countdown is.
  NoteTimerStatus get status => _status;

  /// Whether the countdown is running.
  bool get isRunning => _status == NoteTimerStatus.running;

  /// The fraction of the countdown already spent, `0`–`1`.
  double get progress => _duration == Duration.zero
      ? 0
      : 1 - _remaining.inMicroseconds / _duration.inMicroseconds;

  /// [value] clamped to `0`–[maxDuration].
  static Duration clampDuration(Duration value) {
    if (value.isNegative) return Duration.zero;

    return value > maxDuration ? maxDuration : value;
  }

  /// Sets the length (clamped). Stops a running or paused countdown and
  /// returns to idle with the new length remaining.
  void setDuration(Duration value) {
    if (_disposed) return;
    final next = clampDuration(value);
    if (next == _duration && _status == NoteTimerStatus.idle) return;
    _duration = next;
    _enterIdle();
  }

  /// Counts down from the full length (from idle or finished), or resumes a
  /// paused countdown. Does nothing while running or when the length is zero.
  void start() {
    if (_disposed || isRunning) return;
    if (_status == NoteTimerStatus.paused) return resume();
    if (_duration == Duration.zero) return;
    _remaining = _duration;
    _enterRunning();
  }

  /// Pauses a running countdown, keeping the time that already passed.
  void pause() {
    if (_disposed || !isRunning) return;
    tick(_ticker.drain());
    if (!isRunning) return;
    _ticker.stop();
    _status = NoteTimerStatus.paused;
    notifyListeners();
  }

  /// Continues a paused countdown.
  void resume() {
    if (_disposed || _status != NoteTimerStatus.paused) return;
    _enterRunning();
  }

  /// Returns to idle with the full length remaining.
  void reset() {
    if (_disposed) return;
    if (_status == NoteTimerStatus.idle && _remaining == _duration) return;
    _enterIdle();
  }

  /// Lets [elapsed] time pass. Only a running countdown reacts; zero and
  /// negative values are ignored.
  void tick(Duration elapsed) {
    if (_disposed || !isRunning || elapsed <= Duration.zero) return;
    if (elapsed < _remaining) {
      _remaining -= elapsed;
      notifyListeners();

      return;
    }
    _remaining = Duration.zero;
    _status = NoteTimerStatus.finished;
    _ticker.stop();
    notifyListeners();
    onFinished?.call();
  }

  void _enterRunning() {
    _status = NoteTimerStatus.running;
    _ticker.start(tick);
    notifyListeners();
  }

  void _enterIdle() {
    _ticker.stop();
    _status = NoteTimerStatus.idle;
    _remaining = _duration;
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
