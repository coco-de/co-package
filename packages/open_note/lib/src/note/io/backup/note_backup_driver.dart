import 'dart:typed_data';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';
import 'package:open_note/src/note/io/backup/note_backup_exception.dart';

/// Where backups are kept: a folder (`DirectoryNoteBackupDriver`), memory
/// (`MemoryNoteBackupDriver`) or a cloud drive plugged in by the host.
///
/// Backup names are flat file names; check them with [validateName].
abstract interface class NoteBackupDriver {
  /// Stores [bytes] as [name], replacing any backup of that name.
  Future<void> put(String name, Uint8List bytes);

  /// The backup called [name], or `null`.
  Future<Uint8List?> get(String name);

  /// Every backup, in any order.
  Future<List<NoteBackupEntry>> list();

  /// Deletes [name]; a missing backup is not an error.
  Future<void> delete(String name);

  /// Returns [name] if it is a safe flat file name: not empty, no `/`, `\` or
  /// control character, and not starting with a dot. Otherwise throws
  /// [NoteBackupException].
  static String validateName(String name) {
    final isUnsafe =
        name.contains('/') ||
        name.startsWith('.') ||
        name.codeUnits.any((unit) => unit < 0x20 || unit == 0x7F);
    try {
      NoteStoreKeys.validateKey(name);
    } on NoteStoreException catch (error) {
      throw NoteBackupException('unsafe backup name: $name', cause: error);
    }
    if (isUnsafe) throw NoteBackupException('unsafe backup name: $name');

    return name;
  }
}
