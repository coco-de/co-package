import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';

const _center = Offset(400, 300);

NoteRulerController _ruler({bool visible = true, double angle = 0}) =>
    NoteRulerController(center: _center, angle: angle, visible: visible);

Widget _host(NoteRulerController controller, {VoidCallback? onPageTap}) =>
    noteTestHost(
      Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPageTap,
            ),
          ),
          Positioned.fill(child: NoteRuler(controller: controller)),
        ],
      ),
    );

void expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 0.01), reason: '$actual');
  expect(actual.dy, closeTo(expected.dy, 0.01), reason: '$actual');
}

void main() {
  testWidgets('draws nothing while hidden', (tester) async {
    final controller = _ruler(visible: false);
    await tester.pumpWidget(_host(controller));

    expect(find.byKey(NoteRuler.bodyKey), findsNothing);

    controller.setVisible(true);
    await tester.pump();
    expect(find.byKey(NoteRuler.bodyKey), findsOneWidget);
  });

  testWidgets('shows the length in the selected unit and the angle', (
    tester,
  ) async {
    final controller = _ruler();
    await tester.pumpWidget(_host(controller));
    expect(find.text('12.7 cm · 0°'), findsOneWidget);
    expectOffset(tester.getCenter(find.byKey(NoteRuler.bodyKey)), _center);

    controller
      ..setUnit(NoteRulerUnit.inch)
      ..setAngle(-math.pi / 4);
    await tester.pump();

    expect(find.text('5.00 in · 135°'), findsOneWidget);
  });

  testWidgets('dragging the body moves the ruler by the same amount', (
    tester,
  ) async {
    final controller = _ruler();
    await tester.pumpWidget(_host(controller));

    await tester.dragFrom(const Offset(300, 300), const Offset(50, 30));
    await tester.pump();

    expectOffset(controller.center, _center + const Offset(50, 30));
    expect(controller.angle, 0);
    expectOffset(
      tester.getCenter(find.byKey(NoteRuler.bodyKey)),
      _center + const Offset(50, 30),
    );
  });

  testWidgets('a turned ruler still moves with the finger', (tester) async {
    final controller = _ruler(angle: math.pi / 2);
    await tester.pumpWidget(_host(controller));

    await tester.dragFrom(const Offset(400, 200), const Offset(70, 0));

    expectOffset(controller.center, _center + const Offset(70, 0));
  });

  testWidgets('the handle turns the ruler toward the finger', (tester) async {
    final controller = _ruler();
    await tester.pumpWidget(_host(controller));
    // The handle sits 160 to the right of the centre.
    expectOffset(
      tester.getCenter(find.byKey(NoteRuler.rotateHandleKey)),
      const Offset(560, 300),
    );

    await tester.drag(
      find.byKey(NoteRuler.rotateHandleKey),
      const Offset(-160, 160),
    );
    await tester.pump();

    expect(controller.angle, closeTo(math.pi / 2, 1e-6));
    expect(controller.center, _center);
    expectOffset(
      tester.getCenter(find.byKey(NoteRuler.rotateHandleKey)),
      const Offset(400, 460),
    );
  });

  testWidgets('two fingers turn the ruler', (tester) async {
    final controller = _ruler();
    await tester.pumpWidget(_host(controller));
    final first = await tester.startGesture(const Offset(350, 300));
    final second = await tester.startGesture(const Offset(450, 300));

    for (var step = 1; step <= 10; step++) {
      final angle = math.pi / 6 * step / 10;
      final arm = Offset(50 * math.cos(angle), 50 * math.sin(angle));
      await first.moveTo(_center - arm);
      await second.moveTo(_center + arm);
    }
    await tester.pump();

    expect(controller.angle, closeTo(math.pi / 6, 0.02));
    expectOffset(controller.center, _center);
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  });

  testWidgets('only the ruler takes pointers', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_ruler(), onPageTap: () => taps++));

    await tester.tapAt(const Offset(400, 100));
    await tester.tapAt(const Offset(400, 400));
    expect(taps, 2);

    await tester.tapAt(const Offset(300, 300));
    expect(taps, 2);
  });

  testWidgets('describes itself and rotates for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = _ruler();
    await tester.pumpWidget(_host(controller));
    expect(find.semantics.byLabel('Ruler'), findsOne);

    tester.semantics.increase(find.semantics.byLabel('Rotate ruler'));
    await tester.pump();

    expect(controller.angle, closeTo(NoteRuler.semanticStep, 1e-9));
    semantics.dispose();
  });

  test('the painter repaints only when its look changes', () {
    const painter = NoteRulerPainter(unit: NoteRulerUnit.cm);

    expect(
      painter.shouldRepaint(const NoteRulerPainter(unit: NoteRulerUnit.cm)),
      isFalse,
    );
    expect(
      painter.shouldRepaint(const NoteRulerPainter(unit: NoteRulerUnit.mm)),
      isTrue,
    );
  });
}
