import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

import 'overlay_test_support.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _clear = 0;

NoteMaskObject _rectMask({
  NoteMaskFill fill = const NoteMaskFill.solid(_red),
  double fillOpacity = 1,
  bool revealed = false,
}) => NoteMaskObject(
  id: 'm',
  bounds: const Rect.fromLTWH(20, 20, 100, 60),
  fill: fill,
  fillOpacity: fillOpacity,
  revealed: revealed,
);

void main() {
  test('a hidden mask covers its bounds and nothing else', () async {
    final pixels = await pixelsOf(_rectMask(), const [
      Offset(70, 50),
      Offset(10, 50),
      Offset(150, 50),
    ]);

    expect(pixels, [_red.toARGB32(), _clear, _clear]);
  });

  test('a revealed mask leaves only a faint outline', () async {
    final pixels = await pixelsOf(_rectMask(revealed: true), const [
      Offset(70, 50),
      Offset(20, 50),
    ]);

    expect(pixels.first, _clear);
    expect(pixels.last >>> 24, inExclusiveRange(0, 255));
  });

  test('the fill opacity fades the cover', () async {
    final pixels = await pixelsOf(_rectMask(fillOpacity: 0.5), const [
      Offset(70, 50),
    ]);

    expect(pixels.single >>> 24, closeTo(128, 2));
  });

  test('stripes and dots add the pattern colour inside the shape', () async {
    for (final fill in const [
      NoteMaskFill.stripes(color: _red, patternColor: _blue),
      NoteMaskFill.dots(color: _red, patternColor: _blue),
    ]) {
      final across = [for (var x = 21; x < 119; x++) Offset(x.toDouble(), 45)];
      final pixels = await pixelsOf(_rectMask(fill: fill), [
        ...across,
        const Offset(10, 45),
        const Offset(70, 10),
      ]);

      final inside = pixels.take(across.length).toSet();
      expect(inside, contains(_red.toARGB32()), reason: fill.kind.name);
      expect(inside, contains(_blue.toARGB32()), reason: fill.kind.name);
      expect(pixels.skip(across.length), [_clear, _clear]);
    }
  });

  test('an image fill uses the picture, or the plain colour', () async {
    final mask = _rectMask(
      fill: const NoteMaskFill.image('cover', color: _red),
    );
    final picture = solidImage(_blue);

    final loaded = await pixelsOf(
      mask,
      const [Offset(70, 50), Offset(10, 50)],
      context: NoteObjectPaintContext(
        imageLookup: (source) => source == 'cover' ? picture : null,
      ),
    );
    final missing = await pixelsOf(mask, const [Offset(70, 50)]);

    expect(loaded, [_blue.toARGB32(), _clear]);
    expect(missing, [_red.toARGB32()]);
    picture.dispose();
  });

  test('a stroke mask covers the line, not its whole box', () async {
    final mask = NoteMaskObject.stroke(
      id: 's',
      pagePoints: const [Offset(20, 20), Offset(180, 80)],
      thickness: 20,
      fill: const NoteMaskFill.solid(_red),
    );

    final pixels = await pixelsOf(mask, const [
      Offset(100, 50),
      Offset(170, 20),
      Offset(30, 80),
    ]);

    expect(pixels, [_red.toARGB32(), _clear, _clear]);
  });

  test('a patterned stroke is clipped to the stroke', () async {
    final mask = NoteMaskObject.stroke(
      id: 's',
      pagePoints: const [Offset(20, 50), Offset(180, 50)],
      thickness: 20,
      fill: const NoteMaskFill.stripes(color: _red, patternColor: _blue),
    );

    final pixels = await pixelsOf(mask, [
      for (var x = 20; x < 180; x++) Offset(x.toDouble(), 20),
      for (var x = 20; x < 180; x++) Offset(x.toDouble(), 80),
    ]);

    expect(pixels.toSet(), {_clear});
  });

  test('a revealed stroke keeps only its rim', () async {
    final mask = NoteMaskObject.stroke(
      id: 's',
      pagePoints: const [Offset(30, 50), Offset(170, 50)],
      thickness: 30,
    ).copyWith(revealed: true);

    final pixels = await pixelsOf(mask, const [
      Offset(100, 50),
      Offset(100, 35),
    ]);

    expect(pixels.first, _clear);
    expect(pixels.last >>> 24, greaterThan(0));
  });

  test('a straight tape covers a diagonal band', () async {
    final tape = NoteTapeObject.straight(
      id: 't',
      pageStart: const Offset(20, 20),
      pageEnd: const Offset(180, 80),
      thickness: 16,
      fill: const NoteMaskFill.solid(_blue),
    );

    final pixels = await pixelsOf(tape, const [
      Offset(100, 50),
      Offset(170, 20),
    ]);

    expect(pixels, [_blue.toARGB32(), _clear]);
  });

  test('a peeled tape leaves only its outline', () async {
    final tape = NoteTapeObject(
      id: 't',
      bounds: const Rect.fromLTWH(20, 20, 100, 60),
      fill: const NoteMaskFill.solid(_blue),
      revealed: true,
    );

    final pixels = await pixelsOf(tape, const [Offset(70, 50), Offset(70, 20)]);

    expect(pixels.first, _clear);
    expect(pixels.last >>> 24, greaterThan(0));
  });
}
