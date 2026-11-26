import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';
import 'note_view_test_support.dart';

const _body = ValueKey<String>('body');

Widget _column({
  required bool hidden,
  bool collapse = true,
  VoidCallback? onToolbarTap,
}) => noteTestHost(
  Column(
    children: [
      NoteChromeVisibility(
        hidden: hidden,
        collapse: collapse,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToolbarTap,
          child: const StatefulProbe(size: Size(800, 40)),
        ),
      ),
      const Expanded(child: SizedBox.expand(key: _body)),
    ],
  ),
);

double _bodyTop(WidgetTester tester) => tester.getTopLeft(find.byKey(_body)).dy;

void main() {
  group('NoteFullScreenController', () {
    test('toggles between full screen and chrome', () {
      final controller = NoteFullScreenController();
      final counter = NotifyCounter(controller);

      controller.show();
      controller.toggle();
      expect(controller.chromeHidden, isTrue);
      controller.hide();
      controller.toggle();
      controller.setChromeHidden(true);

      expect(controller.chromeHidden, isTrue);
      expect(counter.count, 3);
    });

    test('does nothing after dispose', () {
      final controller = NoteFullScreenController(chromeHidden: true)
        ..dispose();

      controller.toggle();

      expect(controller.chromeHidden, isTrue);
    });
  });

  group('NoteChromeVisibility', () {
    testWidgets('gives its space back while hiding', (tester) async {
      await tester.pumpWidget(_column(hidden: false));
      expect(_bodyTop(tester), 40);

      await tester.pumpWidget(_column(hidden: true));
      await tester.pump(const Duration(milliseconds: 110));
      expect(_bodyTop(tester), inExclusiveRange(0, 40));
      await tester.pumpAndSettle();

      expect(_bodyTop(tester), 0);
      await tester.pumpWidget(_column(hidden: false));
      await tester.pumpAndSettle();
      expect(_bodyTop(tester), 40);
    });

    testWidgets('starts hidden without animating', (tester) async {
      await tester.pumpWidget(_column(hidden: true));

      expect(_bodyTop(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('ignores pointers while hidden and keeps state', (
      tester,
    ) async {
      var taps = 0;
      Widget build(bool hidden) =>
          _column(hidden: hidden, onToolbarTap: () => taps++);
      await tester.pumpWidget(build(false));
      tester.state<StatefulProbeState>(find.byType(StatefulProbe)).marker = 9;

      await tester.pumpWidget(build(true));
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(400, 20));
      expect(taps, 0);

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(400, 20));
      expect(taps, 1);
      expect(
        tester.state<StatefulProbeState>(find.byType(StatefulProbe)).marker,
        9,
      );
    });

    testWidgets('keeps the room when it does not collapse', (tester) async {
      await tester.pumpWidget(_column(hidden: false, collapse: false));

      await tester.pumpWidget(_column(hidden: true, collapse: false));
      await tester.pumpAndSettle();

      expect(_bodyTop(tester), 40);
      expect(
        tester.getBottomLeft(find.byType(StatefulProbe)).dy,
        0,
        reason: 'slid out through the top',
      );
    });

    testWidgets('collapses sideways for side panels', (tester) async {
      Widget build(bool hidden) => noteTestHost(
        Row(
          children: [
            NoteChromeVisibility(
              hidden: hidden,
              edge: NoteChromeEdge.left,
              child: const SizedBox(width: 60, height: 600),
            ),
            const Expanded(child: SizedBox.expand(key: _body)),
          ],
        ),
      );
      await tester.pumpWidget(build(false));
      expect(tester.getTopLeft(find.byKey(_body)).dx, 60);

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(_body)).dx, 0);
    });

    testWidgets('hidden chrome leaves the accessibility tree', (tester) async {
      final semantics = tester.ensureSemantics();
      Widget build(bool hidden) => noteTestHost(
        NoteChromeVisibility(
          hidden: hidden,
          collapse: false,
          child: Semantics(label: 'tool', child: const SizedBox(width: 10)),
        ),
      );
      await tester.pumpWidget(build(false));
      expect(find.semantics.byLabel('tool'), findsOne);

      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel('tool'), findsNothing);
      semantics.dispose();
    });
  });
}
