import 'dart:convert';
import 'dart:typed_data';

/// Thrown when a [NoteStore] key is malformed or an operation fails.
class NoteStoreException implements Exception {
  const NoteStoreException(this.message);

  final String message;

  @override
  String toString() => 'NoteStoreException: $message';
}

/// A tiny virtual file system every persisted note model writes through.
///
/// Keys are `/`-separated relative paths such as `library.json` or
/// `notes/<id>/note.json`. A key never starts with `/`, never contains an
/// empty, `.` or `..` segment, a backslash or a NUL — [validateKey] enforces
/// this for every implementation so a hostile key cannot escape the root.
///
/// Implementations: [MemoryNoteStore] (tests, previews) and `FileNoteStore`
/// (a directory on disk). Hosts may add their own (cloud, database).
abstract interface class NoteStore {
  /// Whether [key] exists.
  Future<bool> exists(String key);

  /// The bytes under [key], or `null` when missing.
  Future<Uint8List?> readBytes(String key);

  /// The UTF-8 text under [key], or `null` when missing.
  Future<String?> readString(String key);

  /// Writes [bytes] under [key], replacing any previous value.
  Future<void> writeBytes(String key, Uint8List bytes);

  /// Writes [value] as UTF-8 under [key], replacing any previous value.
  Future<void> writeString(String key, String value);

  /// Deletes [key]; a missing key is not an error.
  Future<void> delete(String key);

  /// Deletes every key that starts with [prefix] (use `notes/<id>/` to remove
  /// a whole note).
  Future<void> deletePrefix(String prefix);

  /// Every key that starts with [prefix], sorted ascending.
  Future<List<String>> list(String prefix);
}

/// Shared key rules for [NoteStore] implementations.
abstract final class NoteStoreKeys {
  /// Throws [NoteStoreException] unless [key] is a safe relative key.
  static String validateKey(String key) {
    if (key.isEmpty) throw const NoteStoreException('empty key');
    if (key.startsWith('/')) {
      throw NoteStoreException('absolute key: $key');
    }
    if (key.contains(r'\') || key.contains('\u0000')) {
      throw NoteStoreException('illegal character in key: $key');
    }
    for (final segment in key.split('/')) {
      if (segment.isEmpty || segment == '.' || segment == '..') {
        throw NoteStoreException('illegal segment in key: $key');
      }
    }

    return key;
  }

  /// Validates a prefix. A prefix may be empty (everything) or end with `/`.
  static String validatePrefix(String prefix) {
    if (prefix.isEmpty) return prefix;
    final trimmed = prefix.endsWith('/')
        ? prefix.substring(0, prefix.length - 1)
        : prefix;
    validateKey(trimmed);

    return prefix;
  }

  /// UTF-8 encodes [value].
  static Uint8List encode(String value) =>
      Uint8List.fromList(utf8.encode(value));

  /// UTF-8 decodes [bytes], tolerating malformed sequences.
  static String decode(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true);
}
