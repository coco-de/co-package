import 'dart:typed_data';

import 'package:open_note/src/note/core/note_store.dart';

/// A [NoteStore] kept in memory — for tests, previews and ephemeral notes.
class MemoryNoteStore implements NoteStore {
  final Map<String, Uint8List> _entries = {};

  /// Number of stored keys (test convenience).
  int get length => _entries.length;

  @override
  Future<bool> exists(String key) async =>
      _entries.containsKey(NoteStoreKeys.validateKey(key));

  @override
  Future<Uint8List?> readBytes(String key) async {
    final bytes = _entries[NoteStoreKeys.validateKey(key)];

    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<String?> readString(String key) async {
    final bytes = _entries[NoteStoreKeys.validateKey(key)];

    return bytes == null ? null : NoteStoreKeys.decode(bytes);
  }

  @override
  Future<void> writeBytes(String key, Uint8List bytes) async {
    _entries[NoteStoreKeys.validateKey(key)] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _entries[NoteStoreKeys.validateKey(key)] = NoteStoreKeys.encode(value);
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(NoteStoreKeys.validateKey(key));
  }

  @override
  Future<void> deletePrefix(String prefix) async {
    NoteStoreKeys.validatePrefix(prefix);
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<List<String>> list(String prefix) async {
    NoteStoreKeys.validatePrefix(prefix);

    return _entries.keys.where((key) => key.startsWith(prefix)).toList()
      ..sort();
  }
}
