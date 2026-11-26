import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_thumbnail_cell.dart';
import 'package:open_note/src/note/view/note_thumbnail_grid_controller.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// A scrolling grid of page thumbnails.
///
/// The number of columns comes from [controller]; a two-finger (or trackpad)
/// pinch changes it in steps and scrolling is suspended while two fingers are
/// down. The current page has a ring. A tap opens a page ([onPageTap]), or
/// toggles it while the controller is in selection mode. Taps and long presses
/// that happen during a pinch are ignored.
class NoteThumbnailGrid extends StatefulWidget {
  /// A grid of [pageCount] thumbnails built by [itemBuilder].
  const NoteThumbnailGrid({
    required this.controller,
    required this.pageCount,
    required this.itemBuilder,
    super.key,
    this.currentPage,
    this.onPageTap,
    this.onPageLongPress,
    this.pageAspectRatio = 595 / 842,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(12),
    this.showPageNumbers = true,
    this.scrollController,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  }) : assert(pageCount >= 0),
       assert(pageAspectRatio > 0);

  /// Columns, selection and pinch state.
  final NoteThumbnailGridController controller;

  /// Number of pages.
  final int pageCount;

  /// Builds the preview of the 0-based page; it fills the thumbnail frame.
  final Widget Function(BuildContext context, int pageIndex) itemBuilder;

  /// 0-based index of the page shown elsewhere, or `null`.
  final int? currentPage;

  /// A page was tapped outside selection mode.
  final ValueChanged<int>? onPageTap;

  /// A page was long-pressed (for example to start selecting).
  final ValueChanged<int>? onPageLongPress;

  /// Width / height of a thumbnail frame (default A4 portrait).
  final double pageAspectRatio;

  /// Gap between thumbnails, both directions.
  final double spacing;

  /// Space around the grid.
  final EdgeInsetsGeometry padding;

  /// Whether the 1-based page number is printed under each thumbnail.
  final bool showPageNumbers;

  /// Optional scroll position of the grid.
  final ScrollController? scrollController;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteThumbnailGrid> createState() => _NoteThumbnailGridState();
}

class _NoteThumbnailGridState extends State<NoteThumbnailGrid> {
  final Map<int, Offset> _pointers = {};
  double? _lastSpan;
  double _lastTrackpadScale = 1;
  bool _pinching = false;

  /// Whether the current touch sequence has pinched (so it is not a tap).
  bool _pinched = false;

  void _onPointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) _pinched = false;
    _pointers[event.pointer] = event.position;
    _syncPinch();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    final span = _span();
    final last = _lastSpan;
    if (span == null || last == null) return;
    if (span > 0 && last > 0) widget.controller.scaleBy(span / last);
    _lastSpan = span;
  }

  void _onPointerEnd(PointerEvent event) {
    if (_pointers.remove(event.pointer) != null) _syncPinch();
  }

  void _syncPinch() {
    final span = _span();
    _lastSpan = span;
    final pinching = span != null;
    if (pinching == _pinching) return;
    if (pinching) {
      _pinched = true;
      widget.controller.beginPinch();
    }
    setState(() => _pinching = pinching);
  }

  /// Distance between the first two fingers, or `null` with fewer.
  double? _span() {
    if (_pointers.length < 2) return null;
    final points = _pointers.values.take(2).toList();

    return (points.first - points.last).distance;
  }

  void _onTrackpadStart(PointerPanZoomStartEvent event) {
    _lastTrackpadScale = 1;
    widget.controller.beginPinch();
  }

  void _onTrackpadUpdate(PointerPanZoomUpdateEvent event) {
    if (event.scale <= 0) return;
    widget.controller.scaleBy(event.scale / _lastTrackpadScale);
    _lastTrackpadScale = event.scale;
  }

  void _onTap(int index) {
    if (_pinched) return;
    if (widget.controller.selectionMode) {
      widget.controller.toggleSelect(index);
    } else {
      widget.onPageTap?.call(index);
    }
  }

  void _onLongPress(int index) {
    if (_pinched) return;
    widget.onPageLongPress?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      onPointerPanZoomStart: _onTrackpadStart,
      onPointerPanZoomUpdate: _onTrackpadUpdate,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => LayoutBuilder(builder: _buildGrid),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, BoxConstraints constraints) {
    final columns = widget.controller.columns;
    final padding = widget.padding.resolve(Directionality.of(context));
    final available =
        constraints.maxWidth -
        padding.horizontal -
        widget.spacing * (columns - 1);
    final cellWidth = available / columns;
    if (!cellWidth.isFinite || cellWidth <= 0) return const SizedBox.shrink();
    final labelExtent = widget.showPageNumbers
        ? NoteThumbnailCell.labelExtent
        : 0.0;

    return GridView.builder(
      controller: widget.scrollController,
      physics: _pinching ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: widget.spacing,
        mainAxisSpacing: widget.spacing,
        mainAxisExtent: cellWidth / widget.pageAspectRatio + labelExtent,
      ),
      itemCount: widget.pageCount,
      itemBuilder: _buildCell,
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    return NoteThumbnailCell(
      key: ValueKey<String>('note-thumbnail-$index'),
      pageNumber: index + 1,
      current: index == widget.currentPage,
      selected: widget.controller.isSelected(index),
      selecting: widget.controller.selectionMode,
      showNumber: widget.showPageNumbers,
      onTap: () => _onTap(index),
      onLongPress: widget.onPageLongPress == null
          ? null
          : () => _onLongPress(index),
      style: widget.style,
      strings: widget.strings,
      child: widget.itemBuilder(context, index),
    );
  }
}
