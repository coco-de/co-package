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

NoteMaskObject _full() => NoteMaskObject(
  id: 'm1',
  bounds: const Rect.fromLTWH(10, 20, 100, 50),
  shape: NoteMaskShape.stroke,
  points: const [Offset(0, 0.5), Offset(0.5, 0.25), Offset(1, 0.5)],
  thickness: 30,
  fill: const NoteMaskFill.dots(color: Color(0xFF112233)),
  fillOpacity: 0.5,
  revealed: true,
  scope: NoteMaskScope.document,
  rotation: 0.3,
  opacity: 0.7,
  locked: true,
);

NoteMaskObject _decode(Map<String, Object?> payload) =>
    NoteMaskObject.fromPayload(
      const NoteObjectBase(
        id: 'm',
        bounds: Rect.fromLTWH(0, 0, 10, 10),
        rotation: 0,
        opacity: 1,
        locked: false,
      ),
      payload,
    );

void main() {
  test('is the mask kind', () {
    expect(_full().kind, 'mask');
    expect(NoteMaskObject.kindName, 'mask');
  });

  test('round-trips through a JSON document and the registry', () {
    final document = jsonDecode(jsonEncode(_full().toJson()));

    final decoded = _registry().decode(document);

    expect(decoded, _full());
    expect(decoded.hashCode, _full().hashCode);
  });

  test('enum names are the persisted ones', () {
    expect(
      [for (final shape in NoteMaskShape.values) shape.name],
      ['rect', 'stroke'],
    );
    expect(
      [for (final scope in NoteMaskScope.values) scope.name],
      ['page', 'document'],
    );
  });

  test('a malformed payload is clamped and defaulted, never thrown', () {
    final mask = _decode({
      'shape': 'blob',
      'points': [
        {'x': 'a', 'y': 1},
        3,
        {'x': 0.2, 'y': 7},
      ],
      'thickness': 'wide',
      'fillOpacity': 9,
      'revealed': 'yes',
      'scope': 'galaxy',
      'fill': 7,
    });

    expect(mask.shape, NoteMaskShape.rect);
    expect(mask.points, const [Offset(0.2, 1)]);
    expect(mask.thickness, NoteMaskObject.defaultThickness);
    expect(mask.fillOpacity, 1);
    expect(mask.revealed, isFalse);
    expect(mask.scope, NoteMaskScope.page);
    expect(mask.fill, const NoteMaskFill());
  });

  test('an empty payload gives a plain page mask', () {
    final mask = _decode({});

    expect(mask.shape, NoteMaskShape.rect);
    expect(mask.revealed, isFalse);
    expect(mask.points, isEmpty);
  });

  test('a stroke without a valid point still covers its bounds', () {
    final mask = _decode({
      'shape': 'stroke',
      'points': ['bad'],
    });

    expect(mask.shape, NoteMaskShape.rect);
    expect(mask.geometryIn(mask.bounds), isA<NoteMaskRectGeometry>());
  });

  test('thickness and fill opacity are clamped into range', () {
    final thin = NoteMaskObject(
      id: 'a',
      bounds: Rect.zero,
      thickness: 0,
      fillOpacity: -1,
    );
    final wide = thin.copyWith(thickness: 500, fillOpacity: 2);

    expect(thin.thickness, NoteMaskObject.minThickness);
    expect(thin.fillOpacity, 0);
    expect(wide.thickness, NoteMaskObject.maxThickness);
    expect(wide.fillOpacity, 1);
    expect(
      NoteMaskObject.clampThickness(double.nan),
      NoteMaskObject.defaultThickness,
    );
  });

  test('the points are copied and cannot be changed afterwards', () {
    final source = [const Offset(0.1, 0.1)];
    final mask = NoteMaskObject(
      id: 'a',
      bounds: Rect.zero,
      shape: NoteMaskShape.stroke,
      points: source,
    );

    source.add(const Offset(0.9, 0.9));

    expect(mask.points, hasLength(1));
    expect(() => mask.points.add(Offset.zero), throwsUnsupportedError);
  });

  group('a stroke from page points', () {
    const page = [Offset(20, 30), Offset(70, 40), Offset(120, 80)];

    test('has bounds grown by half the thickness', () {
      final mask = NoteMaskObject.stroke(
        id: 's',
        pagePoints: page,
        thickness: 20,
      );

      expect(mask.shape, NoteMaskShape.stroke);
      expect(mask.bounds, const Rect.fromLTRB(10, 20, 130, 90));
      expect(mask.points.first, Offset.zero);
      expect(mask.points.last, const Offset(1, 1));
    });

    test('reads the same page points back', () {
      final mask = NoteMaskObject.stroke(id: 's', pagePoints: page);

      for (var i = 0; i < page.length; i++) {
        expect((mask.pagePoints[i] - page[i]).distance, lessThan(1e-6));
      }
    });

    test('a flat line sits in the middle of its box', () {
      final mask = NoteMaskObject.stroke(
        id: 's',
        pagePoints: const [Offset(10, 50), Offset(90, 50)],
        thickness: 10,
      );

      expect(mask.points, const [Offset(0, 0.5), Offset(1, 0.5)]);
      expect(mask.bounds, const Rect.fromLTRB(5, 45, 95, 55));
    });

    test('moving and resizing the bounds carries the stroke along', () {
      final mask = NoteMaskObject.stroke(
        id: 's',
        pagePoints: const [Offset(10, 10), Offset(50, 30)],
        thickness: 10,
      );

      final moved = mask.withBase(
        bounds: mask.bounds.shift(const Offset(100, 0)),
      );
      final grown = mask.withBase(bounds: const Rect.fromLTWH(0, 0, 210, 110));

      expect(moved.pagePoints.first, const Offset(110, 10));
      expect(grown.pagePoints, const [Offset(5, 5), Offset(205, 105)]);
      expect(grown.thickness, 10);
    });

    test('a box thinner than the stroke draws it thinner, inside', () {
      final mask = NoteMaskObject.stroke(
        id: 's',
        pagePoints: const [Offset(10, 50), Offset(90, 50)],
        thickness: 30,
      ).withBase(bounds: const Rect.fromLTWH(0, 0, 100, 12));

      final geometry = mask.geometryIn(mask.bounds) as NoteMaskStrokeGeometry;

      expect(geometry.width, 12);
      expect(geometry.coverage.top, greaterThanOrEqualTo(0));
      expect(geometry.coverage.bottom, lessThanOrEqualTo(12));
    });

    test('needs at least one point', () {
      expect(
        () => NoteMaskObject.stroke(id: 's', pagePoints: const []),
        throwsArgumentError,
      );
    });
  });

  test('withBase changes only the shared fields', () {
    final moved = _full().withBase(
      bounds: const Rect.fromLTWH(1, 2, 3, 4),
      rotation: 1,
      opacity: 0.2,
      locked: false,
    );

    expect(moved.bounds, const Rect.fromLTWH(1, 2, 3, 4));
    expect(moved.rotation, 1);
    expect(moved.opacity, 0.2);
    expect(moved.locked, isFalse);
    expect(moved.points, _full().points);
    expect(moved.revealed, isTrue);
    expect(moved.id, 'm1');
  });

  test('copyWith without arguments is equal, any change is not', () {
    final mask = _full();

    expect(mask.copyWith(), mask);
    expect(mask.copyWith(revealed: false), isNot(mask));
    expect(mask.copyWith(id: 'm2'), isNot(mask));
    expect(mask.copyWith(points: const [Offset.zero]), isNot(mask));
    expect(mask.copyWith(scope: NoteMaskScope.page), isNot(mask));
    expect(mask.copyWith(fill: const NoteMaskFill()), isNot(mask));
    expect(mask.copyWith(locked: false), isNot(mask));
  });

  test('an image fill is exposed for preloading', () {
    final mask = _full().copyWith(fill: const NoteMaskFill.image('a.png'));

    expect(mask.imageSource, 'a.png');
    expect(_full().imageSource, isNull);
  });
}
