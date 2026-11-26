import 'package:flutter/foundation.dart';

/// A file to import: its [name], [bytes] and, when known, [mimeType].
///
/// A transient request holding raw bytes, so it has no JSON form. The bytes
/// must not be mutated after construction.
@immutable
class NoteImportSource {
  /// A source named [name] with the file content [bytes].
  const NoteImportSource({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  /// File name, with its extension when there is one.
  final String name;

  /// File content.
  final Uint8List bytes;

  /// MIME type reported by the picker, if any.
  final String? mimeType;

  /// The lower-case extension of [name] without the dot, or `''`.
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    final tail = name.substring(dot + 1);

    return tail.contains('/') ? '' : tail.toLowerCase();
  }

  /// A copy with the given fields replaced.
  NoteImportSource copyWith({
    String? name,
    Uint8List? bytes,
    String? mimeType,
  }) => NoteImportSource(
    name: name ?? this.name,
    bytes: bytes ?? this.bytes,
    mimeType: mimeType ?? this.mimeType,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteImportSource &&
      other.name == name &&
      other.mimeType == mimeType &&
      listEquals(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(name, mimeType, bytes.length);

  @override
  String toString() => 'NoteImportSource($name, ${bytes.length} bytes)';
}
