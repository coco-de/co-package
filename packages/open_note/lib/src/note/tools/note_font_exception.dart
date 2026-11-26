/// A font could not be registered or downloaded.
class NoteFontException implements Exception {
  /// What went wrong.
  final String message;

  /// Creates an exception with a human readable [message].
  const NoteFontException(this.message);

  @override
  String toString() => 'NoteFontException: $message';
}
