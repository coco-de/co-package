import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/import/note_document_importer.dart';
import 'package:open_note/src/note/io/import/note_image_page_builder.dart';
import 'package:open_note/src/note/io/import/note_import_page_selection.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';

/// Imports a PNG or JPEG picture as one page.
///
/// The page is as wide as [pageSize] and its height follows the picture's
/// aspect ratio (EXIF orientation is applied by the decoder). The background is
/// a PNG: PNG input is kept byte for byte unless it must be scaled down, JPEG
/// is re-encoded.
class NoteImageImporter implements NoteDocumentImporter {
  /// An importer fitting pictures to the width of [pageSize].
  const NoteImageImporter({
    this.pageSize = NotePageSize.a4,
    this.maxPixelDimension = 4096,
  }) : assert(maxPixelDimension > 0, 'maxPixelDimension must be positive');

  /// Gives imported pages their width (the height is ignored).
  final NotePageSize pageSize;

  /// Larger pictures are scaled down so the longer side has this many pixels.
  final int maxPixelDimension;

  @override
  Future<List<NoteImportedPage>> import(
    NoteImportSource source, {
    List<int>? pageIndices,
  }) async {
    if (NoteImportPageSelection.select(1, pageIndices).isEmpty) return [];

    return [
      await noteImagePage(
        source.bytes,
        name: source.name,
        pageWidth: pageSize.width,
        maxPixelDimension: maxPixelDimension,
      ),
    ];
  }
}
