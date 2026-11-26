import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_exception.dart';
import 'package:open_note/src/note/io/bundle/note_bundle_unpack_result.dart';

/// Packs the files of a [NoteStore] into one self-describing JSON document and
/// back — the format used to share a notebook and for backups.
///
/// JSON schema (UTF-8):
///
/// ```json
/// {
///   "v": 1,
///   "files": {
///     "<key relative to the packed prefix>": {
///       "enc": "utf8" | "b64",
///       "data": "<text, or standard base64>"
///     }
///   }
/// }
/// ```
///
/// A file is stored as `utf8` when its bytes are well-formed UTF-8 without
/// control characters other than tab, line feed and carriage return (so it
/// round-trips exactly), otherwise as `b64`.
///
/// A non-empty `prefix` names a directory (a trailing `/` is added when
/// missing). Keys inside the bundle are relative to it, so packing
/// `notes/a/` and unpacking into `notes/b/` copies a note.
abstract final class NoteBundleCodec {
  /// The format version written by [pack] and accepted by [unpack].
  static const int version = 1;

  /// Bundles every file under [prefix] (default: the whole store).
  ///
  /// Throws [NoteStoreException] for an unsafe [prefix].
  static Future<Uint8List> pack(NoteStore store, {String prefix = ''}) async {
    final root = _directory(prefix);
    final files = <String, Object?>{};
    for (final key in await store.list(root)) {
      final bytes = await store.readBytes(key);
      if (bytes != null) files[key.substring(root.length)] = _encode(bytes);
    }

    return NoteStoreKeys.encode(jsonEncode({'v': version, 'files': files}));
  }

  /// Writes the files of a bundle into [store] under [prefix].
  ///
  /// The whole bundle is validated first; nothing is written when any key is
  /// unsafe (absolute, `..`, backslash, control character…), two keys cannot
  /// coexist as files, or an entry is malformed. Existing keys are only
  /// replaced when [overwrite] is true, otherwise they are reported as skipped.
  ///
  /// Throws [NoteBundleException] for a bad bundle and [NoteStoreException] for
  /// an unsafe [prefix].
  static Future<NoteBundleUnpackResult> unpack(
    Uint8List bytes,
    NoteStore store, {
    String prefix = '',
    bool overwrite = false,
  }) async {
    final files = _decode(bytes, _directory(prefix));
    final written = <String>[];
    final skipped = <String>[];
    for (final key in files.keys.toList()..sort()) {
      if (!overwrite && await store.exists(key)) {
        skipped.add(key);
        continue;
      }
      await store.writeBytes(key, files[key]!);
      written.add(key);
    }

    return NoteBundleUnpackResult(written: written, skipped: skipped);
  }

  static String _directory(String prefix) {
    NoteStoreKeys.validatePrefix(prefix);

    return prefix.isEmpty || prefix.endsWith('/') ? prefix : '$prefix/';
  }

  static JsonMap _encode(Uint8List bytes) {
    final text = _asText(bytes);

    return text == null
        ? {'enc': 'b64', 'data': base64Encode(bytes)}
        : {'enc': 'utf8', 'data': text};
  }

  static String? _asText(Uint8List bytes) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      return null;
    }
    final hasControl = text.codeUnits.any(
      (unit) => unit < 0x20 && unit != 0x09 && unit != 0x0A && unit != 0x0D,
    );
    // The decoder drops a byte order mark, which would not round-trip.
    if (hasControl || !listEquals(utf8.encode(text), bytes)) return null;

    return text;
  }

  /// Parses and validates the document into `full store key → bytes`.
  static Map<String, Uint8List> _decode(Uint8List bytes, String root) {
    final document = _parseDocument(bytes);
    final entries = NoteJson.asMap(document['files']);
    if (entries == null) {
      throw const NoteBundleException('"files" is missing or not an object');
    }
    final files = <String, Uint8List>{};
    for (final entry in entries.entries) {
      files[_fullKey(root, entry.key)] = _decodeEntry(entry.key, entry.value);
    }
    _rejectNestedKeys(files.keys);

    return files;
  }

  static JsonMap _parseDocument(Uint8List bytes) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw NoteBundleException('the bundle is not UTF-8 JSON', cause: error);
    }
    final document = NoteJson.asMap(decoded);
    if (document == null) {
      throw const NoteBundleException('the bundle is not a JSON object');
    }
    if (document['v'] != version) {
      throw NoteBundleException('unsupported bundle version: ${document['v']}');
    }

    return document;
  }

  static String _fullKey(String root, String relative) {
    final hasControl = relative.codeUnits.any(
      (unit) => unit < 0x20 || unit == 0x7F,
    );
    if (hasControl) {
      throw NoteBundleException(
        'unsafe key in bundle: ${jsonEncode(relative)}',
      );
    }
    try {
      NoteStoreKeys.validateKey(relative);

      return NoteStoreKeys.validateKey('$root$relative');
    } on NoteStoreException catch (error) {
      throw NoteBundleException(
        'unsafe key in bundle: $relative',
        cause: error,
      );
    }
  }

  static Uint8List _decodeEntry(String key, Object? value) {
    final entry = NoteJson.asMap(value);
    final data = entry?['data'];
    if (data is! String) {
      throw NoteBundleException('entry "$key" has no string "data"');
    }
    switch (entry!['enc']) {
      case 'utf8':
        return NoteStoreKeys.encode(data);
      case 'b64':
        try {
          return base64Decode(data);
        } on FormatException catch (error) {
          throw NoteBundleException(
            'entry "$key" is not valid base64',
            cause: error,
          );
        }
      default:
        throw NoteBundleException(
          'entry "$key" has an unknown encoding: ${entry['enc']}',
        );
    }
  }

  /// A key may not also be a directory of another key (`a` and `a/b`): a file
  /// store could only write one of them, leaving a half-unpacked bundle.
  static void _rejectNestedKeys(Iterable<String> keys) {
    final all = keys.toSet();
    for (final key in all) {
      var slash = key.indexOf('/');
      while (slash >= 0) {
        final parent = key.substring(0, slash);
        if (all.contains(parent)) {
          throw NoteBundleException(
            'unsafe keys in bundle: "$parent" is both a file and a directory',
          );
        }
        slash = key.indexOf('/', slash + 1);
      }
    }
  }
}
