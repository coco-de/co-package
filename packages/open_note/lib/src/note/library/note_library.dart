import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/note_cover.dart';
import 'package:open_note/src/note/library/note_folder.dart';
import 'package:open_note/src/note/library/note_folder_icons.dart';
import 'package:open_note/src/note/library/note_folder_tree.dart';
import 'package:open_note/src/note/library/note_library_query.dart';
import 'package:open_note/src/note/library/note_library_view_state.dart';
import 'package:open_note/src/note/library/note_summary.dart';

part 'note_library_base.dart';
part 'note_library_folders.dart';
part 'note_library_notes.dart';
part 'note_library_selection.dart';

/// The user's notes and folders, the trash and how the library is viewed.
///
/// The library only holds [NoteSummary] records. The pages of a note are the
/// document layer's business: it creates data after [createNote], copies it
/// through [onNotesDuplicated] and deletes it through [onNotesRemoved], which
/// fires only when notes leave the library for good (not when they go to the
/// trash).
///
/// Listeners are notified after every real change, including view state and
/// selection changes. After [dispose], methods that would change something
/// assert.
///
/// JSON schema ([toJson]):
/// ```json
/// {
///   "v": 1,
///   "folders": [NoteFolder],
///   "notes": [NoteSummary],
///   "trash": [NoteSummary],
///   "view": NoteLibraryViewState
/// }
/// ```
/// The selection and the search query are not persisted.
class NoteLibrary extends _NoteLibraryBase
    with _NoteLibraryFolders, _NoteLibraryNotes, _NoteLibrarySelection {
  /// Creates a library holding [folders], [notes] and [trash].
  ///
  /// The input is repaired the same way a loaded file is: repeated ids are
  /// dropped (a note found in both lists stays in [notes]), parents that do not
  /// exist or form a cycle are removed, and references to unknown folders are
  /// cleared.
  NoteLibrary({
    Iterable<NoteFolder> folders = const [],
    Iterable<NoteSummary> notes = const [],
    Iterable<NoteSummary> trash = const [],
    NoteLibraryViewState viewState = const NoteLibraryViewState(),
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    ValueChanged<List<String>>? onNotesRemoved,
    ValueChanged<Map<String, String>>? onNotesDuplicated,
  }) : super(idFactory, clock) {
    this.onNotesRemoved = onNotesRemoved;
    this.onNotesDuplicated = onNotesDuplicated;
    _folders.addAll(NoteFolderTree.sanitize(folders));
    final seen = <String>{};
    _notes.addAll(_distinct(notes, seen));
    _trash.addAll(_distinct(trash, seen));
    _viewState = _normalizeViewState(viewState);
  }

  /// Rebuilds a library from [toJson]. It never throws: entries that cannot be
  /// read are skipped and anything that is not an object gives an empty
  /// library.
  factory NoteLibrary.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    ValueChanged<List<String>>? onNotesRemoved,
    ValueChanged<Map<String, String>>? onNotesDuplicated,
  }) {
    final json = NoteJson.asMap(value) ?? <String, Object?>{};

    return NoteLibrary(
      folders: [
        for (final entry in NoteJson.list(json, 'folders'))
          ?NoteFolder.fromJson(entry),
      ],
      notes: [
        for (final entry in NoteJson.list(json, 'notes'))
          ?NoteSummary.fromJson(entry),
      ],
      trash: [
        for (final entry in NoteJson.list(json, 'trash'))
          ?NoteSummary.fromJson(entry),
      ],
      viewState: NoteLibraryViewState.fromJson(json['view']),
      idFactory: idFactory,
      clock: clock,
      onNotesRemoved: onNotesRemoved,
      onNotesDuplicated: onNotesDuplicated,
    );
  }

  /// The version written as `v` by [toJson].
  static const int schemaVersion = 1;

  /// The layout, zoom, sort order and filters.
  NoteLibraryViewState get viewState => _viewState;

  /// Changes the view. The zoom is clamped and an unknown folder id is
  /// removed. Selected notes that the new filters hide are deselected.
  set viewState(NoteLibraryViewState value) {
    final next = _normalizeViewState(value);
    if (next == _viewState) return;
    _viewState = next;
    _commit();
  }

  /// Shows the notes of [folderId], or every note when it is `null`.
  void showFolder(String? folderId) =>
      viewState = _viewState.copyWith(folderId: () => folderId);

  /// Multiplies the drawer zoom by [scaleDelta] (the ratio between two steps of
  /// a pinch, 1 meaning no change) and clamps the result to
  /// [NoteLibraryViewState.minDrawerZoom]..
  /// [NoteLibraryViewState.maxDrawerZoom]. Non-positive or non-finite values
  /// are ignored.
  void zoomDrawer(double scaleDelta) {
    if (!scaleDelta.isFinite || scaleDelta <= 0) return;
    final zoom = (_viewState.drawerZoom * scaleDelta).clamp(
      NoteLibraryViewState.minDrawerZoom,
      NoteLibraryViewState.maxDrawerZoom,
    );
    viewState = _viewState.copyWith(drawerZoom: zoom.toDouble());
  }

  /// The notes the current [viewState] shows, in display order: pinned notes
  /// first (see [NoteLibraryQuery.apply]). The trash is never included.
  List<NoteSummary> visibleNotes() =>
      NoteLibraryQuery.apply(_notes, _viewState);

  /// The persisted form (see the class documentation).
  JsonMap toJson() => {
    'v': schemaVersion,
    'folders': [for (final folder in _folders) folder.toJson()],
    'notes': [for (final note in _notes) note.toJson()],
    'trash': [for (final note in _trash) note.toJson()],
    'view': _viewState.copyWith(query: () => null).toJson(),
  };

  List<NoteSummary> _distinct(Iterable<NoteSummary> notes, Set<String> seen) =>
      [
        for (final note in notes)
          if (note.id.isNotEmpty && seen.add(note.id)) _withKnownFolder(note),
      ];

  NoteLibraryViewState _normalizeViewState(NoteLibraryViewState state) {
    final folderId = state.folderId;

    return state.copyWith(
      drawerZoom: state.drawerZoom,
      folderId: () => _hasFolder(folderId) ? folderId : null,
    );
  }
}
