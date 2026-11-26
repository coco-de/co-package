import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/fake_note_document_scanner.dart';
import 'package:open_note/src/note/io/import/fake_note_office_converter.dart';
import 'package:open_note/src/note/io/import/fake_note_pdf_page_renderer.dart';
import 'package:open_note/src/note/io/import/note_image_importer.dart';
import 'package:open_note/src/note/io/import/note_import_exception.dart';
import 'package:open_note/src/note/io/import/note_import_page_selection.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/import/note_office_importer.dart';
import 'package:open_note/src/note/io/import/note_pdf_renderer_importer.dart';
import 'package:open_note/src/note/io/import/note_scan_filter.dart';
import 'package:open_note/src/note/io/import/note_scan_importer.dart';

import '../support/io_test_support.dart';

const _red = ui.Color(0xFFFF0000);

NoteImportSource _source(String name, Uint8List bytes) =>
    NoteImportSource(name: name, bytes: bytes);

Future<(int, int)> _pngSize(Uint8List png) async {
  final image = await decodeImage(png);
  final size = (image.width, image.height);
  image.dispose();

  return size;
}

Future<ui.Color> _pixel(Uint8List png, int x, int y) async {
  final image = await decodeImage(png);
  final color = await pixelAt(image, x, y);
  image.dispose();

  return color;
}

