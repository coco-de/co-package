import 'package:open_note/src/note/study/utilities/utilities.dart';

/// A [NoteTicker] that never runs on its own: tests call [elapse] as if the
/// periodic timer had fired, and set [pending] to the time that passed since
/// the last report (what `drain` returns).
class ManualNoteTicker implements NoteTicker {
  NoteTickCallback? _onTick;
  Duration pending = Duration.zero;
  int starts = 0;
  int stops = 0;

  bool get isActive => _onTick != null;

  /// Fires a report of [elapsed] time.
  void elapse(Duration elapsed) => _onTick?.call(elapsed);

  @override
  void start(NoteTickCallback onTick) {
    _onTick = onTick;
    pending = Duration.zero;
    starts++;
  }

  @override
  Duration drain() {
    if (!isActive) return Duration.zero;
    final drained = pending;
    pending = Duration.zero;

    return drained;
  }

  @override
  void stop() {
    if (isActive) stops++;
    _onTick = null;
    pending = Duration.zero;
  }
}
