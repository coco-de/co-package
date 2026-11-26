/// Receives the time that passed since the previous report.
typedef NoteTickCallback = void Function(Duration elapsed);

/// A repeating source of "this much time has passed", behind the timer and the
/// stopwatch.
///
/// Production code uses `NotePeriodicTicker`; tests pass their own, or drive a
/// controller's public `tick` directly.
abstract interface class NoteTicker {
  /// Starts reporting to [onTick], forgetting any earlier run. Nothing is
  /// reported synchronously by this call.
  void start(NoteTickCallback onTick);

  /// The time since the last report (or since [start]), which then counts as
  /// reported. [Duration.zero] while stopped.
  ///
  /// Controllers call it before pausing so that the part of an interval that
  /// already passed is not lost.
  Duration drain();

  /// Stops reporting and drops unreported time (call [drain] first to keep
  /// it). A no-op while stopped.
  void stop();
}
