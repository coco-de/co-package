import 'dart:math' as math;

/// Formats durations the way a digital clock reads them: `mm:ss`, and
/// `h:mm:ss` from one hour up (the hour is not zero-padded).
abstract final class NoteDurationFormat {
  /// Formats [value]; negative values read `00:00`.
  ///
  /// A partial second is cut off. With [roundUp] it counts as a whole second
  /// instead, which is what a countdown needs: it keeps reading `00:01` until
  /// the time is really up.
  static String clock(Duration value, {bool roundUp = false}) {
    final micros = math.max(value.inMicroseconds, 0);
    final partial = roundUp && micros % Duration.microsecondsPerSecond != 0;
    final total = micros ~/ Duration.microsecondsPerSecond + (partial ? 1 : 0);
    final hours = total ~/ Duration.secondsPerHour;
    final minutes =
        total % Duration.secondsPerHour ~/ Duration.secondsPerMinute;
    final tail = '${_pad(minutes)}:${_pad(total % Duration.secondsPerMinute)}';

    return hours == 0 ? tail : '$hours:$tail';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
