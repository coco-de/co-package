import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import '../support/note_test_host.dart';

/// Frozen time used by the nav tests.
final DateTime kNow = DateTime.utc(2026, 3, 4, 5, 6, 7);

/// A clock that always says [kNow].
DateTime frozenClock() => kNow;

/// An id factory yielding `<prefix>1`, `<prefix>2`…
NoteIdFactory countingIds([String prefix = 'id']) {
  var next = 0;

  return () => '$prefix${++next}';
}

/// Counts the notifications of [listenable].
class NotifyCounter {
  NotifyCounter(Listenable listenable) {
    listenable.addListener(() => count++);
  }

  int count = 0;
}

/// A [NoteFlashTicker] driven by hand.
class FakeFlashTicker implements NoteFlashTicker {
  ValueChanged<Duration>? onTick;
  int starts = 0;
  int stops = 0;
  bool disposed = false;

  bool get isRunning => onTick != null;

  @override
  void start(ValueChanged<Duration> onTick) {
    starts++;
    this.onTick = onTick;
  }

  @override
  void stop() {
    stops++;
    onTick = null;
  }

  @override
  void dispose() {
    disposed = true;
    onTick = null;
  }

  void advance(Duration elapsed) => onTick?.call(elapsed);
}

/// Pumps [child] at the size of a narrow side panel.
Future<void> pumpPanel(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  double height = 560,
}) => tester.pumpWidget(
  noteTestHost(
    Center(
      child: SizedBox(width: width, height: height, child: child),
    ),
  ),
);

/// Finds the widget with the string key [key].
Finder byKeyName(String key) => find.byKey(ValueKey(key));
