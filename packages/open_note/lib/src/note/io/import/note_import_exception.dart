/// An import that failed: an unsupported or broken file, or a host plug-in
/// error (kept in [cause]).
class NoteImportException implements Exception {
  /// An error described by [message], optionally caused by [cause].
  const NoteImportException(this.message, {this.cause});

  /// What went wrong.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  @override
  String toString() =>
      'NoteImportException: $message${cause == null ? '' : ' ($cause)'}';
}
