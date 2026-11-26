import 'package:open_note/src/note/io/markup/note_pdf_text_layer.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';

/// A [NotePdfTextLayer] for tests and the example app, answering from a fixed
/// map of page index to runs.
class FakeNotePdfTextLayer implements NotePdfTextLayer {
  /// A layer with the runs of [pages].
  FakeNotePdfTextLayer([this.pages = const {}]);

  /// Runs by 0-based page index.
  final Map<int, List<NotePdfTextRun>> pages;

  @override
  Future<List<NotePdfTextRun>> runs(int pageIndex) async =>
      List.of(pages[pageIndex] ?? const []);
}
