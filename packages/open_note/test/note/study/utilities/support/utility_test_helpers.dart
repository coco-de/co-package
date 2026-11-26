import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The label a screen reader announces for the button with [key].
String? semanticLabelOf(WidgetTester tester, Key key) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .label;

/// Whether the button with [key] is enabled.
bool isButtonEnabled(WidgetTester tester, Key key) => tester
    .widget<Semantics>(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    )
    .properties
    .enabled!;

/// Taps the widget with [key] and settles the frame.
Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
}

/// The text of the [Text] with [key].
String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

/// Counts the notifications of [listenable] from now on.
List<int> countNotifications(Listenable listenable) {
  final calls = <int>[];
  listenable.addListener(() => calls.add(calls.length));

  return calls;
}
