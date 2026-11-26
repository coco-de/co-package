import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';

/// The pattern family of a [NoteMaskFill]. The `name`s are persisted.
enum NoteMaskFillKind {
  /// One flat [NoteMaskFill.color].
  solid,

  /// Diagonal stripes of [NoteMaskFill.patternColor] over
  /// [NoteMaskFill.color].
  stripes,

  /// A grid of [NoteMaskFill.patternColor] dots over [NoteMaskFill.color].
  dots,

  /// The picture at [NoteMaskFill.source], scaled to cover the shape.
  /// [NoteMaskFill.color] is painted under it and while it is not available.
  image,
}

/// How a cover-up mask or a tape is painted.
///
/// JSON: `{"kind": "solid"|"stripes"|"dots"|"image", "color": int,
/// "patternColor": int, "source": string}` (colours are ARGB integers and
/// `source` is optional).
/// [NoteMaskFill.fromJson] never throws: unknown kinds and an image without a
/// source become `solid`, and bad colours take the defaults.
@immutable
class NoteMaskFill {
  /// A fill of [kind]. [source] is only used by [NoteMaskFillKind.image].
  const NoteMaskFill({
    this.kind = NoteMaskFillKind.solid,
    this.color = defaultColor,
    this.patternColor = defaultPatternColor,
    this.source,
  });

  /// A flat fill of [color].
  const NoteMaskFill.solid([Color color = defaultColor]) : this(color: color);

  /// Diagonal stripes of [patternColor] over [color].
  const NoteMaskFill.stripes({
    Color color = defaultColor,
    Color patternColor = defaultPatternColor,
  }) : this(
         kind: NoteMaskFillKind.stripes,
         color: color,
         patternColor: patternColor,
       );

  /// Dots of [patternColor] over [color].
  const NoteMaskFill.dots({
    Color color = defaultColor,
    Color patternColor = defaultPatternColor,
  }) : this(
         kind: NoteMaskFillKind.dots,
         color: color,
         patternColor: patternColor,
       );

  /// The picture at [source] (an opaque string such as a path or URL) over a
  /// [color] fallback.
  const NoteMaskFill.image(String source, {Color color = defaultColor})
    : this(kind: NoteMaskFillKind.image, color: color, source: source);

  /// Reads [toJson] output; anything that is not a JSON object gives
  /// [fallback].
  factory NoteMaskFill.fromJson(
    Object? value, [
    NoteMaskFill fallback = const NoteMaskFill(),
  ]) {
    final json = NoteJson.asMap(value);
    if (json == null) return fallback;
    final source = NoteJson.stringOrNull(json, 'source');
    final kind = NoteJson.enumByName(
      NoteMaskFillKind.values,
      json['kind'],
      NoteMaskFillKind.solid,
    );
    final usable =
        kind != NoteMaskFillKind.image || (source?.isNotEmpty ?? false);

    return NoteMaskFill(
      kind: usable ? kind : NoteMaskFillKind.solid,
      color: NoteJson.color(json, 'color', defaultColor),
      patternColor: NoteJson.color(json, 'patternColor', defaultPatternColor),
      source: source,
    );
  }

  /// The default base colour (an opaque warm yellow).
  static const Color defaultColor = Color(0xFFFFD54F);

  /// The default colour of stripes and dots (translucent white).
  static const Color defaultPatternColor = Color(0x99FFFFFF);

  /// Which pattern is painted.
  final NoteMaskFillKind kind;

  /// The base colour.
  final Color color;

  /// The colour of stripes or dots (unused by other kinds).
  final Color patternColor;

  /// The image source of an [NoteMaskFillKind.image] fill.
  final String? source;

  /// The image this fill needs decoded, or `null` when it needs none. A host
  /// that exports pages preloads these for [NoteObject.paintToCanvas].
  String? get imageSource =>
      kind == NoteMaskFillKind.image && (source?.isNotEmpty ?? false)
      ? source
      : null;

  /// A copy with the given fields replaced ([source] cannot be cleared).
  NoteMaskFill copyWith({
    NoteMaskFillKind? kind,
    Color? color,
    Color? patternColor,
    String? source,
  }) => NoteMaskFill(
    kind: kind ?? this.kind,
    color: color ?? this.color,
    patternColor: patternColor ?? this.patternColor,
    source: source ?? this.source,
  );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'kind': kind.name,
    'color': NoteJson.colorToJson(color),
    'patternColor': NoteJson.colorToJson(patternColor),
    'source': ?source,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteMaskFill &&
      other.kind == kind &&
      other.color == color &&
      other.patternColor == patternColor &&
      other.source == source;

  @override
  int get hashCode => Object.hash(kind, color, patternColor, source);

  @override
  String toString() => 'NoteMaskFill(${kind.name}, $color)';
}
