import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/internal/note_tools_numbers.dart';
import 'package:open_note/src/note/tools/note_preset.dart';
import 'package:open_note/src/note/tools/note_text_style_align.dart';

/// A saved text style. Applying it to text is up to the host; this object only
/// carries the values.
///
/// Values read from this object are valid: [fontSize] is clamped into
/// [minFontSize]–[maxFontSize] and [lineHeight] is 0 or inside
/// [minLineHeight]–[maxLineHeight]. Colours are compared by their 32-bit ARGB
/// value.
///
/// JSON: `{"id": String, "name": String, "fontFamily": String,
/// "fontSize": number, "lineHeight": number, "color": int ARGB, "bold": bool,
/// "italic": bool, "underline": bool, "align": "left" | "center" | "right"}`.
@immutable
class NoteTextStylePreset implements NotePreset {
  /// Smallest [fontSize].
  static const double minFontSize = 4;

  /// Largest [fontSize].
  static const double maxFontSize = 200;

  /// Default [fontSize].
  static const double defaultFontSize = 14;

  /// Smallest explicit [lineHeight].
  static const double minLineHeight = 0.5;

  /// Largest [lineHeight].
  static const double maxLineHeight = 5;

  @override
  final String id;

  /// Display name; may be empty.
  final String name;

  /// Font family; `''` means the default font.
  final String fontFamily;

  /// Text colour.
  final Color color;

  /// Bold text.
  final bool bold;

  /// Italic text.
  final bool italic;

  /// Underlined text.
  final bool underline;

  /// Paragraph alignment.
  final NoteTextStyleAlign align;

  final double _fontSize;

  final double _lineHeight;

  /// Creates a text style.
  const NoteTextStylePreset({
    required this.id,
    this.name = '',
    this.fontFamily = '',
    double fontSize = defaultFontSize,
    double lineHeight = 0,
    this.color = const Color(0xFF000000),
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.align = NoteTextStyleAlign.left,
  }) : _fontSize = fontSize,
       _lineHeight = lineHeight;

  /// Reads the JSON form; never throws. A missing id reads as `''` (a preset
  /// store skips such an entry) and an unknown `align` as left.
  factory NoteTextStylePreset.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteTextStylePreset(
      id: NoteJson.string(map, 'id'),
      name: NoteJson.string(map, 'name'),
      fontFamily: NoteJson.string(map, 'fontFamily'),
      fontSize: NoteJson.number(map, 'fontSize', defaultFontSize),
      lineHeight: NoteJson.number(map, 'lineHeight'),
      color: NoteJson.color(map, 'color', const Color(0xFF000000)),
      bold: NoteJson.boolean(map, 'bold'),
      italic: NoteJson.boolean(map, 'italic'),
      underline: NoteJson.boolean(map, 'underline'),
      align: NoteJson.enumByName(
        NoteTextStyleAlign.values,
        map['align'],
        NoteTextStyleAlign.left,
      ),
    );
  }

  /// Font size in page units. Default 14.
  double get fontSize => noteClampOr(
    _fontSize,
    min: minFontSize,
    max: maxFontSize,
    fallback: defaultFontSize,
  );

  /// Line height as a multiple of the font size; 0 (also for NaN or a value
  /// that is not positive) keeps the font's own.
  double get lineHeight => _lineHeight.isFinite && _lineHeight > 0
      ? _lineHeight.clamp(minLineHeight, maxLineHeight)
      : 0;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fontFamily,
    fontSize,
    lineHeight,
    color.toARGB32(),
    bold,
    italic,
    underline,
    align,
  );

  /// A copy with the given values replaced.
  NoteTextStylePreset copyWith({
    String? id,
    String? name,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    Color? color,
    bool? bold,
    bool? italic,
    bool? underline,
    NoteTextStyleAlign? align,
  }) => NoteTextStylePreset(
    id: id ?? this.id,
    name: name ?? this.name,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    color: color ?? this.color,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    align: align ?? this.align,
  );

  @override
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'color': NoteJson.colorToJson(color),
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'align': align.name,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteTextStylePreset &&
      other.id == id &&
      other.name == name &&
      other.fontFamily == fontFamily &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.color.toARGB32() == color.toARGB32() &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.align == align;

  @override
  String toString() => 'NoteTextStylePreset(${toJson()})';
}
