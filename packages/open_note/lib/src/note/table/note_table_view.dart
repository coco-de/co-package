import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_object_layer_scope.dart';
import 'package:open_note/src/note/table/note_table_cell_editor.dart';
import 'package:open_note/src/note/table/note_table_edit_session.dart';
import 'package:open_note/src/note/table/note_table_layout.dart';
import 'package:open_note/src/note/table/note_table_object.dart';
import 'package:open_note/src/note/table/note_table_painter.dart';
import 'package:open_note/src/note/table/note_table_range.dart';
import 'package:open_note/src/note/table/note_table_selection_controller.dart';
import 'package:open_note/src/note/table/note_table_strings.dart';
import 'package:open_note/src/note/table/note_table_view_style.dart';

/// Draws a table and, when `scope.interactive`, lets the user select and edit
/// its cells.
///
/// - Tap: selects the cell (a merged cell as a whole) and commits an open
///   editor.
/// - Drag: selects a rectangular range, grown over the merges it cuts.
/// - Double tap: edits the cell; if the scope is not already `editing` it also
///   calls `scope.onRequestEdit` so the host can start an editing session.
/// - `scope.editing`: opens the editor on the selected (else top-left) cell;
///   while it is `true` a tap on another cell moves the editor there.
///
/// The typed text is committed through `scope.onChanged` when the field loses
/// focus, the user taps or drags another cell, the host ends the session
/// (`editing` or `selected` turns `false`, or `interactive` becomes `false`) or
/// the view is removed. Commits made during a rebuild or a removal arrive after
/// that frame, so after a removal the callback must not assume its widget is
/// still mounted; nothing is reported when the whole navigator is torn down.
/// Escape discards the text. So does an outside change of the table that resizes
/// the grid, re-merges the edited region or rewrites its text. Editing needs
/// `scope.onChanged`; selecting does not.
///
/// The view fills its constraints (the host layer gives tight constraints equal
/// to the object's bounds) and takes `table.bounds.size` where they are loose.
class NoteTableView extends StatefulWidget {
  /// Creates a view of [table].
  const NoteTableView({
    required this.table,
    required this.scope,
    super.key,
    this.selectionController,
    this.strings = const NoteTableStrings(),
    this.style = const NoteTableViewStyle(),
  });

  /// Key of the selection highlight.
  static const Key selectionKey = ValueKey<String>('note-table-selection');

  /// The table to show.
  final NoteTableObject table;

  /// Interaction state and callbacks given by the hosting layer.
  final NoteObjectViewScope scope;

  /// Shared selection, so a toolbar can act on it. `null` keeps the selection
  /// private to this view.
  final NoteTableSelectionController? selectionController;

  /// Accessibility text.
  final NoteTableStrings strings;

  /// Colours of the selection highlight and cell editor.
  final NoteTableViewStyle style;

  @override
  State<NoteTableView> createState() => _NoteTableViewState();
}

typedef _CellPosition = ({int row, int column});

class _NoteTableViewState extends State<NoteTableView> {
  NoteTableSelectionController? _ownedController;
  NoteTableEditSession? _session;
  NavigatorState? _navigator;
  NoteObjectController? _layer;
  NotePendingEditRegistration? _pendingEdit;
  _CellPosition? _lastTapped;
  _CellPosition? _dragOrigin;

  NoteTableSelectionController get _selection =>
      widget.selectionController ??
      (_ownedController ??= NoteTableSelectionController());

  bool get _canEdit =>
      widget.scope.interactive && widget.scope.onChanged != null;

  NoteTableRange? get _shownSelection {
    if (!widget.scope.interactive) return null;
    final range = _selection.rangeFor(widget.table.id);

    return range == null ? null : widget.table.expandToMerges(range);
  }

  @override
  void initState() {
    super.initState();
    if (widget.scope.editing && _canEdit) _openOnSelection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.maybeOf(context);
    final layer = NoteObjectLayerScope.maybeControllerOf(context);
    if (layer != _layer) {
      _layer = layer;
      if (_session != null) _registerPendingEdit();
    }
  }

