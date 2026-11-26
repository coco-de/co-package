import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_range.dart';

/// Applies the text still being typed in an open cell editor to a table and
/// closes the editor. Returns the table unchanged when the editor does not fit
/// it.
typedef NoteTableEditorFlush = NoteTableObject Function(NoteTableObject table);

/// The cell selection of tables, shared by `NoteTableView` and
/// `NoteTableToolbar`. At most one table has a selection at a time.
///
/// Give the same controller to the view (through `registerNoteTableObject`) and
/// to the toolbar. It notifies only when the selection really changes. After
/// [dispose] every method is a no-op.
class NoteTableSelectionController extends ChangeNotifier {
  String? _tableId;
  NoteTableRange? _range;
  String? _editorTableId;
  NoteTableEditorFlush? _editorFlush;
  bool _isDisposed = false;

  /// Id of the table that holds the selection, or `null`.
  String? get tableId => _tableId;

  /// The selected cells, or `null`. It may be stale after the table changed;
  /// pass it through `NoteTableObject.expandToMerges` before use.
  NoteTableRange? get range => _range;

  /// The selection of table [tableId], or `null` when it has none.
  NoteTableRange? rangeFor(String tableId) =>
      tableId == _tableId ? _range : null;

  /// Selects [range] of table [tableId], replacing any selection.
  void select(String tableId, NoteTableRange range) {
    if (_isDisposed || (_tableId == tableId && _range == range)) return;
    _tableId = tableId;
    _range = range;
    notifyListeners();
  }

  /// Clears the selection; with a [tableId] only when that table holds it.
  void clear([String? tableId]) {
    if (_isDisposed || _tableId == null) return;
    if (tableId != null && tableId != _tableId) return;
    _tableId = null;
    _range = null;
    notifyListeners();
  }

  /// Registers the open cell editor of table [tableId]; the view calls this.
  /// The latest registration wins.
  void attachEditor(String tableId, NoteTableEditorFlush flush) {
    if (_isDisposed) return;
    _editorTableId = tableId;
    _editorFlush = flush;
  }

  /// Removes the editor registered with [flush]; the view calls this.
  void detachEditor(NoteTableEditorFlush flush) {
    if (_editorFlush != flush) return;
    _editorTableId = null;
    _editorFlush = null;
  }

  /// [table] with the text still being typed in its open cell editor, which is
  /// closed without reporting that text on its own. Call this before changing
  /// the structure of a table that may be in an editing session, and apply the
  /// change to the returned table; the toolbar does.
  NoteTableObject flushEditor(NoteTableObject table) {
    final flush = _editorFlush;
    if (_isDisposed || flush == null || _editorTableId != table.id) {
      return table;
    }

    return flush(table);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _editorFlush = null;
    super.dispose();
  }
}
