import 'package:flutter/foundation.dart';

/// Why an AI pen request failed.
enum NoteAiPenErrorCode {
  /// The app set up no service.
  notConfigured,

  /// The input cannot be processed (for example, nothing was selected).
  invalidRequest,

  /// The service could not be reached.
  network,

  /// Anything else.
  unknown,
}

/// The failure of an AI pen request. Services throw it; the controller wraps
/// every other error into one with [NoteAiPenErrorCode.unknown].
@immutable
class NoteAiPenException implements Exception {
  /// Creates an exception.
  const NoteAiPenException(
    this.message, {
    this.code = NoteAiPenErrorCode.unknown,
    this.cause,
  });

  /// A description for logs. The result panel shows the localised text of
  /// [code] instead.
  final String message;

  /// The category of the failure.
  final NoteAiPenErrorCode code;

  /// The underlying error, if any.
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      other is NoteAiPenException &&
      other.message == message &&
      other.code == code &&
      other.cause == cause;

  @override
  int get hashCode => Object.hash(message, code, cause);

  @override
  String toString() => 'NoteAiPenException(${code.name}): $message';
}
