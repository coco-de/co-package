import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_pane_divider.dart';
import 'package:open_note/src/note/view/note_pane_fractions.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// Panes side by side ([Axis.horizontal]) or stacked ([Axis.vertical]) with
/// draggable dividers. It needs bounded constraints.
///
/// Sizes are fractions of the space left after the dividers; every pane keeps
/// at least [minFraction] of it. With [fractions] the widget is controlled:
/// it draws exactly those, and reports every drag through
/// [onFractionsChanged]. Without them it keeps its own sizes, starting from
/// [initialFractions] (equal shares by default). Give the children keys to
/// keep their state when you reorder them.
class NoteResizablePanes extends StatefulWidget {
  /// Lays [children] out along [axis] with a divider between neighbours.
  const NoteResizablePanes({
    required this.children,
    super.key,
    this.axis = Axis.horizontal,
    this.fractions,
    this.initialFractions,
    this.minFraction = defaultMinFraction,
    this.onFractionsChanged,
    this.onResizeEnd,
    this.dividerThickness = 12,
    this.dividerHitExtent = 24,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  }) : assert(minFraction >= 0 && minFraction <= 0.5),
       assert(dividerThickness >= 0);

  /// Default [minFraction].
  static const double defaultMinFraction = 0.15;

  /// Change of the pane before a divider per accessibility step.
  static const double semanticStep = 0.05;

  /// Key of the draggable divider after pane [index].
  static Key dividerKey(int index) =>
      ValueKey<String>('note-pane-divider-$index');

  /// The panes, in screen order.
  final List<Widget> children;

  /// Direction in which the panes follow each other.
  final Axis axis;

  /// Controlled sizes, one per child; see the class comment.
  final List<double>? fractions;

  /// Starting sizes of an uncontrolled widget.
  final List<double>? initialFractions;

  /// Smallest share a pane may be dragged to (at most `1 / children.length`).
  final double minFraction;

  /// New sizes while a divider moves.
  final ValueChanged<List<double>>? onFractionsChanged;

  /// The sizes when a drag ends — a good moment to persist them.
  final ValueChanged<List<double>>? onResizeEnd;

  /// Layout space between two panes.
  final double dividerThickness;

  /// Width of the area that grabs a divider; at least [dividerThickness].
  final double dividerHitExtent;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteResizablePanes> createState() => _NoteResizablePanesState();
}

class _NoteResizablePanesState extends State<NoteResizablePanes> {
  late List<double> _own;
  List<double>? _dragStart;
  int _dragDivider = 0;
  Offset _dragOrigin = Offset.zero;
  List<double>? _dragLatest;
  double _available = 0;

  bool get _horizontal => widget.axis == Axis.horizontal;

  List<double> get _current => NotePaneFractions.normalize(
    widget.fractions ?? _own,
    widget.children.length,
    minFraction: widget.minFraction,
  );

  @override
  void initState() {
    super.initState();
    _own = NotePaneFractions.normalize(
      widget.initialFractions,
      widget.children.length,
      minFraction: widget.minFraction,
    );
  }

  @override
  void didUpdateWidget(NoteResizablePanes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _dragStart = null;
      _own = NotePaneFractions.normalize(
        widget.initialFractions,
        widget.children.length,
        minFraction: widget.minFraction,
      );
    }
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject();

    return box is RenderBox && box.hasSize ? box.globalToLocal(global) : global;
  }

  void _startDrag(int divider, DragStartDetails details) {
    _dragDivider = divider;
    _dragStart = _current;
    _dragLatest = null;
    _dragOrigin = _toLocal(details.globalPosition);
  }

  void _updateDrag(DragUpdateDetails details) {
    final start = _dragStart;
    if (start == null || _available <= 0) return;
    final moved = _toLocal(details.globalPosition) - _dragOrigin;
    final delta = (_horizontal ? moved.dx : moved.dy) / _available;
    _apply(
      NotePaneFractions.moveDivider(
        start,
        _dragDivider,
        delta,
        minFraction: widget.minFraction,
      ),
    );
  }

  void _endDrag() {
    if (_dragStart == null) return;
    _dragStart = null;
    widget.onResizeEnd?.call(_dragLatest ?? _current);
    _dragLatest = null;
  }

  void _nudge(int divider, double delta) {
    _apply(
      NotePaneFractions.moveDivider(
        _current,
        divider,
        delta,
        minFraction: widget.minFraction,
      ),
    );
    widget.onResizeEnd?.call(_dragLatest ?? _current);
    _dragLatest = null;
  }

  void _apply(List<double> next) {
    if (listEquals(next, _current)) return;
    _dragLatest = next;
    if (widget.fractions == null) setState(() => _own = next);
    widget.onFractionsChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth && constraints.hasBoundedHeight,
          'NoteResizablePanes needs bounded constraints',
        );

        return _buildPanes(
          _horizontal ? constraints.maxWidth : constraints.maxHeight,
        );
      },
    );
  }

  Widget _buildPanes(double total) {
    final count = widget.children.length;
    final thickness = widget.dividerThickness;
    _available = math.max(0, total - thickness * (count - 1));
    final fractions = _current;
    final panes = <Widget>[];
    final dividers = <Widget>[];
    var offset = 0.0;
    for (var i = 0; i < count; i++) {
      final extent = fractions[i] * _available;
      panes.add(_placePane(i, offset, extent));
      offset += extent;
      if (i == count - 1) break;
      dividers.add(_placeDivider(i, offset + thickness / 2, fractions[i]));
      offset += thickness;
    }

    return Stack(children: [...panes, ...dividers]);
  }

  Widget _placePane(int index, double start, double extent) {
    final child = widget.children[index];

    // Wraps the child's own key (so the child is not matched twice) and keeps
    // the element of a keyed child when the order changes.
    final key = ValueKey<Object>(child.key ?? index);

    return Positioned(
      key: key,
      left: _horizontal ? start : 0,
      top: _horizontal ? 0 : start,
      right: _horizontal ? null : 0,
      bottom: _horizontal ? 0 : null,
      width: _horizontal ? extent : null,
      height: _horizontal ? null : extent,
      child: ClipRect(child: child),
    );
  }

  Widget _placeDivider(int index, double center, double fraction) {
    final hit = math.max(widget.dividerThickness, widget.dividerHitExtent);

    return Positioned(
      key: ValueKey<String>('note-pane-divider-slot-$index'),
      left: _horizontal ? center - hit / 2 : 0,
      top: _horizontal ? 0 : center - hit / 2,
      right: _horizontal ? null : 0,
      bottom: _horizontal ? 0 : null,
      width: _horizontal ? hit : null,
      height: _horizontal ? null : hit,
      child: NotePaneDivider(
        dividerKey: NoteResizablePanes.dividerKey(index),
        axis: widget.axis,
        fraction: fraction,
        step: NoteResizablePanes.semanticStep,
        cursor: _horizontal
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        onDragStart: (details) => _startDrag(index, details),
        onDragUpdate: _updateDrag,
        onDragEnd: _endDrag,
        onNudge: (delta) => _nudge(index, delta),
        style: widget.style,
        strings: widget.strings,
      ),
    );
  }
}
