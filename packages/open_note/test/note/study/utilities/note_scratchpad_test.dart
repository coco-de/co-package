import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/module/widgets/simple_scribble_widget.dart';
import 'package:open_note/src/note/study/utilities/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/note_test_host.dart';
import 'support/utility_test_helpers.dart';

const _clear = ValueKey('scratchpad-clear');
const _close = ValueKey('scratchpad-close');

Scribble _oneStroke() => Scribble(strokes: [Stroke()]);

/// Lets the engine's short timers run out.
Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

/// Drags across the pad from [from] with [kind] and finishes the stroke.
Future<void> _draw(
  WidgetTester tester,
  Offset from, {
  PointerDeviceKind kind = PointerDeviceKind.stylus,
}) async {
  final gesture = await tester.startGesture(from, kind: kind);
  await tester.pump(const Duration(milliseconds: 50));
  for (var i = 0; i < 6; i++) {
    await gesture.moveBy(const Offset(8, 5));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('NoteScratchpadController', () {
    late NoteScratchpadController pad;

    setUp(() => pad = NoteScratchpadController());
    tearDown(() => pad.dispose());

    test('starts with a pale translucent sheet and no ink', () {
      expect(pad.color, NoteScratchpadController.defaultSheetColor);
      expect(pad.opacity, NoteScratchpadController.defaultOpacity);
      expect(pad.isEmpty, isTrue);
    });

    test('notifies when the sheet changes, clamping the opacity', () {
      final calls = countNotifications(pad);

      pad
        ..color = const Color(0xFF00BCD4)
        ..color = const Color(0xFF00BCD4)
        ..opacity = 2;
      expect(pad.opacity, 1);
      expect(calls, hasLength(2));

      pad.opacity = -1;
      expect(pad.opacity, NoteScratchpadController.minOpacity);
      pad
        ..opacity = 0
        ..opacity = double.nan;
      expect(pad.opacity, NoteScratchpadController.minOpacity);
      expect(calls, hasLength(3));
    });

    test('clamps the initial opacity', () {
      final faint = NoteScratchpadController(opacity: 0);
      final bad = NoteScratchpadController(opacity: double.nan);
      addTearDown(faint.dispose);
      addTearDown(bad.dispose);

      expect(faint.opacity, NoteScratchpadController.minOpacity);
      expect(bad.opacity, NoteScratchpadController.defaultOpacity);
    });

    test('notifies when ink changes and clear erases it', () {
      final calls = countNotifications(pad);

      pad.scribbleController.loadScribble(_oneStroke());
      expect(pad.isEmpty, isFalse);
      expect(calls, isNotEmpty);

      final before = calls.length;
      pad.clear();
      expect(pad.isEmpty, isTrue);
      expect(pad.scribbleController.currentScribble.strokes, isEmpty);
      expect(calls.length, greaterThan(before));
    });

    test('clearing an empty pad does not notify', () {
      final calls = countNotifications(pad);

      pad.clear();

      expect(calls, isEmpty);
    });

    test('does nothing after dispose', () {
      final disposed = NoteScratchpadController()..dispose();

      expect(
        () => disposed
          ..clear()
          ..color = const Color(0xFF000000)
          ..opacity = 0.5
          ..dispose(),
        returnsNormally,
      );
      expect(disposed.color, NoteScratchpadController.defaultSheetColor);
    });
  });

  group('NoteScratchpadView', () {
    late NoteScratchpadController pad;

    setUp(() => pad = NoteScratchpadController());

    Future<void> pumpPad(WidgetTester tester, Widget view) async {
      await tester.pumpWidget(noteTestHost(Center(child: view)));
      await _settle(tester);
    }

    /// Unmounts the view before the controller goes away.
    Future<void> tearDownPad(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await _settle(tester);
      pad.dispose();
    }

    testWidgets('drawing on the pad produces strokes in its controller', (
      tester,
    ) async {
      await pumpPad(tester, NoteScratchpadView(controller: pad));
      final calls = countNotifications(pad);
      final surface = tester.getRect(find.byType(SimpleScribbleWidget));
      expect(surface.size, const Size(320, 240));

      await _draw(tester, surface.center);

      final strokes = pad.scribbleController.currentScribble.strokes;
      expect(strokes, hasLength(1));
      expect(strokes.single.points.length, greaterThan(2));
      expect(strokes.single.points.first.x, closeTo(160, 2));
      expect(strokes.single.points.first.y, closeTo(120, 2));
      expect(pad.isEmpty, isFalse);
      expect(calls, isNotEmpty);
      await tearDownPad(tester);
    });

    testWidgets('keeps its coordinates when it is scaled down', (tester) async {
      await pumpPad(
        tester,
        SizedBox(
          width: 160,
          child: NoteScratchpadView(controller: pad, showHeader: false),
        ),
      );
      final surface = tester.getRect(find.byType(SimpleScribbleWidget));
      expect(surface.size, const Size(160, 120));

      await _draw(tester, surface.center);

      final first = pad.scribbleController.currentScribble.strokes.single;
      expect(first.points.first.x, closeTo(160, 3));
      expect(first.points.first.y, closeTo(120, 3));
      await tearDownPad(tester);
    });

    testWidgets("follows the engine's pointer mode", (tester) async {
      await pumpPad(tester, NoteScratchpadView(controller: pad));
      final center = tester.getCenter(find.byType(SimpleScribbleWidget));

      // Pen only (the engine default): a finger does not draw.
      await _draw(tester, center, kind: PointerDeviceKind.touch);
      expect(pad.isEmpty, isTrue);

      final state = DrawingState();
      state.pointerMode.value = DrawingPointerMode.mouseOnly;
      await _settle(tester);
      await _draw(tester, center, kind: PointerDeviceKind.touch);
      expect(pad.isEmpty, isFalse);

      state.pointerMode.value = DrawingPointerMode.penOnly;
      await tearDownPad(tester);
    });

    testWidgets('the clear button erases the ink', (tester) async {
      await pumpPad(tester, NoteScratchpadView(controller: pad));
      expect(isButtonEnabled(tester, _clear), isFalse);
      await _draw(tester, tester.getCenter(find.byType(SimpleScribbleWidget)));
      expect(isButtonEnabled(tester, _clear), isTrue);

      await tapKey(tester, _clear);
      await _settle(tester);

      expect(pad.isEmpty, isTrue);
      expect(isButtonEnabled(tester, _clear), isFalse);
      await tearDownPad(tester);
    });

    testWidgets('paints the sheet colour at its opacity', (tester) async {
      pad
        ..color = const Color(0xFF00BCD4)
        ..opacity = 0.5;
      await pumpPad(tester, NoteScratchpadView(controller: pad));

      Color? sheet() {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(NoteScratchpadView),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );

        return (box.decoration as BoxDecoration).color;
      }

      expect(sheet(), const Color(0xFF00BCD4).withValues(alpha: 0.5));

      pad.opacity = 1;
      await tester.pump();
      expect(sheet(), const Color(0xFF00BCD4));
      await tearDownPad(tester);
    });

    testWidgets('offers closing only with a callback', (tester) async {
      await pumpPad(tester, NoteScratchpadView(controller: pad));
      expect(find.byKey(_close), findsNothing);

      var closed = 0;
      await pumpPad(
        tester,
        NoteScratchpadView(controller: pad, onClose: () => closed++),
      );
      await tapKey(tester, _close);

      expect(closed, 1);
      await tearDownPad(tester);
    });

    testWidgets('the header is optional', (tester) async {
      await pumpPad(
        tester,
        NoteScratchpadView(controller: pad, showHeader: false),
      );

      expect(find.byKey(_clear), findsNothing);
      expect(find.text('Scratchpad'), findsNothing);
      await tearDownPad(tester);
    });
  });
}
