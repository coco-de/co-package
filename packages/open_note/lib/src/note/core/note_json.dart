import 'dart:convert';
import 'dart:ui';

/// JSON object shape used by every note model (`jsonDecode` result type).
typedef JsonMap = Map<String, Object?>;

/// Lenient JSON readers and writers shared by the note models.
///
/// Every reader returns its fallback when the key is missing or has an
/// unexpected type, so a document written by a newer version of the package
/// (extra keys, widened enums) still loads instead of throwing.
abstract final class NoteJson {
  /// Reads a string, or [fallback].
  static String string(JsonMap json, String key, [String fallback = '']) {
    final value = json[key];

    return value is String ? value : fallback;
  }

  /// Reads a string, or `null` when absent or not a string.
  static String? stringOrNull(JsonMap json, String key) {
    final value = json[key];

    return value is String ? value : null;
  }

  /// Reads an integer (numbers are truncated), or [fallback].
  static int integer(JsonMap json, String key, [int fallback = 0]) {
    final value = json[key];
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();

    return fallback;
  }

  /// Reads a finite double, or [fallback].
  static double number(JsonMap json, String key, [double fallback = 0]) {
    final value = json[key];
    if (value is num && value.isFinite) return value.toDouble();

    return fallback;
  }

  /// Reads a bool, or [fallback].
  static bool boolean(JsonMap json, String key, [bool fallback = false]) {
    final value = json[key];

    return value is bool ? value : fallback;
  }

  /// Reads a list (a fresh copy), or an empty list.
  static List<Object?> list(JsonMap json, String key) {
    final value = json[key];

    return value is List ? List<Object?>.of(value) : <Object?>[];
  }

  /// Reads a nested object, or an empty map. Non-string keys are stringified.
  static JsonMap map(JsonMap json, String key) =>
      asMap(json[key]) ?? <String, Object?>{};

  /// Reads a list of nested objects; entries that are not objects are dropped.
  static List<JsonMap> mapList(JsonMap json, String key) => [
    for (final entry in list(json, key))
      if (asMap(entry) case final JsonMap map) map,
  ];

  /// Reads a list of strings; entries that are not strings are dropped.
  static List<String> stringList(JsonMap json, String key) => [
    for (final entry in list(json, key))
      if (entry is String) entry,
  ];

  /// Converts any [Map] to a [JsonMap]; `null` when [value] is not a map.
  static JsonMap? asMap(Object? value) {
    if (value is! Map) return null;

    return value.map((key, entry) => MapEntry('$key', entry));
  }

  /// Looks an enum value up by `name`, or returns [fallback] (unknown names
  /// written by a newer version must not crash older readers).
  static T enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    if (name is! String) return fallback;

    return values.asNameMap()[name] ?? fallback;
  }

  /// Encodes [color] as its 32-bit ARGB integer.
  static int colorToJson(Color color) => color.toARGB32();

  /// Decodes a 32-bit ARGB integer, or returns [fallback].
  static Color colorFromJson(Object? value, Color fallback) {
    if (value is int) return Color(value & 0xFFFFFFFF);
    if (value is num && value.isFinite) {
      return Color(value.toInt() & 0xFFFFFFFF);
    }

    return fallback;
  }

  /// Reads a color stored under [key], or [fallback].
  static Color color(JsonMap json, String key, Color fallback) =>
      colorFromJson(json[key], fallback);

  /// Encodes [rect] as `{x, y, w, h}`.
  static JsonMap rectToJson(Rect rect) => {
    'x': rect.left,
    'y': rect.top,
    'w': rect.width,
    'h': rect.height,
  };

  /// Decodes `{x, y, w, h}`, or returns [fallback].
  static Rect rectFromJson(Object? value, [Rect fallback = Rect.zero]) {
    final map = asMap(value);
    if (map == null) return fallback;
    final x = map['x'];
    final y = map['y'];
    final w = map['w'];
    final h = map['h'];
    if (x is! num || y is! num || w is! num || h is! num) return fallback;
    if (!(x.isFinite && y.isFinite && w.isFinite && h.isFinite)) {
      return fallback;
    }

    return Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      w.toDouble(),
      h.toDouble(),
    );
  }

  /// Reads a rect stored under [key], or [fallback].
  static Rect rect(JsonMap json, String key, [Rect fallback = Rect.zero]) =>
      rectFromJson(json[key], fallback);

  /// Encodes [offset] as `{x, y}`.
  static JsonMap offsetToJson(Offset offset) => {
    'x': offset.dx,
    'y': offset.dy,
  };

  /// Decodes `{x, y}`, or returns [fallback].
  static Offset offsetFromJson(Object? value, [Offset fallback = Offset.zero]) {
    final map = asMap(value);
    if (map == null) return fallback;
    final x = map['x'];
    final y = map['y'];
    if (x is! num || y is! num || !x.isFinite || !y.isFinite) return fallback;

    return Offset(x.toDouble(), y.toDouble());
  }

  /// Reads an offset stored under [key], or [fallback].
  static Offset offset(
    JsonMap json,
    String key, [
    Offset fallback = Offset.zero,
  ]) => offsetFromJson(json[key], fallback);

  /// Encodes [value] to a JSON string.
  static String encode(JsonMap value) => jsonEncode(value);

  /// Decodes a JSON object string; `null` when [source] is not a valid JSON
  /// object.
  static JsonMap? decodeMap(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return asMap(jsonDecode(source));
    } on FormatException {
      return null;
    }
  }
}