  @override
  void didUpdateWidget(NoteTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionController != widget.selectionController) {
      _switchController(oldWidget);
    }
    _reconcileSession(oldWidget);
    if (oldWidget.scope.selected && !widget.scope.selected) {
      _clearSelectionLater();
    }
  }

  @override
  void dispose() {
    _commitAfterFrame(widget.table, _whileHostLives(widget.scope.onChanged));
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    // While a cell is edited, presses on the table must not blur the field (the
    // gestures decide what happens). Otherwise the table is "outside" every
    // other text field, so pressing it blurs them.
    enabled: _session != null,
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.strings.tableLabel(
        widget.table.rowCount,
        widget.table.columnCount,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.constrain(widget.table.bounds.size);
          final layout = NoteTableLayout(widget.table, Offset.zero & size);

          return SizedBox.fromSize(
            size: size,
            child: ListenableBuilder(
              listenable: _selection,
              builder: (context, _) => _surface(context, layout),
            ),
          );
        },
      ),
    ),
  );

  Widget _surface(BuildContext context, NoteTableLayout layout) {
    final session = _session;
    final selection = _shownSelection;
    final interactive = widget.scope.interactive;

    return _NoteTableSurface(
      layout: layout,
      style: widget.style,
      gestures: _gestures(layout),
      painter: NoteTablePainter(
        table: widget.table,
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        hiddenTextCell: session == null
            ? null
            : (row: session.row, column: session.column),
        selection: selection,
        strings: widget.strings,
        onCellTap: interactive
            ? (row, column) => _handleTap((row: row, column: column), 1)
            : null,
      ),
      // The editor has its own border, so its cell is not highlighted too.
      highlight: selection == session?.range ? null : selection,
      editorRange: session?.range,
      editor: session == null
          ? null
          : NoteTableCellEditor(
              session: session,
              table: widget.table,
              cellSize: layout.rectOf(session.range).size,
              viewStyle: widget.style,
              strings: widget.strings,
              onSubmitted: () => _handleSubmitted(session),
              onCancel: () => _handleCancel(session),
            ),
    );
  }

  Map<Type, GestureRecognizerFactory> _gestures(NoteTableLayout layout) {
    if (!widget.scope.interactive) return const {};

    return {
      SerialTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
            () => SerialTapGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer.onSerialTapUp = (details) =>
                _handleTap(layout.cellAt(details.localPosition), details.count),
          ),
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer
              // Report the pressed cell, not the one reached after the slop.
              ..dragStartBehavior = DragStartBehavior.down
              ..onStart = ((details) =>
                  _startDrag(layout.cellAt(details.localPosition)))
              ..onUpdate = ((details) =>
                  _updateDrag(layout.cellAt(details.localPosition)))
              ..onEnd = ((_) => _dragOrigin = null)
              ..onCancel = (() => _dragOrigin = null),
          ),
    };
  }

  void _handleTap(_CellPosition cell, int count) {
    final table = widget.table;
    final anchor = table.anchorOf(cell.row, cell.column);
    // A tap series may wander to a neighbour; only a repeat on the same cell
    // is a double tap.
    final isRepeat = count > 1 && anchor == _lastTapped;
    _lastTapped = anchor;
    // Only an accessibility tap can reach the cell under the editor.
    if (_session?.isAt(anchor) ?? false) return;
    _commit();
    _selection.select(table.id, table.rangeAt(anchor.row, anchor.column));
    if (isRepeat) {
      _startEditing(anchor, askHost: true);
    } else if (widget.scope.editing) {
      _startEditing(anchor);
    }
  }

  void _startDrag(_CellPosition cell) {
    _commit();
    _dragOrigin = cell;
    _selectBetween(cell, cell);
  }

  void _updateDrag(_CellPosition cell) {
    final origin = _dragOrigin;
    if (origin != null) _selectBetween(origin, cell);
  }

  void _selectBetween(_CellPosition from, _CellPosition to) {
    final table = widget.table;
    final range = NoteTableRange(
      firstRow: from.row,
      firstColumn: from.column,
      lastRow: to.row,
      lastColumn: to.column,
    );
    _selection.select(table.id, table.expandToMerges(range));
  }

  void _startEditing(_CellPosition anchor, {bool askHost = false}) {
    if (!_canEdit) return;
    setState(() => _openSession(anchor));
    if (askHost && !widget.scope.editing) widget.scope.onRequestEdit?.call();
  }

  void _openSession(_CellPosition anchor) {
    final session = NoteTableEditSession(
      widget.table,
      anchor.row,
      anchor.column,
    );
    _session = session;
    _selection.attachEditor(widget.table.id, _flushEditor);
    _registerPendingEdit();
    session.focusNode.requestFocus();
  }

  /// Lets the object layer commit the typed text as its own undo step before
  /// a drag starts or the history moves: on touch screens pressing elsewhere
  /// does not take the focus away, so the text would join that step.
  void _registerPendingEdit() {
    _pendingEdit?.cancel();
    _pendingEdit = _layer?.registerPendingEdit(widget.table.id, (current) {
      if (current is! NoteTableObject) return null;
      final updated = _flushEditor(current);

      return identical(updated, current) ? null : updated;
    });
  }

  /// Opens the editor from `initState` / `didUpdateWidget`.
  void _openOnSelection() {
    final table = widget.table;
    final selected = table.expandToMerges(
      _selection.rangeFor(table.id) ?? const NoteTableRange.cell(0, 0),
    );
    final anchor = table.anchorOf(selected.firstRow, selected.firstColumn);
    _openSession(anchor);
    _selectLater(table.id, table.rangeAt(anchor.row, anchor.column));
  }

  /// Ends the session without reporting anything. The field is still mounted,
  /// so its controller and focus node are released after the frame.
  void _closeSession() {
    final session = _session;
    if (session == null) return;
    _session = null;
    _pendingEdit?.cancel();
    _pendingEdit = null;
    _selection.detachEditor(_flushEditor);
    WidgetsBinding.instance.addPostFrameCallback((_) => session.dispose());
  }

  void _commit() {
    final session = _session;
    if (session == null) return;
    final table = widget.table;
    final updated = session.applyTo(table);
    setState(_closeSession);
    if (!identical(updated, table)) widget.scope.onChanged?.call(updated);
  }

  /// [onChanged], silenced when the navigator around this view was torn down
  /// with it: then the whole screen is gone and so is the host. A view removed
  /// on its own (a page switch) still reports the typed text.
  ValueChanged<NoteObject>? _whileHostLives(ValueChanged<NoteObject>? report) {
    if (report == null) return null;
    final navigator = _navigator;

    return (object) {
      if (navigator == null || navigator.mounted) report(object);
    };
  }

  /// Commits while the tree is being built or torn down: the host is told after
  /// the frame, when it may rebuild.
  void _commitAfterFrame(
    NoteTableObject table,
    ValueChanged<NoteObject>? onChanged,
  ) {
    final session = _session;
    if (session == null) return;
    final updated = session.applyTo(table);
    _closeSession();
    if (identical(updated, table) || onChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(updated));
  }

  NoteTableObject _flushEditor(NoteTableObject base) {
    final session = _session;
    if (!mounted || session == null || !session.isValidFor(base)) return base;
    final updated = session.applyTo(base);
    setState(_closeSession);

    return updated;
  }

  void _handleSubmitted(NoteTableEditSession session) {
    if (mounted && identical(session, _session)) _commit();
  }

  void _handleCancel(NoteTableEditSession session) {
    if (mounted && identical(session, _session)) setState(_closeSession);
  }

  void _reconcileSession(NoteTableView oldWidget) {
    final session = _session;
    if (session != null) {
      if (oldWidget.table.id != widget.table.id) {
        _commitAfterFrame(oldWidget.table, oldWidget.scope.onChanged);
      } else if (!session.isValidFor(widget.table)) {
        _closeSession();
      } else if (_endsEditing(oldWidget.scope)) {
        _commitAfterFrame(
          widget.table,
          widget.scope.onChanged ?? oldWidget.scope.onChanged,
        );
      }
    }
    final startsEditing = widget.scope.editing && !oldWidget.scope.editing;
    if (startsEditing && _session == null && _canEdit) _openOnSelection();
  }

  bool _endsEditing(NoteObjectViewScope before) {
    final now = widget.scope;

    return !_canEdit ||
        (before.editing && !now.editing) ||
        (before.selected && !now.selected);
  }

  void _switchController(NoteTableView oldWidget) {
    (oldWidget.selectionController ?? _ownedController)?.detachEditor(
      _flushEditor,
    );
    final owned = _ownedController;
    if (widget.selectionController != null && owned != null) {
      _ownedController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => owned.dispose());
    }
    if (_session != null) {
      _selection.attachEditor(widget.table.id, _flushEditor);
    }
  }

  // Notifying listeners during a build would mark widgets dirty mid-frame, so
  // selection changes made while building are applied after the frame.
  void _selectLater(String tableId, NoteTableRange range) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.table.id == tableId) {
        _selection.select(tableId, range);
      }
    });
  }

  void _clearSelectionLater() {
    final tableId = widget.table.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selection.clear(tableId);
    });
  }
}

