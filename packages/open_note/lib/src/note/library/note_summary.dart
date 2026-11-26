import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/note_cover.dart';
import 'package:open_note/src/note/library/internal/note_library_dates.dart';

/// What the library knows about one note: enough to list, sort and filter it
/// without opening its pages (those belong to the document layer, keyed by
/// [id]).
///
/// Two summaries are equal when every field matches; timestamps compare by the
/// instant they denote, so a UTC value read back from JSON equals the local
/// value that was written. [tags] must not be modified after construction.
///
/// JSON schema:
/// ```json
/// {
///   "id": "…",
///   "title": "Algebra",
///   "cover": { see NoteCover },
///   "tags": ["math"],
///   "pinned": false,
///   "folderId": "…",
///   "createdAt": "2026-01-01T10:00:00.000Z",
///   "modifiedAt": "2026-01-02T10:00:00.000Z",
///   "pageCount": 1
/// }
/// ```
/// `folderId` is omitted for a note outside every folder.
@immutable
class NoteSummary {
  /// Creates a summary. [pageCount] must not be negative.
  const NoteSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.modifiedAt,
    this.cover = NoteCover.standard,
    this.tags = const [],
    this.pinned = false,
    this.folderId,
    this.pageCount = 1,
  }) : assert(pageCount >= 0, 'pageCount must not be negative');

  /// The longest tag, in characters (code points).
  static const int maxTagLength = 40;

  /// The identifier of the note, also used by the document layer.
  final String id;

  /// The name shown in the library; may be empty.
  final String title;

  /// The notebook cover.
  final NoteCover cover;

  /// The tags, normalised with [normalizeTag], without case-insensitive
  /// duplicates.
  final List<String> tags;

  /// Pinned notes are listed first.
  final bool pinned;

  /// The folder the note is in, or `null` when it is in none.
  final String? folderId;

  /// When the note was created.
  final DateTime createdAt;

  /// When the note was last changed (content, title or cover). Organising it
  /// (moving, pinning, tagging) does not change this.
  final DateTime modifiedAt;

  /// How many pages the note has.
  final int pageCount;

  /// Trims [tag], collapses runs of white space and cuts it to [maxTagLength]
  /// characters. A blank tag becomes the empty string.
  static String normalizeTag(String tag) {
    final collapsed = tag.trim().replaceAll(RegExp(r'\s+'), ' ');
    final runes = collapsed.runes;
    if (runes.length <= maxTagLength) return collapsed;

    return String.fromCharCodes(runes.take(maxTagLength)).trimRight();
  }

  /// Normalises every tag, drops blank ones and removes case-insensitive
  /// duplicates (the first spelling wins).
  static List<String> normalizeTags(Iterable<String> tags) {
    final seen = <String>{};

    return List.unmodifiable([
      for (final tag in tags.map(normalizeTag))
        if (tag.isNotEmpty && seen.add(tag.toLowerCase())) tag,
    ]);
  }

  /// Decodes the JSON form; `null` when [value] is not an object with a
  /// non-empty `id`. Other fields fall back: a missing `modifiedAt` equals
  /// `createdAt`, a missing timestamp is the Unix epoch, a negative
  /// `pageCount` is 0 and a missing one is 1.
  static NoteSummary? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    if (id.isEmpty) return null;
    final createdAt =
        NoteLibraryDates.tryFromJson(json['createdAt']) ??
        NoteLibraryDates.epoch;
    final folderId = NoteJson.string(json, 'folderId');
    final pageCount = NoteJson.integer(json, 'pageCount', 1);

    return NoteSummary(
      id: id,
      title: NoteJson.string(json, 'title'),
      cover: NoteCover.fromJson(json['cover']),
      tags: normalizeTags(NoteJson.stringList(json, 'tags')),
      pinned: NoteJson.boolean(json, 'pinned'),
      folderId: folderId.isEmpty ? null : folderId,
      createdAt: createdAt,
      modifiedAt: NoteLibraryDates.tryFromJson(json['modifiedAt']) ?? createdAt,
      pageCount: pageCount < 0 ? 0 : pageCount,
    );
  }

  /// A copy with some fields replaced. Pass `folderId: () => null` to take the
  /// note out of its folder.
  NoteSummary copyWith({
    String? id,
    String? title,
    NoteCover? cover,
    List<String>? tags,
    bool? pinned,
    ValueGetter<String?>? folderId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? pageCount,
  }) => NoteSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    cover: cover ?? this.cover,
    tags: tags == null ? this.tags : List.unmodifiable(tags),
    pinned: pinned ?? this.pinned,
    folderId: folderId == null ? this.folderId : folderId(),
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    pageCount: pageCount ?? this.pageCount,
  );

  /// The persisted form (see the class documentation).
  JsonMap toJson() => {
    'id': id,
    'title': title,
    'cover': cover.toJson(),
    'tags': tags,
    'pinned': pinned,
    'folderId': ?folderId,
    'createdAt': NoteLibraryDates.toJson(createdAt),
    'modifiedAt': NoteLibraryDates.toJson(modifiedAt),
    'pageCount': pageCount,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteSummary &&
      other.id == id &&
      other.title == title &&
      other.cover == cover &&
      listEquals(other.tags, tags) &&
      other.pinned == pinned &&
      other.folderId == folderId &&
      other.createdAt.isAtSameMomentAs(createdAt) &&
      other.modifiedAt.isAtSameMomentAs(modifiedAt) &&
      other.pageCount == pageCount;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    cover,
    Object.hashAll(tags),
    pinned,
    folderId,
    createdAt.microsecondsSinceEpoch,
    modifiedAt.microsecondsSinceEpoch,
    pageCount,
  );

  @override
  String toString() => 'NoteSummary($id, "$title")';
}
