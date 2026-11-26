import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';
import 'package:open_note/src/note/io/render/note_page_renderer.dart';
import 'package:open_note/src/note/io/render/note_region_capture.dart';

import '../support/io_test_support.dart';

const _size = NotePageSize(100, 100);
const _red = ui.Color(0xFFFF0000);
const _blue = ui.Color(0xFF0000FF);
const _green = ui.Color(0xFF00FF00);
const _white = ui.Color(0xFFFFFFFF);

Stroke _bar(List<List<num>> points, ui.Color color, {String ink = 'pencil'}) =>
    testStroke(
      ink: ink,
      points: testPoints(points),
      color: color.toARGB32(),
      size: 20,
    );

Stroke _across(ui.Color color) => _bar([
  [10, 50],
  [90, 50],
], color);

NotePageRenderInput _input({
  List<NotePageRenderLayer> layers = const [],
  List<NoteObject> objects = const [],
  Map<String, ui.Image> images = const {},
  bool paper = false,
}) => NotePageRenderInput(
  size: _size,
  layers: layers,
  objects: objects,
  images: images,
  paintBackground: paper
      ? (canvas, size) =>
            canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = _white)
      : null,
);

NotePageRenderLayer _layer({
  List<Stroke> strokes = const [],
  List<ImageDrawable> images = const [],
  List<TextDrawable> texts = const [],
  double opacity = 1,
  bool visible = true,
}) => NotePageRenderLayer(
  scribble: Scribble(
    strokes: strokes,
    imageDrawables: images,
    textDrawables: texts,
  ),
  opacity: opacity,
  visible: visible,
);

