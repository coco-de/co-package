// Forked from dox_storage 3.0.1 (MIT, see THIRD_PARTY_LICENSES and FORK.md).
// Source: https://github.com/dartondox/dox-storage
/// Gives the current time. Inject a fixed clock in tests.
class Clock {
  const Clock();

  /// Current time in UTC.
  DateTime now() {
    return DateTime.now().toUtc();
  }
}

/// A clock that always returns the same time. Useful in tests.
class FixedClock extends Clock {
  DateTime time;

  FixedClock(DateTime time) : time = time.toUtc();

  @override
  DateTime now() {
    return time;
  }
}
