import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';
import 'package:open_note/src/note/tools/note_ink_types.dart';
import 'package:open_note/src/note/tools/note_preset.dart';

/// A saved pen favourite: ink, colour, width, line style and shape target.
///
/// Values read from this object are always valid: an unknown [ink] reads as
/// `pen`, [width] is clamped into [minWidth]–[maxWidth] (NaN reads as
/// [defaultWidth]) and an empty [lineStyle] reads as `solid`. Colours are
/// compared by their 32-bit ARGB value, which is also how they are stored.
///
/// JSON: `{"id": String, "name": String, "ink": String, "color": int ARGB,
/// "width": number, "lineStyle": String, "shapeTarget": String}`.
@immutable
class NoteToolPreset implements NotePreset {
  /// Smallest [width].
  static const double minWidth = 0.1;

  /// Largest [width] (text presets use it as the font size).
  static const double maxWidth = 200;

  /// [width] used for a missing or unusable value.
  static const double defaultWidth = 1;

  /// Default [lineStyle].
  static const String defaultLineStyle = 'solid';

  @override
  final String id;

  /// Display name; may be empty.
  final String name;

  /// Colour, including its alpha (translucent for highlighters).
  final Color color;

  /// Target shape of the shape ink, `''` for free drawing with recognition.
  final String shapeTarget;

  final String _ink;

  final double _width;

  final String _lineStyle;

  /// Creates a preset.
  const NoteToolPreset({
    required this.id,
    required String ink,
    required this.color,
    required double width,
    this.name = '',
    String lineStyle = defaultLineStyle,
    this.shapeTarget = '',
  }) : _ink = ink,
       _width = width,
       _lineStyle = lineStyle;

  /// Reads the JSON form; never throws. A missing id reads as `''` (a preset
  /// store skips such an entry), a missing colour as black.
  factory NoteToolPreset.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteToolPreset(
      id: NoteJson.string(map, 'id'),
      name: NoteJson.string(map, 'name'),
      ink: NoteJson.string(map, 'ink', NoteInkTypes.pen),
      color: NoteJson.color(map, 'color', const Color(0xFF000000)),
      width: NoteJson.number(map, 'width', defaultWidth),
      lineStyle: NoteJson.string(map, 'lineStyle', defaultLineStyle),
      shapeTarget: NoteJson.string(map, 'shapeTarget'),
    );
  }

  /// One of [NoteInkTypes.presetInks]; anything else reads as `pen`.
  String get ink => NoteInkTypes.isPresetInk(_ink) ? _ink : NoteInkTypes.pen;

  /// Stroke width in page units (the font size for the text ink).
  double get width =>
      noteClampOr(_width, min: minWidth, max: maxWidth, fallback: defaultWidth);

  /// Encoded line style, opaque to this module. Default `solid`.
  String get lineStyle => _lineStyle.isEmpty ? defaultLineStyle : _lineStyle;

  /// [width] without trailing zeros: `0.3`, `3`, `2.5` (two decimals at
  /// most).
  String get widthLabel => noteTrimNumber(width);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ink,
    color.toARGB32(),
    width,
    lineStyle,
    shapeTarget,
  );

  /// A copy with the given values replaced.
  NoteToolPreset copyWith({
    String? id,
    String? name,
    String? ink,
    Color? color,
    double? width,
    String? lineStyle,
    String? shapeTarget,
  }) => NoteToolPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    ink: ink ?? this.ink,
    color: color ?? this.color,
    width: width ?? this.width,
    lineStyle: lineStyle ?? this.lineStyle,
    shapeTarget: shapeTarget ?? this.shapeTarget,
  );

  @override
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'ink': ink,
    'color': NoteJson.colorToJson(color),
    'width': width,
    'lineStyle': lineStyle,
    'shapeTarget': shapeTarget,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteToolPreset &&
      other.id == id &&
      other.name == name &&
      other.ink == ink &&
      other.color.toARGB32() == color.toARGB32() &&
      other.width == width &&
      other.lineStyle == lineStyle &&
      other.shapeTarget == shapeTarget;

  @override
  String toString() => 'NoteToolPreset(${toJson()})';
}
