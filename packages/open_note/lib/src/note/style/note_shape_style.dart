import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/style/note_line_style.dart';
import 'package:open_note/src/note/style/note_shape_head_style.dart';
import 'package:open_note/src/note/style/note_style_values.dart';

/// How a shape is filled and stroked.
///
/// ## Encoded form (stored in a protobuf string field)
///
/// [encode] returns the compact JSON of [toJson]: an object with any of
///
/// | key             | value                               | default    |
/// |-----------------|-------------------------------------|------------|
/// | `fillColor`     | 32-bit ARGB integer                 | no fill    |
/// | `fillOpacity`   | 0 – 1                               | 1          |
/// | `strokeOpacity` | 0 – 1                               | 1          |
/// | `cornerRadius`  | 0 – 1000 page units                 | 0          |
/// | `lineStyle`     | `NoteLineStyle.encode()` string     | `solid`    |
/// | `headStyle`     | `none`, `triangle`, `open` or `dot` | `triangle` |
///
/// Fields at their default are left out, so [plain] encodes as `{}`.
/// [NoteShapeStyle.decode] accepts `null`, broken JSON or wrong types (they
/// read as the default), clamps numbers and never throws.
@immutable
class NoteShapeStyle {
  /// No fill, an opaque solid outline.
  static const NoteShapeStyle plain = NoteShapeStyle._(
    fillColor: null,
    fillOpacity: 1,
    strokeOpacity: 1,
    cornerRadius: 0,
    lineStyle: NoteLineStyle.solid,
    headStyle: NoteShapeHeadStyle.triangle,
  );

  /// Largest `cornerRadius`.
  static const double maxCornerRadius = 1000;

  /// Fill colour, or `null` for an unfilled shape. Linear kinds are never
  /// filled.
  final Color? fillColor;

  /// 0 – 1, multiplies the alpha of [fillColor].
  final double fillOpacity;

  /// 0 – 1, multiplies the alpha of the stroke colour.
  final double strokeOpacity;

  /// Corner rounding in page units (rectangles and flat polygons).
  final double cornerRadius;

  /// Decoration of the outline (hidden edges are always dashed).
  final NoteLineStyle lineStyle;

  /// Head of `arrow` and `doubleArrow`.
  final NoteShapeHeadStyle headStyle;

  const NoteShapeStyle._({
    required this.fillColor,
    required this.fillOpacity,
    required this.strokeOpacity,
    required this.cornerRadius,
    required this.lineStyle,
    required this.headStyle,
  });

  /// Creates a style; numbers are clamped, non-finite ones take the default and
  /// colours are rounded to 8 bits per channel.
  NoteShapeStyle({
    Color? fillColor,
    double fillOpacity = 1,
    double strokeOpacity = 1,
    double cornerRadius = 0,
    this.lineStyle = NoteLineStyle.solid,
    this.headStyle = NoteShapeHeadStyle.triangle,
  }) : fillColor = NoteStyleValues.quantiseOrNull(fillColor),
       fillOpacity = NoteStyleValues.clamped(fillOpacity, 1, 0, 1),
       strokeOpacity = NoteStyleValues.clamped(strokeOpacity, 1, 0, 1),
       cornerRadius = NoteStyleValues.clamped(
         cornerRadius,
         0,
         0,
         maxCornerRadius,
       );

  /// Reads [toJson]; anything unreadable takes the default.
  factory NoteShapeStyle.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return plain;

    return NoteShapeStyle(
      fillColor: NoteStyleValues.colorOrNull(json, 'fillColor'),
      fillOpacity: NoteJson.number(json, 'fillOpacity', 1),
      strokeOpacity: NoteJson.number(json, 'strokeOpacity', 1),
      cornerRadius: NoteJson.number(json, 'cornerRadius'),
      lineStyle: NoteLineStyle.fromJson(json['lineStyle']),
      headStyle: NoteJson.enumByName(
        NoteShapeHeadStyle.values,
        json['headStyle'],
        NoteShapeHeadStyle.triangle,
      ),
    );
  }

  /// Reads the encoded string; never throws.
  factory NoteShapeStyle.decode(String? source) =>
      NoteShapeStyle.fromJson(NoteJson.decodeMap(source));

  /// The encoded form; `NoteShapeStyle.decode(encode())` equals `this`.
  String encode() => NoteJson.encode(toJson());

  /// A copy with some fields replaced. [clearFillColor] removes the fill.
  NoteShapeStyle copyWith({
    Color? fillColor,
    bool clearFillColor = false,
    double? fillOpacity,
    double? strokeOpacity,
    double? cornerRadius,
    NoteLineStyle? lineStyle,
    NoteShapeHeadStyle? headStyle,
  }) => NoteShapeStyle(
    fillColor: clearFillColor ? null : fillColor ?? this.fillColor,
    fillOpacity: fillOpacity ?? this.fillOpacity,
    strokeOpacity: strokeOpacity ?? this.strokeOpacity,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    lineStyle: lineStyle ?? this.lineStyle,
    headStyle: headStyle ?? this.headStyle,
  );

  /// The JSON map form (see the class documentation).
  JsonMap toJson() => {
    if (fillColor case final color?) 'fillColor': NoteJson.colorToJson(color),
    if (fillOpacity != 1) 'fillOpacity': fillOpacity,
    if (strokeOpacity != 1) 'strokeOpacity': strokeOpacity,
    if (cornerRadius != 0) 'cornerRadius': cornerRadius,
    if (lineStyle != NoteLineStyle.solid) 'lineStyle': lineStyle.encode(),
    if (headStyle != NoteShapeHeadStyle.triangle) 'headStyle': headStyle.name,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteShapeStyle &&
      other.fillColor == fillColor &&
      other.fillOpacity == fillOpacity &&
      other.strokeOpacity == strokeOpacity &&
      other.cornerRadius == cornerRadius &&
      other.lineStyle == lineStyle &&
      other.headStyle == headStyle;

  @override
  int get hashCode => Object.hash(
    fillColor,
    fillOpacity,
    strokeOpacity,
    cornerRadius,
    lineStyle,
    headStyle,
  );

  @override
  String toString() => 'NoteShapeStyle(${encode()})';
}
