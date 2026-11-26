import 'package:open_note/src/note/io/import/note_document_scanner.dart';
import 'package:open_note/src/note/io/import/note_import_source.dart';

/// A [NoteDocumentScanner] for tests and the example app: every scan returns
/// [pages] and records its input.
class FakeNoteDocumentScanner implements NoteDocumentScanner {
  /// A fake answering with [pages], or throwing [failure] when set.
  FakeNoteDocumentScanner({this.pages = const [], this.failure});

  /// The pictures every scan returns.
  final List<NoteImportSource> pages;

  /// Thrown by every call when set.
  final Exception? failure;

  /// The input of each call (`null` for a camera capture).
  final List<NoteImportSource?> requests = [];

  @override
  Future<List<NoteImportSource>> scan({NoteImportSource? source}) async {
    final error = failure;
    if (error != null) throw error;
    requests.add(source);

    return List.of(pages);
  }
}
