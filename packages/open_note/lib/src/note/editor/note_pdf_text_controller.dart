import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_run.dart';
import 'package:open_note/src/note/io/markup/note_pdf_text_selection.dart';

/// Where reading a page's PDF text stands.
enum NotePdfTextStatus { idle, loading, ready, empty, failed }

/// The text of the open PDF page and what is selected on it, in PDF
/// coordinates.
class NotePdfTextController extends ChangeNotifier {
  NotePdfTextStatus _status = NotePdfTextStatus.idle;
  List<NotePdfTextRun> _runs = const [];
  List<NotePdfTextRun> _selected = const [];
  Object? _key;
  bool _isDisposed = false;

  NotePdfTextStatus get status => _status;

  /// The page's runs in reading order.
  List<NotePdfTextRun> get runs => _runs;

  List<NotePdfTextRun> get selected => _selected;

  String get selectedText => NotePdfTextSelection.textOf(_selected);

  /// Reads the runs of the page named [key] with [read], unless they are read
  /// or being read already. A failure is reported and may be tried again.
  Future<void> load(
    Object key,
    Future<List<NotePdfTextRun>> Function() read,
  ) async {
    if (key == _key && _status != NotePdfTextStatus.failed) return;
    _key = key;
    _set(NotePdfTextStatus.loading);
    try {
      final runs = NotePdfTextSelection.readingOrder(await read());
      if (_isDisposed || _key != key) return;
      _set(
        runs.isEmpty ? NotePdfTextStatus.empty : NotePdfTextStatus.ready,
        runs: runs,
      );
    } on Object catch (error, stack) {
      if (_isDisposed || _key != key) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'open_note',
          context: ErrorDescription('while reading PDF text'),
        ),
      );
      _set(NotePdfTextStatus.failed);
    }
  }

  /// Forgets the page.
  void reset() {
    if (_key == null) return;
    _key = null;
    _set(NotePdfTextStatus.idle);
  }

  void select(Offset from, Offset to) =>
      _select(NotePdfTextSelection.between(_runs, from, to));

  void clear() => _select(const []);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _select(List<NotePdfTextRun> selected) {
    if (listEquals(selected, _selected)) return;
    _selected = selected;
    notifyListeners();
  }

  void _set(NotePdfTextStatus status, {List<NotePdfTextRun> runs = const []}) {
    _status = status;
    _runs = runs;
    _selected = const [];
    notifyListeners();
  }
}
