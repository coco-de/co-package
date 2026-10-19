import 'dart:async';

import 'package:co_bdd/src/driver/test_driver.dart';

/// Condition-based waiting for both fake-time widget tests and live Patrol.
extension ConditionWait on TestDriver {
  /// Returns immediately when ready. [timeout] is a limit, not a fixed delay.
  /// This pumps through the driver so widget-test timers advance too.
  Future<void> waitUntil(
    bool Function() predicate, {
    Duration timeout = const Duration(seconds: 15),
    Duration interval = const Duration(milliseconds: 50),
    String description = 'condition',
  }) async {
    if (interval <= Duration.zero || timeout < Duration.zero) {
      throw ArgumentError('interval must be positive and timeout non-negative');
    }
    var elapsed = Duration.zero;
    while (!predicate()) {
      if (elapsed >= timeout) throw TimeoutException(description, timeout);
      final remaining = timeout - elapsed;
      final step = remaining < interval ? remaining : interval;
      await wait(step);
      elapsed += step;
    }
  }
}
