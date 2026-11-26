import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/table/table.dart';

import '../../support/note_test_host.dart';
import 'table_invariants.dart';

/// Plays the host of a table view: keeps the table, applies `onChanged` and
/// drives the scope flags. The view is 300 x 120, so a 3 x 3 table has cells of
/// 100 x 40 (less the border inset).
class TableProbe {
  TableProbe({NoteTableObject? table, this.toolbar = false})
    : table = table ?? labelledTable();

  /// Whether a [NoteTableToolbar] is shown under the view.
  final bool toolbar;

  NoteTableObject table;
  final NoteTableSelectionController selection = NoteTableSelectionController();

  /// Passes no selection controller to the view when `true`.
  bool privateSelection = false;
  NoteTableSelectionController? otherSelection;

  final List<NoteTableObject> changes = [];
  int editRequests = 0;
  bool selected = false;
  bool editing = false;
  bool interactive = true;
  bool writable = true;
  bool shown = true;

  /// Answers `onRequestEdit` by switching [editing] on, as a real host does.
  bool grantsEditing = false;
  Size size = const Size(300, 120);
  late StateSetter _rebuild;
  late WidgetTester _tester;

  Future<void> pump(WidgetTester tester) async {
    _tester = tester;
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      noteTestHost(
        Align(
          alignment: Alignment.topLeft,
          child: StatefulBuilder(
            builder: (context, setState) {
              _rebuild = setState;

              return _content();
            },
          ),
        ),
      ),
    );
  }

  /// Changes the host state and lets the tree settle.
  Future<void> update(VoidCallback change) async {
    _rebuild(change);
    await _tester.pump();
    await _tester.pump();
  }

  /// The centre of grid position ([row], [column]) on screen, for the default
  /// 3 x 3 layout.
  Offset center(int row, int column) =>
      _tester.getTopLeft(find.byType(NoteTableView)) +
      Offset(50.0 + 100 * column, 20.0 + 40 * row);

  /// One tap that does not continue a double-tap series.
  Future<void> tap(int row, int column) async {
    await _tester.tapAt(center(row, column));
    await _tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> doubleTap(int row, int column) async {
    await _tester.tapAt(center(row, column));
    await _tester.pump(const Duration(milliseconds: 60));
    await _tester.tapAt(center(row, column));
    await _tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> drag(
    (int, int) from,
    (int, int) to, {
    List<(int, int)> through = const [],
  }) async {
    final gesture = await _tester.startGesture(
      center(from.$1, from.$2),
      kind: PointerDeviceKind.touch,
    );
    for (final (row, column) in [...through, to]) {
      await gesture.moveTo(center(row, column));
      await _tester.pump();
    }
    await gesture.up();
    await _tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> type(String text) async {
    await _tester.enterText(find.byType(EditableText), text);
    await _tester.pump();
  }

  Future<void> blur() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _tester.pump();
    await _tester.pump();
  }

  /// The text of the open editor, or `null` when none is open.
  String? get editorText {
    final field = find.byType(EditableText).evaluate();
    if (field.isEmpty) return null;

    return (field.single.widget as EditableText).controller.text;
  }

  bool get editorHasFocus {
    final field = find.byType(EditableText).evaluate();
    if (field.isEmpty) return false;

    return (field.single.widget as EditableText).focusNode.hasFocus;
  }

  NoteTableRange? get range => selection.rangeFor(table.id);

  Widget _content() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (shown)
        SizedBox.fromSize(size: size, child: _view())
      else
        const SizedBox.shrink(),
      if (toolbar)
        SizedBox(
          width: 600,
          child: NoteTableToolbar(
            table: table,
            selectionController: selection,
            onChanged: _apply,
          ),
        ),
    ],
  );

  Widget _view() => NoteTableView(
    table: table,
    selectionController: privateSelection ? null : otherSelection ?? selection,
    scope: NoteObjectViewScope(
      selected: selected,
      editing: editing,
      interactive: interactive,
      onChanged: writable
          ? (object) => _apply(object as NoteTableObject)
          : null,
      onRequestEdit: _requestEdit,
    ),
  );

  void _requestEdit() {
    editRequests++;
    if (grantsEditing) _rebuild(() => editing = true);
  }

  void _apply(NoteTableObject next) {
    changes.add(next);
    _rebuild(() => table = next);
  }
}
