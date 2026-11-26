import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_tab.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';

/// The notes open in tabs, in order, and which one is active.
///
/// Invariants: one tab per note id; with at least one tab exactly one of them
/// is active.
///
/// JSON: `{tabs: [{noteId, title}], active?: noteId}`.
class NoteTabsController extends NoteViewNotifier {
  /// Creates the strip; duplicate and empty note ids are skipped and an
  /// unknown [activeId] means the first tab.
  NoteTabsController({Iterable<NoteTab> tabs = const [], String? activeId}) {
    final seen = <String>{};
    for (final tab in tabs) {
      if (tab.noteId.isNotEmpty && seen.add(tab.noteId)) _tabs.add(tab);
    }
    _activeId = activeId != null && seen.contains(activeId)
        ? activeId
        : _tabs.firstOrNull?.noteId;
  }

  /// Reads [toJson]; unreadable tabs are skipped.
  factory NoteTabsController.fromJson(Object? value) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteTabsController(
      tabs: [
        for (final entry in NoteJson.list(map, 'tabs'))
          if (NoteTab.fromJson(entry) case final NoteTab tab) tab,
      ],
      activeId: NoteJson.stringOrNull(map, 'active'),
    );
  }

  final List<NoteTab> _tabs = [];
  String? _activeId;

  /// The tabs, left to right.
  List<NoteTab> get tabs => List.unmodifiable(_tabs);

  /// Note id of the active tab, `null` without tabs.
  String? get activeId => _activeId;

  /// The active tab, `null` without tabs.
  NoteTab? get active {
    final index = indexOf(_activeId ?? '');

    return index < 0 ? null : _tabs[index];
  }

  /// Position of the tab of [noteId], or -1.
  int indexOf(String noteId) => _tabs.indexWhere((tab) => tab.noteId == noteId);

  /// Whether [noteId] has a tab.
  bool contains(String noteId) => indexOf(noteId) >= 0;

  /// Focuses the tab of [noteId], updating its [title]; a note that is not open
  /// gets a new tab at the end. An empty id is ignored.
  void open(String noteId, String title) {
    if (isDisposed || noteId.isEmpty) return;
    final index = indexOf(noteId);
    final tab = NoteTab(noteId: noteId, title: title);
    if (index < 0) {
      _tabs.add(tab);
    } else if (_tabs[index] == tab && _activeId == noteId) {
      return;
    } else {
      _tabs[index] = tab;
    }
    _activeId = noteId;
    notifyChanged();
  }

  /// Focuses an open note; unknown ids are ignored.
  void activate(String noteId) {
    if (isDisposed || noteId == _activeId || !contains(noteId)) return;
    _activeId = noteId;
    notifyChanged();
  }

  /// Renames the tab of [noteId].
  void rename(String noteId, String title) {
    final index = indexOf(noteId);
    if (isDisposed || index < 0 || _tabs[index].title == title) return;
    _tabs[index] = _tabs[index].copyWith(title: title);
    notifyChanged();
  }

  /// Closes the tab of [noteId]; if it was active, the tab to its right (else
  /// to its left) becomes active. Returns whether it was open.
  bool close(String noteId) {
    final index = indexOf(noteId);
    if (isDisposed || index < 0) return false;
    _tabs.removeAt(index);
    if (_activeId == noteId) {
      _activeId = _tabs.isEmpty
          ? null
          : _tabs[index < _tabs.length ? index : _tabs.length - 1].noteId;
    }
    notifyChanged();

    return true;
  }

  /// Closes every tab but that of [noteId], which becomes active. An unknown id
  /// closes nothing.
  void closeOthers(String noteId) {
    final index = indexOf(noteId);
    if (isDisposed || index < 0) return;
    if (_tabs.length == 1 && _activeId == noteId) return;
    final keep = _tabs[index];
    _tabs
      ..clear()
      ..add(keep);
    _activeId = noteId;
    notifyChanged();
  }

  /// Closes all tabs.
  void closeAll() {
    if (isDisposed || _tabs.isEmpty) return;
    _tabs.clear();
    _activeId = null;
    notifyChanged();
  }

  /// Moves the tab at [oldIndex] so that it ends up at [newIndex] (clamped to
  /// the strip). An unknown [oldIndex] is ignored.
  void move(int oldIndex, int newIndex) {
    if (isDisposed || oldIndex < 0 || oldIndex >= _tabs.length) return;
    final target = newIndex.clamp(0, _tabs.length - 1);
    if (target == oldIndex) return;
    _tabs.insert(target, _tabs.removeAt(oldIndex));
    notifyChanged();
  }

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'tabs': [for (final tab in _tabs) tab.toJson()],
    if (_activeId != null) 'active': _activeId,
  };
}
