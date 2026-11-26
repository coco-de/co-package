import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/objects/objects.dart';

import 'support/objects_test_support.dart';

void main() {
  group('rotation', () {
    test('positive angles turn clockwise on screen (y grows downward)', () {
      expect(
        NoteObjectGeometry.rotateVector(const Offset(1, 0), math.pi / 2),
        offsetCloseTo(const Offset(0, 1)),
      );
      expect(
        NoteObjectGeometry.rotateVector(const Offset(0, 1), math.pi / 2),
        offsetCloseTo(const Offset(-1, 0)),
      );
    });

    test('rotateAround keeps the center fixed', () {
      const center = Offset(10, 20);

      expect(
        NoteObjectGeometry.rotateAround(center, center, 1.3),
        offsetCloseTo(center),
      );
      expect(
        NoteObjectGeometry.rotateAround(const Offset(20, 20), center, math.pi),
        offsetCloseTo(const Offset(0, 20)),
      );
    });
  });

  group('contains', () {
    const bounds = Rect.fromLTWH(100, 100, 120, 40);

    // Points given in the object's own frame, relative to its center.
    const inside = [
      Offset.zero,
      Offset(59, 19),
      Offset(-59, -19),
      Offset(59, -19),
      Offset(-30, 10),
    ];
    const outside = [
      Offset(61, 0),
      Offset(-61, 0),
      Offset(0, 21),
      Offset(0, -21),
      Offset(61, 21),
    ];

    for (final degrees in [0, 30, 45, 90, 135, 180, -60, 270, 400]) {
      test('follows a rotation of $degrees degrees', () {
        final radians = degrees * math.pi / 180;
        Offset onPage(Offset local) =>
            bounds.center + NoteObjectGeometry.rotateVector(local, radians);

        for (final point in inside) {
          expect(
            NoteObjectGeometry.contains(bounds, radians, onPage(point)),
            isTrue,
            reason: '$point should be inside',
          );
        }
        for (final point in outside) {
          expect(
            NoteObjectGeometry.contains(bounds, radians, onPage(point)),
            isFalse,
            reason: '$point should be outside',
          );
        }
      });
    }

    test('a wide box turned a quarter is tall', () {
      // Its corners were at x 100..220; turned, it spans x 140..180, y 60..180.
      expect(
        NoteObjectGeometry.contains(bounds, math.pi / 2, const Offset(160, 65)),
        isTrue,
      );
      expect(
        NoteObjectGeometry.contains(
          bounds,
          math.pi / 2,
          const Offset(105, 120),
        ),
        isFalse,
      );
    });

    test('edges count, and a mirrored rect is read as positive', () {
      expect(
        NoteObjectGeometry.contains(bounds, 0, bounds.bottomRight),
        isTrue,
      );
      expect(
        NoteObjectGeometry.contains(
          const Rect.fromLTRB(220, 140, 100, 100),
          0,
          const Offset(150, 120),
        ),
        isTrue,
      );
    });
  });

  test('corners and boundingBox of a turned square', () {
    const bounds = Rect.fromLTWH(-1, -1, 2, 2);
    final box = NoteObjectGeometry.boundingBox(bounds, math.pi / 4);

    expect(
      box,
      rectCloseTo(Rect.fromCircle(center: Offset.zero, radius: math.sqrt2)),
    );
    expect(
      NoteObjectGeometry.corners(bounds, math.pi / 2).first,
      offsetCloseTo(const Offset(1, -1)),
    );
    expect(
      NoteObjectGeometry.boundingBox(const Rect.fromLTWH(5, 6, 7, 8), 0),
      const Rect.fromLTWH(5, 6, 7, 8),
    );
  });

  test('normalizeAngle wraps into (-pi, pi]', () {
    expect(NoteObjectGeometry.normalizeAngle(0), 0);
    expect(NoteObjectGeometry.normalizeAngle(math.pi), math.pi);
    expect(NoteObjectGeometry.normalizeAngle(-math.pi), math.pi);
    expect(NoteObjectGeometry.normalizeAngle(2 * math.pi), closeTo(0, 1e-12));
    expect(
      NoteObjectGeometry.normalizeAngle(3 * math.pi / 2),
      closeTo(-math.pi / 2, 1e-12),
    );
    expect(
      NoteObjectGeometry.normalizeAngle(-5 * math.pi / 2),
      closeTo(-math.pi / 2, 1e-12),
    );
    expect(NoteObjectGeometry.normalizeAngle(double.nan).isNaN, isTrue);
  });

  test('normalizeRect mirrors negative sizes and applies the minimum', () {
    expect(
      NoteObjectGeometry.normalizeRect(const Rect.fromLTRB(10, 30, 0, 20)),
      const Rect.fromLTRB(0, 20, 10, 30),
    );
    expect(
      NoteObjectGeometry.normalizeRect(
        const Rect.fromLTWH(10, 10, 2, 40),
        minimum: 12,
      ),
      const Rect.fromLTWH(5, 10, 12, 40),
    );
  });

  test('handlePoint places grips on the rotated bounds', () {
    const bounds = Rect.fromLTWH(0, 0, 100, 40);

    expect(
      NoteObjectGeometry.handlePoint(bounds, 0, NoteObjectHandle.bottomRight),
      const Offset(100, 40),
    );
    expect(
      NoteObjectGeometry.handlePoint(
        bounds,
        math.pi / 2,
        NoteObjectHandle.right,
      ),
      offsetCloseTo(const Offset(50, 70)),
    );
  });

  group('resize', () {
    const bounds = Rect.fromLTWH(100, 100, 200, 100);

    test('moves only the sides the grip names', () {
      final cases = {
        NoteObjectHandle.right: (
          const Offset(350, 999),
          const Rect.fromLTRB(100, 100, 350, 200),
        ),
        NoteObjectHandle.left: (
          const Offset(80, -999),
          const Rect.fromLTRB(80, 100, 300, 200),
        ),
        NoteObjectHandle.top: (
          const Offset(-999, 50),
          const Rect.fromLTRB(100, 50, 300, 200),
        ),
        NoteObjectHandle.bottom: (
          const Offset(999, 260),
          const Rect.fromLTRB(100, 100, 300, 260),
        ),
        NoteObjectHandle.topLeft: (
          const Offset(120, 130),
          const Rect.fromLTRB(120, 130, 300, 200),
        ),
        NoteObjectHandle.bottomRight: (
          const Offset(400, 300),
          const Rect.fromLTRB(100, 100, 400, 300),
        ),
      };
      for (final MapEntry(key: handle, value: (pointer, expected))
          in cases.entries) {
        expect(
          NoteObjectGeometry.resize(
            bounds: bounds,
            rotation: 0,
            handle: handle,
            pointer: pointer,
          ),
          rectCloseTo(expected),
          reason: handle.name,
        );
      }
    });

    test('never brings sides closer than the minimum', () {
      final smallest = NoteObjectGeometry.resize(
        bounds: bounds,
        rotation: 0,
        handle: NoteObjectHandle.bottomRight,
        pointer: const Offset(-500, -500),
      );

      expect(smallest, rectCloseTo(const Rect.fromLTWH(100, 100, 12, 12)));
      expect(
        NoteObjectGeometry.resize(
          bounds: bounds,
          rotation: 0,
          handle: NoteObjectHandle.topLeft,
          pointer: const Offset(999, 999),
        ),
        rectCloseTo(const Rect.fromLTWH(288, 188, 12, 12)),
      );
    });

    for (final degrees in [30, 90, 137, -45, 200]) {
      for (final handle in NoteObjectHandle.values.where((h) => h.isResize)) {
        test('${handle.name} at $degrees deg keeps the opposite side', () {
          final radians = degrees * math.pi / 180;
          final opposite = NoteObjectHandle.values.firstWhere(
            (other) =>
                other.isResize &&
                other.horizontal == -handle.horizontal &&
                other.vertical == -handle.vertical,
          );
          final anchor = NoteObjectGeometry.handlePoint(
            bounds,
            radians,
            opposite,
          );
          // Pull the grip outward, along its own direction, by 30 units.
          final grip = NoteObjectGeometry.handlePoint(bounds, radians, handle);
          final outward = NoteObjectGeometry.rotateVector(
            Offset(handle.horizontal * 30, handle.vertical * 30),
            radians,
          );

          final next = NoteObjectGeometry.resize(
            bounds: bounds,
            rotation: radians,
            handle: handle,
            pointer: grip + outward,
          );

          expect(next.width, closeTo(200 + 30 * handle.horizontal.abs(), 1e-6));
          expect(next.height, closeTo(100 + 30 * handle.vertical.abs(), 1e-6));
          expect(
            NoteObjectGeometry.handlePoint(next, radians, opposite),
            offsetCloseTo(anchor, 1e-6),
          );
          expect(
            NoteObjectGeometry.handlePoint(next, radians, handle),
            offsetCloseTo(grip + outward, 1e-6),
          );
        });
      }
    }

    test('the rotation grip resizes nothing', () {
      expect(
        NoteObjectGeometry.resize(
          bounds: bounds,
          rotation: 1,
          handle: NoteObjectHandle.rotate,
          pointer: Offset.zero,
        ),
        bounds,
      );
      expect(NoteObjectHandle.rotate.isResize, isFalse);
      expect(
        NoteObjectHandle.values.where((handle) => handle.isResize),
        hasLength(8),
      );
    });
  });
}
