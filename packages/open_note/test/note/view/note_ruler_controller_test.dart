import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/view/view.dart';

import 'note_view_test_support.dart';

void expectOffset(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 1e-6), reason: '$actual');
  expect(actual.dy, closeTo(expected.dy, 1e-6), reason: '$actual');
}

void main() {
  // Top edge at y = 80, bottom edge at y = 120, x from 0 to 200.
  NoteRulerController ruler({double angle = 0, bool visible = true}) =>
      NoteRulerController(
        center: const Offset(100, 100),
        angle: angle,
        length: 200,
        width: 40,
        visible: visible,
      );

  group('snap', () {
    test('projects a point near an edge onto it', () {
      expectOffset(ruler().snap(const Offset(150, 85)), const Offset(150, 80));
      expectOffset(ruler().snap(const Offset(150, 75)), const Offset(150, 80));
      expectOffset(ruler().snap(const Offset(40, 126)), const Offset(40, 120));
    });

    test('leaves far points alone', () {
      expect(ruler().snap(const Offset(150, 60)), const Offset(150, 60));
      expect(ruler().snap(const Offset(150, 133)), const Offset(150, 133));
      expectOffset(
        ruler().snap(const Offset(150, 132)),
        const Offset(150, 120),
      );
    });

    test('honours the threshold', () {
      const point = Offset(150, 70);

      expect(ruler().snap(point, threshold: 5), point);
      expectOffset(ruler().snap(point, threshold: 10), const Offset(150, 80));
    });

    test('does not snap past the ends', () {
      expect(ruler().snap(const Offset(250, 80)), const Offset(250, 80));
      expect(ruler().snap(const Offset(-1, 80)), const Offset(-1, 80));
      expectOffset(ruler().snap(const Offset(200, 82)), const Offset(200, 80));
    });

    test('does nothing while hidden', () {
      expect(
        ruler(visible: false).snap(const Offset(150, 81)),
        const Offset(150, 81),
      );
      expect(ruler(visible: false).edgeNear(const Offset(150, 80)), isNull);
    });

    test('prefers the top edge when both are as near', () {
      final narrow = NoteRulerController(
        center: const Offset(100, 100),
        length: 200,
        width: 20,
        visible: true,
      );

      expect(narrow.edgeNear(const Offset(100, 100)), NoteRulerEdge.top);
      expectOffset(narrow.snap(const Offset(100, 100)), const Offset(100, 90));
    });

    test('works on a vertical ruler', () {
      final upright = ruler(angle: math.pi / 2);

      expectOffset(
        upright.snap(const Offset(125, 150)),
        const Offset(120, 150),
      );
      expectOffset(upright.snap(const Offset(75, 150)), const Offset(80, 150));
      expect(upright.edgeNear(const Offset(125, 150)), NoteRulerEdge.top);
      expect(upright.edgeNear(const Offset(75, 150)), NoteRulerEdge.bottom);
    });

    test('works at 45 degrees', () {
      final diagonal = NoteRulerController(
        center: Offset.zero,
        angle: math.pi / 4,
        length: 200,
        width: 20,
        visible: true,
      );
      const half = 5 * math.sqrt2;

      expectOffset(
        diagonal.snap(const Offset(10, 10)),
        const Offset(10 + half, 10 - half),
      );
    });

    test('ignores non-finite points', () {
      const bad = Offset(double.nan, 80);

      expect(ruler().edgeNear(bad), isNull);
    });
  });

  group('edges', () {
    test('edgeSegment gives both ends in order', () {
      final (start, end) = ruler().edgeSegment(NoteRulerEdge.top);

      expectOffset(start, const Offset(0, 80));
      expectOffset(end, const Offset(200, 80));
      final (bottomStart, bottomEnd) = ruler().edgeSegment(
        NoteRulerEdge.bottom,
      );
      expectOffset(bottomStart, const Offset(0, 120));
      expectOffset(bottomEnd, const Offset(200, 120));
    });

    test('projectOnto keeps a stroke on one edge', () {
      final bar = ruler();

      expectOffset(
        bar.projectOnto(NoteRulerEdge.bottom, const Offset(90, 20)),
        const Offset(90, 120),
      );
      expectOffset(
        bar.projectOnto(NoteRulerEdge.top, const Offset(900, 20)),
        const Offset(200, 80),
      );
      expectOffset(
        bar.projectOnto(
          NoteRulerEdge.top,
          const Offset(900, 20),
          clampToLength: false,
        ),
        const Offset(900, 80),
      );
    });

    test('direction and normal follow the angle', () {
      final upright = ruler(angle: math.pi / 2);

      expectOffset(upright.direction, const Offset(0, 1));
      expectOffset(upright.normal, const Offset(-1, 0));
    });
  });

  group('state', () {
    test('wraps angles into (-pi, pi]', () {
      expect(
        NoteRulerController.normalizeAngle(3 * math.pi / 2),
        closeTo(-math.pi / 2, 1e-12),
      );
      expect(
        NoteRulerController.normalizeAngle(-math.pi),
        closeTo(math.pi, 1e-12),
      );
      expect(
        NoteRulerController.normalizeAngle(5 * math.pi / 2),
        closeTo(math.pi / 2, 1e-12),
      );
    });

    test('degrees are a line angle from 0 to 180', () {
      expect(ruler(angle: -math.pi / 4).degrees, closeTo(135, 1e-9));
      expect(ruler(angle: math.pi / 2).degrees, closeTo(90, 1e-9));
    });

    test('clamps length and width', () {
      final bar = NoteRulerController(length: 1, width: 1000);

      expect(bar.length, 60);
      expect(bar.width, 200);
      bar.setLength(1e9);
      expect(bar.length, 5000);
    });

    test('edits notify only on change', () {
      final bar = ruler();
      final counter = NotifyCounter(bar);

      bar.setCenter(const Offset(100, 100));
      bar.setAngle(0);
      bar.setLength(200);
      bar.setVisible(true);
      bar.setUnit(NoteRulerUnit.cm);
      expect(counter.count, 0);

      bar.moveBy(const Offset(10, -5));
      bar.rotateBy(math.pi / 6);
      bar.setLength(300);
      bar.toggle();
      bar.setUnit(NoteRulerUnit.inch);
      expect(counter.count, 5);
      expectOffset(bar.center, const Offset(110, 95));
      expect(bar.angle, closeTo(math.pi / 6, 1e-12));
      expect(bar.visible, isFalse);
    });

    test('ignores non-finite edits', () {
      final bar = ruler();

      bar.setCenter(const Offset(double.nan, 1));
      bar.setAngle(double.infinity);
      bar.setLength(double.nan);

      expect(bar.center, const Offset(100, 100));
      expect(bar.angle, 0);
      expect(bar.length, 200);
    });

    test('formats the length in the unit', () {
      final bar = NoteRulerController(length: 72);

      expect(bar.lengthText, '2.5');
      bar.setUnit(NoteRulerUnit.inch);
      expect(bar.lengthText, '1.00');
      bar.setUnit(NoteRulerUnit.mm);
      expect(bar.lengthText, '25');
      bar.setUnit(NoteRulerUnit.pt);
      expect(bar.lengthText, '72');
    });

    test('does nothing after dispose', () {
      final bar = ruler()..dispose();

      bar.moveBy(const Offset(1, 1));
      bar.rotateBy(1);
      bar.setLength(100);
      bar.toggle();
      bar.setUnit(NoteRulerUnit.pt);

      expect(bar.center, const Offset(100, 100));
      expect(bar.visible, isTrue);
    });
  });

  group('json', () {
    test('round-trips', () {
      final bar = ruler(angle: 0.5)..setUnit(NoteRulerUnit.inch);

      final restored = NoteRulerController.fromJson(bar.toJson());

      expect(restored.toJson(), bar.toJson());
      expect(bar.toJson()['unit'], 'in');
      expect(restored.unit, NoteRulerUnit.inch);
    });

    test('survives junk', () {
      for (final junk in <Object?>[null, 'x', 3]) {
        final restored = NoteRulerController.fromJson(junk);

        expect(restored.visible, isFalse);
        expect(restored.length, NoteRulerController.defaultLength);
        expect(restored.unit, NoteRulerUnit.cm);
      }
      final repaired = NoteRulerController.fromJson({
        'center': 'middle',
        'angle': 'x',
        'length': -1,
        'unit': 'furlong',
        'visible': 'yes',
      });

      expect(repaired.center, const Offset(300, 300));
      expect(repaired.length, 60);
      expect(repaired.unit, NoteRulerUnit.cm);
    });
  });

  group('NoteRulerUnit', () {
    test('converts to and from points', () {
      expect(NoteRulerUnit.inch.toPoints(2), 144);
      expect(NoteRulerUnit.mm.fromPoints(72), closeTo(25.4, 1e-9));
      expect(NoteRulerUnit.cm.toPoints(2.54), closeTo(72, 1e-9));
      expect(NoteRulerUnit.pt.fromPoints(12), 12);
    });

    test('fromCode falls back for unknown codes', () {
      expect(NoteRulerUnit.fromCode('in'), NoteRulerUnit.inch);
      expect(NoteRulerUnit.fromCode('pt'), NoteRulerUnit.pt);
      expect(NoteRulerUnit.fromCode('inch'), NoteRulerUnit.cm);
      expect(NoteRulerUnit.fromCode(null, NoteRulerUnit.mm), NoteRulerUnit.mm);
    });

    test('point ticks every 10, numbers every 50', () {
      final ticks = NoteRulerUnit.pt.ticks(120);

      expect(ticks, hasLength(13));
      expect(ticks.first, const NoteRulerTick(position: 0, label: '0'));
      expect(ticks[5].label, '50');
      expect(ticks[10].label, '100');
      expect(ticks.where((tick) => tick.isMajor), hasLength(3));
      expect(ticks.last.position, 120);
    });

    test('inch ticks every eighth', () {
      final ticks = NoteRulerUnit.inch.ticks(72);

      expect(ticks, hasLength(9));
      expect(ticks[4].position, 36);
      expect(ticks[4].isMajor, isFalse);
      expect(ticks[8].label, '1');
    });

    test('centimetre ticks every millimetre', () {
      final ticks = NoteRulerUnit.cm.ticks(NoteRulerUnit.cm.toPoints(2));

      expect(ticks, hasLength(21));
      expect(
        [
          for (final tick in ticks)
            if (tick.isMajor) tick.label,
        ],
        ['0', '1', '2'],
      );
    });

    test('millimetre numbers count by ten', () {
      final ticks = NoteRulerUnit.mm.ticks(NoteRulerUnit.mm.toPoints(20));

      expect(
        [
          for (final tick in ticks)
            if (tick.isMajor) tick.label,
        ],
        ['0', '10', '20'],
      );
    });

    test('no ticks for a bad length', () {
      for (final length in [0.0, -3.0, double.nan, double.infinity]) {
        expect(NoteRulerUnit.pt.ticks(length), isEmpty);
      }
    });
  });
}
