import 'dart:io';
import 'dart:typed_data';

import 'package:open_note/src/note/core/note_store.dart';

/// A [NoteStore] backed by a directory on disk (native platforms only — web
/// has no file I/O; use a host-provided store there).
///
/// Writes are atomic on POSIX: bytes go to a sibling `.tmp` file that is then
/// renamed over the target, so a crash never leaves a half-written note.
class FileNoteStore implements NoteStore {
  FileNoteStore(this.root);

  /// The directory every key lives under.
  final Directory root;

  File _file(String key) =>
      File('${root.path}/${NoteStoreKeys.validateKey(key)}');

  @override
  Future<bool> exists(String key) => _file(key).exists();

  @override
  Future<Uint8List?> readBytes(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;

    return file.readAsBytes();
  }

  @override
  Future<String?> readString(String key) async {
    final bytes = await readBytes(key);

    return bytes == null ? null : NoteStoreKeys.decode(bytes);
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    final target = _file(key);
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);
  }

  @override
  Future<void> writeString(String key, String value) =>
      writeBytes(key, NoteStoreKeys.encode(value));

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deletePrefix(String prefix) async {
    NoteStoreKeys.validatePrefix(prefix);
    for (final key in await list(prefix)) {
      await delete(key);
    }
    // Remove directories emptied by the deletion.
    if (prefix.endsWith('/')) {
      final directory = Directory(
        '${root.path}/${prefix.substring(0, prefix.length - 1)}',
      );
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  @override
  Future<List<String>> list(String prefix) async {
    NoteStoreKeys.validatePrefix(prefix);
    if (!await root.exists()) return const [];
    final rootPath = root.path.endsWith('/') ? root.path : '${root.path}/';
    final keys = <String>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.tmp')) continue;
      final key = entity.path.substring(rootPath.length);
      if (key.startsWith(prefix)) keys.add(key);
    }

    return keys..sort();
  }
}
