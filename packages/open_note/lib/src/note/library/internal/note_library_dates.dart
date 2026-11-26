/// The persisted form of the library's timestamps: ISO-8601 strings in UTC.
abstract final class NoteLibraryDates {
  static const int _maxMilliseconds = 8640000000000000;

  /// What an unreadable timestamp decodes to: the Unix epoch.
  static final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  /// Encodes [value] as an ISO-8601 string in UTC.
  static String toJson(DateTime value) => value.toUtc().toIso8601String();

  /// Decodes an ISO-8601 string (or a number of milliseconds since the epoch)
  /// into a UTC [DateTime], or `null` when [value] is neither.
  static DateTime? tryFromJson(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is num && value.isFinite && value.abs() <= _maxMilliseconds) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }

    return null;
  }
}
