import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';

/// Turns a file into note pages.
///
/// Implementations: `NoteImageImporter`, `NotePdfRendererImporter`,
/// `NoteOfficeImporter` and `NoteScanImporter`.
abstract interface class NoteDocumentImporter {
  /// The pages of [source].
  ///
  /// With [pageIndices] (0-based) only those pages are imported, in the given
  /// order; repeated and out-of-range indices are ignored (see
  /// `NoteImportPageSelection`). Throws `NoteImportException` when the file
  /// cannot be imported.
  Future<List<NoteImportedPage>> import(
    NoteImportSource source, {
    List<int>? pageIndices,
  });
}
