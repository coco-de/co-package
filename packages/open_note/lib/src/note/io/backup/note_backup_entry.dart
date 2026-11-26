import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// One backup held by a `NoteBackupDriver`.
///
/// JSON schema: `{"name": String, "size": int, "modified": ISO-8601 String}`.
@immutable
class NoteBackupEntry {
  /// A backup called [name] of [size] bytes, written at [modified].
  const NoteBackupEntry({
    required this.name,
    required this.size,
    required this.modified,
  });

  /// Lenient decoding: a bad size is 0, a bad date the Unix epoch.
  factory NoteBackupEntry.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};
    final size = NoteJson.integer(json, 'size');

    return NoteBackupEntry(
      name: NoteJson.string(json, 'name'),
      size: size < 0 ? 0 : size,
      modified:
          DateTime.tryParse(NoteJson.string(json, 'modified')) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// The driver's name for the backup (a flat file name).
  final String name;

  /// Size in bytes.
  final int size;

  /// When the driver stored it.
  final DateTime modified;

  /// A copy with the given fields replaced.
  NoteBackupEntry copyWith({String? name, int? size, DateTime? modified}) =>
      NoteBackupEntry(
        name: name ?? this.name,
        size: size ?? this.size,
        modified: modified ?? this.modified,
      );

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'name': name,
    'size': size,
    'modified': modified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteBackupEntry &&
      other.name == name &&
      other.size == size &&
      other.modified == modified;

  @override
  int get hashCode => Object.hash(name, size, modified);

  @override
  String toString() => 'NoteBackupEntry($name, $size bytes, $modified)';
}
