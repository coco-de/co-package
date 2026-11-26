import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_deflate_stub.dart' as stub;
import 'package:open_note/src/note/io/pdf/note_pdf_image.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_syntax.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_writer.dart';
import 'package:open_note/src/note/io/pdf/note_vector_path.dart';

import '../support/pdf_test_parser.dart';

/// A 2 x 1 image: opaque red and half transparent blue.
NotePdfImage _translucentImage() => NotePdfImage.fromRgba(
  Uint8List.fromList([255, 0, 0, 255, 0, 0, 255, 128]),
  width: 2,
  height: 1,
);

NotePdfImage _opaqueImage() => NotePdfImage.fromRgba(
  Uint8List.fromList([1, 2, 3, 255]),
  width: 1,
  height: 1,
);

void main() {
  group('NotePdfWriter structure', () {
    test('writes a header, xref table, trailer and page tree', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(595, 842);
      writer.addPage(420.5, 200);

      final document = PdfTestDocument.parse(writer.save());
      final pages = document.pages;

      expect(writer.pageCount, 2);
      expect(pages, hasLength(2));
      expect(pages[0].numberArray('MediaBox'), [0, 0, 595, 842]);
      expect(pages[1].numberArray('MediaBox'), [0, 0, 420.5, 200]);
      expect(document.info.body, contains('/Producer (open_note)'));
      for (final page in pages) {
        expect(
          pdfOperatorNames(document.contentOf(page), page),
          ['cm'],
          reason: 'an empty page only flips the coordinate system',
        );
      }
    });

    test('flips each page to top-left coordinates', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 250);

      final document = PdfTestDocument.parse(writer.save());

      expect(
        document.contentOf(document.pages.single),
        startsWith('1 0 0 -1 0 250 cm\n'),
      );
    });

    test('compressed streams carry FlateDecode and inflate to the same', () {
      Uint8List build(NotePdfCompressor? compressor) {
        final writer = compressor == null
            ? NotePdfWriter()
            : NotePdfWriter(compressor: compressor);
        final page = writer.addPage(100, 100);
        for (var i = 0; i < 50; i++) {
          page
            ..rectangle(Rect.fromLTWH(i * 1.0, 2, 3, 4))
            ..fill();
        }
        page.drawImage(_translucentImage(), const Rect.fromLTWH(0, 0, 20, 10));

        return writer.save();
      }

      final compressedBytes = build(null);
      final rawBytes = build(NotePdfWriter.noCompression);
      final compressed = PdfTestDocument.parse(compressedBytes);
      final raw = PdfTestDocument.parse(rawBytes);

      expect(latin1.decode(compressedBytes), contains('/Filter /FlateDecode'));
      expect(latin1.decode(rawBytes), isNot(contains('/Filter')));
      expect(compressedBytes.length, lessThan(rawBytes.length));
      expect(
        compressed.contentOf(compressed.pages.single),
        raw.contentOf(raw.pages.single),
      );
      final inflated = compressed.imagesOf(compressed.pages.single);
      final stored = raw.imagesOf(raw.pages.single);
      expect(inflated.values.single.data, stored.values.single.data);
    });

    test('platforms without zlib store streams raw', () {
      final writer = NotePdfWriter(compressor: stub.notePdfDeflate);
      writer.addPage(10, 10)
        ..rectangle(const Rect.fromLTWH(1, 1, 2, 2))
        ..fill();

      final bytes = writer.save();

      expect(latin1.decode(bytes), isNot(contains('/Filter')));
      expect(PdfTestDocument.parse(bytes).pages, hasLength(1));
    });

    test('output is deterministic', () {
      Uint8List build() {
        final writer = NotePdfWriter();
        writer.addPage(100, 100)
          ..setOpacity(fill: 0.5)
          ..rectangle(const Rect.fromLTWH(1, 1, 2, 2))
          ..fill();

        return writer.save();
      }

      expect(build(), build());
    });

    test('can be saved again after more pages are added', () {
      final writer = NotePdfWriter();
      writer.addPage(10, 10);
      final first = PdfTestDocument.parse(writer.save());
      writer.addPage(20, 20);
      final second = PdfTestDocument.parse(writer.save());

      expect(first.pages, hasLength(1));
      expect(second.pages, hasLength(2));
    });

    test('writes title and creation date', () {
      final writer = NotePdfWriter(
        title: r'Notes (draft) \ 1',
        creationDate: DateTime.utc(2026, 3, 4, 5, 6, 7),
      );
      writer.addPage(10, 10);
      final info = PdfTestDocument.parse(writer.save()).info.body;

      expect(info, contains(r'/Title (Notes \(draft\) \\ 1)'));
      expect(info, contains('/CreationDate (D:20260304050607Z)'));
    });

    test('encodes non-ASCII titles as UTF-16BE', () {
      final writer = NotePdfWriter(title: '노트');
      writer.addPage(10, 10);

      expect(
        PdfTestDocument.parse(writer.save()).info.body,
        contains('/Title <FEFFB178D2B8>'),
      );
    });

    test('rejects documents without pages and bad page sizes', () {
      expect(() => NotePdfWriter().save(), throwsStateError);
      expect(() => NotePdfWriter().addPage(0, 10), throwsArgumentError);
      expect(
        () => NotePdfWriter().addPage(10, double.nan),
        throwsArgumentError,
      );
    });

    test('rejects unclosed saves, groups and paths', () {
      void expectRejected(void Function(NotePdfWriter writer) build) {
        final writer = NotePdfWriter();
        build(writer);
        expect(writer.save, throwsStateError);
      }

      expectRejected((writer) => writer.addPage(10, 10).save());
      expectRejected((writer) => writer.addPage(10, 10).beginGroup());
      expectRejected((writer) => writer.addPage(10, 10).moveTo(Offset.zero));
    });
  });

  group('NotePdfPage operators', () {
    test('writes the path, colour and line operators', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 100)
        ..save()
        ..setFillColor(const Color(0xFFFF0000))
        ..setStrokeColor(const Color(0xFF0000FF))
        ..setLineWidth(2.5)
        ..setLineCap(StrokeCap.round)
        ..setLineJoin(StrokeJoin.bevel)
        ..setDashPattern([3, 2], 1)
        ..moveTo(const Offset(1, 2))
        ..lineTo(const Offset(3, 4))
        ..curveTo(const Offset(5, 6), const Offset(7, 8), const Offset(9, 10))
        ..closePath()
        ..fill()
        ..rectangle(const Rect.fromLTWH(10, 20, 30, 40))
        ..fill(evenOdd: true)
        ..moveTo(Offset.zero)
        ..lineTo(const Offset(1, 1))
        ..stroke()
        ..rectangle(const Rect.fromLTWH(0, 0, 5, 5))
        ..fillAndStroke()
        ..restore();

      final document = PdfTestDocument.parse(writer.save());
      final page = document.pages.single;
      final content = document.contentOf(page);

      expect(pdfOperatorNames(content, page), [
        'cm', 'q', 'rg', 'RG', 'w', 'J', 'j', 'd', //
        'm', 'l', 'c', 'h', 'f', 're', 'f*', 'm', 'l', 'S', 're', 'B', 'Q',
      ]);
      expect(content, contains('1 0 0 rg\n'));
      expect(content, contains('0 0 1 RG\n'));
      expect(content, contains('2.5 w\n'));
      expect(content, contains('1 J\n'));
      expect(content, contains('2 j\n'));
      expect(content, contains('[3 2] 1 d\n'));
      expect(content, contains('5 6 7 8 9 10 c\n'));
      expect(content, contains('10 20 30 40 re\n'));
    });

    test('clips with W n and W* n', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 100)
        ..save()
        ..rectangle(const Rect.fromLTWH(0, 0, 10, 10))
        ..clip()
        ..ellipse(const Rect.fromLTWH(0, 0, 10, 10))
        ..clip(evenOdd: true)
        ..restore();

      final document = PdfTestDocument.parse(writer.save());
      final content = document.contentOf(document.pages.single);

      expect(content, contains('W n\n'));
      expect(content, contains('W* n\n'));
      expect(pdfOperatorNames(content), contains('W'));
    });

    test('painting without a path writes nothing', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(10, 10)
        ..fill()
        ..stroke()
        ..fillAndStroke();

      final document = PdfTestDocument.parse(writer.save());

      expect(pdfOperatorNames(document.contentOf(document.pages.single)), [
        'cm',
      ]);
    });

    test('enforces PDF path rules', () {
      final page = NotePdfWriter().addPage(10, 10);

      expect(() => page.lineTo(Offset.zero), throwsStateError);
      expect(() => page.closePath(), throwsStateError);
      expect(() => page.clip(), throwsStateError);
      expect(page.restore, throwsStateError);
      expect(page.endGroup, throwsStateError);
      page.moveTo(Offset.zero);
      expect(page.save, throwsStateError);
      expect(() => page.setLineWidth(1), throwsStateError);
      expect(() => page.setOpacity(fill: 1), throwsStateError);
      expect(() => page.beginGroup(), throwsStateError);
    });

    test('rejects invalid dash patterns and allows solid', () {
      final page = NotePdfWriter().addPage(10, 10);

      expect(() => page.setDashPattern([-1]), throwsArgumentError);
      expect(() => page.setDashPattern([0, 0]), throwsArgumentError);
      expect(() => page.setDashPattern([]), returnsNormally);
    });

    test('rotates about a centre like Canvas.rotate', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 100).rotate(math.pi / 2, const Offset(10, 20));
      final document = PdfTestDocument.parse(writer.save());
      final matrix = pdfOperators(
        document.contentOf(document.pages.single),
      ).last.operands.map(double.parse).toList();

      // (x, y) -> (a x + c y + e, b x + d y + f). A quarter turn clockwise
      // about (10, 20) maps (11, 20) to (10, 21).
      final x = matrix[0] * 11 + matrix[2] * 20 + matrix[4];
      final y = matrix[1] * 11 + matrix[3] * 20 + matrix[5];
      expect(x, closeTo(10, 1e-3));
      expect(y, closeTo(21, 1e-3));
    });

    test('quadratic curves become the equivalent cubic', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 100)
        ..moveTo(Offset.zero)
        ..quadraticTo(const Offset(30, 0), const Offset(30, 30))
        ..stroke();
      final document = PdfTestDocument.parse(writer.save());

      expect(
        document.contentOf(document.pages.single),
        contains('20 0 30 10 30 30 c\n'),
      );
    });

    test('addPath replays every vector segment', () {
      final path = NoteVectorPath()
        ..moveTo(const Offset(1, 1))
        ..lineTo(const Offset(2, 2))
        ..quadraticTo(const Offset(3, 3), const Offset(4, 4))
        ..close();
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 100)
        ..addPath(path)
        ..fill();
      final document = PdfTestDocument.parse(writer.save());

      expect(pdfOperatorNames(document.contentOf(document.pages.single)), [
        'cm',
        'm',
        'l',
        'c',
        'h',
        'f',
      ]);
    });
  });

  group('graphics states, images and groups', () {
    test('opacity uses deduplicated ExtGState objects', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      final first = writer.addPage(100, 100);
      first
        ..save()
        ..setOpacity(fill: 0.5)
        ..restore()
        ..save()
        ..setOpacity(fill: 0.5)
        ..setOpacity(stroke: 0.25)
        ..restore();
      writer.addPage(100, 100).setOpacity(fill: 0.5);

      final document = PdfTestDocument.parse(writer.save());
      final states = document.pages.first.resources('ExtGState');

      expect(states, hasLength(2));
      expect(
        states.values.map((n) => document[n].body),
        containsAll(<Matcher>[
          allOf(contains('/ca 0.5 '), contains('/CA 1 ')),
          allOf(contains('/ca 0.5 '), contains('/CA 0.25 ')),
        ]),
      );
      expect(
        document.pages.last.resources('ExtGState').values.single,
        states.values.first,
        reason: 'the same alpha is one object across pages',
      );
    });

    test('restore forgets opacity set inside the save', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(10, 10)
        ..save()
        ..setOpacity(fill: 0.2, stroke: 0.2)
        ..restore()
        // Only the stroke is given: the fill must be back to 1.
        ..setOpacity(stroke: 0.7);

      final document = PdfTestDocument.parse(writer.save());
      final states = document.pages.single.resources('ExtGState').values;

      expect(
        states.map((n) => document[n].body),
        contains(allOf(contains('/ca 1 '), contains('/CA 0.7 '))),
      );
    });

    test('embeds images with RGB planes and a soft mask', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      final image = _translucentImage();
      writer.addPage(100, 100)
        ..drawImage(image, const Rect.fromLTWH(10, 20, 30, 40))
        ..drawImage(image, const Rect.fromLTWH(0, 0, 5, 5));
      writer
          .addPage(100, 100)
          .drawImage(image, const Rect.fromLTWH(0, 0, 1, 1));

      final document = PdfTestDocument.parse(writer.save());
      final page = document.pages.first;
      final xObject = document.imagesOf(page).values.single;

      expect(xObject.body, contains('/Width 2 /Height 1'));
      expect(xObject.body, contains('/ColorSpace /DeviceRGB'));
      expect(xObject.body, contains('/BitsPerComponent 8'));
      expect(xObject.data, [255, 0, 0, 0, 0, 255]);
      final mask = document[xObject.ref('SMask')];
      expect(mask.body, contains('/ColorSpace /DeviceGray'));
      expect(mask.data, [255, 128]);
      expect(
        document.imagesOf(document.pages.last).values.single.number,
        xObject.number,
        reason: 'one instance is embedded once',
      );
      final content = document.contentOf(page);
      // The unit square is mapped upright into the y-down page.
      expect(content, contains('30 0 0 -40 10 60 cm\n/Im1 Do\n'));
      expect(pdfOperatorNames(content, page).where((o) => o == 'Do'), [
        'Do',
        'Do',
      ]);
    });

    test('opaque images have no soft mask', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer
          .addPage(10, 10)
          .drawImage(_opaqueImage(), const Rect.fromLTWH(0, 0, 1, 1));

      final document = PdfTestDocument.parse(writer.save());
      final image = document.imagesOf(document.pages.single).values.single;

      expect(image.body, isNot(contains('/SMask')));
      expect(image.data, [1, 2, 3]);
    });

    test('ignores empty image destinations', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(10, 10)
        ..drawImage(_opaqueImage(), const Rect.fromLTWH(0, 0, 0, 5))
        ..drawImage(_opaqueImage(), const Rect.fromLTWH(0, 0, double.nan, 5));

      final document = PdfTestDocument.parse(writer.save());

      expect(document.imagesOf(document.pages.single), isEmpty);
    });

    test('transparency groups become form XObjects with their resources', () {
      final writer = NotePdfWriter(compressor: NotePdfWriter.noCompression);
      writer.addPage(100, 80)
        ..beginGroup(opacity: 0.5)
        ..setOpacity(fill: 0.3)
        ..rectangle(const Rect.fromLTWH(0, 0, 10, 10))
        ..fill()
        ..drawImage(_opaqueImage(), const Rect.fromLTWH(0, 0, 1, 1))
        ..beginGroup()
        ..rectangle(const Rect.fromLTWH(1, 1, 2, 2))
        ..fill()
        ..endGroup()
        ..endGroup();

      final document = PdfTestDocument.parse(writer.save());
      final page = document.pages.single;
      final outer = document.formsOf(page).values.single;

      expect(outer.body, contains('/BBox [0 0 100 80]'));
      expect(outer.body, contains('/Group << /Type /Group /S /Transparency'));
      expect(document.imagesOf(outer), hasLength(1));
      expect(document.formsOf(outer), hasLength(1));
      expect(
        pdfOperatorNames(outer.text, outer),
        containsAllInOrder(<String>['gs', 're', 'f', 'Do', 'Do']),
      );
      final names = pdfOperatorNames(document.contentOf(page), page);
      expect(names, ['cm', 'q', 'gs', 'Do', 'Q']);
      final state = document[page.resources('ExtGState').values.single];
      expect(state.body, contains('/ca 0.5 /CA 0.5'));
    });
  });

  group('PDF syntax', () {
    test('numbers never use exponents and are trimmed', () {
      expect(notePdfNumber(1), '1');
      expect(notePdfNumber(100), '100');
      expect(notePdfNumber(2.5), '2.5');
      expect(notePdfNumber(-0.00001), '0');
      expect(notePdfNumber(1e-9), '0');
      expect(notePdfNumber(1.23456), '1.2346');
      expect(notePdfNumber(1e30), '1000000000');
      expect(notePdfNumber(double.nan), '0');
      expect(notePdfNumber(double.negativeInfinity), '0');
    });
  });

  group('NotePdfImage', () {
    test('splits planes and detects transparency', () {
      final image = _translucentImage();

      expect(image.rgb, [255, 0, 0, 0, 0, 255]);
      expect(image.softMask, [255, 128]);
      expect(image.hasAlpha, isTrue);
      expect(image.isFullyTransparent, isFalse);
      expect(
        NotePdfImage.fromRgba(
          Uint8List(8),
          width: 2,
          height: 1,
        ).isFullyTransparent,
        isTrue,
      );
      expect(_opaqueImage().softMask, isNull);
    });

    test('rejects wrong sizes', () {
      expect(
        () => NotePdfImage.fromRgba(Uint8List(3), width: 1, height: 1),
        throwsArgumentError,
      );
      expect(
        () => NotePdfImage.fromRgba(Uint8List(0), width: 0, height: 1),
        throwsArgumentError,
      );
    });
  });
}
