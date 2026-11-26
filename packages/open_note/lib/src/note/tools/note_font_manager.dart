import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_font_exception.dart';
import 'package:open_note/src/note/tools/note_font_format.dart';

/// Makes the font in [bytes] usable under [family] in text styles.
typedef NoteFontRegistrar =
    Future<void> Function(String family, Uint8List bytes);

/// The user's own fonts: loads them into Flutter and, given a [store], keeps
/// the files so that [restore] loads them again at the next start.
///
/// Family names are compared ignoring case, so two families can never share a
/// file on a case insensitive file system. A loaded font cannot be unloaded.
///
/// Persisted as the font file under `fonts/<family>.<ttf|otf>` plus the index
/// [indexKey]: `{"v": 1, "fonts": [{"family": String, "ext": "ttf" | "otf"}]}`.
/// The index is merged with what is already stored, so registering before
/// [restore] does not lose older fonts.
class NoteFontManager extends ChangeNotifier {
  /// [NoteStore] key of the font index.
  static const String indexKey = 'fonts/index.json';

  /// Longest accepted family name.
  static const int maxFamilyLength = 80;

  static final RegExp _forbiddenCharacters = RegExp(
    r'[\x00-\x1f\x7f/\\:*?"<>|]',
  );

  /// Where newly registered fonts are written, or `null` to keep them in
  /// memory only.
  final NoteStore? store;

  final NoteFontRegistrar _registrar;

  final Map<String, String> _families = {};
  final Set<String> _loading = {};
  Future<void> _writes = Future<void>.value();
  bool _disposed = false;

  /// Creates a manager. Fonts are kept only when [store] is given.
  /// [registrar] loads the bytes; it defaults to [registerWithFontLoader] and
  /// is replaceable in tests.
  NoteFontManager({this.store, NoteFontRegistrar? registrar})
    : _registrar = registrar ?? registerWithFontLoader;

  /// The families loaded so far, in the order they were loaded.
  List<String> get families => List<String>.unmodifiable(_families.values);

  /// The default registrar: loads [bytes] with a Flutter `FontLoader`.
  static Future<void> registerWithFontLoader(
    String family,
    Uint8List bytes,
  ) async {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  /// Whether [family] can be a family name: after trimming it is 1 to
  /// [maxFamilyLength] characters long, is not `.` or `..` and has none of
  /// `/ \ : * ? " < > |` or control characters (it is also a file name).
  static bool isValidFamilyName(String family) {
    final name = family.trim();

    return name.isNotEmpty &&
        name.length <= maxFamilyLength &&
        name != '.' &&
        name != '..' &&
        !_forbiddenCharacters.hasMatch(name);
  }

  /// Whether a family with this name (ignoring case) is loaded.
  bool isRegistered(String family) => _families.containsKey(_normalize(family));

  /// Loads [bytes] as the family [family] (trimmed) and persists them to
  /// [store].
  ///
  /// Returns `false` without doing anything when that family is loaded or
  /// being loaded, or after [dispose]. Throws [NoteFontException] for an
  /// invalid name or bytes without a TTF/OTF header. Errors of the registrar
  /// or the store are passed on and the family is not listed.
  Future<bool> registerFont(String family, Uint8List bytes) async {
    if (_disposed) return false;
    final name = family.trim();
    if (!isValidFamilyName(name)) {
      throw NoteFontException('invalid font family name: "$family"');
    }
    final format = NoteFontFormat.detect(bytes);
    if (format == null) {
      throw const NoteFontException('not a TTF or OTF font');
    }
    final copy = Uint8List.fromList(bytes);
    final added = await _install(
      name,
      copy,
      () => _persist(_FontEntry(name, format), copy),
    );
    if (added) _notify();

    return added;
  }

  /// Loads every font recorded in [source]. Entries whose file is missing,
  /// damaged or fails to load are skipped, as are families already loaded; a
  /// missing or corrupt index loads nothing. Returns how many were loaded.
  Future<int> restore(NoteStore source) async {
    if (_disposed) return 0;
    var restored = 0;
    for (final entry in await _readIndex(source)) {
      if (_disposed) break;
      if (await _restoreEntry(source, entry)) restored++;
    }
    if (restored > 0) _notify();

    return restored;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static String _normalize(String family) => family.trim().toLowerCase();

  static Future<List<_FontEntry>> _readIndex(NoteStore source) async {
    final json = NoteJson.decodeMap(await source.readString(indexKey));
    if (json == null) return [];

    return [
      for (final map in NoteJson.mapList(json, 'fonts'))
        if (_FontEntry.tryParse(map) case final _FontEntry entry) entry,
    ];
  }

  Future<bool> _install(
    String family,
    Uint8List bytes,
    Future<void> Function()? afterLoading,
  ) async {
    final key = _normalize(family);
    if (_families.containsKey(key) || !_loading.add(key)) return false;
    try {
      await _registrar(family, bytes);
      await afterLoading?.call();
      _families[key] = family;
    } finally {
      _loading.remove(key);
    }

    return true;
  }

  Future<bool> _restoreEntry(NoteStore source, _FontEntry entry) async {
    try {
      final bytes = await source.readBytes(entry.key);
      if (bytes == null || NoteFontFormat.detect(bytes) == null) return false;

      return await _install(entry.family, bytes, null);
    } on Exception {
      return false;
    }
  }

  /// Writes one at a time: the index is read, changed and written back.
  Future<void> _persist(_FontEntry entry, Uint8List bytes) {
    final target = store;
    if (target == null) return Future<void>.value();
    final write = _writes.then((_) => _write(target, entry, bytes));
    // A failed write must not block later ones; the caller still gets it.
    _writes = write.catchError((Object _) => null);

    return write;
  }

  Future<void> _write(
    NoteStore target,
    _FontEntry entry,
    Uint8List bytes,
  ) async {
    await target.writeBytes(entry.key, bytes);
    final entries = await _readIndex(target);
    final family = _normalize(entry.family);
    final replaced = entries
        .where((other) => _normalize(other.family) == family)
        .toList();
    for (final old in replaced) {
      entries.remove(old);
      if (old.key != entry.key) await target.delete(old.key);
    }
    entries.add(entry);
    await target.writeString(
      indexKey,
      NoteJson.encode({
        'v': 1,
        'fonts': [for (final item in entries) item.toJson()],
      }),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}

class _FontEntry {
  final String family;

  final NoteFontFormat format;

  const _FontEntry(this.family, this.format);

  String get key => 'fonts/$family.${format.fileExtension}';

  static _FontEntry? tryParse(JsonMap json) {
    final family = NoteJson.string(json, 'family').trim();
    final format = NoteFontFormat.values
        .asNameMap()[NoteJson.string(json, 'ext')];

    return format != null && NoteFontManager.isValidFamilyName(family)
        ? _FontEntry(family, format)
        : null;
  }

  JsonMap toJson() => {'family': family, 'ext': format.fileExtension};
}
