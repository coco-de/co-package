import 'package:flutter/foundation.dart';

/// The texts of the library widgets, in English by default. Apps pass a
/// translated instance as `strings:`.
@immutable
class NoteLibraryStrings {
  /// Creates the strings.
  const NoteLibraryStrings({
    this.untitled = 'Untitled',
    this.untitledFolder = 'Untitled folder',
    this.allNotes = 'All notes',
    this.pinnedSection = 'Pinned',
    this.notesSection = 'Notes',
    this.emptyLibrary = 'No notes yet',
    this.noMatches = 'No matching notes',
    this.pinned = 'Pinned',
    this.expandFolder = 'Expand folder',
    this.collapseFolder = 'Collapse folder',
    this.pageCount = _defaultPageCount,
    this.noteCount = _defaultNoteCount,
    this.formatDate = _defaultDate,
  });

  /// The name shown for a note without a title.
  final String untitled;

  /// The name shown for a folder without a name.
  final String untitledFolder;

  /// The sidebar row that shows every note.
  final String allNotes;

  /// The heading of the pinned notes.
  final String pinnedSection;

  /// The heading of the other notes, shown when some are pinned.
  final String notesSection;

  /// Shown when there is no note at all.
  final String emptyLibrary;

  /// Shown when the filters hide every note.
  final String noMatches;

  /// The accessibility word for a pinned note.
  final String pinned;

  /// The accessibility label of a closed folder's toggle.
  final String expandFolder;

  /// The accessibility label of an open folder's toggle.
  final String collapseFolder;

  /// Names a number of pages, like "3 pages".
  final String Function(int count) pageCount;

  /// Names a number of notes, like "3 notes".
  final String Function(int count) noteCount;

  /// Writes a date; the default is `2026-01-31` in local time.
  final String Function(DateTime date) formatDate;

  static String _defaultPageCount(int count) =>
      count == 1 ? '1 page' : '$count pages';

  static String _defaultNoteCount(int count) =>
      count == 1 ? '1 note' : '$count notes';

  static String _defaultDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
