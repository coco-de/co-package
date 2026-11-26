import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

NoteObjectRegistry _registry() {
  final registry = NoteObjectRegistry();
  registerNoteStudyObjects(registry);

  return registry;
}

NoteTapeObject _full() => NoteTapeObject(
  id: 't1',
  bounds: const Rect.fromLTWH(5, 5, 200, 80),
  shape: NoteTapeShape.straight,
  start: const Offset(0.1, 0.2),
  end: const Offset(0.9, 0.8),
  thickness: 18,
  fill: const NoteMaskFill.solid(Color(0xFFAA0000)),
  fillOpacity: 0.8,
  revealed: true,
  rotation: -0.2,
  opacity: 0.9,
  locked: true,
);

NoteTapeObject _decode(Map<String, Object?> payload) =>
    NoteTapeObject.fromPayload(
      const NoteObjectBase(
        id: 't',
        bounds: Rect.fromLTWH(0, 0, 40, 20),
        rotation: 0,
        opacity: 1,
        locked: false,
      ),
      payload,
    );

void main() {
  test('round-trips through a JSON document and the registry', () {
    final document = jsonDecode(jsonEncode(_full().toJson()));

    final decoded = _registry().decode(document);

    expect(decoded, _full());
    expect(decoded.hashCode, _full().hashCode);
    expect(_full().kind, 'tape');
  });

  test('enum names are the persisted ones', () {
    expect(
      [for (final shape in NoteTapeShape.values) shape.name],
      ['straight', 'rect'],
    );
  });

  test('a malformed payload is clamped and defaulted, never thrown', () {
    final tape = _decode({
      'shape': 'knot',
      'start': {'x': -3, 'y': 5},
      'end': 'there',
      'thickness': -1,
      'fillOpacity': 'full',
      'revealed': 1,
      'fill': 'blue',
    });

    expect(tape.shape, NoteTapeShape.rect);
    expect(tape.start, const Offset(0, 1));
    expect(tape.end, NoteTapeObject.defaultEnd);
    expect(tape.thickness, NoteMaskObject.minThickness);
    expect(tape.fillOpacity, 1);
    expect(tape.revealed, isFalse);
    expect(tape.fill, NoteTapeObject.defaultFill);
  });

  test('a straight tape without both ends covers its bounds', () {
    final tape = _decode({
      'shape': 'straight',
      'start': {'x': 0, 'y': 0},
    });

    expect(tape.shape, NoteTapeShape.rect);
  });

  test('a straight tape from page points keeps them and fits its bounds', () {
    final tape = NoteTapeObject.straight(
      id: 't',
      pageStart: const Offset(100, 20),
      pageEnd: const Offset(20, 60),
      thickness: 20,
    );

    expect(tape.shape, NoteTapeShape.straight);
    expect(tape.bounds, const Rect.fromLTRB(10, 10, 110, 70));
    expect(tape.pageStart, const Offset(100, 20));
    expect(tape.pageEnd, const Offset(20, 60));
    final strip = tape.geometryIn(tape.bounds);
    expect(tape.bounds.inflate(1e-6).contains(strip.coverage.topLeft), isTrue);
    expect(strip.coverage.right, lessThanOrEqualTo(tape.bounds.right + 1e-6));
    expect(strip.coverage.bottom, lessThanOrEqualTo(tape.bounds.bottom + 1e-6));
  });

  test('resizing the bounds stretches the tape', () {
    final tape = NoteTapeObject.straight(
      id: 't',
      pageStart: const Offset(20, 50),
      pageEnd: const Offset(100, 50),
      thickness: 20,
    ).withBase(bounds: const Rect.fromLTWH(0, 0, 220, 20));

    expect(tape.pageStart, const Offset(10, 10));
    expect(tape.pageEnd, const Offset(210, 10));
  });

  test('geometry follows the shape', () {
    final tape = _full();

    expect(tape.geometryIn(tape.bounds), isA<NoteMaskQuadGeometry>());
    expect(
      tape.copyWith(shape: NoteTapeShape.rect).geometryIn(tape.bounds),
      isA<NoteMaskRectGeometry>(),
    );
  });

  test('thickness is limited to the mask range', () {
    final tape = _full().copyWith(thickness: 999);

    expect(tape.thickness, NoteMaskObject.maxThickness);
  });

  test('copyWith and withBase keep everything else', () {
    final tape = _full();

    expect(tape.copyWith(), tape);
    expect(tape.copyWith(revealed: false), isNot(tape));
    expect(tape.copyWith(start: Offset.zero), isNot(tape));
    final moved = tape.withBase(bounds: const Rect.fromLTWH(0, 0, 1, 1));
    expect(moved.start, tape.start);
    expect(moved.fill, tape.fill);
    expect(moved.revealed, isTrue);
  });
}
