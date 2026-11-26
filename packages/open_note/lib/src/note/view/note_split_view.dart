import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_resizable_panes.dart';
import 'package:open_note/src/note/view/note_view_layout_controller.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// Two panes with one draggable divider — [NoteResizablePanes] for the common
/// case.
///
/// With [ratio] the split is controlled (update it from [onRatioChanged]);
/// without it the widget keeps its own, starting at [initialRatio]. The first
/// pane's share stays within [minRatio] and `1 - minRatio`.
class NoteSplitView extends StatelessWidget {
  /// Shows [first] and [second] with a draggable divider between them.
  const NoteSplitView({
    required this.first,
    required this.second,
    super.key,
    this.axis = Axis.horizontal,
    this.ratio,
    this.initialRatio = NoteViewLayoutController.defaultRatio,
    this.minRatio = NoteViewLayoutController.minRatio,
    this.onRatioChanged,
    this.onResizeEnd,
    this.dividerThickness = 12,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  }) : assert(minRatio >= 0 && minRatio <= 0.5);

  /// The left or top pane.
  final Widget first;

  /// The right or bottom pane.
  final Widget second;

  /// [Axis.horizontal]: side by side; [Axis.vertical]: stacked.
  final Axis axis;

  /// Controlled share of [first], or `null` to let the widget keep it.
  final double? ratio;

  /// Starting share of [first] when [ratio] is `null`.
  final double initialRatio;

  /// Smallest share either pane can be dragged to (0–0.5).
  final double minRatio;

  /// New share of the first pane while the divider moves.
  final ValueChanged<double>? onRatioChanged;

  /// Share of the first pane when a drag ends.
  final ValueChanged<double>? onResizeEnd;

  /// Layout space between the two panes.
  final double dividerThickness;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  static List<double> _fractions(double ratio) => [ratio, 1 - ratio];

  @override
  Widget build(BuildContext context) {
    final controlled = ratio;
    final changed = onRatioChanged;
    final ended = onResizeEnd;

    return NoteResizablePanes(
      axis: axis,
      fractions: controlled == null ? null : _fractions(controlled),
      initialFractions: _fractions(initialRatio),
      minFraction: minRatio,
      dividerThickness: dividerThickness,
      onFractionsChanged: changed == null
          ? null
          : (fractions) => changed(fractions.first),
      onResizeEnd: ended == null ? null : (fractions) => ended(fractions.first),
      style: style,
      strings: strings,
      children: [first, second],
    );
  }
}
