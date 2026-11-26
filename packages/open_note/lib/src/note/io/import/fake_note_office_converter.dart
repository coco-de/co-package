import 'dart:typed_data';

import 'package:open_note/src/note/io/import/note_import_source.dart';
import 'package:open_note/src/note/io/import/note_office_converter.dart';

/// A [NoteOfficeConverter] for tests and the example app: every conversion
/// returns [pdf] and is recorded.
class FakeNoteOfficeConverter implements NoteOfficeConverter {
  /// A fake answering with [pdf], or throwing [failure] when set.
  FakeNoteOfficeConverter({Uint8List? pdf, this.failure})
    : pdf = pdf ?? Uint8List.fromList('%PDF-1.4\n%%EOF\n'.codeUnits);

  /// The conversion result.
  final Uint8List pdf;

  /// Thrown by every call when set.
  final Exception? failure;

  /// What was converted, in call order.
  final List<NoteImportSource> sources = [];

  @override
  Future<Uint8List> toPdf(NoteImportSource source) async {
    final error = failure;
    if (error != null) throw error;
    sources.add(source);

    return pdf;
  }
}
