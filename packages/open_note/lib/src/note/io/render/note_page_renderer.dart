import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/painter/shape_paint_delegate.dart';
import 'package:open_note/src/module/painter/stroke_paint_delegate.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';
import 'package:open_note/src/note/io/render/note_render_geometry.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_image_style_painter.dart';

/// Draws a [NotePageRenderInput] without widgets, with the engine's own
/// painters so an export looks like the screen.
///
/// Order, bottom to top: paper, then each layer bottom to top (strokes, then
/// text, then images, skipping hidden drawables — the order the engine's
/// `ScribbleWidget` and `NoteScribbleView` stack them on screen), then the note
/// objects. Lasso and eraser strokes are never drawn. Drawing is clipped to the
/// page.
abstract final class NotePageRenderer {
  /// The longest edge, in pixels, [renderToImage] accepts.
  static const int maxPixelDimension = 16384;

  /// Paints [input] onto [canvas] in page coordinates (the caller applies any
  /// scale or offset first). Only the part inside [clip] (default: the whole
  /// page) is painted. With [includeBackground] false the paper is left out.
  /// The canvas is returned in the state it was given.
  static void paint(
    ui.Canvas canvas,
    NotePageRenderInput input, {
    ui.Rect? clip,
    bool includeBackground = true,
  }) {
    final page = input.size.toRect();
    final area = clip == null ? page : page.intersect(clip);
    if (area.width <= 0 || area.height <= 0) return;
    final saveCount = canvas.getSaveCount();
    canvas
      ..save()
      ..clipRect(area);
    if (includeBackground) _paintBackground(canvas, input);
    for (final layer in input.layers) {
      if (layer.isPaintable) _paintLayer(canvas, layer, input);
    }
    final context = input.paintContext;
    for (final object in input.objects) {
      notePaintObject(canvas, object, context);
    }
    canvas.restoreToCount(saveCount);
  }

  /// Rasterises [region] (page units, default: the whole page) at [pixelRatio]
  /// pixels per page unit. The image is `ceil(region size * pixelRatio)`
  /// pixels; parts of [region] outside the page stay transparent. The caller
  /// disposes the image.
  ///
  /// Throws [ArgumentError] when [pixelRatio] or [region] is not positive and
  /// finite, or the result would exceed [maxPixelDimension].
  static Future<ui.Image> renderToImage(
    NotePageRenderInput input, {
    double pixelRatio = 1,
    ui.Rect? region,
    bool includeBackground = true,
  }) async {
    final target = region ?? input.size.toRect();
    if (!pixelRatio.isFinite || pixelRatio <= 0) {
      throw ArgumentError.value(pixelRatio, 'pixelRatio', 'must be positive');
    }
    if (!noteIsFiniteRect(target) || target.width <= 0 || target.height <= 0) {
      throw ArgumentError.value(target, 'region', 'must have a positive area');
    }
    final width = _pixels(target.width * pixelRatio);
    final height = _pixels(target.height * pixelRatio);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..scale(pixelRatio)
      ..translate(-target.left, -target.top);
    paint(canvas, input, clip: target, includeBackground: includeBackground);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }

  /// [renderToImage] encoded as PNG bytes.
  static Future<Uint8List> renderToPng(
    NotePageRenderInput input, {
    double pixelRatio = 1,
    ui.Rect? region,
    bool includeBackground = true,
  }) async {
    final image = await renderToImage(
      input,
      pixelRatio: pixelRatio,
      region: region,
      includeBackground: includeBackground,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('the engine could not encode a PNG');

      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  static int _pixels(double length) {
    if (!(length <= maxPixelDimension)) {
      throw ArgumentError(
        'the image would be $length px long (maximum $maxPixelDimension)',
      );
    }
    // The epsilon keeps float noise (100.0000001) from adding a pixel row.
    final pixels = (length - 1e-6).ceil();

    return pixels < 1 ? 1 : pixels;
  }

  static void _paintBackground(ui.Canvas canvas, NotePageRenderInput input) {
    final background = input.paintBackground;
    if (background == null) return;
    final saveCount = canvas.getSaveCount();
    canvas.save();
    background(canvas, input.size.toSize());
    canvas.restoreToCount(saveCount);
  }

  static void _paintLayer(
    ui.Canvas canvas,
    NotePageRenderLayer layer,
    NotePageRenderInput input,
  ) {
    final opacity = layer.effectiveOpacity;
    final saveCount = canvas.getSaveCount();
    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(null, ui.Paint()..color = noteOpacityColor(opacity));
    }
    for (final stroke in layer.scribble.strokes) {
      _paintStroke(canvas, stroke);
    }
    TextDrawablePainter(
      textDrawables: [
        for (final text in layer.scribble.textDrawables)
          if (noteIsFiniteText(text)) text,
      ],
      selectedTextDrawable: null,
      isTransforming: false,
      editingTextId: null,
      textBoxTypography: input.textBoxTypography,
    ).paint(canvas, input.size.toSize());
    for (final image in layer.scribble.imageDrawables) {
      _paintImage(canvas, image, input);
    }
    canvas.restoreToCount(saveCount);
  }

  /// The same dispatch the engine's static ink painter uses.
  static void _paintStroke(ui.Canvas canvas, Stroke stroke) {
    if (stroke.ink == InkModes.lasso || !noteIsFiniteStroke(stroke)) return;
    if (stroke.shapeType.isNotEmpty) {
      final paint = ui.Paint()
        ..color = ui.Color(stroke.color)
        ..strokeWidth = stroke.options.size
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..style = ui.PaintingStyle.stroke;
      const ShapePaintDelegate(strokes: []).drawShape(canvas, paint, stroke);

      return;
    }
    // The engine's marker painter rewrites `stroke.color` in place; give it a
    // copy so rendering never edits the caller's document.
    final target = stroke.ink == InkModes.marker ? stroke.deepCopy() : stroke;
    const StrokePaintDelegate(strokes: []).drawStroke(canvas, target);
  }

  static void _paintImage(
    ui.Canvas canvas,
    ImageDrawable drawable,
    NotePageRenderInput input,
  ) {
    if (!noteIsPaintableImage(drawable)) return;
    final rect = noteImageRect(drawable);
    final opacity = noteImageOpacity(drawable);
    final image = input.imageFor(drawable.source);
    canvas.save();
    noteRotateAbout(canvas, drawable.rotation, rect.center);
    if (image == null) {
      const color = noteMissingImageColor;
      canvas.drawRect(
        rect,
        ui.Paint()..color = color.withValues(alpha: color.a * opacity),
      );
    } else if (drawable.imageStyle.isNotEmpty) {
      final style = NoteImageStyle.decode(drawable.imageStyle);
      NoteImageStylePainter.paint(
        canvas,
        image,
        rect,
        style.copyWith(opacity: style.opacity * opacity),
      );
    } else {
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0),
        rect,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.medium
          ..color = noteOpacityColor(opacity),
      );
    }
    canvas.restore();
  }
}
