import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';

/// The text of a PDF, provided by the host's PDF library so users can select
/// text to highlight, underline or strike out. The package ships none.
abstract interface class NotePdfTextLayer {
  /// The text runs of page [pageIndex] (0-based), in page coordinates. Pages
  /// without text (or out of range) give an empty list.
  Future<List<NotePdfTextRun>> runs(int pageIndex);
}
