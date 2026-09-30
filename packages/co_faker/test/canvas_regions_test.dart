import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30);
  CoFaker ko([int seed = 1]) => CoFaker(locale: 'ko', seed: seed, now: now);

  void expectInside(CoFakeCanvasMark mark, CoRegionRect rect) {
    for (final p in mark.points) {
      expect(p.x, inInclusiveRange(rect.left, rect.right));
      expect(p.y, inInclusiveRange(rect.top, rect.bottom));
    }
  }

  group('canvasMarks regions', () {
    test('marks stay inside caller rectangles', () {
      const rects = <String, CoRegionRect>{
        'forehead': (left: 0.3, top: 0.1, right: 0.7, bottom: 0.25),
        'chin': (left: 0.42, top: 0.66, right: 0.58, bottom: 0.74),
      };
      final faker = ko();
      for (var i = 0; i < 30; i++) {
        final marks = faker.clinic.canvasMarks(regionRects: rects);
        final pen = marks.where((m) => m.tool == 'pen').toList();
        expect(pen, isNotEmpty);
        for (final m in pen) {
          expect(rects.keys, contains(m.region));
          expectInside(m, rects[m.region]!);
        }
      }
      final one = faker.clinic.canvasMarks(
        regionRects: rects,
        regions: ['chin'],
      );
      expect(one.first.region, 'chin');
      expect(
        () => faker.clinic.canvasMarks(regionRects: rects, regions: ['nose']),
        throwsArgumentError,
      );
      expect(
        () => faker.clinic.canvasMarks(regionRects: const {}),
        throwsArgumentError,
      );
    });

    test('faceFront uses the built-in 3:4 chart layout', () {
      final faker = ko();
      final marks = faker.clinic.canvasMarks(
        template: 'faceFront',
        regions: ['leftCheek', 'lips', 'forehead'],
      );
      for (final m in marks.where((m) => m.tool == 'pen')) {
        expectInside(m, CoFakerClinic.faceFrontRegions[m.region]!);
      }
      expect(
        CoFakerClinic.faceFrontRegions.keys,
        containsAll(CoFakerClinic.faceRegions.keys),
      );
    });

    test('the default face template output is unchanged', () {
      final a = ko(9).clinic.canvasMarks();
      final b = ko(9).clinic.canvasMarks(template: 'face');
      expect(a.toString(), b.toString());
      for (final m in a.where((m) => m.tool == 'pen')) {
        final c = CoFakerClinic.faceRegions[m.region]!;
        final cy =
            m.points.map((p) => p.y).reduce((x, y) => x + y) / m.points.length;
        expect(cy, closeTo(c.$2, 0.02));
      }
    });
  });
}
