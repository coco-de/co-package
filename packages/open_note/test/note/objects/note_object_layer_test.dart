import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

import '../support/note_test_host.dart';
import 'support/objects_test_support.dart';

void main() {
  group('drawing', () {
    testWidgets('places, turns and fades objects in stacking order', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a', rotation: 0.5, opacity: 0.5),
          box('b', bounds: const Rect.fromLTWH(150, 140, 100, 80)),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      const bounds = Rect.fromLTWH(100, 100, 100, 80);
      expect(harness.centerOfKey('box-view-a'), offsetCloseTo(bounds.center));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('box-view-a'))) -
            tester.getTopLeft(find.byType(NoteObjectLayer)),
        offsetCloseTo(
          NoteObjectGeometry.rotateAround(bounds.topLeft, bounds.center, 0.5),
        ),
      );
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('box-view-a')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);
      // Where they overlap, the later object is on top.
      await harness.tap(const Offset(170, 160));
      expect(harness.log.taps, ['b']);
    });

    testWidgets('rebuilds when the controller changes', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      harness.controller.add(box('b'));
      await tester.pump();

      expect(find.byKey(const ValueKey('note-object-b')), findsOneWidget);
      harness.controller.remove(['a']);
      await tester.pump();
      expect(find.byKey(const ValueKey('note-object-a')), findsNothing);
    });

    testWidgets('shows the objects of a new controller', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      final other = NoteObjectController(objects: [box('z')]);
      addTearDown(other.dispose);

      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: NoteObjectLayer(
              controller: other,
              registry: harness.registry,
              size: testPageSize,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('note-object-z')), findsOneWidget);
      expect(find.byKey(const ValueKey('note-object-a')), findsNothing);
    });

    testWidgets('shows a placeholder for an unregistered kind', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteUnknownObject(
            id: 'u',
            bounds: Rect.fromLTWH(0, 0, 100, 40),
            unknownKind: 'future',
            payload: {},
          ),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      expect(find.text('future'), findsOneWidget);
    });
  });

  group('pointers fall through', () {
    for (final mode in NoteObjectLayerMode.values) {
      testWidgets('empty space reaches what is beneath in ${mode.name}', (
        tester,
      ) async {
        final harness = LayerHarness(tester, objects: [box('a')]);
        await harness.pump(mode);

        await harness.tap(const Offset(350, 450));

        expect(harness.beneathTaps, 1);
        expect(harness.log.taps, isEmpty);
      });
    }

    for (final (mode, reachesBeneath) in [
      (NoteObjectLayerMode.view, false),
      (NoteObjectLayerMode.edit, false),
      (NoteObjectLayerMode.passThrough, true),
    ]) {
      testWidgets('an object covers what is beneath in ${mode.name}: '
          '${!reachesBeneath}', (tester) async {
        final harness = LayerHarness(tester, objects: [box('a')]);
        await harness.pump(mode);

        await harness.tap(const Offset(150, 140));

        expect(harness.beneathTaps, reachesBeneath ? 1 : 0);
      });
    }

    testWidgets('a rotated object only covers where it is drawn', (
      tester,
    ) async {
      // 200x40 turned a quarter covers x 180..220, y 120..320.
      final harness = LayerHarness(
        tester,
        objects: [
          box(
            'a',
            bounds: const Rect.fromLTWH(100, 200, 200, 40),
            rotation: math.pi / 2,
          ),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      await harness.tap(const Offset(200, 130));
      await harness.tap(const Offset(110, 220));

      expect(harness.log.taps, ['a']);
      expect(harness.beneathTaps, 1);
    });

    testWidgets('arrows and stickers let view-mode taps through', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteArrowObject(id: 'r', bounds: Rect.fromLTWH(10, 10, 100, 40)),
          NoteStickerObject(id: 's', bounds: Rect.fromLTWH(10, 100, 60, 60)),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      await harness.tap(const Offset(60, 30));
      await harness.tap(const Offset(40, 130));

      expect(harness.beneathTaps, 2);
    });
  });

  group('view mode', () {
    testWidgets('objects take their own taps and nothing is selected', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')])
        ..controller.select('a');
      await harness.pump(NoteObjectLayerMode.view);

      await harness.tap(const Offset(150, 140));

      expect(harness.log.taps, ['a']);
      final scope = harness.log.scopes['a']!;
      expect(scope.interactive, isTrue);
      expect(scope.selected, isFalse);
      expect(scope.editing, isFalse);
      expect(scope.onRequestEdit, isNull);
      expect(find.byKey(const ValueKey('note-object-overlay')), findsNothing);
    });

    testWidgets('a change from a widget is recorded as an undo step', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump(NoteObjectLayerMode.view);

      harness.log.scopes['a']!.onChanged!(box('a', label: 'revealed'));
      await tester.pump();

      expect((harness.object('a') as BoxObject).label, 'revealed');
      expect(harness.history.undoLength, 1);
    });

    testWidgets('tapping a link reports its parsed target', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteLinkObject(
            id: 'l',
            bounds: Rect.fromLTWH(10, 10, 80, 20),
            target: 'page:3',
            appearance: NoteLinkAppearance.hidden,
          ),
          NoteLinkObject(
            id: 'n',
            bounds: Rect.fromLTWH(10, 60, 80, 20),
            target: 'note:abc#page:2',
          ),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      await harness.tap(const Offset(40, 20));
      await harness.tap(const Offset(40, 70));

      expect(harness.links, const [
        NotePageLink(3),
        NoteNoteLink('abc', page: 2),
      ]);
      expect(harness.beneathTaps, 0);
    });

    testWidgets('a link without a target lets taps through', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteLinkObject(id: 'l', bounds: Rect.fromLTWH(10, 10, 80, 20)),
        ],
      );
      await harness.pump(NoteObjectLayerMode.view);

      await harness.tap(const Offset(40, 20));

      expect(harness.links, isEmpty);
      expect(harness.beneathTaps, 1);
    });

    testWidgets('edit mode selects a link instead of following it', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteLinkObject(
            id: 'l',
            bounds: Rect.fromLTWH(10, 10, 80, 20),
            target: 'page:3',
          ),
        ],
      );
      await harness.pump();

      await harness.tap(const Offset(40, 20));

      expect(harness.links, isEmpty);
      expect(harness.controller.selectedIds, {'l'});
    });
  });

  group('selection in edit mode', () {
    testWidgets('a tap selects the topmost; empty space deselects', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(150, 140, 100, 80)),
        ],
      );
      await harness.pump();

      await harness.tap(const Offset(170, 160));
      expect(harness.controller.selectedIds, {'b'});
      await harness.tap(const Offset(110, 110));
      expect(harness.controller.selectedIds, {'a'});
      expect(harness.beneathTaps, 0);

      await harness.tap(const Offset(350, 450));
      expect(harness.controller.selectedIds, isEmpty);
      // The empty tap was watched, not taken.
      expect(harness.beneathTaps, 1);
      expect(harness.history.undoLength, 0);
    });

    testWidgets('nobody is interactive and scopes show the selection', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(10, 300, 40, 40)),
        ],
      );
      await harness.pump();

      await harness.tap(const Offset(150, 140));

      expect(harness.log.scopes['a']!.selected, isTrue);
      expect(harness.log.scopes['b']!.selected, isFalse);
      expect(harness.log.scopes['a']!.interactive, isFalse);
      expect(harness.log.taps, isEmpty);
    });

    testWidgets('shift-tap adds and removes', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(10, 300, 40, 40)),
        ],
      );
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await harness.tap(const Offset(30, 320));
      expect(harness.controller.selectedIds, {'a', 'b'});
      await harness.tap(const Offset(150, 140));
      expect(harness.controller.selectedIds, {'b'});
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    });

    testWidgets('a swipe or a second finger on empty space keeps it', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await harness.drag(const Offset(300, 400), const Offset(0, -60));
      expect(harness.controller.selectedIds, {'a'});

      final first = await tester.startGesture(
        harness.at(const Offset(300, 400)),
        pointer: 7,
      );
      final second = await tester.startGesture(
        harness.at(const Offset(350, 400)),
        pointer: 8,
      );
      await first.up();
      await second.up();
      await tester.pump();

      expect(harness.controller.selectedIds, {'a'});
    });
  });

  group('with a double-tap ancestor', () {
    // A page that zooms on double tap, around the layer.
    Future<(LayerHarness, List<String>)> pumpZoomable(
      WidgetTester tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      final doubleTaps = <String>[];
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => doubleTaps.add('zoom'),
              child: SizedBox.fromSize(
                size: testPageSize,
                child: harness.layer(NoteObjectLayerMode.edit),
              ),
            ),
          ),
        ),
      );

      return (harness, doubleTaps);
    }

    testWidgets('selects at once and keeps double taps on objects', (
      tester,
    ) async {
      final (harness, doubleTaps) = await pumpZoomable(tester);

      await tester.tapAt(harness.at(const Offset(150, 140)));
      await tester.pump();
      expect(harness.controller.selectedIds, {'a'});
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(harness.at(const Offset(150, 140)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(harness.controller.editingId, 'a');
      expect(doubleTaps, isEmpty);
    });

    testWidgets('leaves double taps on empty space to it', (tester) async {
      final (harness, doubleTaps) = await pumpZoomable(tester);

      await harness.doubleTap(const Offset(350, 450));

      expect(doubleTaps, ['zoom']);
    });
  });

  group('with a zooming ancestor', () {
    testWidgets('two fingers pan the page even when one is on an object', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      final zoom = TransformationController();
      addTearDown(zoom.dispose);
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: SizedBox.fromSize(
              size: testPageSize,
              child: InteractiveViewer(
                transformationController: zoom,
                boundaryMargin: const EdgeInsets.all(500),
                child: harness.layer(NoteObjectLayerMode.edit),
              ),
            ),
          ),
        ),
      );
      final onObject = await tester.startGesture(
        harness.at(const Offset(150, 140)),
        pointer: 1,
      );
      final onPage = await tester.startGesture(
        harness.at(const Offset(250, 300)),
        pointer: 2,
      );

      // The layer follows one finger only, so the zoom recognizer wins the
      // other outright and then takes both. Side by side in small steps, as
      // touch hardware reports them, so this is not read as a pinch first.
      for (var step = 0; step < 48; step++) {
        await onObject.moveBy(const Offset(0, 2));
        await onPage.moveBy(const Offset(0, 2));
        await tester.pump();
      }
      await onObject.up();
      await onPage.up();
      await tester.pumpAndSettle();

      expect(zoom.value.getTranslation().y, greaterThan(20));
      expect(harness.object('a'), box('a'));
      expect(harness.controller.selectedIds, isEmpty);
      expect(harness.history.undoLength, 0);
    });

    testWidgets('a second finger does not interrupt a running drag', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      final dragging = await tester.startGesture(
        harness.at(const Offset(150, 140)),
        pointer: 1,
      );
      await dragging.moveBy(const Offset(40, 0));

      final resting = await tester.startGesture(
        harness.at(const Offset(300, 400)),
        pointer: 2,
      );
      await dragging.moveBy(const Offset(40, 0));
      await resting.up();
      await dragging.up();
      await tester.pump();

      expect(harness.object('a').bounds.left, closeTo(180, 0.001));
      expect(harness.controller.selectedIds, {'a'});
      expect(harness.history.undoLength, 1);
    });
  });

  group('moving', () {
    testWidgets('one drag is one undo step', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      await harness.drag(const Offset(150, 140), const Offset(60, 40));

      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(160, 140, 100, 80)),
      );
      expect(harness.controller.selectedIds, {'a'});
      expect(harness.history.undoLength, 1);
      expect(harness.history.undoLabel, 'Move');
      harness.history.undo();
      expect(harness.object('a'), box('a'));
      harness.history.redo();
      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(160, 140, 100, 80)),
      );
    });

    testWidgets('dragging a selection moves it all but the locked', (
      tester,
    ) async {
      const a = Rect.fromLTWH(50, 50, 60, 40);
      const b = Rect.fromLTWH(200, 200, 60, 40);
      const c = Rect.fromLTWH(50, 300, 60, 40);
      final harness = LayerHarness(
        tester,
        objects: [
          box('a', bounds: a),
          box('b', bounds: b),
          box('c', bounds: c, locked: true),
        ],
      )..controller.selectAll();
      await harness.pump();

      await harness.drag(a.center, const Offset(30, 30));

      expect(
        harness.object('a').bounds,
        rectCloseTo(a.shift(const Offset(30, 30))),
      );
      expect(
        harness.object('b').bounds,
        rectCloseTo(b.shift(const Offset(30, 30))),
      );
      expect(harness.object('c').bounds, c);
      expect(harness.controller.selectedIds, {'a', 'b', 'c'});
      expect(harness.history.undoLength, 1);
    });

    testWidgets('the middle of the group stays on the page', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      await harness.drag(const Offset(150, 140), const Offset(2000, 2000));
      expect(
        harness.object('a').bounds.center,
        offsetCloseTo(const Offset(400, 500)),
      );

      harness.history.undo();
      await tester.pump();
      await harness.drag(const Offset(150, 140), const Offset(-2000, -2000));
      expect(harness.object('a').bounds.center, offsetCloseTo(Offset.zero));
    });

    testWidgets('a cancelled pointer puts everything back', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      final gesture = await tester.startGesture(
        harness.at(const Offset(150, 140)),
      );
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(harness.object('a').bounds.left, closeTo(150, 0.001));
      await gesture.cancel();
      await tester.pump();

      expect(harness.object('a'), box('a'));
      expect(harness.history.undoLength, 0);
      expect(harness.controller.isGestureActive, isFalse);
    });

    testWidgets('a reload during a drag ends it without more steps', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      final gesture = await tester.startGesture(
        harness.at(const Offset(150, 140)),
      );
      await gesture.moveBy(const Offset(30, 0));

      harness.controller.replaceAll([box('a')]);
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.up();
      await tester.pump();

      expect(harness.object('a'), box('a'));
      expect(harness.history.undoLength, 0);
    });

    testWidgets('a mouse drag moves after the smallest movement', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      final gesture = await tester.startGesture(
        harness.at(const Offset(150, 140)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(6, 0));
      await gesture.up();
      await tester.pump();

      expect(harness.object('a').bounds.left, closeTo(106, 0.001));
    });
  });

  group('with a scrolling ancestor', () {
    Future<(LayerHarness, ScrollController)> pumpScrolling(
      WidgetTester tester,
      List<NoteObject> objects,
    ) async {
      final harness = LayerHarness(tester, objects: objects);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        noteTestHost(
          Center(
            child: SizedBox.fromSize(
              size: testPageSize,
              child: SingleChildScrollView(
                controller: scroll,
                child: NoteObjectLayer(
                  controller: harness.controller,
                  registry: harness.registry,
                  size: const Size(400, 1000),
                  mode: NoteObjectLayerMode.edit,
                ),
              ),
            ),
          ),
        ),
      );

      return (harness, scroll);
    }

    testWidgets('dragging an object moves it instead of scrolling', (
      tester,
    ) async {
      final (harness, scroll) = await pumpScrolling(tester, [box('a')]);

      await harness.drag(const Offset(150, 140), const Offset(0, 120));

      expect(scroll.offset, 0);
      expect(harness.object('a').bounds.top, closeTo(220, 0.001));
    });

    testWidgets('dragging empty space scrolls', (tester) async {
      final (harness, scroll) = await pumpScrolling(tester, [box('a')]);

      await harness.drag(const Offset(300, 400), const Offset(0, -150));

      expect(scroll.offset, greaterThan(0));
      expect(harness.object('a'), box('a'));
    });

    testWidgets('dragging a locked object scrolls', (tester) async {
      final locked = box('a', locked: true);
      final (harness, scroll) = await pumpScrolling(tester, [locked]);

      await harness.drag(const Offset(150, 140), const Offset(0, -150));

      expect(scroll.offset, greaterThan(0));
      expect(harness.object('a'), locked);
      expect(harness.history.undoLength, 0);
    });
  });

  group('grips', () {
    Finder grip(String name) =>
        find.byKey(ValueKey('note-object-handle-$name'));

    testWidgets('one unlocked selection has nine, others none', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(10, 300, 40, 40)),
        ],
      );
      await harness.pump();
      expect(grip('top'), findsNothing);

      await harness.tap(const Offset(150, 140));
      for (final handle in NoteObjectHandle.values) {
        expect(grip(handle.name), findsOneWidget);
      }
      expect(
        harness.centerOfKey('note-object-handle-bottomRight'),
        offsetCloseTo(const Offset(200, 180)),
      );
      expect(
        harness.centerOfKey('note-object-handle-rotate'),
        offsetCloseTo(const Offset(150, 68)),
      );

      harness.controller.selectAll();
      await tester.pump();
      expect(grip('top'), findsNothing);
      expect(grip('rotate'), findsNothing);
    });

    testWidgets('a corner grip resizes and keeps the far corner', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await harness.drag(const Offset(200, 180), const Offset(30, 20));

      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(100, 100, 130, 100)),
      );
      expect(harness.history.undoLength, 1);
      expect(harness.history.undoLabel, 'Resize');
      harness.history.undo();
      expect(harness.object('a'), box('a'));
    });

    testWidgets('a grip touched off-center does not jump', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await harness.drag(const Offset(207, 187), const Offset(30, 20));

      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(100, 100, 130, 100)),
      );
    });

    testWidgets('resizing a turned object follows its own axes', (
      tester,
    ) async {
      // 100x60 turned a quarter: its right side is at the bottom.
      final harness = LayerHarness(
        tester,
        objects: [
          box(
            'a',
            bounds: const Rect.fromLTWH(150, 150, 100, 60),
            rotation: math.pi / 2,
          ),
        ],
      );
      await harness.pump();
      await harness.tap(const Offset(200, 180));
      expect(
        harness.centerOfKey('note-object-handle-right'),
        offsetCloseTo(const Offset(200, 230)),
      );

      await harness.drag(const Offset(200, 230), const Offset(0, 40));

      final resized = harness.object('a');
      expect(
        resized.bounds,
        rectCloseTo(const Rect.fromLTWH(130, 170, 140, 60)),
      );
      expect(resized.rotation, math.pi / 2);
    });

    testWidgets('resizing stops at 12 units', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await harness.drag(const Offset(200, 180), const Offset(-300, -300));

      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(100, 100, 12, 12)),
      );
    });

    testWidgets('the rotation grip turns about the center', (tester) async {
      // Center (200, 230); the grip starts 32 above the top side.
      final harness = LayerHarness(
        tester,
        objects: [box('a', bounds: const Rect.fromLTWH(150, 200, 100, 60))],
      );
      await harness.pump();
      await harness.tap(const Offset(200, 230));

      await harness.drag(const Offset(200, 168), const Offset(62, 62));

      expect(harness.object('a').rotation, closeTo(math.pi / 2, 0.001));
      expect(
        harness.object('a').bounds,
        const Rect.fromLTWH(150, 200, 100, 60),
      );
      expect(harness.history.undoLength, 1);
      expect(harness.history.undoLabel, 'Rotate');
      harness.history.undo();
      expect(harness.object('a').rotation, 0);
    });

    testWidgets('the rotation grip moves below an object at the top', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: [box('a', bounds: const Rect.fromLTWH(150, 2, 100, 60))],
      );
      await harness.pump();
      await harness.tap(const Offset(200, 32));

      expect(
        harness.centerOfKey('note-object-handle-rotate'),
        offsetCloseTo(const Offset(200, 94)),
      );

      await harness.drag(const Offset(200, 94), const Offset(-62, -62));
      expect(harness.object('a').rotation, closeTo(math.pi / 2, 0.001));
    });

    testWidgets('a tiny object still moves from its middle', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: [box('a', bounds: const Rect.fromLTWH(100, 100, 20, 20))],
      );
      await harness.pump();
      await harness.tap(const Offset(110, 110));

      await harness.drag(const Offset(110, 110), const Offset(40, 0));

      expect(
        harness.object('a').bounds,
        rectCloseTo(const Rect.fromLTWH(140, 100, 20, 20)),
      );
    });

    testWidgets('tapping a grip changes nothing', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await harness.tap(const Offset(150, 140));

      await harness.tap(const Offset(200, 180));

      expect(harness.controller.selectedIds, {'a'});
      expect(harness.object('a'), box('a'));
    });

    testWidgets('the lock badge takes the given colour', (tester) async {
      final controller = NoteObjectController(
        objects: [box('a', locked: true)],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        noteTestHost(
          NoteObjectLayer(
            controller: controller,
            registry: testRegistry(),
            size: testPageSize,
            mode: NoteObjectLayerMode.edit,
            lockColor: const Color(0xFF00AA00),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('note-object-lock-a')),
        paints..circle(color: const Color(0xFF00AA00)),
      );
    });

    testWidgets('a locked object shows a lock and cannot be transformed', (
      tester,
    ) async {
      final locked = box('a', locked: true);
      final harness = LayerHarness(tester, objects: [locked]);
      await harness.pump();
      expect(find.byKey(const ValueKey('note-object-lock-a')), findsOneWidget);

      await harness.tap(const Offset(150, 140));
      expect(harness.controller.selectedIds, {'a'});
      expect(grip('bottomRight'), findsNothing);
      await harness.drag(const Offset(150, 140), const Offset(60, 0));
      await harness.drag(const Offset(200, 180), const Offset(60, 0));

      expect(harness.object('a'), locked);
      expect(harness.history.undoLength, 0);

      await harness.pump(NoteObjectLayerMode.view);
      expect(find.byKey(const ValueKey('note-object-lock-a')), findsNothing);
    });
  });

  group('inline editing', () {
    testWidgets('a double tap edits: only that widget reacts', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(10, 300, 80, 60)),
        ],
      );
      await harness.pump();

      await harness.doubleTap(const Offset(150, 140));

      expect(harness.controller.editingId, 'a');
      expect(harness.log.scopes['a']!.editing, isTrue);
      expect(harness.log.scopes['a']!.interactive, isTrue);
      expect(harness.log.scopes['b']!.editing, isFalse);
      expect(harness.log.scopes['b']!.interactive, isFalse);
      expect(harness.log.taps, isEmpty);

      await harness.tap(const Offset(150, 140));
      expect(harness.log.taps, ['a']);
      expect(harness.controller.editingId, 'a');
    });

    testWidgets('the second tap only has to start in time', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await tester.tapAt(harness.at(const Offset(150, 140)));
      await tester.pump(const Duration(milliseconds: 200));

      // Pressed inside the window, lifted after it.
      final second = await tester.startGesture(
        harness.at(const Offset(150, 140)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await second.up();
      await tester.pump(const Duration(milliseconds: 400));

      expect(harness.controller.editingId, 'a');
    });

    testWidgets('two slow taps do not edit', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      await harness.tap(const Offset(150, 140));
      await harness.tap(const Offset(150, 140));

      expect(harness.controller.editingId, isNull);
    });

    testWidgets('selecting something else ends editing', (tester) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(10, 300, 80, 60)),
        ],
      );
      await harness.pump();
      await harness.doubleTap(const Offset(150, 140));

      await harness.tap(const Offset(40, 320));

      expect(harness.controller.editingId, isNull);
      expect(harness.controller.selectedIds, {'b'});
    });

    testWidgets('a covered editor gets no touches meant for what covers it', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: [
          box('a'),
          box('b', bounds: const Rect.fromLTWH(150, 140, 100, 80)),
        ],
      )..controller.beginEditing('a');
      await harness.pump();

      await harness.tap(const Offset(170, 160));

      expect(harness.controller.selectedIds, {'b'});
      expect(harness.controller.editingId, isNull);
      expect(harness.log.taps, isEmpty);
    });

    testWidgets('an edited widget without gestures can still be dragged', (
      tester,
    ) async {
      final harness = LayerHarness(
        tester,
        objects: const [
          NoteArrowObject(id: 'r', bounds: Rect.fromLTWH(100, 100, 100, 60)),
        ],
      );
      await harness.pump();
      await harness.doubleTap(const Offset(150, 130));
      expect(harness.controller.editingId, 'r');

      await harness.drag(const Offset(150, 130), const Offset(0, 50));

      expect(harness.object('r').bounds.top, closeTo(150, 0.001));
      expect(harness.controller.editingId, 'r');
    });

    testWidgets('drags inside an edited widget that wants them stay there', (
      tester,
    ) async {
      // A table selects a cell range by dragging, with a plain pan gesture.
      final harness = LayerHarness(tester, objects: [box('a')]);
      var panned = Offset.zero;
      harness.registry.register(
        'box',
        decoder: BoxObject.decode,
        builder: (context, object, scope) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: scope.interactive
              ? (details) => panned += details.delta
              : null,
          child: const SizedBox.expand(),
        ),
      );
      harness.controller.beginEditing('a');
      await harness.pump();

      await harness.drag(const Offset(150, 140), const Offset(80, 0));

      expect(panned.dx, greaterThan(0));
      expect(harness.object('a'), box('a'));
      expect(harness.history.undoLength, 0);
    });

    testWidgets('a widget can ask to be edited', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();

      harness.log.scopes['a']!.onRequestEdit!();
      await tester.pump();

      expect(harness.controller.editingId, 'a');
    });
  });

  group('lifecycle', () {
    testWidgets('leaving edit mode ends editing', (tester) async {
      final harness = LayerHarness(tester, objects: [box('a')])
        ..controller.beginEditing('a');
      await harness.pump();

      await harness.pump(NoteObjectLayerMode.view);
      await tester.pump();

      expect(harness.controller.editingId, isNull);
    });

    testWidgets('leaving edit mode mid-drag keeps the move as one step', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      final gesture = await tester.startGesture(
        harness.at(const Offset(150, 140)),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();

      await harness.pump(NoteObjectLayerMode.passThrough);
      await gesture.moveBy(const Offset(40, 0));
      await gesture.up();
      await tester.pump();

      expect(harness.object('a').bounds.left, closeTo(140, 0.001));
      expect(harness.controller.isGestureActive, isFalse);
      expect(harness.history.undoLength, 1);
    });

    testWidgets('removing the layer mid-drag keeps the move as one step', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      final gesture = await tester.startGesture(
        harness.at(const Offset(150, 140)),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();

      await tester.pumpWidget(noteTestHost(const SizedBox()));
      await tester.pump();
      await gesture.up();

      expect(harness.controller.isGestureActive, isFalse);
      expect(harness.history.undoLength, 1);
    });

    testWidgets('a pending double tap does not outlive the layer', (
      tester,
    ) async {
      final harness = LayerHarness(tester, objects: [box('a')]);
      await harness.pump();
      await tester.tapAt(harness.at(const Offset(150, 140)));

      // No pending-timer failure when the tree goes away at once.
      await tester.pumpWidget(noteTestHost(const SizedBox()));
    });
  });

  group('accessibility', () {
    testWidgets('names objects, selection, grips and locks', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = LayerHarness(
        tester,
        objects: [
          box('a', bounds: const Rect.fromLTWH(10, 300, 80, 60), locked: true),
          const NoteArrowObject(
            id: 'r',
            bounds: Rect.fromLTWH(100, 100, 100, 60),
          ),
        ],
      )..controller.select('r');
      await harness.pump();

      expect(find.bySemanticsLabel('Object (box)'), findsOneWidget);
      expect(find.bySemanticsLabel('Arrow'), findsOneWidget);
      expect(find.bySemanticsLabel('Locked'), findsOneWidget);
      expect(find.bySemanticsLabel('Resize handle'), findsNWidgets(8));
      expect(find.bySemanticsLabel('Rotate handle'), findsOneWidget);
      Semantics slotSemantics(String id) => tester.widget<Semantics>(
        find
            .descendant(
              of: find.byKey(ValueKey('note-object-$id')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(slotSemantics('r').properties.selected, isTrue);
      expect(slotSemantics('a').properties.selected, isFalse);

      // Assistive technology can select without a pointer.
      slotSemantics('a').properties.onTap!();
      expect(harness.controller.selectedIds, {'a'});
      semantics.dispose();
    });
  });
}