/// The painted grid with the selection highlight and the cell editor on top.
class _NoteTableSurface extends StatelessWidget {
  const _NoteTableSurface({
    required this.layout,
    required this.gestures,
    required this.painter,
    required this.style,
    this.highlight,
    this.editorRange,
    this.editor,
  });

  final NoteTableLayout layout;
  final Map<Type, GestureRecognizerFactory> gestures;
  final NoteTablePainter painter;
  final NoteTableViewStyle style;
  final NoteTableRange? highlight;
  final NoteTableRange? editorRange;
  final Widget? editor;

  @override
  Widget build(BuildContext context) {
    final highlighted = highlight;
    final edited = editorRange;
    final field = editor;

    return Stack(
      children: [
        // The detector lies under the editor, not around it, so that presses
        // on the text field (placing the cursor) are the field's own.
        Positioned.fill(
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            // Cells have their own semantics; a drag is not a scroll.
            excludeFromSemantics: true,
            gestures: gestures,
            child: CustomPaint(painter: painter),
          ),
        ),
        // The keys keep the text field's state when the highlight comes and goes.
        if (highlighted != null)
          Positioned.fromRect(
            key: const ValueKey<String>('highlight'),
            rect: layout.rectOf(highlighted),
            child: IgnorePointer(
              child: DecoratedBox(
                key: NoteTableView.selectionKey,
                decoration: BoxDecoration(
                  color: style.selectionFillColor,
                  border: Border.all(
                    color: style.selectionColor,
                    width: style.selectionBorderWidth,
                  ),
                ),
              ),
            ),
          ),
        if (edited != null && field != null)
          Positioned.fromRect(
            key: const ValueKey<String>('editor'),
            rect: layout.rectOf(edited),
            child: field,
          ),
      ],
    );
  }
}
