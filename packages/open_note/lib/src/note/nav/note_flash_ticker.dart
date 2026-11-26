import 'package:flutter/foundation.dart';

/// A restartable source of elapsed-time ticks for
/// `NoteExcerptFlashController`.
///
/// The default implementation is `NoteSchedulerFlashTicker` (one tick per
/// frame); tests and non-widget hosts can drive the flash with their own.
abstract interface class NoteFlashTicker {
  /// Starts, or restarts from zero, calling [onTick] with the time elapsed
  /// since this call.
  void start(ValueChanged<Duration> onTick);

  /// Stops ticking; safe to call when idle.
  void stop();

  /// Releases resources; the ticker is not used afterwards.
  void dispose();
}
