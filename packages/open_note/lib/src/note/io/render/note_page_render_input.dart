import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/module/text/text_box_typography.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/render/note_page_render_layer.dart';

/// Paints the paper of a page into [size] (page coordinates, origin top-left).
/// It may change the canvas state; the renderer restores it afterwards.
typedef NotePageBackgroundPainter =
    void Function(ui.Canvas canvas, ui.Size size);

/// Everything needed to draw one page without widgets: used for page
/// thumbnails, region captures (stickers) and PDF export.
///
/// Painting is synchronous, so every image the page needs must already be
/// decoded and listed in [images]. The lists and the map must not be mutated
/// after construction. A transient render request, not a persisted model, so
/// it has no JSON form.
@immutable
class NotePageRenderInput {
  /// A render request for a page of [size].
  const NotePageRenderInput({
    required this.size,
    this.paintBackground,
    this.layers = const <NotePageRenderLayer>[],
    this.objects = const <NoteObject>[],
    this.images = const <String, ui.Image>{},
    this.textBoxTypography = defaultTextBoxTypography,
  });

  /// Page size in page units (PDF points).
  final NotePageSize size;

  /// Paints the paper (template, imported page background…). `null` means no
  /// paper: the page stays transparent.
  final NotePageBackgroundPainter? paintBackground;

  /// Ink layers, bottom first.
  final List<NotePageRenderLayer> layers;

  /// Note objects, bottom first, drawn above every layer.
  final List<NoteObject> objects;

  /// Decoded images keyed by their source string (`ImageDrawable.source`, a
  /// sticker's `source`…). A missing entry draws a light placeholder. The
  /// caller owns the images and disposes them.
  final Map<String, ui.Image> images;

  /// Display typography of text boxes, matching what the screen uses.
  final TextBoxTypography textBoxTypography;

  /// The decoded image for [source], or `null`.
  ui.Image? imageFor(String source) => images[source];

  /// What [NoteObject.paintToCanvas] receives.
  NoteObjectPaintContext get paintContext =>
      NoteObjectPaintContext(imageLookup: imageFor);

  /// The sources of every visible image drawable on paintable layers, so a
  /// host knows which images to decode. Sources used by [objects] (stickers)
  /// are not listed because objects are opaque to this module.
  Set<String> get drawableImageSources => {
    for (final layer in layers)
      if (layer.isPaintable)
        for (final image in layer.scribble.imageDrawables)
          if (!image.hidden && image.source.isNotEmpty) image.source,
  };

  /// A copy with the given fields replaced. Pass [removeBackground] to drop
  /// [paintBackground].
  NotePageRenderInput copyWith({
    NotePageSize? size,
    NotePageBackgroundPainter? paintBackground,
    bool removeBackground = false,
    List<NotePageRenderLayer>? layers,
    List<NoteObject>? objects,
    Map<String, ui.Image>? images,
    TextBoxTypography? textBoxTypography,
  }) => NotePageRenderInput(
    size: size ?? this.size,
    paintBackground: removeBackground
        ? null
        : paintBackground ?? this.paintBackground,
    layers: layers ?? this.layers,
    objects: objects ?? this.objects,
    images: images ?? this.images,
    textBoxTypography: textBoxTypography ?? this.textBoxTypography,
  );

  @override
  bool operator ==(Object other) =>
      other is NotePageRenderInput &&
      other.size == size &&
      other.paintBackground == paintBackground &&
      listEquals(other.layers, layers) &&
      listEquals(other.objects, objects) &&
      mapEquals(other.images, images) &&
      other.textBoxTypography == textBoxTypography;

  @override
  int get hashCode => Object.hash(
    size,
    paintBackground,
    Object.hashAll(layers),
    Object.hashAll(objects),
    Object.hashAllUnordered(images.keys),
    textBoxTypography,
  );
}
