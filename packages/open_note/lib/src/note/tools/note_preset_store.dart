import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_preset.dart';

/// An ordered, capped list of presets with one optional selection: the shared
/// behaviour of `NoteToolPresetStore` and `NoteTextStylePresetStore`.
///
/// Invariants: ids are non-empty and unique, there are at most [maxPresets]
/// entries, and [activeId] is `null` or the id of an entry. Listeners are told
/// only about real changes of the list or the selection. After [dispose] every
/// change method does nothing and returns `false` (or `null`).
///
/// Persisted under [storageKey] as
/// `{"v": 1, "activeId": String?, "presets": [preset JSON, ...]}`.
abstract class NotePresetStore<T extends NotePreset> extends ChangeNotifier {
  /// Default [maxPresets].
  static const int defaultMaxPresets = 24;

  /// Most entries the store holds.
  final int maxPresets;

  /// Produces the ids of new presets.
  @protected
  final NoteIdFactory idFactory;

  final List<T> _presets = [];

  String? _activeId;
  bool _disposed = false;

  /// Starts with [presets] (duplicate ids, empty ids and everything beyond
  /// [maxPresets] are dropped). [activeId] is ignored when no entry has it.
  /// [idFactory] names the presets created by the subclasses.
  NotePresetStore({
    Iterable<T> presets = const [],
    String? activeId,
    this.maxPresets = defaultMaxPresets,
    NoteIdFactory? idFactory,
  }) : assert(maxPresets > 0, 'maxPresets must be positive'),
       idFactory = idFactory ?? generateNoteId {
    _presets.addAll(_sanitize(presets));
    _activeId = _knownIdOrNull(activeId);
  }

  /// Where [save] writes and [load] reads inside a [NoteStore].
  String get storageKey;

  /// The presets in display order. A snapshot: later changes do not alter it.
  List<T> get presets => List<T>.unmodifiable(_presets);

  /// Number of presets.
  int get length => _presets.length;

  /// Whether no more presets can be added.
  bool get isFull => _presets.length >= maxPresets;

  /// Id of the selected preset, or `null`.
  String? get activeId => _activeId;

  /// The selected preset, or `null`.
  T? get active => find(_activeId);

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  /// The preset with [id], or `null`.
  T? find(String? id) {
    final index = id == null ? -1 : indexOf(id);

    return index < 0 ? null : _presets[index];
  }

  /// Position of the preset with [id], or -1.
  int indexOf(String id) => _presets.indexWhere((preset) => preset.id == id);

  /// Appends [preset] and, when [select] is true, selects it.
  ///
  /// Returns `false` without changing anything when the store is full, the id
  /// is empty or another preset already has it.
  bool add(T preset, {bool select = true}) {
    if (_disposed || isFull) return false;
    if (preset.id.isEmpty || indexOf(preset.id) >= 0) return false;
    _presets.add(preset);
    if (select) _activeId = preset.id;
    notifyListeners();

    return true;
  }

  /// Replaces the preset with the same id as [preset], keeping its position and
  /// the selection. Returns `false` when the id is unknown or nothing differs.
  bool update(T preset) {
    final index = indexOf(preset.id);
    if (_disposed || index < 0 || _presets[index] == preset) return false;
    _presets[index] = preset;
    notifyListeners();

    return true;
  }

  /// Removes the preset with [id]. Removing the selected one clears the
  /// selection (nothing else is picked for the user).
  bool remove(String id) {
    final index = indexOf(id);
    if (_disposed || index < 0) return false;
    _presets.removeAt(index);
    if (_activeId == id) _activeId = null;
    notifyListeners();

    return true;
  }

  /// Moves the preset at [oldIndex] so that it ends up at [newIndex].
  ///
  /// [newIndex] is the position after the move and is clamped to the list; this
  /// is not the `ReorderableListView` convention (there a downward move reports
  /// one more than the final position). Returns `false` when [oldIndex] is out
  /// of range or nothing moves.
  bool move(int oldIndex, int newIndex) {
    if (_disposed || oldIndex < 0 || oldIndex >= _presets.length) {
      return false;
    }
    final target = newIndex.clamp(0, _presets.length - 1);
    if (target == oldIndex) return false;
    _presets.insert(target, _presets.removeAt(oldIndex));
    notifyListeners();

    return true;
  }

  /// Selects the preset with [id], or nothing when [id] is `null`. Returns
  /// `false` for an unknown id and when it is already the selection.
  bool select(String? id) {
    if (_disposed || id == _activeId) return false;
    if (id != null && indexOf(id) < 0) return false;
    _activeId = id;
    notifyListeners();

    return true;
  }

  /// Selects the preset after the selected one, wrapping around (the first
  /// when nothing is selected), and returns the selection; `null` when empty.
  T? selectNext() {
    if (_disposed || _presets.isEmpty) return null;
    final current = _activeId == null ? -1 : indexOf(_activeId!);
    select(_presets[(current + 1) % _presets.length].id);

    return active;
  }

  /// The persisted form described on the class.
  JsonMap toJson() => {
    'v': 1,
    'activeId': _activeId,
    'presets': [for (final preset in _presets) preset.toJson()],
  };

  /// Writes [toJson] to [store] under [storageKey].
  Future<void> save(NoteStore store) async {
    if (_disposed) return;
    await store.writeString(storageKey, NoteJson.encode(toJson()));
  }

  /// Replaces the contents with what [store] holds under [storageKey].
  ///
  /// Returns `false` and keeps the current presets when the key is missing or
  /// is not a JSON object with a `presets` list (so a first launch keeps the
  /// defaults). Entries that are not objects or lack an id are skipped; an
  /// empty list is valid. Errors of [store] itself are not caught.
  Future<bool> load(NoteStore store) async {
    final source = await store.readString(storageKey);
    final json = NoteJson.decodeMap(source);
    if (_disposed || json == null || json['presets'] is! List) return false;
    final loaded = _sanitize([
      for (final entry in NoteJson.mapList(json, 'presets'))
        decodePreset(entry),
    ]);
    _replace(loaded, NoteJson.stringOrNull(json, 'activeId'));

    return true;
  }

  /// Reads one preset. A result with an empty id is discarded.
  @protected
  T decodePreset(JsonMap json);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<T> _sanitize(Iterable<T> source) {
    final ids = <String>{};

    return [
      for (final preset in source)
        if (preset.id.isNotEmpty && ids.add(preset.id)) preset,
    ].take(maxPresets).toList();
  }

  String? _knownIdOrNull(String? id) =>
      id != null && indexOf(id) >= 0 ? id : null;

  void _replace(List<T> next, String? nextActiveId) {
    final listChanged = !listEquals(_presets, next);
    if (listChanged) {
      _presets
        ..clear()
        ..addAll(next);
    }
    final activeId = _knownIdOrNull(nextActiveId);
    if (!listChanged && activeId == _activeId) return;
    _activeId = activeId;
    notifyListeners();
  }
}
