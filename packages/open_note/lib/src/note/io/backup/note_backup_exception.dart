/// A backup operation that failed: a bad name, a missing backup or a driver
/// error (kept in [cause]).
class NoteBackupException implements Exception {
  /// An error described by [message], optionally caused by [cause].
  const NoteBackupException(this.message, {this.cause});

  /// What went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() =>
      'NoteBackupException: $message${cause == null ? '' : ' ($cause)'}';
}
