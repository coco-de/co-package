// Internal to the io module: geometry and painting rules the page renderer and
// the PDF exporter must share so that both draw a page the same way. Not
// exported from the module barrel.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/core/core.dart';

/// Fill of the box drawn for an image that has not been decoded.
const ui.Color noteMissingImageColor = ui.Color(0x22000000);

/// Whether every edge of [rect] is finite.
bool noteIsFiniteRect(ui.Rect rect) =>
    rect.left.isFinite &&
    rect.top.isFinite &&
    rect.right.isFinite &&
    rect.bottom.isFinite;

/// Whether [stroke] holds only finite numbers. The engine painters assert on
/// NaN shapes, so corrupt strokes are skipped instead of failing a whole page.
bool noteIsFiniteStroke(Stroke stroke) =>
    stroke.options.size.isFinite &&
    stroke.points.every(
      (point) => point.x.isFinite && point.y.isFinite && point.p.isFinite,
    ) &&
    stroke.segments.every(
      (segment) =>
          segment.start.x.isFinite &&
          segment.start.y.isFinite &&
          segment.end.x.isFinite &&
          segment.end.y.isFinite,
    );

/// Whether [text] has a finite position, rotation, size and wrap width.
bool noteIsFiniteText(TextDrawable text) =>
    text.x.isFinite &&
    text.y.isFinite &&
    text.rotation.isFinite &&
    text.fontSize.isFinite &&
    text.maxWidth.isFinite;

/// The axis-aligned box around [rect] turned by [radians] about [pivot]
/// (default: the rect's centre).
ui.Rect noteRotatedBounds(ui.Rect rect, double radians, [ui.Offset? pivot]) {
  if (radians == 0 || !radians.isFinite) return rect;
  final center = pivot ?? rect.center;
  final cos = math.cos(radians);
  final sin = math.sin(radians);
  var bounds = const ui.Rect.fromLTRB(
    double.infinity,
    double.infinity,
    double.negativeInfinity,
    double.negativeInfinity,
  );
  for (final corner in [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ]) {
    final delta = corner - center;
    final x = center.dx + delta.dx * cos - delta.dy * sin;
    final y = center.dy + delta.dx * sin + delta.dy * cos;
    bounds = ui.Rect.fromLTRB(
      math.min(bounds.left, x),
      math.min(bounds.top, y),
      math.max(bounds.right, x),
      math.max(bounds.bottom, y),
    );
  }

  return bounds;
}

/// Turns [canvas] by [radians] about [pivot]; a zero or non-finite angle does
/// nothing.
void noteRotateAbout(ui.Canvas canvas, double radians, ui.Offset pivot) {
  if (radians == 0 || !radians.isFinite) return;
  canvas
    ..translate(pivot.dx, pivot.dy)
    ..rotate(radians)
    ..translate(-pivot.dx, -pivot.dy);
}

/// The page box of an image drawable (before rotation).
ui.Rect noteImageRect(ImageDrawable image) =>
    ui.Rect.fromLTWH(image.x, image.y, image.width, image.height);

/// The opacity an image drawable is drawn with, as the engine's image layer
/// applies it.
double noteImageOpacity(ImageDrawable image) =>
    image.opacity.isFinite ? image.opacity.clamp(0.0, 1.0) : 0;

/// Whether the engine would show [image] at all.
bool noteIsPaintableImage(ImageDrawable image) =>
    !image.hidden &&
    noteImageOpacity(image) > 0 &&
    noteIsFiniteRect(noteImageRect(image)) &&
    image.width > 0 &&
    image.height > 0;

/// The page box covered by a painted text drawable, including rotation.
/// Mirrors [TextDrawablePainter]: a rotated box is centred on the stored
/// position whatever its alignment.
ui.Rect noteTextPaintBounds(
  TextDrawable text,
  TextBoxTypography textBoxTypography,
) {
  final bounds = TextDrawablePainter.getTextBounds(
    text,
    textBoxTypography: textBoxTypography,
  );
  if (text.rotation == 0 || !text.rotation.isFinite) return bounds;
  final position = ui.Offset(text.x, text.y);
  final centred = ui.Rect.fromCenter(
    center: position,
    width: bounds.width,
    height: bounds.height,
  );

  return noteRotatedBounds(centred, text.rotation, position);
}

/// Paints [object] with its rotation and opacity applied, which is the canvas
/// state [NoteObject.paintToCanvas] expects. Any save the object leaves open is
/// restored.
void notePaintObject(
  ui.Canvas canvas,
  NoteObject object,
  NoteObjectPaintContext context,
) {
  final opacity = object.opacity.isFinite
      ? object.opacity.clamp(0.0, 1.0)
      : 1.0;
  if (opacity <= 0 || !noteIsFiniteRect(object.bounds)) return;
  final saveCount = canvas.getSaveCount();
  canvas.save();
  noteRotateAbout(canvas, object.rotation, object.bounds.center);
  if (opacity < 1) {
    canvas.saveLayer(null, ui.Paint()..color = noteOpacityColor(opacity));
  }
  object.paintToCanvas(canvas, context);
  canvas.restoreToCount(saveCount);
}

/// A paint colour whose only effect is to fade what it composites.
ui.Color noteOpacityColor(double opacity) =>
    ui.Color.fromRGBO(0, 0, 0, opacity);
