import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_painter.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import 'overlay_test_support.dart';

NoteMaskObject _mask() =>
    NoteMaskObject(id: 'm', bounds: const Rect.fromLTWH(0, 0, 200, 100));

/// A diagonal stroke from the bottom-left to the top-right of 200 x 100.
NoteMaskObject _strokeMask() => NoteMaskObject.stroke(
  id: 's',
  pagePoints: const [Offset(10, 90), Offset(190, 10)],
  thickness: 20,
);

NoteMaskCoverPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<NoteMaskCoverPainter>()
    .single;

void main() {
  testWidgets('a tap reveals the mask and a second tap covers it', (
    tester,
  ) async {
    final changes = <NoteObject>[];
    var mask = _mask();
    Widget build() => boxed(
      NoteMaskView(
        mask: mask,
        scope: NoteObjectViewScope(onChanged: changes.add),
      ),
    );
    await tester.pumpWidget(build());

    await tester.tapAt(const Offset(100, 50));
    mask = changes.single as NoteMaskObject;
    expect(mask.revealed, isTrue);
    expect(mask.id, 'm');

    await tester.pumpWidget(build());
    expect(_painter(tester).revealed, isTrue);
    await tester.tapAt(const Offset(100, 50));

    expect((changes.last as NoteMaskObject).revealed, isFalse);
  });

  testWidgets('does nothing when not interactive', (tester) async {
    final changes = <NoteObject>[];
    await tester.pumpWidget(
      boxed(
        NoteMaskView(
          mask: _mask(),
          scope: NoteObjectViewScope(
            interactive: false,
            onChanged: changes.add,
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(100, 50));

    expect(changes, isEmpty);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('without onChanged a tap is harmless', (tester) async {
    await tester.pumpWidget(boxed(NoteMaskView(mask: _mask())));

    await tester.tapAt(const Offset(100, 50));

    expect(tester.takeException(), isNull);
  });

  testWidgets('announces the action of its state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      boxed(
        NoteMaskView(
          mask: _mask().copyWith(revealed: true),
          scope: NoteObjectViewScope(onChanged: (_) {}),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Cover again')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Show what the mask hides'), findsNothing);
    handle.dispose();
  });

  testWidgets('a stroke mask is only tapped on its stroke', (tester) async {
    final changes = <NoteObject>[];
    await tester.pumpWidget(
      boxed(
        NoteMaskView(
          mask: _strokeMask(),
          scope: NoteObjectViewScope(onChanged: changes.add),
        ),
        size: const Size(200, 100),
      ),
    );

    await tester.tapAt(const Offset(20, 20));
    expect(changes, isEmpty);
    await tester.tapAt(const Offset(100, 50));

    expect(changes, hasLength(1));
  });

  testWidgets('presses beside a stroke reach what lies beneath', (
    tester,
  ) async {
    var beneath = 0;
    final changes = <NoteObject>[];
    await tester.pumpWidget(
      boxed(
        Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => beneath++,
            ),
            NoteMaskView(
              mask: _strokeMask(),
              scope: NoteObjectViewScope(onChanged: changes.add),
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.tapAt(const Offset(100, 50));

    expect(beneath, 1);
    expect(changes, hasLength(1));
  });

  testWidgets('a tape peels and sticks back on tap', (tester) async {
    final changes = <NoteObject>[];
    final tape = NoteTapeObject.straight(
      id: 't',
      pageStart: const Offset(10, 50),
      pageEnd: const Offset(190, 50),
    );
    await tester.pumpWidget(
      boxed(
        NoteTapeView(
          tape: tape,
          scope: NoteObjectViewScope(onChanged: changes.add),
        ),
        size: tape.bounds.size,
      ),
    );

    await tester.tapAt(tape.bounds.size.center(Offset.zero));

    expect((changes.single as NoteTapeObject).revealed, isTrue);
  });

  testWidgets('a tape that is not interactive ignores taps', (tester) async {
    final changes = <NoteObject>[];
    await tester.pumpWidget(
      boxed(
        NoteTapeView(
          tape: NoteTapeObject(id: 't', bounds: Offset.zero & const Size(9, 9)),
          scope: NoteObjectViewScope(
            interactive: false,
            onChanged: changes.add,
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(100, 50));

    expect(changes, isEmpty);
  });

  testWidgets('fills the constraints and maps the stroke into them', (
    tester,
  ) async {
    await tester.pumpWidget(
      boxed(NoteMaskView(mask: _strokeMask()), size: const Size(400, 200)),
    );

    expect(tester.getSize(find.byType(NoteMaskView)), const Size(400, 200));
    final geometry = _painter(tester).geometry as NoteMaskStrokeGeometry;
    expect(geometry.points.first.dx, closeTo(10, 1e-6));
    expect(geometry.points.last.dx, closeTo(390, 1e-6));
  });

  testWidgets('loads an image fill through the resolver', (tester) async {
    final picture = solidImage(const Color(0xFF00FF00));
    final provider = ReadyImageProvider(picture);
    final asked = <String>[];
    await tester.pumpWidget(
      boxed(
        NoteMaskView(
          mask: _mask().copyWith(fill: const NoteMaskFill.image('cover.png')),
          imageResolver: (source) {
            asked.add(source);

            return provider;
          },
        ),
      ),
    );
    await tester.pump();

    expect(asked, contains('cover.png'));
    expect(_painter(tester).image, isNotNull);
    expect(_painter(tester).image!.width, 8);

    await tester.pumpWidget(boxed(NoteMaskView(mask: _mask())));

    expect(_painter(tester).image, isNull);
    picture.dispose();
  });

  testWidgets('keeps the plain colour when the resolver fails', (tester) async {
    await tester.pumpWidget(
      boxed(
        NoteMaskView(
          mask: _mask().copyWith(fill: const NoteMaskFill.image('nope')),
          imageResolver: (source) => throw StateError('no such image'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_painter(tester).image, isNull);
  });

  testWidgets('repaints when the cover changes', (tester) async {
    await tester.pumpWidget(boxed(NoteMaskView(mask: _mask())));
    final before = _painter(tester);
    await tester.pumpWidget(boxed(NoteMaskView(mask: _mask())));
    expect(_painter(tester).shouldRepaint(before), isFalse);

    await tester.pumpWidget(
      boxed(NoteMaskView(mask: _mask().copyWith(revealed: true))),
    );

    expect(_painter(tester).shouldRepaint(before), isTrue);
  });
}
