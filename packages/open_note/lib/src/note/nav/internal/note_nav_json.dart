/// JSON helpers shared by the nav module. Not exported by the barrel.
library;

/// Schema version written under the `v` key by the nav controllers.
const int noteNavJsonVersion = 1;

/// Encodes [value] as an ISO-8601 UTC string.
String noteNavDateToJson(DateTime value) => value.toUtc().toIso8601String();

/// Decodes an ISO-8601 string to UTC; anything else becomes the Unix epoch.
DateTime noteNavDateFromJson(Object? value) {
  final parsed = value is String ? DateTime.tryParse(value) : null;

  return parsed?.toUtc() ?? DateTime.utc(1970);
}
