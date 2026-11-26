import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_ruler_controller.dart';
import 'package:open_note/src/note/view/note_ruler_painter.dart';
import 'package:open_note/src/note/view/note_transform_drag_detector.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// The ruler laid over a page: drag it to move it, use two fingers or the
/// round handle at its end to turn it.
///
/// Give it the page's constraints (it draws in page coordinates); only the
/// ruler itself takes pointers, so ink beneath stays reachable. Draws nothing
/// while the controller is hidden. The label shows the length in the selected
/// unit and the angle (0–179°, clockwise).
class NoteRuler extends StatefulWidget {
  /// The ruler driven by [controller].
  const NoteRuler({
    required this.controller,
    super.key,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  });

  /// Key of the draggable body.
  static const Key bodyKey = ValueKey<String>('note-ruler-body');

  /// Key of the rotation handle.
  static const Key rotateHandleKey = ValueKey<String>('note-ruler-rotate');

  /// Rotation applied by one accessibility step, in radians (5°).
  static const double semanticStep = math.pi / 36;

  static const double _handleSize = 32;

  /// Position, angle, length, unit and visibility.
  final NoteRulerController controller;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteRuler> createState() => _NoteRulerState();
}

class _NoteRulerState extends State<NoteRuler> {
  Offset _startCenter = Offset.zero;
  double _startAngle = 0;

  NoteRulerController get _ruler => widget.controller;

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject();

    return box is RenderBox && box.hasSize ? box.globalToLocal(global) : global;
  }

  void _onStart() {
    _startCenter = _ruler.center;
    _startAngle = _ruler.angle;
  }

  void _onUpdate(Offset delta, double scale, double rotation, int fingers) {
    _ruler.setCenter(_startCenter + delta);
    if (fingers >= 2) _ruler.setAngle(_startAngle + rotation);
  }

  void _rotateTo(Offset global) {
    final relative = _toLocal(global) - _ruler.center;
    if (relative.distanceSquared < 1) return;
    _ruler.setAngle(math.atan2(relative.dy, relative.dx));
  }

  String get _label => widget.strings.rulerLabel(
    _ruler.lengthText,
    _ruler.unit,
    _ruler.degrees.round() % 180,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ruler,
      builder: (context, _) =>
          _ruler.visible ? _buildPlacedRuler() : const SizedBox.shrink(),
    );
  }

  Widget _buildPlacedRuler() {
    return Stack(
      children: [
        Positioned(
          left: _ruler.center.dx - _ruler.length / 2,
          top: _ruler.center.dy - _ruler.width / 2,
          width: _ruler.length,
          height: _ruler.width,
          child: Transform.rotate(angle: _ruler.angle, child: _buildBody()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Semantics(
      container: true,
      label: widget.strings.ruler,
      value: _label,
      child: NoteTransformDragDetector(
        key: NoteRuler.bodyKey,
        toLocal: _toLocal,
        onStart: _onStart,
        onUpdate: _onUpdate,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: NoteRulerPainter(unit: _ruler.unit, style: widget.style),
            ),
            Center(child: IgnorePointer(child: _buildLabel())),
            Positioned(
              right: 4,
              top: (_ruler.width - NoteRuler._handleSize) / 2,
              width: NoteRuler._handleSize,
              height: NoteRuler._handleSize,
              child: _buildRotateHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.style.barColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: ExcludeSemantics(
          child: Text(
            _label,
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: widget.style.textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildRotateHandle() {
    return Semantics(
      container: true,
      button: true,
      label: widget.strings.rotateRuler,
      onIncrease: () => _ruler.rotateBy(NoteRuler.semanticStep),
      onDecrease: () => _ruler.rotateBy(-NoteRuler.semanticStep),
      child: GestureDetector(
        key: NoteRuler.rotateHandleKey,
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) => _rotateTo(details.globalPosition),
        onPanUpdate: (details) => _rotateTo(details.globalPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.style.surfaceColor,
            border: Border.all(color: widget.style.rulerMarkColor),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                '↻',
                style: TextStyle(
                  fontSize: 18,
                  color: widget.style.rulerMarkColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
