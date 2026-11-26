import 'package:open_note/src/note/core/core.dart';

/// JSON helpers shared by the study-utility models. Not part of the public API.
abstract final class NoteUtilityJson {
  /// The longest duration read from JSON (100 000 hours); longer values are
  /// clamped so later arithmetic cannot overflow.
  static const int maxDurationMilliseconds = 360000000000;

  /// Reads whole milliseconds under [key]: `0` when missing or negative.
  static Duration duration(JsonMap json, String key) => Duration(
    milliseconds: NoteJson.integer(json, key).clamp(0, maxDurationMilliseconds),
  );

  /// Reads an ISO-8601 time under [key]; the Unix epoch (UTC) when missing or
  /// malformed.
  static DateTime time(JsonMap json, String key) =>
      DateTime.tryParse(NoteJson.string(json, key)) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
