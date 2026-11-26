/// Thrown by a `NoteAudioRecorder` or `NoteAudioPlayer` that cannot do what it
/// was asked.
class NoteAudioException implements Exception {
  /// Creates a failure with a developer-facing [message].
  const NoteAudioException(this.message);

  /// An English diagnostic for developers.
  final String message;

  @override
  String toString() => 'NoteAudioException: $message';
}
