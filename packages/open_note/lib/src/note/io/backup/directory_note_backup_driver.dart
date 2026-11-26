import 'dart:io';
import 'dart:typed_data';

import 'package:open_note/src/note/io/backup/note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';
import 'package:open_note/src/note/io/backup/note_backup_exception.dart';

/// A [NoteBackupDriver] storing one file per backup in a directory (native
/// platforms only). A folder synced by a cloud client makes a simple cloud
/// backup.
///
/// Keep the directory outside the backed-up store, or backups would contain
/// earlier backups. Writes go to a hidden temporary file that is then renamed,
/// so a crash never leaves a half-written backup. Files whose name starts with
/// a dot are ignored.
class DirectoryNoteBackupDriver implements NoteBackupDriver {
  /// A driver keeping backups in [directory], created when first written.
  DirectoryNoteBackupDriver(this.directory);

  /// Where the backup files are.
  final Directory directory;

  @override
  Future<void> put(String name, Uint8List bytes) {
    final target = _file(name);

    return _guard('writing $name', () async {
      await directory.create(recursive: true);
      final temporary = File('${directory.path}/.$name.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    });
  }

  @override
  Future<Uint8List?> get(String name) {
    final file = _file(name);

    return _guard('reading $name', () async {
      if (!await file.exists()) return null;

      return file.readAsBytes();
    });
  }

  /// The backup files, sorted by name.
  @override
  Future<List<NoteBackupEntry>> list() => _guard('listing backups', () async {
    if (!await directory.exists()) return <NoteBackupEntry>[];
    final entries = <NoteBackupEntry>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('.')) continue;
      final stat = await entity.stat();
      entries.add(
        NoteBackupEntry(name: name, size: stat.size, modified: stat.modified),
      );
    }

    return entries..sort((a, b) => a.name.compareTo(b.name));
  });

  @override
  Future<void> delete(String name) {
    final file = _file(name);

    return _guard('deleting $name', () async {
      if (await file.exists()) await file.delete();
    });
  }

  File _file(String name) =>
      File('${directory.path}/${NoteBackupDriver.validateName(name)}');

  static Future<T> _guard<T>(String step, Future<T> Function() action) async {
    try {
      return await action();
    } on FileSystemException catch (error) {
      throw NoteBackupException('$step failed', cause: error);
    }
  }
}
