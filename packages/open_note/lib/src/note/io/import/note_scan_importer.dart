import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/note_document_importer.dart';
import 'package:open_note/src/note/io/import/note_document_scanner.dart';
import 'package:open_note/src/note/io/import/note_image_page_builder.dart';
import 'package:open_note/src/note/io/import/note_import_guard.dart';
import 'package:open_note/src/note/io/import/note_import_page_selection.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/import/note_scan_filter.dart';

/// Imports pages from a [NoteDocumentScanner], applying a [NoteScanFilter].
/// Pages are as wide as [pageSize] and as tall as each picture's aspect ratio
/// needs.
class NoteScanImporter implements NoteDocumentImporter {
  /// An importer applying [filter] to what [scanner] returns.
  const NoteScanImporter(
    this.scanner, {
    this.filter = NoteScanFilter.none,
    this.pageSize = NotePageSize.a4,
    this.maxPixelDimension = 4096,
  }) : assert(maxPixelDimension > 0, 'maxPixelDimension must be positive');

  /// Produces the page pictures.
  final NoteDocumentScanner scanner;

  /// Applied to every page.
  final NoteScanFilter filter;

  /// Gives imported pages their width (the height is ignored).
  final NotePageSize pageSize;

  /// Larger pictures are scaled down so the longer side has this many pixels.
  final int maxPixelDimension;

  /// Hands [source] to the scanner for processing and imports the result;
  /// [pageIndices] picks among the scanned pages.
  @override
  Future<List<NoteImportedPage>> import(
    NoteImportSource source, {
    List<int>? pageIndices,
  }) => _scan(source, pageIndices);

  /// Captures new pages with the scanner (camera) and imports them. A
  /// cancelled capture gives an empty list.
  Future<List<NoteImportedPage>> capture({List<int>? pageIndices}) =>
      _scan(null, pageIndices);

  Future<List<NoteImportedPage>> _scan(
    NoteImportSource? source,
    List<int>? pageIndices,
  ) async {
    final scans = await noteGuardImport(
      'scanning',
      () => scanner.scan(source: source),
    );
    final pages = <NoteImportedPage>[];
    for (final index in NoteImportPageSelection.select(
      scans.length,
      pageIndices,
    )) {
      final scan = scans[index];
      pages.add(
        await noteImagePage(
          scan.bytes,
          name: scan.name,
          pageWidth: pageSize.width,
          maxPixelDimension: maxPixelDimension,
          filter: filter,
        ),
      );
    }

    return pages;
  }
}
