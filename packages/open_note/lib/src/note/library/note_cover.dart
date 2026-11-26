import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/note_cover_catalog.dart';

/// The cover of a notebook as shown in the library.
///
/// A cover is a built-in design ([NoteCoverKind.builtin], [builtinId]), a solid
/// colour ([NoteCoverKind.color], [color]) or a picture
/// ([NoteCoverKind.image], [imageSource]). Only the field named by [kind] is
/// used; [copyWith] and [NoteCover.fromJson] drop the others.
///
/// [size] and [orientation] give the cover the proportions of a page: see
/// [pageSize] and [aspectRatio].
///
/// JSON schema (fields the kind does not use are omitted):
/// ```json
/// {
///   "kind": "builtin" | "color" | "image",
///   "builtinId": "ocean",
///   "color": 4280391411,
///   "imageSource": "/path/or/url",
///   "size": {"w": 595, "h": 842},
///   "orientation": "portrait" | "landscape"
/// }
/// ```
@immutable
class NoteCover {
  /// Creates a cover of [kind]; the field belonging to the kind must be given.
  const NoteCover({
    required this.kind,
    this.builtinId,
    this.color,
    this.imageSource,
    this.size = NotePageSize.a4,
    this.orientation = NotePageOrientation.portrait,
  }) : assert(
         kind != NoteCoverKind.builtin || builtinId != null,
         'a builtin cover needs a builtinId',
       ),
       assert(
         kind != NoteCoverKind.color || color != null,
         'a color cover needs a color',
       ),
       assert(
         kind != NoteCoverKind.image || imageSource != null,
         'an image cover needs an imageSource',
       );

  /// A built-in design (see [NoteCoverCatalog.builtIn]). An unknown [id] is
  /// kept, but drawn like [NoteCoverCatalog.defaultId].
  const NoteCover.builtIn(
    String id, {
    this.size = NotePageSize.a4,
    this.orientation = NotePageOrientation.portrait,
  }) : kind = NoteCoverKind.builtin,
       builtinId = id,
       color = null,
       imageSource = null;

  /// A cover filled with one colour.
  const NoteCover.solid(
    Color fill, {
    this.size = NotePageSize.a4,
    this.orientation = NotePageOrientation.portrait,
  }) : kind = NoteCoverKind.color,
       builtinId = null,
       color = fill,
       imageSource = null;

  /// A cover showing the picture at [source] (an opaque string: file path, URL
  /// or an id the host's image resolver understands).
  const NoteCover.picture(
    String source, {
    this.size = NotePageSize.a4,
    this.orientation = NotePageOrientation.portrait,
  }) : kind = NoteCoverKind.image,
       builtinId = null,
       color = null,
       imageSource = source;

  /// Decodes the JSON form. Anything malformed falls back to [standard]; a
  /// `color` or `image` cover without its value becomes a built-in cover. A
  /// missing orientation follows the proportions of the decoded size.
  factory NoteCover.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return standard;
    final size = NotePageSize.fromJson(json['size']);
    final orientation = NoteJson.enumByName(
      NotePageOrientation.values,
      json['orientation'],
      size.orientation,
    );
    final kind = NoteJson.enumByName(
      NoteCoverKind.values,
      json['kind'],
      NoteCoverKind.builtin,
    );
    final color = json['color'];
    if (kind == NoteCoverKind.color && color is num && color.isFinite) {
      return NoteCover.solid(
        NoteJson.colorFromJson(color, const Color(0xFF000000)),
        size: size,
        orientation: orientation,
      );
    }
    final source = NoteJson.string(json, 'imageSource');
    if (kind == NoteCoverKind.image && source.isNotEmpty) {
      return NoteCover.picture(source, size: size, orientation: orientation);
    }
    final id = NoteJson.string(json, 'builtinId');

    return NoteCover.builtIn(
      id.isEmpty ? NoteCoverCatalog.defaultId : id,
      size: size,
      orientation: orientation,
    );
  }

  /// The cover given to new notes: the [NoteCoverCatalog.defaultId] design on
  /// an A4 portrait page.
  static const NoteCover standard = NoteCover.builtIn(
    NoteCoverCatalog.defaultId,
  );

  /// What the cover is made of.
  final NoteCoverKind kind;

  /// The design id of a [NoteCoverKind.builtin] cover.
  final String? builtinId;

  /// The fill of a [NoteCoverKind.color] cover.
  final Color? color;

  /// The picture of a [NoteCoverKind.image] cover.
  final String? imageSource;

  /// The page size (PDF points) the cover is proportioned after.
  final NotePageSize size;

  /// How [size] is turned; it wins over the width/height order of [size].
  final NotePageOrientation orientation;

  /// [size] turned to [orientation].
  NotePageSize get pageSize => size.withOrientation(orientation);

  /// Width divided by height of [pageSize].
  double get aspectRatio => pageSize.aspectRatio;

  /// A copy with some fields replaced. The result keeps only the field its kind
  /// uses; switching to a kind needs that kind's field.
  NoteCover copyWith({
    NoteCoverKind? kind,
    String? builtinId,
    Color? color,
    String? imageSource,
    NotePageSize? size,
    NotePageOrientation? orientation,
  }) {
    final next = kind ?? this.kind;

    return NoteCover(
      kind: next,
      builtinId: next == NoteCoverKind.builtin
          ? builtinId ?? this.builtinId ?? NoteCoverCatalog.defaultId
          : null,
      color: next == NoteCoverKind.color ? color ?? this.color : null,
      imageSource: next == NoteCoverKind.image
          ? imageSource ?? this.imageSource
          : null,
      size: size ?? this.size,
      orientation: orientation ?? this.orientation,
    );
  }

  /// The persisted form (see the class documentation).
  JsonMap toJson() {
    final fill = color;

    return {
      'kind': kind.name,
      if (kind == NoteCoverKind.builtin) 'builtinId': builtinId,
      if (kind == NoteCoverKind.color && fill != null)
        'color': NoteJson.colorToJson(fill),
      if (kind == NoteCoverKind.image) 'imageSource': imageSource,
      'size': size.toJson(),
      'orientation': orientation.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is NoteCover &&
      other.kind == kind &&
      other.builtinId == builtinId &&
      other.color == color &&
      other.imageSource == imageSource &&
      other.size == size &&
      other.orientation == orientation;

  @override
  int get hashCode =>
      Object.hash(kind, builtinId, color, imageSource, size, orientation);

  @override
  String toString() => switch (kind) {
    NoteCoverKind.builtin => 'NoteCover.builtIn($builtinId)',
    NoteCoverKind.color => 'NoteCover.solid($color)',
    NoteCoverKind.image => 'NoteCover.picture($imageSource)',
  };
}

/// What a [NoteCover] is made of. The names are persisted.
enum NoteCoverKind {
  /// One of the designs of [NoteCoverCatalog].
  builtin,

  /// A single solid colour.
  color,

  /// A picture resolved from a source string.
  image,
}
