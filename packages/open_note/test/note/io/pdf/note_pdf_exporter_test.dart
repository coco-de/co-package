import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_exporter.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_writer.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';

import '../support/io_test_support.dart';
import '../support/pdf_test_parser.dart';

const _size = NotePageSize(200, 150);

NotePageRenderInput _page({
  List<Stroke> strokes = const [],
  List<ImageDrawable> images = const [],
  List<TextDrawable> texts = const [],
  List<NoteObject> objects = const [],
  Map<String, ui.Image> decoded = const {},
  void Function(ui.Canvas, ui.Size)? paper,
  double opacity = 1,
  bool visible = true,
}) => NotePageRenderInput(
  size: _size,
  paintBackground: paper,
  images: decoded,
  objects: objects,
  layers: [
    NotePageRenderLayer(
      scribble: Scribble(
        strokes: strokes,
        imageDrawables: images,
        textDrawables: texts,
      ),
      opacity: opacity,
      visible: visible,
    ),
  ],
);

Future<PdfTestDocument> _export(
  List<NotePageRenderInput> pages, {
  bool includeBackground = true,
  double rasterScale = 1,
  int maxImageDimension = 2048,
}) async => PdfTestDocument.parse(
  await NotePdfExporter.export(
    pages,
    includeBackground: includeBackground,
    rasterScale: rasterScale,
    maxImageDimension: maxImageDimension,
    compressor: NotePdfWriter.noCompression,
  ),
);

/// The operator names of page [index] (grammar checked against its
/// resources).
List<String> _operators(PdfTestDocument document, [int index = 0]) {
  final page = document.pages[index];

  return pdfOperatorNames(document.contentOf(page), page);
}

String _content(PdfTestDocument document) =>
    document.contentOf(document.pages.first);

