import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/style/note_style_values.dart';
import 'package:open_note/src/note/style/note_text_box_border_style.dart';

/// How the box around a text drawable looks.
///
/// ## Encoded form (stored in a protobuf string field)
///
/// [encode] returns the compact JSON of [toJson]: an object with any of
///
/// | key               | value                          | default      |
/// |-------------------|--------------------------------|--------------|
/// | `backgroundColor` | 32-bit ARGB integer            | none         |
/// | `borderColor`     | 32-bit ARGB integer            | none         |
/// | `borderWidth`     | 0 – 20 page units              | 1            |
/// | `borderLineStyle` | `solid` or `dashed`            | `solid`      |
/// | `cornerRadius`    | 0 – 200 page units             | 0            |
/// | `padding`         | `[l, t, r, b]`, each 0 – 200   | `[4,4,4,4]`  |
/// | `opacity`         | 0 – 1                          | 1            |
/// | `lineHeight`      | 0 (font default) or 0.5 – 4    | 0            |
///
/// Fields at their default are left out, so [plain] encodes as `{}`.
/// [NoteTextBoxStyle.decode] accepts `null`, broken JSON or wrong types (they
/// read as the default), clamps numbers and never throws.
@immutable
class NoteTextBoxStyle {
  /// Neither background nor border, 4 units of padding.
  static const NoteTextBoxStyle plain = NoteTextBoxStyle._(
    backgroundColor: null,
    borderColor: null,
    borderWidth: defaultBorderWidth,
    borderLineStyle: NoteTextBoxBorderStyle.solid,
    cornerRadius: 0,
    padding: defaultPadding,
    opacity: 1,
    lineHeight: 0,
  );

  /// Default `borderWidth`.
  static const double defaultBorderWidth = 1;

  /// Default `padding`.
  static const EdgeInsets defaultPadding = EdgeInsets.all(4);

  /// Largest `borderWidth`.
  static const double maxBorderWidth = 20;

  /// Largest `cornerRadius`.
  static const double maxCornerRadius = 200;

  /// Largest padding per side.
  static const double maxPadding = 200;

  /// Smallest line height multiplier other than 0 (font default).
  static const double minLineHeight = 0.5;

  /// Largest line height multiplier.
  static const double maxLineHeight = 4;

  /// Fill behind the text, or `null` for none.
  final Color? backgroundColor;

  /// Border colour, or `null` for no border.
  final Color? borderColor;

  /// Border width in page units (drawn inside the box).
  final double borderWidth;

  /// Solid or dashed border.
  final NoteTextBoxBorderStyle borderLineStyle;

  /// Corner radius of the box in page units.
  final double cornerRadius;

  /// Space between the text bounds and the box edge, per side.
  final EdgeInsets padding;

  /// 0 – 1. Applies to the background and border; the host should apply it to
  /// the text as well.
  final double opacity;

  /// Line height multiplier of the text; 0 keeps the font's own.
  final double lineHeight;

  const NoteTextBoxStyle._({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderLineStyle,
    required this.cornerRadius,
    required this.padding,
    required this.opacity,
    required this.lineHeight,
  });

  /// Creates a style; numbers are clamped, non-finite ones take the default and
  /// colours are rounded to 8 bits per channel. A [lineHeight] of 0 or less
  /// means the font default.
  NoteTextBoxStyle({
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = defaultBorderWidth,
    this.borderLineStyle = NoteTextBoxBorderStyle.solid,
    double cornerRadius = 0,
    EdgeInsets padding = defaultPadding,
    double opacity = 1,
    double lineHeight = 0,
  }) : backgroundColor = NoteStyleValues.quantiseOrNull(backgroundColor),
       borderColor = NoteStyleValues.quantiseOrNull(borderColor),
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
       padding = _cleanPadding(padding),
       opacity = NoteStyleValues.clamped(opacity, 1, 0, 1),
       lineHeight = _cleanLineHeight(lineHeight);

  /// Reads [toJson]; anything unreadable takes the default.
  factory NoteTextBoxStyle.fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return plain;

