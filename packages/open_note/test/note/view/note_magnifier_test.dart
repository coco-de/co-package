import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';
import 'note_view_test_support.dart';

NoteMagnifierController _lens({bool visible = true}) =>
    NoteMagnifierController(center: const Offset(200, 200), visible: visible);

Widget _host(
  NoteMagnifierController controller, {
  bool showControls = true,
  VoidCallback? onPageTap,
}) => noteTestHost(
  Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPageTap,
        ),
      ),
      Positioned.fill(
        child: NoteMagnifier(
          controller: controller,
          showControls: showControls,
        ),
      ),
    ],
  ),
);

void main() {
  group('NoteMagnifierController', () {
    test('clamps zoom and diameter', () {
      final lens = NoteMagnifierController(zoom: 100, diameter: 1);

      expect(lens.zoom, 6);
      expect(lens.diameter, 80);
      lens
        ..setZoom(0)
        ..setDiameter(9999);
      expect(lens.zoom, 1.5);
      expect(lens.diameter, 400);
    });

    test('notifies only on change and ignores bad values', () {
      final lens = _lens();
      final counter = NotifyCounter(lens);

      lens.setZoom(2);
      lens.setCenter(const Offset(200, 200));
      lens.setDiameter(160);
      lens.setVisible(true);
      lens.setZoom(double.nan);
      lens.setCenter(const Offset(double.infinity, 0));
      lens.setDiameter(double.nan);
      expect(counter.count, 0);

      lens.moveBy(const Offset(5, 6));
      lens.toggle();
      expect(lens.center, const Offset(205, 206));
      expect(lens.visible, isFalse);
      expect(counter.count, 2);
    });

    test('round-trips through json and survives junk', () {
      final lens = _lens()..setZoom(3.5);

      expect(NoteMagnifierController.fromJson(lens.toJson()).toJson(), {
        'center': {'x': 200.0, 'y': 200.0},
        'zoom': 3.5,
        'diameter': 160.0,
        'visible': true,
      });
      for (final junk in <Object?>[null, 'x', 1]) {
        final restored = NoteMagnifierController.fromJson(junk);
        expect(restored.zoom, 2);
        expect(restored.diameter, 160);
        expect(restored.visible, isFalse);
      }
    });

    test('does nothing after dispose', () {
      final lens = _lens()..dispose();

      lens.setZoom(5);
      lens.moveBy(const Offset(1, 1));
      lens.toggle();

      expect(lens.zoom, 2);
      expect(lens.visible, isTrue);
    });
  });

  group('NoteMagnifier', () {
    testWidgets('draws nothing while hidden', (tester) async {
      final lens = _lens(visible: false);
      await tester.pumpWidget(_host(lens));
      expect(find.byType(RawMagnifier), findsNothing);

      lens.setVisible(true);
      await tester.pump();

      expect(find.byType(RawMagnifier), findsOneWidget);
    });

    testWidgets('builds a lens of the requested size and power', (
      tester,
    ) async {
      final lens = _lens()..setZoom(3);
      await tester.pumpWidget(_host(lens));

      final magnifier = tester.widget<RawMagnifier>(find.byType(RawMagnifier));

      expect(magnifier.magnificationScale, 3);
      expect(magnifier.size, const Size.square(160));
      expect(magnifier.focalPointOffset, Offset.zero);
      expect(
        tester.getRect(find.byType(RawMagnifier)),
        const Rect.fromLTWH(120, 120, 160, 160),
      );
      expect(find.text('3.0×'), findsOneWidget);
    });

    testWidgets('dragging moves the lens by the finger distance', (
      tester,
    ) async {
      final lens = _lens();
      await tester.pumpWidget(_host(lens));

      await tester.drag(
        find.byKey(NoteMagnifier.lensKey),
        const Offset(60, 40),
      );
      await tester.pump();

      expect(lens.center, const Offset(260, 240));
      expect(
        tester.getCenter(find.byType(RawMagnifier)),
        const Offset(260, 240),
      );
    });

    testWidgets('keeps the centre inside the overlay', (tester) async {
      final lens = _lens();
      await tester.pumpWidget(_host(lens));

      await tester.drag(
        find.byKey(NoteMagnifier.lensKey),
        const Offset(-900, 900),
      );

      expect(lens.center, const Offset(0, 600));
    });

    testWidgets('buttons change the power and close', (tester) async {
      final lens = _lens();
      await tester.pumpWidget(_host(lens));

      await tester.tap(find.byKey(NoteMagnifier.zoomInKey));
      await tester.pump();
      expect(lens.zoom, 2.5);
      await tester.tap(find.byKey(NoteMagnifier.zoomOutKey));
      await tester.tap(find.byKey(NoteMagnifier.zoomOutKey));
      await tester.pump();
      expect(lens.zoom, 1.5);
      await tester.tap(find.byKey(NoteMagnifier.closeKey));
      await tester.pump();

      expect(lens.visible, isFalse);
      expect(find.byType(RawMagnifier), findsNothing);
    });

    testWidgets('pinching changes the power', (tester) async {
      final lens = _lens();
      await tester.pumpWidget(_host(lens));
      final left = await tester.startGesture(const Offset(180, 200));
      final right = await tester.startGesture(const Offset(220, 200));

      for (var step = 1; step <= 8; step++) {
        await left.moveTo(Offset(180 - step * 2.5, 200));
        await right.moveTo(Offset(220 + step * 2.5, 200));
      }
      await tester.pump();

      // The fingers went from 40 to 80 apart: twice the power.
      expect(lens.zoom, closeTo(4, 0.05));
      expect((lens.center - const Offset(200, 200)).distance, lessThan(0.01));
      await left.up();
      await right.up();
      await tester.pumpAndSettle();
    });

    testWidgets('only the lens takes pointers', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(_lens(), showControls: false, onPageTap: () => taps++),
      );

      await tester.tapAt(const Offset(500, 500));
      // A corner of the square around the round lens is outside it.
      await tester.tapAt(const Offset(125, 125));
      expect(taps, 2);

      await tester.tapAt(const Offset(200, 200));
      expect(taps, 2);
    });

    testWidgets('keeps the buttons on the page', (tester) async {
      final lens = _lens();
      await tester.pumpWidget(_host(lens));
      Offset buttons() =>
          tester.getTopLeft(find.byKey(NoteMagnifier.zoomOutKey));
      // Under the lens: 200 + 80 radius + 6 gap, inside a 1 wide border.
      expect(buttons().dy, closeTo(286, 1.01));

      lens.setCenter(const Offset(200, 580));
      await tester.pump();
      // No room below, so above it: 580 - 80 - 6 - 32.
      expect(buttons().dy, closeTo(462, 1.01));

      lens.setCenter(const Offset(0, 300));
      await tester.pump();
      expect(buttons().dx, greaterThanOrEqualTo(0));
      lens.setCenter(const Offset(800, 300));
      await tester.pump();
      expect(
        tester.getTopRight(find.byKey(NoteMagnifier.closeKey)).dx,
        lessThanOrEqualTo(800),
      );
    });

    testWidgets('can hide the controls', (tester) async {
      await tester.pumpWidget(_host(_lens(), showControls: false));

      expect(find.byKey(NoteMagnifier.zoomInKey), findsNothing);
      expect(find.text('2.0×'), findsNothing);
    });

    testWidgets('lets screen readers change the power', (tester) async {
      final semantics = tester.ensureSemantics();
      final lens = _lens();
      await tester.pumpWidget(_host(lens, showControls: false));

      tester.semantics.increase(find.semantics.byLabel('Magnifier'));
      await tester.pump();

      expect(lens.zoom, 2.5);
      semantics.dispose();
    });
  });
}
