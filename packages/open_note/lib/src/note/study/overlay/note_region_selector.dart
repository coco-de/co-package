import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_region_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_region_painter.dart';
import 'package:open_note/src/note/study/overlay/note_region_selector_style.dart';
import 'package:open_note/src/note/study/overlay/note_region_toolbar.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

enum _DragKind { create, move, resize }

class _Drag {
  _Drag(this.kind, {required this.origin, this.before, this.handle});

  final _DragKind kind;
  final Offset origin;
  final Rect? before;
  final NoteRegionHandle? handle;
  bool moved = false;
}

/// Lets the user pick a rectangle of a page: for the AI pen and the screenshot
/// pen.
///
/// Lay it over the page with tight constraints equal to the page size; it works
/// and reports in page coordinates. Disable page panning while it is shown so
/// the drag reaches it. A drag on empty page draws a new rectangle; a drag on
/// one of the eight handles resizes it (never smaller than [minSize]) and a drag
/// inside moves it. The rectangle stays on the page. A new drag spanning less
/// than [minSize] in both directions is ignored and one that is short in one
/// direction is widened to [minSize].
///
/// A small toolbar next to the selection confirms ([onRegionSelected]) or
/// cancels ([onCancel]); Enter and Escape do the same. With
/// [confirmOnRelease] there is no confirm button: every finished drag reports
/// its rectangle immediately.
class NoteRegionSelector extends StatefulWidget {
  /// Creates a selector.
  const NoteRegionSelector({
    required this.onRegionSelected,
    this.onCancel,
    this.onRegionChanged,
    this.initialRegion,
    this.minSize = defaultMinSize,
    this.confirmOnRelease = false,
    this.autofocus = true,
    this.style = const NoteRegionSelectorStyle(),
    this.strings = const NoteStudyOverlayStrings(),
    super.key,
  }) : assert(minSize >= 0, 'minSize must not be negative');

  /// Default [minSize], page units.
  static const double defaultMinSize = 24;

  /// Called with the accepted rectangle in page coordinates.
  final ValueChanged<Rect> onRegionSelected;

  /// Called when the user abandons the selection. Without it there is no cancel
  /// button.
  final VoidCallback? onCancel;

  /// Called with every change of the rectangle (`null`: no selection).
  final ValueChanged<Rect?>? onRegionChanged;

  /// A rectangle to start with (read once).
  final Rect? initialRegion;

  /// Smallest side of a selection; limited to the page size.
  final double minSize;

  /// Report each finished drag at once instead of waiting for a confirmation.
  final bool confirmOnRelease;

  /// Whether the selector takes keyboard focus (for Enter and Escape).
  final bool autofocus;

  /// Colours and metrics.
  final NoteRegionSelectorStyle style;

  /// Accessibility labels.
  final NoteStudyOverlayStrings strings;

  @override
  State<NoteRegionSelector> createState() => _NoteRegionSelectorState();
}

class _NoteRegionSelectorState extends State<NoteRegionSelector> {
  late Rect? _region = widget.initialRegion;
  _Drag? _drag;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final page = constraints.biggest;
      final shown = _shownOn(page);

      return Focus(
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) => _onKey(event, page),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.strings.regionSelector,
          child: SizedBox.fromSize(
            size: page,
            child: Stack(
              children: [
                Positioned.fill(child: _surface(page, shown)),
                if (_drag == null) _toolbar(page, shown),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _surface(Size page, Rect? shown) => GestureDetector(
    key: const ValueKey('note-region-surface'),
    behavior: HitTestBehavior.opaque,
    dragStartBehavior: DragStartBehavior.down,
    onPanStart: (details) => _start(details, page),
    onPanUpdate: (details) => _update(details, page),
    onPanEnd: (_) => _end(page),
    onPanCancel: _abort,
    child: CustomPaint(
      painter: NoteRegionPainter(region: shown, style: widget.style),
    ),
  );

  Widget _toolbar(Size page, Rect? shown) => NoteRegionToolbar(
    page: page,
    region: shown,
    style: widget.style,
    strings: widget.strings,
    onConfirm: shown == null || widget.confirmOnRelease
        ? null
        : () => widget.onRegionSelected(shown),
    onCancel: widget.onCancel,
  );

  Rect? _shownOn(Size page) {
    final region = _region;

    return region == null ? null : NoteRegionGeometry.fit(region, page);
  }

  KeyEventResult _onKey(KeyEvent event, Size page) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final cancel = widget.onCancel;
    if (event.logicalKey == LogicalKeyboardKey.escape && cancel != null) {
      cancel();

      return KeyEventResult.handled;
    }
    final region = _shownOn(page);
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || region == null) return KeyEventResult.ignored;
    widget.onRegionSelected(region);

    return KeyEventResult.handled;
  }

  (_DragKind, NoteRegionHandle?) _classify(Rect? region, Offset point) {
    if (region == null) return (_DragKind.create, null);
    final reach = widget.style.handleHitRadius;
    // The middle always moves, even when the handles of a small selection
    // overlap it.
    final core = region.deflate(math.min(reach, region.shortestSide / 4));
    if (core.contains(point)) return (_DragKind.move, null);
    final handle = NoteRegionGeometry.handleAt(region, point, reach);
    if (handle != null) return (_DragKind.resize, handle);

    return (region.contains(point) ? _DragKind.move : _DragKind.create, null);
  }

  void _start(DragStartDetails details, Size page) {
    final before = _shownOn(page);
    final (kind, handle) = _classify(before, details.localPosition);
    setState(() {
      _drag = _Drag(
        kind,
        origin: details.localPosition,
        before: before,
        handle: handle,
      );
    });
  }

  void _update(DragUpdateDetails details, Size page) {
    final drag = _drag;
    if (drag == null) return;
    final delta = details.localPosition - drag.origin;
    if (delta == Offset.zero && !drag.moved) return;
    drag.moved = true;
    _setRegion(switch (drag.kind) {
      _DragKind.create => NoteRegionGeometry.fromDrag(
        drag.origin,
        details.localPosition,
        page,
      ),
      _DragKind.move => NoteRegionGeometry.move(drag.before!, delta, page),
      _DragKind.resize => NoteRegionGeometry.resize(
        drag.before!,
        drag.handle!,
        delta,
        page,
        minSize: widget.minSize,
      ),
    });
  }

  void _end(Size page) {
    final drag = _drag;
    if (drag == null) return;
    setState(() => _drag = null);
    if (!drag.moved) return;
    var accepted = _region;
    if (drag.kind == _DragKind.create && accepted != null) {
      accepted = NoteRegionGeometry.atLeast(accepted, page, widget.minSize);
      _setRegion(accepted ?? drag.before);
    }
    if (widget.confirmOnRelease && accepted != null) {
      widget.onRegionSelected(accepted);
    }
  }

  void _abort() {
    final drag = _drag;
    if (drag == null) return;
    setState(() => _drag = null);
    _setRegion(drag.before);
  }

  void _setRegion(Rect? region) {
    if (region == _region) return;
    setState(() => _region = region);
    widget.onRegionChanged?.call(region);
  }
}
