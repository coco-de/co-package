import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/style/note_image_crop.dart';
import 'package:open_note/src/note/style/note_style_values.dart';

/// Frame, rounding, transparency and crop of a placed image.
///
/// ## Encoded form (stored in a protobuf string field)
///
/// [encode] returns the compact JSON of [toJson]: an object with any of
///
/// | key            | value                      | default   |
/// |----------------|----------------------------|-----------|
/// | `borderColor`  | 32-bit ARGB integer        | no border |
/// | `borderWidth`  | 0 – 50 page units          | 2         |
/// | `cornerRadius` | 0 – 1000 page units        | 0         |
/// | `opacity`      | 0 – 1                      | 1         |
/// | `crop`         | `NoteImageCrop.toJson()`   | no crop   |
///
/// Fields at their default are left out, so [plain] encodes as `{}`.
/// [NoteImageStyle.decode] accepts `null`, broken JSON or wrong types (they
/// read as the default), clamps numbers and never throws.
@immutable
class NoteImageStyle {
  /// The untouched image.
  static const NoteImageStyle plain = NoteImageStyle._(
    borderColor: null,
    borderWidth: defaultBorderWidth,
    cornerRadius: 0,
    opacity: 1,
    crop: NoteImageCrop.none,
  );

  /// Default `borderWidth` (used once a border colour is set).
  static const double defaultBorderWidth = 2;

  /// Largest `borderWidth`.
  static const double maxBorderWidth = 50;

  /// Largest `cornerRadius`.
  static const double maxCornerRadius = 1000;

  /// Border colour, or `null` for no border.
  final Color? borderColor;

  /// Border width in page units, drawn inside the image outline.
  final double borderWidth;

  /// Corner radius in page units.
  final double cornerRadius;

  /// 0 – 1.
  final double opacity;

  /// The visible part of the image.
  final NoteImageCrop crop;

  const NoteImageStyle._({
    required this.borderColor,
    required this.borderWidth,
    required this.cornerRadius,
    required this.opacity,
    required this.crop,
  });

  /// Creates a style; numbers are clamped, non-finite ones take the default and
  /// the colour is rounded to 8 bits per channel.
  NoteImageStyle({
    Color? borderColor,
    double borderWidth = defaultBorderWidth,
    double cornerRadius = 0,
    double opacity = 1,
    this.crop = NoteImageCrop.none,
  }) : borderColor = NoteStyleValues.quantiseOrNull(borderColor),
       borderWidth = NoteStyleValues.clamped(
         borderWidth,
         defaultBorderWidth,
         0,
         maxBorderWidth,
       ),
       cornerRadius = NoteStyleValues.clamped(
         cornerRadius,
         0,
         0,
         maxCornerRadius,
       ),
       opacity = NoteStyleValues.clamped(opacity, 1, 0, 1);

  /// Reads [toJson]; anything unreadable takes the default.
  factory NoteImageStyle.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return plain;

    return NoteImageStyle(
      borderColor: NoteStyleValues.colorOrNull(json, 'borderColor'),
      borderWidth: NoteJson.number(json, 'borderWidth', defaultBorderWidth),
      cornerRadius: NoteJson.number(json, 'cornerRadius'),
      opacity: NoteJson.number(json, 'opacity', 1),
      crop: NoteImageCrop.fromJson(json['crop']),
    );
  }

  /// Reads the encoded string; never throws.
  factory NoteImageStyle.decode(String? source) =>
      NoteImageStyle.fromJson(NoteJson.decodeMap(source));

  /// Whether a border is drawn.
  bool get hasBorder => borderColor != null && borderWidth > 0;

  /// The encoded form; `NoteImageStyle.decode(encode())` equals `this`.
  String encode() => NoteJson.encode(toJson());

  /// A copy with some fields replaced. [clearBorderColor] removes the border.
  NoteImageStyle copyWith({
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    double? cornerRadius,
    double? opacity,
    NoteImageCrop? crop,
  }) => NoteImageStyle(
    borderColor: clearBorderColor ? null : borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    opacity: opacity ?? this.opacity,
    crop: crop ?? this.crop,
  );

  /// The JSON map form (see the class documentation).
  JsonMap toJson() => {
    if (borderColor case final color?)
      'borderColor': NoteJson.colorToJson(color),
    if (borderWidth != defaultBorderWidth) 'borderWidth': borderWidth,
    if (cornerRadius != 0) 'cornerRadius': cornerRadius,
    if (opacity != 1) 'opacity': opacity,
    if (!crop.isNone) 'crop': crop.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteImageStyle &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.cornerRadius == cornerRadius &&
      other.opacity == opacity &&
      other.crop == crop;

  @override
  int get hashCode =>
      Object.hash(borderColor, borderWidth, cornerRadius, opacity, crop);

  @override
  String toString() => 'NoteImageStyle(${encode()})';
}
