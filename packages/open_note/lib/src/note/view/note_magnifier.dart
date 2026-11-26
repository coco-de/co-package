import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_magnifier_controller.dart';
import 'package:open_note/src/note/view/note_transform_drag_detector.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// A round lens that magnifies what lies under it, built on [RawMagnifier].
///
/// Place it *above* the content in a [Stack] and let it fill the stack: only
/// the lens and its buttons take pointers. Drag the lens to move it (its
/// centre stays inside the overlay) and pinch it to change the power; the
/// buttons under it (above it near the bottom edge) zoom by [zoomStep] and
/// close it. Draws nothing while the controller is hidden.
class NoteMagnifier extends StatefulWidget {
  /// A lens driven by [controller].
  const NoteMagnifier({
    required this.controller,
    super.key,
    this.zoomStep = 0.5,
    this.showControls = true,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  }) : assert(zoomStep > 0);

  /// Key of the draggable lens.
  static const Key lensKey = ValueKey<String>('note-magnifier-lens');

  /// Key of the minus button.
  static const Key zoomOutKey = ValueKey<String>('note-magnifier-zoom-out');

  /// Key of the plus button.
  static const Key zoomInKey = ValueKey<String>('note-magnifier-zoom-in');

  /// Key of the close button.
  static const Key closeKey = ValueKey<String>('note-magnifier-close');

  /// Position, power, size and visibility of the lens.
  final NoteMagnifierController controller;

  /// Zoom change of one button press.
  final double zoomStep;

  /// Whether the zoom and close buttons are shown.
  final bool showControls;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteMagnifier> createState() => _NoteMagnifierState();
}

class _NoteMagnifierState extends State<NoteMagnifier> {
  static const double _controlsWidth = 160;
  static const double _controlsHeight = 32;
  static const double _controlsGap = 6;

  Offset _startCenter = Offset.zero;
  double _startZoom = NoteMagnifierController.defaultZoom;

  NoteMagnifierController get _lens => widget.controller;

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject();

    return box is RenderBox && box.hasSize ? box.globalToLocal(global) : global;
  }

  void _onStart() {
    _startCenter = _lens.center;
    _startZoom = _lens.zoom;
  }

  void _onUpdate(Offset delta, double scale, double rotation, int fingers) {
    _moveTo(_startCenter + delta);
    if (fingers >= 2) _lens.setZoom(_startZoom * scale);
  }

  void _moveTo(Offset center) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      _lens.setCenter(center);

      return;
    }
    final size = box.size;
    _lens.setCenter(
      Offset(
        center.dx.clamp(0.0, size.width),
        center.dy.clamp(0.0, size.height),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lens,
      builder: (context, _) => _lens.visible
          ? LayoutBuilder(
              builder: (context, constraints) =>
                  _buildOverlay(constraints.biggest),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Where the buttons go: under the lens, above it when there is no room
  /// below, and never past the left or right edge.
  Offset _controlsOrigin(Size overlay) {
    final radius = _lens.diameter / 2;
    final below = _lens.center.dy + radius + _controlsGap;
    final above = _lens.center.dy - radius - _controlsGap - _controlsHeight;
    final fitsBelow = below + _controlsHeight <= overlay.height;
    final left = _lens.center.dx - _controlsWidth / 2;

    return Offset(
      left.clamp(0.0, math.max(overlay.width - _controlsWidth, 0.0)),
      fitsBelow || above < 0 ? below : above,
    );
  }

  Widget _buildOverlay(Size overlay) {
    final diameter = _lens.diameter;
    final center = _lens.center;
    final controls = _controlsOrigin(overlay);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - diameter / 2,
          top: center.dy - diameter / 2,
          width: diameter,
          height: diameter,
          child: _buildLens(diameter),
        ),
        if (widget.showControls)
          Positioned(
            left: controls.dx,
            top: controls.dy,
            width: _controlsWidth,
            height: _controlsHeight,
            child: _buildControls(),
          ),
      ],
    );
  }

  Widget _buildLens(double diameter) {
    final label = widget.strings.zoomLabel(_lens.zoom);

    return Semantics(
      container: true,
      label: widget.strings.magnifier,
      value: label,
      increasedValue: widget.strings.zoomLabel(
        (_lens.zoom + widget.zoomStep).clamp(
          NoteMagnifierController.minZoom,
          NoteMagnifierController.maxZoom,
        ),
      ),
      decreasedValue: widget.strings.zoomLabel(
        (_lens.zoom - widget.zoomStep).clamp(
          NoteMagnifierController.minZoom,
          NoteMagnifierController.maxZoom,
        ),
      ),
      onIncrease: () => _lens.setZoom(_lens.zoom + widget.zoomStep),
      onDecrease: () => _lens.setZoom(_lens.zoom - widget.zoomStep),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RawMagnifier(
            size: Size.square(diameter),
            magnificationScale: _lens.zoom,
            decoration: MagnifierDecoration(
              shape: CircleBorder(
                side: BorderSide(
                  color: widget.style.magnifierBorderColor,
                  width: 3,
                ),
              ),
              shadows: const [
                BoxShadow(blurRadius: 10, color: Color(0x55000000)),
              ],
            ),
          ),
          ClipOval(
            child: NoteTransformDragDetector(
              key: NoteMagnifier.lensKey,
              toLocal: _toLocal,
              onStart: _onStart,
              onUpdate: _onUpdate,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.style.barColor,
        borderRadius: BorderRadius.circular(_controlsHeight / 2),
        border: Border.all(color: widget.style.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _button(
            NoteMagnifier.zoomOutKey,
            '−',
            widget.strings.zoomOut,
            () => _lens.setZoom(_lens.zoom - widget.zoomStep),
          ),
          Text(
            widget.strings.zoomLabel(_lens.zoom),
            style: TextStyle(fontSize: 13, color: widget.style.textColor),
          ),
          _button(
            NoteMagnifier.zoomInKey,
            '+',
            widget.strings.zoomIn,
            () => _lens.setZoom(_lens.zoom + widget.zoomStep),
          ),
          _button(
            NoteMagnifier.closeKey,
            '×',
            widget.strings.closeMagnifier,
            () => _lens.setVisible(false),
          ),
        ],
      ),
    );
  }

  Widget _button(Key key, String glyph, String label, VoidCallback onTap) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: _controlsHeight,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                glyph,
                style: TextStyle(fontSize: 18, color: widget.style.textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
