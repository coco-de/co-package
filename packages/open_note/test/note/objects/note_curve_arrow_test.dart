import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_arrow_object.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';

/// 선을 끌어 휘는 곡선 — 기하 · 저장 · 그리기.
void main() {
  /// [point] (page, before rotation) as it appears on screen.
  Offset onScreen(NoteArrowObject arrow, Offset point) =>
      arrow.bounds.center +
      NoteObjectGeometry.rotateVector(
        point - arrow.bounds.center,
        arrow.rotation,
      );

  void expectNear(Offset actual, Offset expected) {
    expect(actual.dx, closeTo(expected.dx, 0.001));
    expect(actual.dy, closeTo(expected.dy, 0.001));
  }

  NoteArrowObject curve() => NoteArrowObject.fromPoints(
    id: 'c',
    from: const Offset(20, 80),
    to: const Offset(180, 80),
    through: const Offset(100, 20),
    headStyle: NoteArrowCap.none,
  );

  test('the bounds fit the curve and the middle passes through', () {
    final arrow = curve();

    expectNear(arrow.bendPoint, const Offset(100, 20));
    expectNear(arrow.startPoint, const Offset(20, 80));
    expect(arrow.bounds.top, closeTo(20, 0.001));
    expect(arrow.bounds.bottom, closeTo(80, 0.001));
  });

  test('bending keeps the ends where they are on screen', () {
    for (final rotation in [0.0, math.pi / 3]) {
      final straight = NoteArrowObject.fromPoints(
        id: 'a',
        from: const Offset(50, 100),
        to: const Offset(150, 100),
      ).copyWith(rotation: rotation);
      final start = onScreen(straight, straight.startPoint);
      final end = onScreen(straight, straight.endPoint);

      final bent = straight.bentThrough(const Offset(100, 40));

      expectNear(onScreen(bent, bent.startPoint), start);
      expectNear(onScreen(bent, bent.endPoint), end);
      expect(bent.bend, isNotNull);
      expect(bent.rotation, rotation);
    }
  });

  test('a curve survives saving; a straight line stores no bend', () {
    final arrow = curve();

    final decoded = NoteArrowObject.decode(
      NoteObjectBase(
        id: arrow.id,
        bounds: arrow.bounds,
        rotation: 0,
        opacity: 1,
        locked: false,
      ),
      arrow.payloadToJson(),
    );

    expect(decoded, arrow);
    expect(arrow.straightened().payloadToJson(), isNot(contains('bend')));
    expect(arrow.withId('d').bend, arrow.bend);
    expect(arrow.straightened(), isNot(arrow));
  });

  test('the curve is drawn through its middle, not along the chord', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    curve()
        .copyWith(width: 4)
        .paintToCanvas(canvas, NoteObjectPaintContext.empty);
    final image = await recorder.endRecording().toImage(200, 100);
    final data = (await image.toByteData())!;
    image.dispose();
    bool inked(int x, int y) => data.getUint8((y * 200 + x) * 4 + 3) > 128;

    expect(inked(100, 20), isTrue);
    expect(inked(100, 80), isFalse);
    expect(inked(21, 79), isTrue);
  });

  test('curve bounds include the extremes between the ends', () {
    final bounds = NoteArrowObject.fromPoints(
      id: 'x',
      from: const Offset(0, 0),
      to: const Offset(10, 0),
      through: const Offset(100, 0),
    ).bounds;

    expect(bounds.right, greaterThan(99.9));
  });
}
