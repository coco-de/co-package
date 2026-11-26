import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/note_library.dart';

/// Runs `task` once after `delay` and returns a function that cancels it if it
/// has not run yet. The default uses a [Timer]; tests inject their own.
typedef NoteLibraryScheduler =
    VoidCallback Function(Duration delay, VoidCallback task);

/// Loads and saves a [NoteLibrary] in a [NoteStore] under [key].
///
/// [bind] saves automatically: a change starts a [debounce] period (each new
/// change restarts it) after which the library is written, unless nothing that
/// is persisted differs from what was last written. Writes happen one at a
/// time in the order they were requested. A failed automatic save is reported
/// to [onError] (or [FlutterError.reportError]) and retried at the next
/// change.
///
/// Stored text that is not a JSON object loads as an empty library, and its
/// exact bytes are first copied to [corruptKey] (replacing an earlier copy).
/// The same copy is made when single entries cannot be read; the others load.
/// If the store itself fails to read or to write that copy, [load] throws, so
/// that a later save cannot destroy data that was never read.
class NoteLibraryRepository {
  /// Creates a repository over [store].
  NoteLibraryRepository(
    this.store, {
    this.debounce = const Duration(milliseconds: 500),
    NoteLibraryScheduler? scheduler,
    this.onError,
  }) : _schedule = scheduler ?? _timerScheduler;

  /// The key the library is stored under.
  static const String key = 'library.json';

  /// Where the bytes of an unreadable library are kept.
  static const String corruptKey = 'library.corrupt.json';

  /// Where the library is stored.
  final NoteStore store;

  /// How long [bind] waits after the last change before saving.
  final Duration debounce;

  /// Called when an automatic save fails.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final NoteLibraryScheduler _schedule;
  NoteLibrary? _loaded;
  NoteLibrary? _bound;
  VoidCallback? _cancelScheduled;
  Future<void> _writes = Future<void>.value();

  /// The text last handed to the store, to skip writes that change nothing.
  String? _lastQueued;
  bool _disposed = false;

  /// The library given to [bind], while it is bound.
  NoteLibrary? get boundLibrary => _bound;

  /// Whether a change is waiting for the debounce period to end.
  bool get hasPendingSave => _cancelScheduled != null;

  /// Reads the stored library; a missing one gives an empty library. The
  /// arguments are passed to the new [NoteLibrary]. Waits for writes that are
  /// still in progress.
  Future<NoteLibrary> load({
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    ValueChanged<List<String>>? onNotesRemoved,
    ValueChanged<Map<String, String>>? onNotesDuplicated,
  }) async {
    await _writes;
    final bytes = await store.readBytes(key);
    final json = bytes == null
        ? null
        : NoteJson.decodeMap(NoteStoreKeys.decode(bytes));
    final library = NoteLibrary.fromJson(
      json,
      idFactory: idFactory,
      clock: clock,
      onNotesRemoved: onNotesRemoved,
      onNotesDuplicated: onNotesDuplicated,
    );
    if (bytes != null && (json == null || _lostEntries(json, library))) {
      await store.writeBytes(corruptKey, bytes);
    }
    _loaded = library;
    _lastQueued = _encode(library);

    return library;
  }

  /// Writes [library] now: by default the bound library, or the one last
  /// returned by [load]. Throws a [StateError] when there is none. A pending
  /// automatic save of the same library is replaced by this one.
  Future<void> save([NoteLibrary? library]) {
    final target = library ?? _bound ?? _loaded;
    if (target == null) {
      throw StateError('Nothing to save: call load() or bind() first.');
    }
    if (identical(target, _bound)) _cancelPending();

    return _write(_encode(target));
  }

  /// Saves [library] after its changes (see the class documentation). Only one
  /// library is bound at a time: another one is first [unbind]-ed. Does
  /// nothing after [dispose].
  ///
  /// Once this repository has loaded or saved, a [library] that differs from
  /// that is also saved without waiting for a change, so edits made between
  /// [load] and [bind] are kept. Before that, binding writes nothing, so a new
  /// empty library cannot overwrite the stored one just by being bound.
  void bind(NoteLibrary library) {
    if (_disposed || identical(library, _bound)) return;
    unawaited(unbind().then((_) {}, onError: _report));
    _bound = library..addListener(_onLibraryChanged);
    final known = _lastQueued;
    if (known != null && _encode(library) != known) _onLibraryChanged();
  }

  /// Stops watching the bound library. A pending save is written at once; the
  /// future completes when it, and everything before it, is written.
  Future<void> unbind() {
    final library = _bound;
    if (library == null) return _writes;
    library.removeListener(_onLibraryChanged);
    final done = flush();
    _bound = null;

    return done;
  }

  /// Writes a pending change now and completes when all writes are done. It
  /// fails if the pending change cannot be written.
  Future<void> flush() {
    final library = _bound;
    if (_cancelScheduled == null || library == null) return _writes;
    _cancelPending();
    final text = _encode(library);

    return text == _lastQueued ? _writes : _write(text);
  }

  /// [unbind]s for good.
  Future<void> dispose() {
    final done = unbind();
    _disposed = true;

    return done;
  }

  static VoidCallback _timerScheduler(Duration delay, VoidCallback task) =>
      Timer(delay, task).cancel;

  static String _encode(NoteLibrary library) =>
      NoteJson.encode(library.toJson());

  /// Whether reading [json] dropped entries of the folder or note lists.
  static bool _lostEntries(JsonMap json, NoteLibrary library) {
    bool lost(Object? entries, int kept) =>
        entries != null && (entries is! List || entries.length != kept);

    return lost(json['folders'], library.folders.length) ||
        lost(json['notes'], library.notes.length) ||
        lost(json['trash'], library.trash.length);
  }

  void _onLibraryChanged() {
    _cancelPending();
    _cancelScheduled = _schedule(debounce, _saveScheduled);
  }

  void _cancelPending() {
    _cancelScheduled?.call();
    _cancelScheduled = null;
  }

  void _saveScheduled() {
    _cancelScheduled = null;
    final library = _bound;
    if (library == null) return;
    final text = _encode(library);
    if (text == _lastQueued) return;
    unawaited(_write(text).then((_) {}, onError: _report));
  }

  Future<void> _write(String text) {
    _lastQueued = text;
    final done = _writes.then((_) => store.writeString(key, text));
    _writes = done.then(
      (_) {},
      onError: (Object _) {
        // Forget the text so that the next change writes it again.
        if (_lastQueued == text) _lastQueued = null;
      },
    );

    return done;
  }

  void _report(Object error, StackTrace stackTrace) {
    final handler = onError;
    if (handler != null) {
      handler(error, stackTrace);

      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'open_note',
        context: ErrorDescription('while saving the note library'),
      ),
    );
  }
}
