import 'dart:typed_data';

import 'package:open_note/src/note/io/import/note_import_source.dart';

/// The converter the host plugs in for slides, word processor documents and
/// e-books (PPT, DOC, EPUB…), typically a server or platform service. The
/// package ships none.
abstract interface class NoteOfficeConverter {
  /// [source] converted to PDF.
  Future<Uint8List> toPdf(NoteImportSource source);
}