/// The colours at [points] of the rendered page.
Future<List<ui.Color>> _pixels(
  NotePageRenderInput input,
  List<(int, int)> points, {
  bool includeBackground = true,
}) async {
  final image = await NotePageRenderer.renderToImage(
    input,
    includeBackground: includeBackground,
  );
  final colors = [for (final (x, y) in points) await pixelAt(image, x, y)];
  image.dispose();

  return colors;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotePageRenderer', () {
    test('paints paper only when included', () async {
      final input = _input(paper: true);

      expect(await _pixels(input, [(5, 5)]), [_white]);
      final bare = await _pixels(input, [(5, 5)], includeBackground: false);
      expect(bare.single.a, 0);
    });

    test('layers paint bottom to top', () async {
      final input = _input(
        layers: [
          _layer(strokes: [_across(_red)]),
          _layer(
            strokes: [
              _bar([
                [50, 10],
                [50, 90],
              ], _blue),
            ],
          ),
        ],
      );

      expect(await _pixels(input, [(50, 50), (20, 50), (50, 20), (5, 5)]), [
        _blue,
        _red,
        _blue,
        const ui.Color(0x00000000),
      ]);
    });

    test('hidden layers are skipped and opacity fades a whole layer', () async {
      final hidden = _input(
        layers: [
          _layer(strokes: [_across(_red)], visible: false),
        ],
      );
      final faded = _input(
        layers: [
          _layer(strokes: [_across(_red), _across(_red)], opacity: 0.5),
        ],
      );

      expect((await _pixels(hidden, [(50, 50)])).single.a, 0);
      final pixel = (await _pixels(faded, [(50, 50)])).single;
      // One group: two overlapping strokes do not add up.
      expect(pixel.a, closeTo(0.5, 0.01));
    });

    test('shape strokes use the shape painter', () async {
      final input = _input(
        layers: [
          _layer(
            strokes: [
              testStroke(
                ink: 'shape',
                shapeType: 'rectangle',
                color: _red.toARGB32(),
                size: 6,
                points: testPoints([
                  [20, 20],
                  [80, 80],
                ]),
              ),
            ],
          ),
        ],
      );

      final colors = await _pixels(input, [(20, 50), (50, 50)]);
      expect(colors[0], _red);
      expect(colors[1].a, 0, reason: 'shapes are outlines');
    });

    test('lasso strokes are never drawn', () async {
      final input = _input(
        layers: [
          _layer(
            strokes: [
              _bar(
                [
                  [10, 50],
                  [90, 50],
                ],
                _red,
                ink: 'lasso',
              ),
            ],
          ),
        ],
      );

      expect((await _pixels(input, [(50, 50)])).single.a, 0);
    });

    test('marker strokes are not edited by painting', () async {
      final marker = _bar(
        [
          [10, 50],
          [90, 50],
        ],
        const ui.Color(0xFFDAD9FF),
        ink: 'marker',
      );
      final before = marker.deepCopy();

      final pixels = await _pixels(
        _input(
          layers: [
            _layer(strokes: [marker]),
          ],
        ),
        [(50, 50)],
      );

      expect(pixels.single.a, closeTo(0.5, 0.01), reason: 'engine pastel rule');
      expect(marker, before);
    });

    test('draws images with rotation and opacity, skips hidden ones', () async {
      final photo = await solidImage(4, 4, _green);
      ImageDrawable image({
        double rotation = 0,
        double opacity = 1,
        bool hidden = false,
        String source = 'photo',
      }) => ImageDrawable(
        id: 'i',
        source: source,
        x: 30,
        y: 45,
        width: 40,
        height: 10,
        rotation: rotation,
        opacity: opacity,
        hidden: hidden,
      );
      NotePageRenderInput page(ImageDrawable drawable) => _input(
        layers: [
          _layer(images: [drawable]),
        ],
        images: {'photo': photo},
      );

      final turned = await _pixels(page(image(rotation: math.pi / 2)), [
        (50, 35),
        (35, 50),
      ]);
      expect(turned[0], _green);
      expect(turned[1].a, 0);
      final faded = await _pixels(page(image(opacity: 0.25)), [(50, 50)]);
      expect(faded.single.a, closeTo(0.25, 0.01));
      final hidden = await _pixels(page(image(hidden: true)), [(50, 50)]);
      expect(hidden.single.a, 0);
      final missing = await _pixels(page(image(source: 'gone')), [(50, 50)]);
      expect(missing.single.a, closeTo(0x22 / 255, 0.01), reason: 'box');
      photo.dispose();
    });

    test('draws text and skips hidden text', () async {
      TextDrawable text({bool hidden = false}) => TextDrawable(
        id: 't',
        text: 'XXXX',
        x: 50,
        y: 50,
        fontSize: 20,
        color: _red.toARGB32(),
        hidden: hidden,
      );

      final shown = await _pixels(
        _input(
          layers: [
            _layer(texts: [text()]),
          ],
        ),
        [(50, 50)],
      );
      final hidden = await _pixels(
        _input(
          layers: [
            _layer(texts: [text(hidden: true)]),
          ],
        ),
        [(50, 50)],
      );

      expect(shown.single.a, greaterThan(0));
      expect(hidden.single.a, 0);
    });

    test('paints objects above layers with rotation and opacity', () async {
      final input = _input(
        layers: [
          _layer(strokes: [_across(_red)]),
        ],
        objects: const [
          BoxObject(
            id: 'turned',
            bounds: ui.Rect.fromLTWH(30, 45, 40, 10),
            rotation: math.pi / 2,
          ),
          // Painted after an object that leaves a save open: must not
          // inherit its rotation.
          BoxObject(
            id: 'faded',
            bounds: ui.Rect.fromLTWH(0, 0, 10, 10),
            opacity: 0.5,
            color: _blue,
          ),
        ],
      );

      final colors = await _pixels(input, [(50, 35), (35, 50), (5, 5)]);

      expect(colors[0], _green);
      expect(colors[1], _red, reason: 'rotated away, the stroke shows');
      expect(colors[2].a, closeTo(0.5, 0.01));
      expect(colors[2].b, closeTo(1, 0.01));
    });

    test('paint clips and leaves the canvas state alone', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final saves = canvas.getSaveCount();

      NotePageRenderer.paint(
        canvas,
        _input(
          paper: true,
          objects: const [BoxObject(id: 'o', bounds: ui.Rect.zero)],
        ),
        clip: const ui.Rect.fromLTWH(0, 0, 20, 20),
      );

      expect(canvas.getSaveCount(), saves);
      final image = await recorder.endRecording().toImage(100, 100);
      expect(await pixelAt(image, 10, 10), _white);
      expect((await pixelAt(image, 30, 30)).a, 0);
      image.dispose();
    });

    test('renders regions at a pixel ratio', () async {
      final image = await NotePageRenderer.renderToImage(
        _input(
          layers: [
            _layer(strokes: [_across(_red)]),
          ],
        ),
        region: const ui.Rect.fromLTWH(40, 45, 20, 30),
        pixelRatio: 3,
      );

      expect((image.width, image.height), (60, 90));
      expect(await pixelAt(image, 30, 15), _red);
      expect((await pixelAt(image, 30, 80)).a, 0);
      image.dispose();
    });

    test('renders PNG bytes', () async {
      final png = await NotePageRenderer.renderToPng(_input(paper: true));
      final image = await decodeImage(png);

      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      expect((image.width, image.height), (100, 100));
      image.dispose();
    });

    test('corrupt ink is skipped instead of failing the page', () async {
      final input = _input(
        layers: [
          _layer(
            strokes: [
              testStroke(
                ink: 'shape',
                shapeType: 'rectangle',
                points: testPoints([
                  [10, 10],
                  [double.nan, 40],
                ]),
              ),
              _across(_red),
            ],
            images: [
              ImageDrawable(
                id: 'i',
                source: 's',
                x: double.infinity,
                width: 10,
                height: 10,
                opacity: 1,
              ),
            ],
            texts: [
              TextDrawable(id: 'a', text: 'x', x: double.nan, y: 5),
              TextDrawable(id: 'b', text: 'y', rotation: double.nan),
            ],
          ),
        ],
      );

      expect(await _pixels(input, [(50, 50)]), [_red]);
    });

    test('rejects absurd pixel ratios', () async {
      await expectLater(
        NotePageRenderer.renderToImage(_input(), pixelRatio: 1e308),
        throwsArgumentError,
      );
    });

    test('rejects invalid raster requests', () async {
      final input = _input();

      await expectLater(
        NotePageRenderer.renderToImage(input, pixelRatio: 0),
        throwsArgumentError,
      );
      await expectLater(
        NotePageRenderer.renderToImage(input, region: ui.Rect.zero),
        throwsArgumentError,
      );
      await expectLater(
        NotePageRenderer.renderToImage(input, pixelRatio: 1000),
        throwsArgumentError,
      );
    });
  });

  group('render requests', () {
    test('layers clamp opacity', () {
      NotePageRenderLayer layer(double opacity) => _layer(opacity: opacity);

      expect(layer(4).effectiveOpacity, 1);
      expect(layer(-1).effectiveOpacity, 0);
      expect(layer(double.nan).effectiveOpacity, 1);
      expect(layer(0).isPaintable, isFalse);
      expect(_layer(visible: false).isPaintable, isFalse);
      expect(_layer(), _layer());
      expect(_layer().hashCode, _layer().hashCode);
      expect(_layer().copyWith(opacity: 0.2).opacity, 0.2);
    });

    test('lists the image sources to decode', () {
      ImageDrawable image(String source, {bool hidden = false}) =>
          ImageDrawable(id: source, source: source, hidden: hidden);
      final input = _input(
        layers: [
          _layer(images: [image('a'), image('b', hidden: true), image('')]),
          _layer(images: [image('c')], visible: false),
          _layer(images: [image('a'), image('d')]),
        ],
      );

      expect(input.drawableImageSources, {'a', 'd'});
    });

    test('copies and compares by value', () {
      final input = _input(paper: true, layers: [_layer()]);

      expect(input.copyWith(), input);
      expect(input.copyWith(removeBackground: true).paintBackground, isNull);
      expect(input.copyWith(size: const NotePageSize(5, 5)), isNot(input));
      expect(input.imageFor('x'), isNull);
    });
  });

  group('NoteRegionCapture', () {
    final input = _input(
      paper: true,
      layers: [
        _layer(strokes: [_across(_red)]),
      ],
      objects: const [
        BoxObject(id: 'o', bounds: ui.Rect.fromLTWH(60, 20, 10, 10)),
      ],
    );
    const region = ui.Rect.fromLTWH(40, 10, 40, 50);

    test('cuts ink and objects out on a transparent background', () async {
      final image = await decodeImage(
        await NoteRegionCapture.capture(input, region),
      );

      expect((image.width, image.height), (80, 100));
      // Page (50, 50) is ink, (65, 25) the object, (45, 15) empty paper.
      expect(await pixelAt(image, 20, 80), _red);
      expect(await pixelAt(image, 50, 30), _green);
      expect((await pixelAt(image, 10, 10)).a, 0);
      image.dispose();
    });

    test('can keep the paper', () async {
      final image = await decodeImage(
        await NoteRegionCapture.capture(
          input,
          region,
          transparentBackground: false,
          pixelRatio: 1,
        ),
      );

      expect((image.width, image.height), (40, 50));
      expect(await pixelAt(image, 5, 5), _white);
      image.dispose();
    });

    test('rejects an empty region', () {
      expect(
        NoteRegionCapture.capture(input, ui.Rect.zero),
        throwsArgumentError,
      );
    });
  });
}
