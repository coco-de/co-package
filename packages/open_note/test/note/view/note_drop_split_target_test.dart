import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import '../support/note_test_host.dart';

const _source = ValueKey<String>('source');
const _data = NoteDragData(noteId: 'n', pageIndex: 2);

// The target spans x 100–800 and y 0–600 of the 800 x 600 surface.
const Map<NoteDropSide, Offset> _zonePoints = {
  NoteDropSide.left: Offset(150, 300),
  NoteDropSide.right: Offset(750, 300),
  NoteDropSide.top: Offset(450, 50),
  NoteDropSide.bottom: Offset(450, 550),
};
const Offset _middle = Offset(450, 300);
const Map<NoteDropSide, String> _labels = {
  NoteDropSide.left: 'Open on the left',
  NoteDropSide.right: 'Open on the right',
  NoteDropSide.top: 'Open on top',
  NoteDropSide.bottom: 'Open at the bottom',
};

Widget _host({
  required void Function(NoteDragData data, NoteDropSide side) onDrop,
  bool Function(NoteDragData data)? canAccept,
  Set<NoteDropSide> sides = NoteDropSplitTarget.allSides,
  VoidCallback? onChildTap,
}) => noteTestHost(
  Row(
    children: [
      const SizedBox(
        width: 100,
        child: Draggable<NoteDragData>(
          data: _data,
          feedback: SizedBox(width: 10, height: 10),
          child: ColoredBox(
            key: _source,
            color: Color(0xFF000000),
            child: SizedBox.expand(),
          ),
        ),
      ),
      Expanded(
        child: NoteDropSplitTarget(
          onDrop: onDrop,
          canAccept: canAccept,
          sides: sides,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChildTap,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ],
  ),
);

Future<TestGesture> _dragTo(WidgetTester tester, Offset target) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(_source)),
  );
  await gesture.moveBy(const Offset(30, 0));
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pump();

  return gesture;
}

Finder _zonesFilled(Color color) => find.byWidgetPredicate((widget) {
  if (widget is! DecoratedBox) return false;
  final decoration = widget.decoration;

  return decoration is BoxDecoration && decoration.color == color;
});