void _paper(ui.Canvas canvas, ui.Size size) {
  canvas.drawRect(
    ui.Offset.zero & size,
    ui.Paint()..color = const ui.Color(0xFFFFF8E1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('document', () {
    test('has one page per input with the page size', () async {
      final progress = <(int, int)>[];

      final bytes = await NotePdfExporter.export(
        [
          const NotePageRenderInput(size: NotePageSize.a4),
          const NotePageRenderInput(size: NotePageSize(300, 200)),
        ],
        title: 'Lecture',
        onPageExported: (done, total) => progress.add((done, total)),
      );
      final document = PdfTestDocument.parse(bytes);

      expect(document.pages, hasLength(2));
      expect(document.pages[0].numberArray('MediaBox'), [0, 0, 595, 842]);
      expect(document.pages[1].numberArray('MediaBox'), [0, 0, 300, 200]);
      expect(document.info.body, contains('/Title (Lecture)'));
      expect(progress, [(1, 2), (2, 2)]);
    });

    test('needs at least one page', () {
      expect(NotePdfExporter.export(const []), throwsArgumentError);
    });

    test('is compressed by default and still parses', () async {
      final input = _page(
        strokes: [
          testStroke(),
          testStroke(ink: 'pencil'),
        ],
        paper: _paper,
      );

      final compressed = await NotePdfExporter.export([input]);
      final raw = await NotePdfExporter.export([
        input,
      ], compressor: NotePdfWriter.noCompression);

      expect(compressed.length, lessThan(raw.length));
      final a = PdfTestDocument.parse(compressed);
      final b = PdfTestDocument.parse(raw);
      expect(_content(a), _content(b));
    });
  });

  group('ink stays vector', () {
    test('pen strokes are filled outlines in the stroke colour', () async {
      final document = await _export([
        _page(strokes: [testStroke(color: 0xFF2040FF, size: 6)]),
      ]);

      final names = _operators(document);
      expect(names, containsAllInOrder(<String>['q', 'rg', 'm', 'c', 'f']));
      expect(names.where((name) => name == 'c').length, greaterThan(10));
      expect(names, isNot(contains('S')));
      expect(names, isNot(contains('Do')));
      expect(_content(document), contains('0.1255 0.251 1 rg\n'));
      expect(document.imagesOf(document.pages.single), isEmpty);
    });

    test('pencil, marker and uniform pens are stroked paths', () async {
      final document = await _export([
        _page(
          strokes: [
            testStroke(ink: 'pencil', size: 3),
            testStroke(ink: 'marker', color: 0x66FFEB3B, size: 5),
            testStroke(ink: 'uniformPen', size: 2),
          ],
        ),
      ]);

      final page = document.pages.single;
      final operators = pdfOperators(document.contentOf(page), page);
      expect(operators.where((o) => o.name == 'S'), hasLength(3));
      expect(operators.where((o) => o.name == 'f'), isEmpty);
      expect(
        operators.where((o) => o.name == 'w').map((o) => o.operands.single),
        ['3', '10', '2'],
      );
      expect(
        operators.where((o) => o.name == 'J').map((o) => o.operands.single),
        everyElement('1'),
      );
      final state = document[page.resources('ExtGState').values.single];
      expect(state.body, contains('/ca 0.4 /CA 0.4'));
    });

    test('shapes are vector paths and lasso ink is not exported', () async {
      final document = await _export([
        _page(
          strokes: [
            testStroke(
              ink: 'shape',
              shapeType: 'rectangle',
              points: testPoints([
                [10, 10],
                [60, 40],
              ]),
            ),
            testStroke(ink: 'lasso'),
            testStroke(ink: 'erase'),
          ],
        ),
      ]);

      expect(_operators(document), [
        'cm', 'q', 'RG', 'w', 'J', 'j', 'm', 'l', 'l', 'l', 'h', 'S', 'Q', //
      ]);
    });

    test('exporting leaves marker strokes untouched', () async {
      final marker = testStroke(ink: 'marker', color: 0xFFDAD9FF);
      final before = marker.deepCopy();

      await _export([
        _page(strokes: [marker]),
      ]);

      expect(marker, before);
    });
  });

  group('layers', () {
    test('a translucent layer is composited as one group', () async {
      final document = await _export([
        _page(strokes: [testStroke(), testStroke()], opacity: 0.4),
      ]);

      final page = document.pages.single;
      expect(_operators(document), ['cm', 'q', 'gs', 'Do', 'Q']);
      final group = document.formsOf(page).values.single;
      expect(group.body, contains('/S /Transparency'));
      final inside = pdfOperatorNames(group.text, group);
      expect(inside.where((name) => name == 'f'), hasLength(2));
      final state = document[page.resources('ExtGState').values.single];
      expect(state.body, contains('/ca 0.4 /CA 0.4'));
    });

    test('hidden and fully transparent layers are skipped', () async {
      final document = await _export([
        _page(strokes: [testStroke()], visible: false),
        _page(strokes: [testStroke()], opacity: 0),
      ]);

      expect(_operators(document), ['cm']);
      expect(_operators(document, 1), ['cm']);
    });

    test('draws paper, then strokes, text, images, then objects', () async {
      final photo = await solidImage(4, 4, const ui.Color(0xFF123456));
      final document = await _export([
        _page(
          paper: _paper,
          strokes: [testStroke()],
          images: [
            ImageDrawable(
              id: 'i',
              source: 'photo',
              x: 5,
              y: 5,
              width: 20,
              height: 20,
              opacity: 1,
            ),
          ],
          texts: [
            TextDrawable(
              id: 't',
              text: 'Hello',
              x: 100,
              y: 100,
              fontSize: 14,
              color: 0xFF000000,
            ),
          ],
          objects: const [
            BoxObject(id: 'o', bounds: ui.Rect.fromLTWH(150, 100, 20, 20)),
          ],
          decoded: {'photo': photo},
        ),
      ]);
      photo.dispose();

      final operators = pdfOperators(_content(document));
      final painted = [
        for (final operator in operators)
          if (operator.name == 'Do' || operator.name == 'f')
            operator.name == 'f' ? 'ink' : operator.operands.single,
      ];
      expect(painted, ['/Im1', 'ink', '/Im2', '/Im3', '/Im4']);
      // Images are numbered in drawing order: paper, text, the photo, object.
      final images = document.imagesOf(document.pages.single);
      expect(images['Im3']!.body, contains('/Width 4 /Height 4'));
    });
  });

  group('rasterised parts', () {
    test('the paper is one full page image at the raster scale', () async {
      final document = await _export([_page(paper: _paper)], rasterScale: 2);

      final paper = document.imagesOf(document.pages.single).values.single;
      expect(paper.body, contains('/Width 400 /Height 300'));
      expect(paper.body, isNot(contains('/SMask')), reason: 'opaque');
      expect(_content(document), contains('200 0 0 -150 0 150 cm\n/Im1 Do'));
      expect(paper.data!.sublist(0, 3), [0xFF, 0xF8, 0xE1]);
    });

    test('includeBackground false leaves the paper out', () async {
      final document = await _export([
        _page(paper: _paper),
      ], includeBackground: false);

      expect(_operators(document), ['cm']);
      expect(document.imagesOf(document.pages.single), isEmpty);
    });

    test('text boxes are images; hidden and empty ones are not', () async {
      TextDrawable text(String id, String value, {bool hidden = false}) =>
          TextDrawable(
            id: id,
            text: value,
            x: 80,
            y: 60,
            fontSize: 16,
            color: 0xFF000000,
            hidden: hidden,
          );

      final shown = await _export([
        _page(texts: [text('a', 'Visible')]),
      ]);
      final hidden = await _export([
        _page(texts: [text('b', 'Hidden', hidden: true), text('c', '')]),
      ]);

      final image = shown.imagesOf(shown.pages.single).values.single;
      expect(image.body, contains('/SMask'), reason: 'transparent around');
      expect(hidden.imagesOf(hidden.pages.single), isEmpty);
    });

    test('a rotated text box is placed around its position', () async {
      final document = await _export([
        _page(
          texts: [
            TextDrawable(
              id: 'r',
              text: 'Rotated text',
              x: 100,
              y: 75,
              fontSize: 12,
              color: 0xFF000000,
              rotation: math.pi / 2,
            ),
          ],
        ),
      ]);

      final matrix = pdfOperators(
        _content(document),
      ).lastWhere((o) => o.name == 'cm').operands.map(double.parse).toList();
      // [w 0 0 -h x y+h]: a quarter turn makes the box taller than wide.
      expect(matrix[3].abs(), greaterThan(matrix[0]));
      expect(matrix[4] + matrix[0] / 2, closeTo(100, 1.5));
      expect(matrix[5] + matrix[3] / 2, closeTo(75, 1.5));
    });

    test('image drawables embed their pixels once', () async {
      final photo = await solidImage(8, 4, const ui.Color(0xFF336699));
      ImageDrawable drawable(String id, double x, {double rotation = 0}) =>
          ImageDrawable(
            id: id,
            source: 'photo',
            x: x,
            y: 20,
            width: 40,
            height: 20,
            opacity: 0.5,
            rotation: rotation,
          );

      final document = await _export([
        _page(
          images: [drawable('a', 10), drawable('b', 100, rotation: 0.3)],
          decoded: {'photo': photo},
        ),
      ]);
      photo.dispose();

      final page = document.pages.single;
      expect(document.imagesOf(page), hasLength(1));
      final operators = pdfOperators(_content(document), page);
      expect(operators.where((o) => o.name == 'Do'), hasLength(2));
      expect(
        operators.where((o) => o.name == 'cm'),
        hasLength(4),
        reason: 'page flip, one rotation, two image placements',
      );
      final state = document[page.resources('ExtGState').values.single];
      expect(state.body, contains('/ca 0.5 /CA 0.5'));
    });

    test('large images are downscaled', () async {
      final photo = await solidImage(32, 16, const ui.Color(0xFF000000));

      final document = await _export([
        _page(
          images: [
            ImageDrawable(
              id: 'a',
              source: 'photo',
              width: 100,
              height: 50,
              opacity: 1,
            ),
          ],
          decoded: {'photo': photo},
        ),
      ], maxImageDimension: 8);
      photo.dispose();

      expect(
        document.imagesOf(document.pages.single).values.single.body,
        contains('/Width 8 /Height 4'),
      );
    });

    test('missing images export a placeholder, hidden ones nothing', () async {
      ImageDrawable missing(String id, {bool hidden = false}) => ImageDrawable(
        id: id,
        source: 'nowhere',
        x: 10,
        y: 10,
        width: 30,
        height: 30,
        opacity: 1,
        hidden: hidden,
      );

      final document = await _export([
        _page(images: [missing('shown'), missing('hidden', hidden: true)]),
      ]);

      expect(_operators(document), [
        'cm', 'q', 'gs', 'rg', 're', 'f', 'Q', //
      ]);
      expect(document.imagesOf(document.pages.single), isEmpty);
    });

    test(
      'objects are painted with paintToCanvas around their bounds',
      () async {
        final document = await _export([
          _page(
            objects: const [
              BoxObject(id: 'a', bounds: ui.Rect.fromLTWH(50, 40, 20, 10)),
              BoxObject(
                id: 'invisible',
                bounds: ui.Rect.fromLTWH(10, 10, 20, 20),
                opacity: 0,
              ),
              BoxObject(
                id: 'paints nothing visible',
                bounds: ui.Rect.fromLTWH(10, 10, 20, 20),
                color: ui.Color(0x00000000),
              ),
            ],
          ),
        ]);

        final images = document.imagesOf(document.pages.single);
        expect(images, hasLength(1));
        // 20 x 10 plus the 24 unit bleed on each side, inside the page.
        expect(images.values.single.body, contains('/Width 68 /Height 58'));
        expect(_content(document), contains('68 0 0 -58 26 74 cm'));
      },
    );

    test('objects outside the page are left out', () async {
      final document = await _export([
        _page(
          objects: const [
            BoxObject(id: 'far', bounds: ui.Rect.fromLTWH(900, 900, 20, 20)),
          ],
        ),
      ]);

      expect(_operators(document), ['cm']);
    });

    test('an object raster keeps the object pixels', () async {
      final document = await _export([
        _page(
          objects: const [
            BoxObject(id: 'a', bounds: ui.Rect.fromLTWH(0, 0, 200, 150)),
          ],
        ),
      ]);

      final image = document.imagesOf(document.pages.single).values.single;
      expect(image.body, contains('/Width 200 /Height 150'));
      expect(image.data!.sublist(0, 3), Uint8List.fromList([0, 255, 0]));
    });
  });
}