Matcher _importError(String message) => throwsA(
  isA<NoteImportException>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteImportPageSelection', () {
    test('keeps order and ignores repeats and bad indices', () {
      expect(NoteImportPageSelection.select(3, null), [0, 1, 2]);
      expect(NoteImportPageSelection.select(5, [4, 1, 4, -1, 5, 0]), [4, 1, 0]);
      expect(NoteImportPageSelection.select(0, null), isEmpty);
      expect(NoteImportPageSelection.select(3, []), isEmpty);
    });
  });

  group('NoteImageImporter', () {
    test('fits a PNG to the page width and keeps its bytes', () async {
      final png = await solidPng(200, 100, _red);

      final pages = await const NoteImageImporter().import(
        _source('wide.png', png),
      );

      expect(pages, hasLength(1));
      expect(pages.single.size, const NotePageSize(595, 297.5));
      expect(pages.single.backgroundPng, same(png));
    });

    test('re-encodes a JPEG as PNG', () async {
      final pages = await const NoteImageImporter(
        pageSize: NotePageSize(160, 160),
      ).import(_source('photo.jpg', redJpeg16x8));

      final page = pages.single;
      expect(page.size, const NotePageSize(160, 80));
      expect(page.backgroundPng!.sublist(1, 4), 'PNG'.codeUnits);
      expect(await _pngSize(page.backgroundPng!), (16, 8));
      final color = await _pixel(page.backgroundPng!, 8, 4);
      expect(color.r, greaterThan(0.7));
      expect(color.g, lessThan(0.3));
    });

    test('scales large pictures down keeping their aspect ratio', () async {
      final tall = await solidPng(40, 80, _red);

      final page = (await const NoteImageImporter(
        maxPixelDimension: 20,
      ).import(_source('tall.png', tall))).single;

      expect(await _pngSize(page.backgroundPng!), (10, 20));
      expect(page.size.height / page.size.width, closeTo(2, 0.01));
    });

    test('imports only page 0 when pages are chosen', () async {
      final png = await solidPng(2, 2, _red);
      const importer = NoteImageImporter();

      expect(
        await importer.import(_source('a.png', png), pageIndices: [0]),
        hasLength(1),
      );
      expect(
        await importer.import(_source('a.png', png), pageIndices: [1]),
        isEmpty,
      );
    });

    test('rejects other formats and broken pictures', () async {
      const importer = NoteImageImporter();

      await expectLater(
        importer.import(_source('a.gif', Uint8List.fromList([1, 2, 3]))),
        _importError('not a PNG or JPEG'),
      );
      await expectLater(
        importer.import(
          _source(
            'broken.png',
            Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2]),
          ),
        ),
        _importError('could not be decoded'),
      );
    });
  });

  group('NotePdfRendererImporter', () {
    final pdf = _source('book.pdf', Uint8List.fromList('%PDF-1.4'.codeUnits));

    test('renders every page at the requested width', () async {
      final renderer = FakeNotePdfPageRenderer(
        pageSize: const NotePageSize(300, 400),
      );

      final pages = await NotePdfRendererImporter(
        renderer,
        targetWidth: 60,
      ).import(pdf);

      expect(renderer.renderedPages, [0, 1, 2]);
      expect(renderer.requestedWidths, [60, 60, 60]);
      expect(pages.map((p) => p.size).toSet(), {const NotePageSize(300, 400)});
      expect(await _pngSize(pages.first.backgroundPng!), (60, 80));
    });

    test('imports only the chosen pages in order', () async {
      final renderer = FakeNotePdfPageRenderer(pages: 10);

      final pages = await NotePdfRendererImporter(
        renderer,
        targetWidth: 20,
      ).import(pdf, pageIndices: [7, 2, 7, 42]);

      expect(pages, hasLength(2));
      expect(renderer.renderedPages, [7, 2]);
    });

    test('derives sizes from the picture when not reported', () async {
      final renderer = FakeNotePdfPageRenderer(
        pages: 1,
        pageSize: const NotePageSize(100, 200),
        reportPageSize: false,
      );

      final pages = await NotePdfRendererImporter(
        renderer,
        targetWidth: 50,
        pageSize: const NotePageSize(400, 1),
      ).import(pdf);

      expect(pages.single.size, const NotePageSize(400, 800));
    });

    test('reports renderer failures and empty documents', () async {
      await expectLater(
        NotePdfRendererImporter(
          FakeNotePdfPageRenderer(failure: const FormatException('bad')),
        ).import(pdf),
        throwsA(
          isA<NoteImportException>()
              .having((e) => e.cause, 'cause', isA<FormatException>())
              .having((e) => '$e', 'text', contains('book.pdf')),
        ),
      );
      await expectLater(
        NotePdfRendererImporter(FakeNotePdfPageRenderer(pages: 0)).import(pdf),
        _importError('no pages'),
      );
    });
  });

  group('NoteOfficeImporter', () {
    final deck = _source('deck.pptx', Uint8List.fromList([80, 75]));

    test('converts to PDF and imports the chosen pages', () async {
      final converter = FakeNoteOfficeConverter();
      final renderer = FakeNotePdfPageRenderer(pages: 4);

      final pages = await NoteOfficeImporter(
        converter,
        NotePdfRendererImporter(renderer, targetWidth: 20),
      ).import(deck, pageIndices: [3]);

      expect(converter.sources, [deck]);
      expect(renderer.renderedPages, [3]);
      expect(pages, hasLength(1));
    });

    test('reports converter failures and empty results', () async {
      final importer = NotePdfRendererImporter(FakeNotePdfPageRenderer());

      await expectLater(
        NoteOfficeImporter(
          FakeNoteOfficeConverter(failure: Exception('offline')),
          importer,
        ).import(deck),
        _importError('converting "deck.pptx" failed'),
      );
      await expectLater(
        NoteOfficeImporter(
          FakeNoteOfficeConverter(pdf: Uint8List(0)),
          importer,
        ).import(deck),
        _importError('produced nothing'),
      );
    });
  });

  group('NoteScanImporter', () {
    test('passes the source to the scanner and filters pages', () async {
      final scanner = FakeNoteDocumentScanner(
        pages: [
          _source('1.png', await solidPng(4, 4, _red)),
          _source('2.jpg', redJpeg16x8),
        ],
      );
      final input = _source('camera.jpg', redJpeg16x8);

      final pages = await NoteScanImporter(
        scanner,
        filter: NoteScanFilter.grayscale,
        pageSize: const NotePageSize(100, 100),
      ).import(input);

      expect(scanner.requests, [input]);
      expect(pages, hasLength(2));
      expect(pages.first.size, const NotePageSize(100, 100));
      expect(pages.last.size, const NotePageSize(100, 50));
      final grey = await _pixel(pages.first.backgroundPng!, 2, 2);
      // Rec. 601 luminance of pure red is 76.
      expect(grey, const ui.Color(0xFF4C4C4C));
    });

    test('black and white thresholds the pages', () async {
      final scanner = FakeNoteDocumentScanner(
        pages: [_source('1.png', await solidPng(2, 2, _red))],
      );

      final dark = await NoteScanImporter(
        scanner,
        filter: NoteScanFilter.blackWhite(100),
      ).capture();
      final light = await NoteScanImporter(
        scanner,
        filter: NoteScanFilter.blackWhite(50),
      ).capture();

      expect(scanner.requests, [null, null]);
      expect(
        await _pixel(dark.single.backgroundPng!, 0, 0),
        const ui.Color(0xFF000000),
      );
      expect(
        await _pixel(light.single.backgroundPng!, 0, 0),
        const ui.Color(0xFFFFFFFF),
      );
    });

    test('without a filter PNG scans are kept as they are', () async {
      final png = await solidPng(3, 3, _red);
      final scanner = FakeNoteDocumentScanner(
        pages: [_source('1.png', png), _source('2.png', png)],
      );

      final pages = await NoteScanImporter(scanner).capture(pageIndices: [1]);

      expect(pages.single.backgroundPng, same(png));
    });

    test('a cancelled scan imports nothing; failures are reported', () async {
      expect(
        await NoteScanImporter(FakeNoteDocumentScanner()).capture(),
        isEmpty,
      );
      await expectLater(
        NoteScanImporter(
          FakeNoteDocumentScanner(failure: Exception('no camera')),
        ).capture(),
        _importError('scanning failed'),
      );
    });
  });

  group('import models', () {
    test('sources expose their extension and compare by content', () {
      final a = _source('Lecture.PDF', Uint8List.fromList([1]));

      expect(a.extension, 'pdf');
      expect(_source('noext', Uint8List(0)).extension, '');
      expect(_source('trailing.', Uint8List(0)).extension, '');
      expect(_source('dir.v2/file', Uint8List(0)).extension, '');
      expect(a, _source('Lecture.PDF', Uint8List.fromList([1])));
      expect(a, isNot(a.copyWith(bytes: Uint8List.fromList([2]))));
      expect(a.copyWith(mimeType: 'application/pdf').mimeType, isNotNull);
      expect('$a', 'NoteImportSource(Lecture.PDF, 1 bytes)');
    });

    test('imported pages round trip through JSON', () {
      final page = NoteImportedPage(
        size: const NotePageSize(10, 20),
        backgroundPng: Uint8List.fromList([1, 2, 3]),
        backgroundSource: 'notes/a/page1.png',
      );

      expect(NoteImportedPage.fromJson(page.toJson()), page);
      expect(page.copyWith(size: NotePageSize.a4).size, NotePageSize.a4);
      expect(page.hashCode, page.copyWith().hashCode);
    });

    test('imported page JSON is lenient', () {
      final page = NoteImportedPage.fromJson({
        'size': 'big',
        'backgroundPng': '%%%',
        'backgroundSource': 7,
      });

      expect(page.size, NotePageSize.a4);
      expect(page.backgroundPng, isNull);
      expect(page.backgroundSource, isNull);
      expect(NoteImportedPage.fromJson(null).size, NotePageSize.a4);
    });
  });
}
