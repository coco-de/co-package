import 'dart:typed_data';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/note_document_importer.dart';
import 'package:open_note/src/note/io/import/note_image_codec.dart';
import 'package:open_note/src/note/io/import/note_import_exception.dart';
import 'package:open_note/src/note/io/import/note_import_guard.dart';
import 'package:open_note/src/note/io/import/note_import_page_selection.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/import/note_pdf_page_renderer.dart';

/// Imports a PDF through the host's [NotePdfPageRenderer]: each page becomes a
/// note page whose background is the rendered picture.
///
/// This is also how a notebook exported as PDF by another note app (GoodNotes
/// and the like) comes in: its pages are **flattened**, so the old ink becomes
/// part of the background picture and cannot be edited or erased.
class NotePdfRendererImporter implements NoteDocumentImporter {
  /// An importer rendering pages [targetWidth] pixels wide. Pages whose size
  /// the renderer does not report are as wide as [pageSize].
  const NotePdfRendererImporter(
    this.renderer, {
    this.targetWidth = 1600,
    this.pageSize = NotePageSize.a4,
    this.documentKey,
  }) : assert(targetWidth > 0, 'targetWidth must be positive');

  /// Draws the PDF pages.
  final NotePdfPageRenderer renderer;

  /// Pixel width requested for every page picture.
  final int targetWidth;

  /// Fallback page width.
  final NotePageSize pageSize;

  /// The key each page's [NotePdfOrigin] records, to find the PDF's text
  /// again; the file name when null. Boxes from a text layer must be in the
  /// page size recorded there, so have the renderer report it.
  final String Function(NoteImportSource source)? documentKey;

  @override
  Future<List<NoteImportedPage>> import(
    NoteImportSource source, {
    List<int>? pageIndices,
  }) async {
    final count = await noteGuardImport(
      'reading "${source.name}"',
      () => renderer.pageCount(source.bytes),
    );
    if (count <= 0) {
      throw NoteImportException('"${source.name}" has no pages');
    }
    final key = documentKey?.call(source) ?? source.name;
    final pages = <NoteImportedPage>[];
    for (final index in NoteImportPageSelection.select(count, pageIndices)) {
      final page = await _page(source.bytes, index);
      pages.add(
        key.isEmpty
            ? page
            : page.copyWith(
                pdf: NotePdfOrigin(
                  document: key,
                  pageIndex: index,
                  size: page.size,
                ),
              ),
      );
    }

    return pages;
  }

  Future<NoteImportedPage> _page(Uint8List bytes, int index) async {
    final rendered = await noteGuardImport(
      'rendering page ${index + 1}',
      () => renderer.renderPage(bytes, index, targetWidth: targetWidth),
    );

    return NoteImportedPage(
      size: rendered.pageSize ?? await _sizeOf(rendered.png),
      backgroundPng: rendered.png,
    );
  }

  Future<NotePageSize> _sizeOf(Uint8List png) async {
    final pixels = await noteReadImageSize(png);

    return NotePageSize(
      pageSize.width,
      pageSize.width * pixels.height / pixels.width,
    );
  }
}