    return NoteTextBoxStyle(
      backgroundColor: NoteStyleValues.colorOrNull(json, 'backgroundColor'),
      borderColor: NoteStyleValues.colorOrNull(json, 'borderColor'),
      borderWidth: NoteJson.number(json, 'borderWidth', defaultBorderWidth),
      borderLineStyle: NoteJson.enumByName(
        NoteTextBoxBorderStyle.values,
        json['borderLineStyle'],
        NoteTextBoxBorderStyle.solid,
      ),
      cornerRadius: NoteJson.number(json, 'cornerRadius'),
      padding: _paddingFromJson(json['padding']),
      opacity: NoteJson.number(json, 'opacity', 1),
      lineHeight: NoteJson.number(json, 'lineHeight'),
    );
  }

  /// Reads the encoded string; never throws.
  factory NoteTextBoxStyle.decode(String? source) =>
      NoteTextBoxStyle.fromJson(NoteJson.decodeMap(source));

  static EdgeInsets _cleanPadding(EdgeInsets padding) {
    double side(double value) =>
        NoteStyleValues.clamped(value, defaultPadding.left, 0, maxPadding);

    return EdgeInsets.fromLTRB(
      side(padding.left),
      side(padding.top),
      side(padding.right),
      side(padding.bottom),
    );
  }

  static double _cleanLineHeight(double value) => value.isFinite && value > 0
      ? value.clamp(minLineHeight, maxLineHeight)
      : 0;

  static EdgeInsets _paddingFromJson(Object? value) {
    if (value is! List || value.length != 4) return defaultPadding;
    final sides = [for (final side in value) side is num ? side : null];
    if (sides.contains(null)) return defaultPadding;

    return EdgeInsets.fromLTRB(
      sides[0]!.toDouble(),
      sides[1]!.toDouble(),
      sides[2]!.toDouble(),
      sides[3]!.toDouble(),
    );
  }

  /// Whether a border is drawn.
  bool get hasBorder => borderColor != null && borderWidth > 0;

  /// Whether the box draws anything.
  bool get isVisible => backgroundColor != null || hasBorder;

  /// [lineHeight] as a `TextStyle.height` value (`null` for the font default).
  double? get textHeight => lineHeight > 0 ? lineHeight : null;

  /// The encoded form; `NoteTextBoxStyle.decode(encode())` equals `this`.
  String encode() => NoteJson.encode(toJson());

  /// A copy with some fields replaced; the `clear` flags remove a colour.
  NoteTextBoxStyle copyWith({
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    NoteTextBoxBorderStyle? borderLineStyle,
    double? cornerRadius,
    EdgeInsets? padding,
    double? opacity,
    double? lineHeight,
  }) => NoteTextBoxStyle(
    backgroundColor: clearBackgroundColor
        ? null
        : backgroundColor ?? this.backgroundColor,
    borderColor: clearBorderColor ? null : borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderLineStyle: borderLineStyle ?? this.borderLineStyle,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    padding: padding ?? this.padding,
    opacity: opacity ?? this.opacity,
    lineHeight: lineHeight ?? this.lineHeight,
  );

  /// The JSON map form (see the class documentation).
  JsonMap toJson() => {
    if (backgroundColor case final color?)
      'backgroundColor': NoteJson.colorToJson(color),
    if (borderColor case final color?)
      'borderColor': NoteJson.colorToJson(color),
    if (borderWidth != defaultBorderWidth) 'borderWidth': borderWidth,
    if (borderLineStyle != NoteTextBoxBorderStyle.solid)
      'borderLineStyle': borderLineStyle.name,
    if (cornerRadius != 0) 'cornerRadius': cornerRadius,
    if (padding != defaultPadding)
      'padding': [padding.left, padding.top, padding.right, padding.bottom],
    if (opacity != 1) 'opacity': opacity,
    if (lineHeight != 0) 'lineHeight': lineHeight,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteTextBoxStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderLineStyle == borderLineStyle &&
      other.cornerRadius == cornerRadius &&
      other.padding == padding &&
      other.opacity == opacity &&
      other.lineHeight == lineHeight;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderLineStyle,
    cornerRadius,
    padding,
    opacity,
    lineHeight,
  );

  @override
  String toString() => 'NoteTextBoxStyle(${encode()})';
}
