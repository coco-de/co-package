import 'dart:typed_data';

import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/backup/note_backup_driver.dart';
import 'package:open_note/src/note/io/backup/note_backup_entry.dart';

/// A [NoteBackupDriver] kept in memory, for tests and the example app.
class MemoryNoteBackupDriver implements NoteBackupDriver {
  /// A driver stamping backups with [clock].
  MemoryNoteBackupDriver({NoteClock clock = systemNoteClock}) : _clock = clock;

  final NoteClock _clock;
  final Map<String, ({Uint8List bytes, DateTime modified})> _files = {};

  @override
  Future<void> put(String name, Uint8List bytes) async {
    _files[NoteBackupDriver.validateName(name)] = (
      bytes: Uint8List.fromList(bytes),
      modified: _clock(),
    );
  }

  @override
  Future<Uint8List?> get(String name) async {
    final file = _files[NoteBackupDriver.validateName(name)];

    return file == null ? null : Uint8List.fromList(file.bytes);
  }

  /// Every backup, sorted by name.
  @override
  Future<List<NoteBackupEntry>> list() async => [
    for (final name in _files.keys.toList()..sort())
      NoteBackupEntry(
        name: name,
        size: _files[name]!.bytes.length,
        modified: _files[name]!.modified,
      ),
  ];

  @override
  Future<void> delete(String name) async {
    _files.remove(NoteBackupDriver.validateName(name));
  }
}
