import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

void main() {
  const area = Rect.fromLTWH(10, 10, 100, 40);

  test('the centre-line box shrinks by half the thickness', () {
    expect(
      NoteMaskGeometry.centerLineBox(area, 20),
      const Rect.fromLTRB(20, 20, 100, 40),
    );
  });

  test('a box thinner than the stroke collapses to its middle', () {
    final box = NoteMaskGeometry.centerLineBox(area, 90);

    expect(box.top, 30);
    expect(box.bottom, 30);
    expect(box.left, 55);
    expect(box.right, 65);
  });

  test('fractions and points convert both ways and clamp', () {
    const box = Rect.fromLTRB(0, 10, 100, 10);

    expect(
      NoteMaskGeometry.toFraction(const Offset(25, 99), box),
      const Offset(0.25, 0.5),
    );
    expect(NoteMaskGeometry.toFraction(const Offset(-5, 10), box).dx, 0);
    expect(
      NoteMaskGeometry.fromFraction(const Offset(0.25, 0.5), box),
      const Offset(25, 10),
    );
    expect(
      NoteMaskGeometry.clampFraction(const Offset(2, double.nan)),
      const Offset(1, 0.5),
    );
  });

  test('reading a fraction rejects anything but two finite numbers', () {
    expect(
      NoteMaskGeometry.fractionFromJson({'x': 0.5, 'y': 4}),
      const Offset(0.5, 1),
    );
    expect(NoteMaskGeometry.fractionFromJson({'x': 'a', 'y': 1}), isNull);
    expect(NoteMaskGeometry.fractionFromJson({'x': 1}), isNull);
    expect(
      NoteMaskGeometry.fractionFromJson({'x': double.infinity, 'y': 1}),
      isNull,
    );
    expect(NoteMaskGeometry.fractionFromJson(3), isNull);
  });

  test('the bounding box of points, and of none', () {
    expect(
      NoteMaskGeometry.boundsOf(const [
        Offset(5, 8),
        Offset(1, 20),
        Offset(9, 2),
      ]),
      const Rect.fromLTRB(1, 2, 9, 20),
    );
    expect(NoteMaskGeometry.boundsOf(const []), Rect.zero);
  });

  test('a rectangle contains its points and, with slop, a margin', () {
    const rect = NoteMaskRectGeometry(area, cornerRadius: 4);

    expect(rect.contains(const Offset(50, 30)), isTrue);
    expect(rect.contains(const Offset(7, 30)), isFalse);
    expect(rect.contains(const Offset(7, 30), slop: 5), isTrue);
    expect(rect.coverage, area);
  });

  test('a strip covers a band along the line with flat ends', () {
    final strip = NoteMaskQuadGeometry.strip(
      const Offset(10, 10),
      const Offset(90, 90),
      20,
    );

    expect(strip.contains(const Offset(50, 50)), isTrue);
    expect(strip.contains(const Offset(80, 20)), isFalse);
    // Beyond an end along the axis: the ends are flat, not round.
    expect(strip.contains(const Offset(96, 96)), isFalse);
    expect(strip.contains(const Offset(94, 94), slop: 8), isTrue);
  });

  test('a strip of zero length is a square around the point', () {
    final strip = NoteMaskQuadGeometry.strip(
      const Offset(50, 50),
      const Offset(50, 50),
      10,
    );

    expect(strip.coverage, const Rect.fromLTRB(45, 45, 55, 55));
  });

  test('a stroke is hit within half its width of the line', () {
    const stroke = NoteMaskStrokeGeometry([
      Offset(10, 10),
      Offset(100, 10),
      Offset(100, 100),
    ], 10);

    expect(stroke.contains(const Offset(50, 14)), isTrue);
    expect(stroke.contains(const Offset(104, 60)), isTrue);
    expect(stroke.contains(const Offset(50, 60)), isFalse);
    expect(stroke.contains(const Offset(50, 22), slop: 8), isTrue);
    expect(stroke.coverage, const Rect.fromLTRB(5, 5, 105, 105));
  });

  test('a single point stroke is a dot, an empty one nothing', () {
    const dot = NoteMaskStrokeGeometry([Offset(10, 10)], 8);
    const nothing = NoteMaskStrokeGeometry([], 8);

    expect(dot.contains(const Offset(13, 10)), isTrue);
    expect(dot.contains(const Offset(20, 10)), isFalse);
    expect(nothing.contains(Offset.zero), isFalse);
  });

  test('geometries compare by value', () {
    expect(const NoteMaskRectGeometry(area), const NoteMaskRectGeometry(area));
    expect(
      const NoteMaskStrokeGeometry([Offset.zero], 2),
      isNot(const NoteMaskStrokeGeometry([Offset.zero], 3)),
    );
    expect(
      NoteMaskQuadGeometry.strip(Offset.zero, const Offset(9, 0), 4),
      NoteMaskQuadGeometry.strip(Offset.zero, const Offset(9, 0), 4),
    );
  });
}