void main() {
  const style = NoteViewStyle();

  test('zone rectangles', () {
    const size = Size(800, 600);

    expect(
      NoteDropSplitTarget.zoneRect(NoteDropSide.left, size),
      const Rect.fromLTRB(0, 0, 200, 600),
    );
    expect(
      NoteDropSplitTarget.zoneRect(NoteDropSide.right, size),
      const Rect.fromLTRB(600, 0, 800, 600),
    );
    expect(
      NoteDropSplitTarget.zoneRect(NoteDropSide.top, size),
      const Rect.fromLTRB(200, 0, 600, 150),
    );
    expect(
      NoteDropSplitTarget.zoneRect(NoteDropSide.bottom, size),
      const Rect.fromLTRB(200, 450, 600, 600),
    );
    expect(
      NoteDropSplitTarget.zoneRect(
        NoteDropSide.top,
        size,
        sides: {NoteDropSide.top},
      ),
      const Rect.fromLTRB(0, 0, 800, 150),
    );
    expect(
      NoteDropSplitTarget.zoneRect(
        NoteDropSide.left,
        size,
        zoneFraction: 3,
      ).width,
      closeTo(360, 1e-9),
    );
  });

  testWidgets('shows nothing at rest and never steals taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(onDrop: (_, _) {}, onChildTap: () => taps++));

    for (final point in [..._zonePoints.values, _middle]) {
      await tester.tapAt(point);
    }

    expect(taps, 5);
    expect(_zonesFilled(style.dropZoneColor), findsNothing);
  });

  for (final side in NoteDropSide.values) {
    testWidgets('highlights and reports a drop on the ${side.name}', (
      tester,
    ) async {
      final drops = <(NoteDragData, NoteDropSide)>[];
      await tester.pumpWidget(
        _host(onDrop: (data, side) => drops.add((data, side))),
      );

      final gesture = await _dragTo(tester, _zonePoints[side]!);

      expect(find.text(_labels[side]!), findsOneWidget);
      expect(_zonesFilled(style.dropZoneActiveColor), findsOneWidget);
      expect(_zonesFilled(style.dropZoneColor), findsNWidgets(3));
      await gesture.up();
      await tester.pump();
      expect(drops, [(_data, side)]);
      expect(find.text(_labels[side]!), findsNothing);
      expect(_zonesFilled(style.dropZoneColor), findsNothing);
    });
  }

  testWidgets('shows the zones in the middle but ignores a drop', (
    tester,
  ) async {
    var drops = 0;
    await tester.pumpWidget(_host(onDrop: (_, _) => drops++));

    final gesture = await _dragTo(tester, _middle);

    expect(_zonesFilled(style.dropZoneColor), findsNWidgets(4));
    expect(_zonesFilled(style.dropZoneActiveColor), findsNothing);
    await gesture.up();
    await tester.pump();
    expect(drops, 0);
    expect(_zonesFilled(style.dropZoneColor), findsNothing);
  });

  testWidgets('follows the pointer from zone to zone and away', (tester) async {
    await tester.pumpWidget(_host(onDrop: (_, _) {}));
    final gesture = await _dragTo(tester, _zonePoints[NoteDropSide.left]!);

    await gesture.moveTo(_zonePoints[NoteDropSide.right]!);
    await tester.pump();
    expect(find.text('Open on the right'), findsOneWidget);
    expect(find.text('Open on the left'), findsNothing);

    await gesture.moveTo(_middle);
    await tester.pump();
    expect(find.text('Open on the right'), findsNothing);
    expect(_zonesFilled(style.dropZoneColor), findsNWidgets(4));

    await gesture.moveTo(const Offset(50, 300));
    await tester.pump();
    expect(_zonesFilled(style.dropZoneColor), findsNothing);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('cancelling the drag hides the zones', (tester) async {
    var drops = 0;
    await tester.pumpWidget(_host(onDrop: (_, _) => drops++));
    final gesture = await _dragTo(tester, _zonePoints[NoteDropSide.top]!);

    await gesture.cancel();
    await tester.pump();

    expect(drops, 0);
    expect(_zonesFilled(style.dropZoneColor), findsNothing);
  });

  testWidgets('canAccept filters notes', (tester) async {
    var drops = 0;
    await tester.pumpWidget(
      _host(onDrop: (_, _) => drops++, canAccept: (data) => false),
    );

    final gesture = await _dragTo(tester, _zonePoints[NoteDropSide.left]!);

    expect(find.text('Open on the left'), findsNothing);
    expect(_zonesFilled(style.dropZoneColor), findsNothing);
    await gesture.up();
    await tester.pump();
    expect(drops, 0);
  });

  testWidgets('offers only the requested sides', (tester) async {
    final drops = <NoteDropSide>[];
    await tester.pumpWidget(
      _host(
        onDrop: (_, side) => drops.add(side),
        sides: {NoteDropSide.left, NoteDropSide.right},
      ),
    );
    expect(
      find.byKey(NoteDropSplitTarget.zoneKey(NoteDropSide.top)),
      findsNothing,
    );

    final top = await _dragTo(tester, _zonePoints[NoteDropSide.top]!);
    expect(_zonesFilled(style.dropZoneColor), findsNWidgets(2));
    await top.up();
    await tester.pump();
    final left = await _dragTo(tester, _zonePoints[NoteDropSide.left]!);
    await left.up();
    await tester.pump();

    expect(drops, [NoteDropSide.left]);
  });

  testWidgets('leaves a middle drop to a target around it', (tester) async {
    final inner = <NoteDropSide>[];
    var outer = 0;
    await tester.pumpWidget(
      noteTestHost(
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Draggable<NoteDragData>(
                data: _data,
                feedback: SizedBox(width: 10, height: 10),
                child: ColoredBox(
                  key: _source,
                  color: Color(0xFF000000),
                  child: SizedBox.expand(),
                ),
              ),
            ),
            Expanded(
              child: DragTarget<NoteDragData>(
                onAcceptWithDetails: (_) => outer++,
                builder: (context, candidates, rejected) => NoteDropSplitTarget(
                  onDrop: (_, side) => inner.add(side),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final middle = await _dragTo(tester, _middle);
    await middle.up();
    await tester.pump();
    final edge = await _dragTo(tester, _zonePoints[NoteDropSide.left]!);
    await edge.up();
    await tester.pump();

    expect(outer, 1);
    expect(inner, [NoteDropSide.left]);
  });

  testWidgets('feeds the layout controller', (tester) async {
    final layout = NoteViewLayoutController(
      panes: const [NoteViewPane(id: 'a', noteId: 'first')],
    );
    await tester.pumpWidget(
      _host(
        onDrop: (data, side) =>
            layout.openBeside(data.noteId, data.pageIndex ?? 0, side: side),
      ),
    );

    final gesture = await _dragTo(tester, _zonePoints[NoteDropSide.bottom]!);
    await gesture.up();

    expect(layout.axis, Axis.vertical);
    expect(layout.panes.map((pane) => pane.noteId), ['first', 'n']);
    expect(layout.panes.last.pageIndex, 2);
  });

  group('NoteDragData', () {
    test('round-trips and compares by value', () {
      expect(NoteDragData.fromJson(_data.toJson()), _data);
      expect(_data.copyWith().hashCode, _data.hashCode);
      expect(_data.copyWith(pageIndex: 3), isNot(_data));
      expect(const NoteDragData(noteId: 'n').toJson(), {'noteId': 'n'});
    });

    test('survives junk', () {
      expect(NoteDragData.fromJson(null), isNull);
      expect(NoteDragData.fromJson({'pageIndex': 1}), isNull);
      expect(
        NoteDragData.fromJson({'noteId': 'n', 'pageIndex': -1}),
        const NoteDragData(noteId: 'n'),
      );
    });

    test('sides know their axis and order', () {
      expect(NoteDropSide.left.axis, Axis.horizontal);
      expect(NoteDropSide.bottom.axis, Axis.vertical);
      expect(NoteDropSide.top.isLeading, isTrue);
      expect(NoteDropSide.right.isLeading, isFalse);
    });
  });
}
