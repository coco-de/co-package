import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/objects/internal/note_sticker_painting.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';

/// A picture stuck on the page. The image keeps its aspect ratio inside the
/// bounds (it is never stretched).
///
/// [source] is opaque to the package (a file path, a URL, an app identifier);
/// the widget turns it into an image with a resolver (by default the engine's
/// `resolveImageSource`).
///
/// JSON payload (the `payload` of [NoteObject.toJson]):
///
/// ```text
/// {"source": String, "flipHorizontal": bool}
/// ```
///
/// [NoteStickerObject.decode] never throws: a missing or mistyped value takes
/// its default.
@immutable
class NoteStickerObject extends NoteObject implements NoteReidentifiableObject {
  /// The `kind` of stickers.
  static const String kindName = 'sticker';

  /// Where the picture comes from.
  final String source;

  /// Whether the picture is mirrored left to right.
  final bool flipHorizontal;

  const NoteStickerObject({
    required super.id,
    required super.bounds,
    this.source = '',
    this.flipHorizontal = false,
    super.rotation,
    super.opacity,
    super.locked,
  });

  /// Rebuilds a sticker from its [base] fields and [payload].
  factory NoteStickerObject.decode(NoteObjectBase base, JsonMap payload) =>
      NoteStickerObject(
        id: base.id,
        bounds: NoteObjectGeometry.normalizeRect(base.bounds),
        rotation: base.rotation,
        opacity: base.opacity,
        locked: base.locked,
        source: NoteJson.string(payload, 'source'),
        flipHorizontal: NoteJson.boolean(payload, 'flipHorizontal'),
      );

  @override
  String get kind => kindName;

  @override
  int get hashCode => Object.hash(
    id,
    bounds,
    rotation,
    opacity,
    locked,
    source,
    flipHorizontal,
  );

  /// A copy with the given fields replaced; the [id] is kept.
  NoteStickerObject copyWith({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
    String? source,
    bool? flipHorizontal,
  }) => NoteStickerObject(
    id: id,
    bounds: bounds ?? this.bounds,
    rotation: rotation ?? this.rotation,
    opacity: opacity ?? this.opacity,
    locked: locked ?? this.locked,
    source: source ?? this.source,
    flipHorizontal: flipHorizontal ?? this.flipHorizontal,
  );

  @override
  NoteStickerObject withBase({
    Rect? bounds,
    double? rotation,
    double? opacity,
    bool? locked,
  }) => copyWith(
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
  );

  @override
  NoteStickerObject withId(String id) => NoteStickerObject(
    id: id,
    bounds: bounds,
    rotation: rotation,
    opacity: opacity,
    locked: locked,
    source: source,
    flipHorizontal: flipHorizontal,
  );

  @override
  JsonMap payloadToJson() => {
    'source': source,
    'flipHorizontal': flipHorizontal,
  };

  /// Draws `context.imageFor(source)`, or a light placeholder while that image
  /// is not available.
  @override
  void paintToCanvas(ui.Canvas canvas, NoteObjectPaintContext context) {
    final image = context.imageFor(source);
    if (image == null) {
      NoteStickerPainting.paintPlaceholder(canvas, bounds);
    } else {
      NoteStickerPainting.paintImage(
        canvas,
        bounds,
        image,
        flipHorizontal: flipHorizontal,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is NoteStickerObject &&
      other.runtimeType == runtimeType &&
      other.id == id &&
      other.bounds == bounds &&
      other.rotation == rotation &&
      other.opacity == opacity &&
      other.locked == locked &&
      other.source == source &&
      other.flipHorizontal == flipHorizontal;

  @override
  String toString() => 'NoteStickerObject($id, $bounds, $source)';
}
