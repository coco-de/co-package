import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const border = Color(0xFF445566);
  const dest = Rect.fromLTWH(10, 10, 100, 80);
  const lasso = [Offset(0.2, 0.1), Offset(0.8, 0.3), Offset(0.5, 0.9)];

  group('NoteImageCrop', () {
    test('none shows the whole image', () {
      expect(NoteImageCrop.none.isNone, isTrue);
      expect(NoteImageCrop.none.bounds, const Rect.fromLTWH(0, 0, 1, 1));
      expect(NoteImageCrop.rect(0, 0, 1, 1), NoteImageCrop.none);
      expect(NoteImageCrop.none.toJson(), isEmpty);
    });

    test('a rectangle is ordered and clamped', () {
      final crop = NoteImageCrop.rect(1.5, 0.75, -1, 0.25);
      expect(crop, isA<NoteImageRectCrop>());
      expect(crop.bounds, const Rect.fromLTRB(0, 0.25, 1, 0.75));
      expect(
        crop.sourceRect(const Size(200, 100)),
        const Rect.fromLTRB(0, 25, 200, 75),
      );
    });

    test('unusable rectangles become none', () {
      expect(NoteImageCrop.rect(0.5, 0, 0.505, 1), NoteImageCrop.none);
      expect(NoteImageCrop.rect(0, 2, 1, 3), NoteImageCrop.none);
      expect(NoteImageCrop.rect(0, 0, double.nan, 1), NoteImageCrop.none);
      expect(NoteImageCrop.rect(0, double.infinity, 1, 1), NoteImageCrop.none);
    });

    test('a polygon is clamped, cleaned and bounded', () {
      final crop = NoteImageCrop.polygon([
        const Offset(0.2, 0.2),
        const Offset(0.2, 0.2),
        const Offset(double.nan, 0.4),
        const Offset(1.4, 0.2),
        const Offset(0.6, 0.9),
        const Offset(0.2, 0.2),
      ]);
      expect(crop, isA<NoteImagePolygonCrop>());
      expect((crop as NoteImagePolygonCrop).points, const [
        Offset(0.2, 0.2),
        Offset(1, 0.2),
        Offset(0.6, 0.9),
      ]);
      expect(crop.bounds, const Rect.fromLTRB(0.2, 0.2, 1, 0.9));
      expect(() => crop.points.add(Offset.zero), throwsUnsupportedError);
    });

    test('a self-crossing lasso is kept', () {
      final bowtie = NoteImageCrop.polygon(const [
        Offset.zero,
        Offset(1, 1),
        Offset(1, 0),
        Offset(0, 1),
      ]);
      expect(bowtie, isA<NoteImagePolygonCrop>());
    });

    test('unusable polygons become none', () {
      for (final points in const [
        <Offset>[],
        [Offset(0.1, 0.1), Offset(0.9, 0.9)],
        // Collinear: no area.
        [Offset(0.1, 0.1), Offset(0.5, 0.5), Offset(0.9, 0.9)],
        // Degenerate width.
        [Offset(0.5, 0), Offset(0.5, 0.5), Offset(0.5, 1)],
      ]) {
        expect(NoteImageCrop.polygon(points), NoteImageCrop.none);
      }
    });

    test('outlineIn maps the crop bounds onto the destination', () {
      final crop = NoteImageCrop.polygon(lasso);
      final path = crop.outlineIn(dest);
      expect(path.getBounds().left, closeTo(dest.left, 1e-3));
      expect(path.getBounds().right, closeTo(dest.right, 1e-3));
      expect(path.getBounds().top, closeTo(dest.top, 1e-3));
      expect(path.getBounds().bottom, closeTo(dest.bottom, 1e-3));
      expect(
        NoteImageCrop.rect(0, 0, 0.5, 0.5).outlineIn(dest).getBounds(),
        dest,
      );
    });

    test('JSON round trip and lenient reading', () {
      for (final crop in [
        NoteImageCrop.none,
        NoteImageCrop.rect(0.1, 0.2, 0.7, 0.95),
        NoteImageCrop.polygon(lasso),
      ]) {
        expect(NoteImageCrop.fromJson(crop.toJson()), crop);
        expect(crop.hashCode, NoteImageCrop.fromJson(crop.toJson()).hashCode);
      }
      final bad = <Object?>[
        null,
        'crop',
        <String, Object?>{},
        {'rect': 'x'},
        {
          'rect': [0, 0, 1],
        },
        {
          'rect': [0, 0, 1, 'a'],
        },
        {
          'polygon': [0.1, 0.1, 0.5],
        },
        {
          'polygon': [0.1, 'a', 0.5, 0.5, 0.9, 0.1],
        },
        {'polygon': []},
      ];
      for (final value in bad) {
        expect(
          NoteImageCrop.fromJson(value),
          NoteImageCrop.none,
          reason: '$value',
        );
      }
    });
  });

  group('NoteImageStyle', () {
    test('has plain defaults', () {
      final style = NoteImageStyle();
      expect(style, NoteImageStyle.plain);
      expect(style.borderColor, isNull);
      expect(style.borderWidth, 2);
      expect(style.cornerRadius, 0);
      expect(style.opacity, 1);
      expect(style.crop.isNone, isTrue);
      expect(style.hasBorder, isFalse);
      expect(style.encode(), '{}');
    });

    test('clamps numbers', () {
      final style = NoteImageStyle(
        borderWidth: 999,
        cornerRadius: -1,
        opacity: 2,
      );
      expect(style.borderWidth, 50);
      expect(style.cornerRadius, 0);
      expect(style.opacity, 1);
      expect(NoteImageStyle(opacity: double.nan).opacity, 1);
    });

    test('decode(encode(x)) == x', () {
      for (final color in <Color?>[null, border]) {
        for (final crop in [
          NoteImageCrop.none,
          NoteImageCrop.rect(1 / 3, 0.1, 0.9, 2 / 3),
          NoteImageCrop.polygon(lasso),
        ]) {
          for (final n in [0.0, 1 / 3, 1.0]) {
            final style = NoteImageStyle(
              borderColor: color,
              borderWidth: n * 7,
              cornerRadius: n * 13,
              opacity: n,
              crop: crop,
            );
            expect(NoteImageStyle.decode(style.encode()), style);
          }
        }
      }
    });

    test('malformed strings read as the default and never throw', () {
      for (final input in <String?>[
        null,
        '',
        '{',
        '[]',
        'nope',
        '{"crop":5}',
        '{"crop":{"polygon":[null]}}',
        '{"borderColor":"x","opacity":"y"}',
        '[' * 100000,
      ]) {
        expect(
          NoteImageStyle.decode(input),
          NoteImageStyle.plain,
          reason: '$input',
        );
      }
    });

    test('copyWith replaces and clears the border colour', () {
      final style = NoteImageStyle(borderColor: border, cornerRadius: 4);
      expect(style.copyWith(), style);
      expect(style.copyWith(clearBorderColor: true).borderColor, isNull);
      expect(style.copyWith(opacity: 0.2).opacity, 0.2);
      expect(style.hasBorder, isTrue);
      expect(style.copyWith(borderWidth: 0).hasBorder, isFalse);
    });
  });

  group('NoteImageStylePainter', () {
    late Image image;

    setUpAll(() async {
      image = await createTestImage(width: 40, height: 20, cache: false);
    });

    tearDownAll(() => image.dispose());

    List<Invocation> record(NoteImageStyle style, [Rect box = dest]) {
      final canvas = TestRecordingCanvas();
      NoteImageStylePainter.paint(canvas, image, box, style);

      return [for (final call in canvas.invocations) call.invocation];
    }

    test('draws the cropped pixels into the destination', () {
      final calls = record(
        NoteImageStyle(crop: NoteImageCrop.rect(0.25, 0, 0.75, 0.5)),
      );
      final draw = calls.singleWhere((c) => c.memberName == #drawImageRect);
      expect(draw.positionalArguments[1], const Rect.fromLTRB(10, 0, 30, 10));
      expect(draw.positionalArguments[2], dest);
      expect(
        calls.map((c) => c.memberName),
        containsAllInOrder([#save, #clipPath, #drawImageRect, #restore]),
      );
      expect(calls.map((c) => c.memberName), isNot(contains(#saveLayer)));
      expect(calls.map((c) => c.memberName), isNot(contains(#drawPath)));
    });

    test('strokes the border inside the outline', () {
      expect(
        (Canvas canvas) => NoteImageStylePainter.paint(
          canvas,
          image,
          dest,
          NoteImageStyle(borderColor: border, borderWidth: 3),
        ),
        paints
          ..drawImageRect(image: image, destination: dest)
          ..path(color: border, strokeWidth: 6, style: PaintingStyle.stroke),
      );
    });

    test('opacity composites one layer; zero draws nothing', () {
      final calls = record(NoteImageStyle(opacity: 0.5));
      expect(calls.first.memberName, #saveLayer);
      expect(calls.where((c) => c.memberName == #restore), hasLength(2));
      expect(record(NoteImageStyle(opacity: 0)), isEmpty);
      expect(record(NoteImageStyle.plain, Rect.zero), isEmpty);
      expect(
        record(
          NoteImageStyle.plain,
          const Rect.fromLTWH(0, 0, double.infinity, 5),
        ),
        isEmpty,
      );
      expect(
        record(NoteImageStyle.plain, const Rect.fromLTWH(0, 0, -5, 5)),
        isEmpty,
      );
    });

    test('clipPathFor rounds the corners', () {
      final plain = NoteImageStylePainter.clipPathFor(
        dest,
        NoteImageStyle.plain,
      );
      final round = NoteImageStylePainter.clipPathFor(
        dest,
        NoteImageStyle(cornerRadius: 20),
      );
      final corner = dest.topLeft + const Offset(1, 1);
      expect(plain.contains(corner), isTrue);
      expect(round.contains(corner), isFalse);
      expect(round.contains(dest.center), isTrue);
      final capped = NoteImageStylePainter.clipPathFor(
        dest,
        NoteImageStyle(cornerRadius: 1000),
      );
      expect(capped.getBounds(), dest);
      expect(
        NoteImageStylePainter.clipPathFor(
          Rect.zero,
          NoteImageStyle(cornerRadius: 5),
        ).getBounds(),
        Rect.zero,
      );
    });

    test('clipPathFor follows the lasso, also with rounded corners', () {
      // A triangle crop pointing down: wide at the top of its bounds.
      final style = NoteImageStyle(
        crop: NoteImageCrop.polygon(const [
          Offset.zero,
          Offset(1, 0),
          Offset(0.5, 1),
        ]),
      );
      final outline = NoteImageStylePainter.clipPathFor(dest, style);
      final bottomCorner = dest.bottomLeft + const Offset(3, -3);
      expect(outline.contains(dest.topCenter + const Offset(0, 2)), isTrue);
      expect(outline.contains(bottomCorner), isFalse);
      final rounded = NoteImageStylePainter.clipPathFor(
        dest,
        style.copyWith(cornerRadius: 30),
      );
      expect(rounded.contains(dest.topLeft + const Offset(2, 1)), isFalse);
      expect(rounded.contains(dest.center), isTrue);
    });
  });
}
