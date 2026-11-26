import 'package:open_note/src/note/io/import/note_document_importer.dart';
import 'package:open_note/src/note/io/import/note_import_exception.dart';
import 'package:open_note/src/note/io/import/note_import_guard.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_imported_page.dart';
import 'package:open_note/src/note/io/import/note_office_converter.dart';

/// Imports office documents and e-books by converting them to PDF with
/// [converter] and importing the result with [pdfImporter].
class NoteOfficeImporter implements NoteDocumentImporter {
  /// An importer from a host [converter] and a PDF [pdfImporter].
  const NoteOfficeImporter(this.converter, this.pdfImporter);

  /// Converts the source to PDF.
  final NoteOfficeConverter converter;

  /// Imports the converted PDF.
  final NoteDocumentImporter pdfImporter;

  @override
  Future<List<NoteImportedPage>> import(
    NoteImportSource source, {
    List<int>? pageIndices,
  }) async {
    final pdf = await noteGuardImport(
      'converting "${source.name}"',
      () => converter.toPdf(source),
    );
    if (pdf.isEmpty) {
      throw NoteImportException('converting "${source.name}" produced nothing');
    }

    return pdfImporter.import(
      NoteImportSource(
        name: '${source.name}.pdf',
        bytes: pdf,
        mimeType: 'application/pdf',
      ),
      pageIndices: pageIndices,
    );
  }
}
