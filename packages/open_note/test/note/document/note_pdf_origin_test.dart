import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/editor/note_export.dart';
import 'package:open_note/src/note/io/io.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

import 'support/document_fixtures.dart';

void main() {
  const size = NotePageSize(400, 600);

  test('a PDF import records where each page came from', () async {
    final importer = NotePdfRendererImporter(
      FakeNotePdfPageRenderer(pages: 2, pageSize: size),
    );

    final imported = await importer.import(
      NoteImportSource(name: 'slides.pdf', bytes: Uint8List(1)),
      pageIndices: [1],
    );
    final pages = await notePagesFromImport(
      imported,
      storeImage: (png, index) async => 'stored-$index.png',
      idFactory: counterIds(),
      clock: fixedClock,
    );

    const origin = NotePdfOrigin(
      document: 'slides.pdf',
      pageIndex: 1,
      size: size,
    );
    expect(imported.single.pdf, origin);
    expect(pages.single.pdf, origin.copyWith(picture: 'stored-0.png'));
    expect(NoteImportedPage.fromJson(imported.single.toJson()).pdf, origin);

    final keyed = await NotePdfRendererImporter(
      FakeNotePdfPageRenderer(pages: 1, pageSize: size),
      documentKey: (source) => 'hash:${source.name}',
    ).import(NoteImportSource(name: 'a.pdf', bytes: Uint8List(1)));
    expect(keyed.single.pdf!.document, 'hash:a.pdf');
  });

  test('a page keeps its origin through JSON and duplication', () {
    final page =
        NotePage.blank(
          template: NotePaperTemplate.image(
            id: 'imported:1',
            imageSource: 'p.png',
            size: size,
          ),
          idFactory: counterIds(),
          clock: fixedClock,
        ).copyWith(
          pdf: const NotePdfOrigin(
            document: 'a.pdf',
            pageIndex: 3,
            size: size,
            picture: 'p.png',
          ),
        );
    final registry = NoteObjectRegistry();

    final restored = NotePage.fromJson(page.toJson(), registry: registry)!;
    expect(restored.pdf, page.pdf);
    expect(
      NotePageOps.duplicate(
        page,
        registry: registry,
        idFactory: counterIds('d'),
        clock: fixedClock,
      ).pdf,
      page.pdf,
    );
    expect(NotePdfOrigin.fromJson({'document': '', 'page': 0}), isNull);
    expect(NotePdfOrigin.fromJson({'document': 'a', 'page': -1}), isNull);
  });

  group('page mapping', () {
    NotePage imported(NotePageSize paper) => NotePage.blank(
      template: NotePaperTemplate.image(
        id: 'imported:1',
        imageSource: 'p.png',
        size: paper,
      ),
      idFactory: counterIds(),
      clock: fixedClock,
    );

    const origin = NotePdfOrigin(document: 'a.pdf', pageIndex: 0, size: size);
    const probe = Offset(40, 90);

    test('follows rotation and margins like the ink does', () {
      final flat = imported(size);
      final at = NotePdfPageMapping(flat, origin).toPage(probe);
      expect(at, probe);

      var page = flat;
      var ink = Scribble(
        strokes: [
          Stroke(
            points: [Point(x: at.dx, y: at.dy)],
          ),
        ],
      );
      Offset inkAt() => Offset(
        ink.strokes.single.points.single.x,
        ink.strokes.single.points.single.y,
      );
      for (var turn = 0; turn < 4; turn++) {
        final margins = EdgeInsets.fromLTRB(10.0 * turn, 20, 0, 30);
        final shift = Offset(
          margins.left - page.margins.left,
          margins.top - page.margins.top,
        );
        ink = NoteInkTransforms.translate(ink, shift);
        page = NotePageOps.setMargins(page, margins);
        ink = NoteInkTransforms.rotate(ink, 1, page.size.toSize());
        page = NotePageOps.rotate(page, 1);

        final mapping = NotePdfPageMapping(page, origin);
        expect(
          (mapping.toPage(probe) - inkAt()).distance,
          lessThan(0.001),
          reason: 'turn ${turn + 1}',
        );
        expect(
          (mapping.toPdf(inkAt()) - probe).distance,
          lessThan(0.001),
          reason: 'turn ${turn + 1}',
        );
      }
    });

    test('fits the PDF page onto the paper like its picture', () {
      // 두 배 크기 종이: 비율이 같으면 균일하게 늘어난다.
      final page = imported(const NotePageSize(800, 1200));
      final mapping = NotePdfPageMapping(page, origin);

      expect(mapping.toPage(probe), probe * 2);
      expect(mapping.scale, 2);

      // 비율이 다르면 contain 은 가운데에 놓는다.
      final wide = NotePdfPageMapping(
        imported(const NotePageSize(600, 600)),
        origin,
      );
      expect(wide.toPage(Offset.zero), const Offset(100, 0));
      expect(
        wide.rectToPage(const Rect.fromLTWH(0, 0, 400, 600)),
        const Rect.fromLTWH(100, 0, 400, 600),
      );
    });
  });
}
