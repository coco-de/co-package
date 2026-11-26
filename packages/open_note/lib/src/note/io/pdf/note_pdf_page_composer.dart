// Internal to the PDF exporter: draws one render input into one PDF page. Not
// exported from the module barrel.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/text/text_painter.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_rasterizer.dart';
import 'package:open_note/src/note/io/pdf/note_pdf_writer.dart';
import 'package:open_note/src/note/io/pdf/note_stroke_vectorizer.dart';
import 'package:open_note/src/note/io/pdf/note_styled_vectorizer.dart';
import 'package:open_note/src/note/io/pdf/note_vector_shape.dart';
import 'package:open_note/src/note/io/render/note_page_render_input.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';
import 'package:open_note/src/note/io/render/note_render_geometry.dart';
import 'package:open_note/src/note/style/note_image_style.dart';
import 'package:open_note/src/note/style/note_image_style_painter.dart';

/// Writes pages in the renderer's order: paper, layers (strokes, text,
/// images), objects. Ink stays vector; paper, text boxes and objects are
/// images.
class NotePdfPageComposer {
  /// A composer drawing the page of [input] into [page].
  NotePdfPageComposer(this.page, this.input, this.rasterizer);

  /// Space around an object's bounds that its raster keeps, for shadows.
  static const double objectBleed = 24;

  /// The page being drawn.
  final NotePdfPage page;

  /// What to draw.
  final NotePageRenderInput input;

  /// Rasterises what cannot stay vector.
  final NotePdfRasterizer rasterizer;

  /// Draws the whole page.
  Future<void> compose({required bool includeBackground}) async {
    if (includeBackground) await _background();
    for (final layer in input.layers) {
      if (layer.isPaintable) await _layer(layer);
    }
    for (final object in input.objects) {
      await _object(object);
    }
  }

  ui.Rect get _bounds => input.size.toRect();

  Future<void> _background() async {
    final paint = input.paintBackground;
    if (paint == null) return;
    await _raster(_bounds, (canvas) => paint(canvas, input.size.toSize()));
  }

  Future<void> _layer(NotePageRenderLayer layer) async {
    final opacity = layer.effectiveOpacity;
    if (opacity < 1) page.beginGroup(opacity: opacity);
    for (final stroke in layer.scribble.strokes) {
      // Line and shape styles draw several shapes; plain ink draws one.
      final styled = NoteStyledVectorizer.vectorize(stroke);
      if (styled != null) {
        styled.forEach(_shape);
        continue;
      }
      final shape = NoteStrokeVectorizer.vectorize(stroke);
      if (shape != null) _shape(shape);
    }
    for (final text in layer.scribble.textDrawables) {
      await _text(text);
    }
    for (final image in layer.scribble.imageDrawables) {
      await _image(image);
    }
    if (opacity < 1) page.endGroup();
  }

  void _shape(NoteVectorShape shape) {
    final alpha = shape.color.a;
    if (alpha <= 0 || shape.path.isEmpty) return;
    page.save();
    if (alpha < 1) page.setOpacity(fill: alpha, stroke: alpha);
    if (shape.filled) {
      page
        ..setFillColor(shape.color)
        ..addPath(shape.path)
        ..fill();
    } else {
      page
        ..setStrokeColor(shape.color)
        ..setLineWidth(shape.strokeWidth)
        ..setLineCap(ui.StrokeCap.round)
        ..setLineJoin(ui.StrokeJoin.round)
        ..addPath(shape.path)
        ..stroke();
    }
    page.restore();
  }

  Future<void> _image(ImageDrawable drawable) async {
    if (!noteIsPaintableImage(drawable)) return;
    final rect = noteImageRect(drawable);
    final opacity = noteImageOpacity(drawable);
    final source = input.imageFor(drawable.source);
    if (source != null && drawable.imageStyle.isNotEmpty) {
      // Crop, corners and border are rasterised the way the screen draws them.
      final style = NoteImageStyle.decode(drawable.imageStyle);
      await _raster(
        noteRotatedBounds(rect, drawable.rotation).inflate(style.borderWidth),
        (canvas) {
          noteRotateAbout(canvas, drawable.rotation, rect.center);
          NoteImageStylePainter.paint(
            canvas,
            source,
            rect,
            style.copyWith(opacity: style.opacity * opacity),
          );
        },
      );

      return;
    }
    final pixels = source == null ? null : await rasterizer.convert(source);
    page.save();
    if (drawable.rotation != 0 && drawable.rotation.isFinite) {
      page.rotate(drawable.rotation, rect.center);
    }
    if (pixels == null) {
      const color = noteMissingImageColor;
      page
        ..setOpacity(fill: color.a * opacity)
        ..setFillColor(color)
        ..rectangle(rect)
        ..fill();
    } else {
      if (opacity < 1) page.setOpacity(fill: opacity, stroke: opacity);
      page.drawImage(pixels, rect);
    }
    page.restore();
  }

  Future<void> _text(TextDrawable text) async {
    if (text.hidden || text.text.isEmpty || !noteIsFiniteText(text)) return;
    final bounds = noteTextPaintBounds(text, input.textBoxTypography);
    if (!noteIsFiniteRect(bounds)) return;
    // Italic and underline overhang the layout box.
    final bleed = math.max(4.0, bounds.height * 0.25);
    await _raster(bounds.inflate(bleed), (canvas) {
      TextDrawablePainter(
        textDrawables: [text],
        selectedTextDrawable: null,
        isTransforming: false,
        editingTextId: null,
        textBoxTypography: input.textBoxTypography,
      ).paint(canvas, input.size.toSize());
    });
  }

  Future<void> _object(NoteObject object) async {
    if (!noteIsFiniteRect(object.bounds) || object.opacity <= 0) return;
    final bounds = noteRotatedBounds(
      object.bounds,
      object.rotation,
    ).inflate(objectBleed);
    final context = input.paintContext;
    await _raster(bounds, (canvas) => notePaintObject(canvas, object, context));
  }

  /// Embeds what [paint] draws inside [region], limited to the page.
  Future<void> _raster(
    ui.Rect region,
    void Function(ui.Canvas canvas) paint,
  ) async {
    final visible = region.intersect(_bounds);
    if (visible.width <= 0 || visible.height <= 0) return;
    final raster = await rasterizer.rasterize(visible, paint);
    if (raster != null) page.drawImage(raster.image, raster.rect);
  }
}
