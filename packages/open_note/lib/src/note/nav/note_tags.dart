import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_json.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text.dart';
import 'package:open_note/src/note/nav/note_nav_notifier.dart';
import 'package:open_note/src/note/nav/note_tag_ref.dart';

/// Tags on notes and pages.
///
/// A tag name is cleaned by [normalize] (trimmed, whitespace collapsed, at most
/// [maxLength] characters). Names are compared case-insensitively and the first
/// spelling used is kept for display. A tag exists only while something carries
/// it.
///
/// JSON: `{"v": 1, "tags": [{"name": String, "refs": [NoteTagRef JSON, …]}]}`.
class NoteTags extends NoteNavNotifier {
  /// Creates an empty set of tags.
  NoteTags();

  /// Reads a [toJson] map; malformed input yields no tags, bad entries are
  /// skipped and tags with the same name are merged.
  factory NoteTags.fromJson(Object? value) {
    final tags = NoteTags();
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    for (final entry in NoteJson.mapList(json, 'tags')) {
      final name = NoteJson.string(entry, 'name');
      for (final raw in NoteJson.list(entry, 'refs')) {
        final ref = NoteTagRef.fromJson(raw);
        if (ref != null) tags._insert(name, ref);
      }
    }

    return tags;
  }

  /// The longest tag name, in user-perceived characters.
  static const int maxLength = 40;

  final Map<String, _NoteTagBucket> _buckets = {};

  /// Whether there is no tag at all.
  bool get isEmpty => _buckets.isEmpty;

  /// Every tag with the number of references carrying it, sorted
  /// case-insensitively, keyed by display spelling.
  Map<String, int> get allTags => Map.unmodifiable({
    for (final key in _buckets.keys.toList()..sort())
      _buckets[key]!.name: _buckets[key]!.refs.length,
  });

  /// [tag] as it is stored: trimmed, whitespace runs collapsed to one space and
  /// cut to [maxLength] characters. `null` when it is blank.
  static String? normalize(String tag) {
    final collapsed = noteNavCollapse(tag);
    if (collapsed.isEmpty) return null;
    final characters = collapsed.characters;
    if (characters.length <= maxLength) return collapsed;

    return characters.take(maxLength).toString().trimRight();
  }

  /// Whether some reference carries [tag].
  bool contains(String tag) => _bucketOf(tag) != null;

  /// Puts [tag] on [ref]. Returns `false` when the tag is blank, the reference
  /// has no note id, it already carries the tag, or the controller is disposed.
  bool add(String tag, NoteTagRef ref) {
    if (isDisposed || !_insert(tag, ref)) return false;
    notifyChanged();

    return true;
  }

  /// Takes [tag] off [ref]. Returns whether it carried it. A tag left on
  /// nothing disappears.
  bool remove(String tag, NoteTagRef ref) {
    final bucket = _bucketOf(tag);
    if (isDisposed || bucket == null || !bucket.refs.remove(ref)) return false;
    if (bucket.refs.isEmpty) _buckets.remove(_keyOf(tag));
    notifyChanged();

    return true;
  }

  /// The tags on [ref] (display spelling), sorted case-insensitively. A note
  /// reference does not include the tags of its pages.
  List<String> tagsOf(NoteTagRef ref) => [
    for (final key in _buckets.keys.toList()..sort())
      if (_buckets[key]!.refs.contains(ref)) _buckets[key]!.name,
  ];

  /// Everything carrying [tag], in the order it was tagged.
  List<NoteTagRef> refsOf(String tag) =>
      List.unmodifiable(_bucketOf(tag)?.refs ?? const <NoteTagRef>{});

  /// Renames [oldTag] to [newTag].
  ///
  /// When another tag already has that name the two are merged and the existing
  /// spelling of the target wins; when only the spelling (case, spacing) differs
  /// the new spelling is taken. Returns whether anything changed (`false` for an
  /// unknown tag or a blank new name).
  bool rename(String oldTag, String newTag) {
    final bucket = _bucketOf(oldTag);
    final name = normalize(newTag);
    if (isDisposed || bucket == null || name == null) return false;
    final oldKey = _keyOf(oldTag);
    final newKey = noteNavFold(name);
    if (newKey == oldKey) {
      if (bucket.name == name) return false;
      bucket.name = name;
    } else {
      _buckets.remove(oldKey);
      final target = _buckets.putIfAbsent(newKey, () => _NoteTagBucket(name));
      target.refs.addAll(bucket.refs);
    }
    notifyChanged();

    return true;
  }

  /// Removes [tag] from everything. Returns whether it existed.
  bool delete(String tag) {
    if (isDisposed || _bucketOf(tag) == null) return false;
    _buckets.remove(_keyOf(tag));
    notifyChanged();

    return true;
  }

  /// Takes every tag off the note [noteId] and all of its pages (call it when a
  /// note is deleted). Returns whether anything changed.
  bool removeNote(String noteId) => _removeWhere((ref) => ref.noteId == noteId);

  /// Takes every tag off the page [pageId] of the note [noteId] (call it when a
  /// page is deleted). Returns whether anything changed.
  bool removePage(String noteId, String pageId) =>
      _removeWhere((ref) => ref.noteId == noteId && ref.pageId == pageId);

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'v': noteNavJsonVersion,
    'tags': [
      for (final bucket in _buckets.values)
        {
          'name': bucket.name,
          'refs': [for (final ref in bucket.refs) ref.toJson()],
        },
    ],
  };

  String _keyOf(String tag) => noteNavFold(normalize(tag) ?? '');

  _NoteTagBucket? _bucketOf(String tag) => _buckets[_keyOf(tag)];

  bool _insert(String tag, NoteTagRef ref) {
    final name = normalize(tag);
    if (name == null || ref.noteId.isEmpty) return false;
    final bucket = _buckets.putIfAbsent(
      noteNavFold(name),
      () => _NoteTagBucket(name),
    );

    return bucket.refs.add(ref);
  }

  bool _removeWhere(bool Function(NoteTagRef ref) test) {
    if (isDisposed) return false;
    var changed = false;
    _buckets.removeWhere((_, bucket) {
      final before = bucket.refs.length;
      bucket.refs.removeWhere(test);
      changed = changed || bucket.refs.length != before;

      return bucket.refs.isEmpty;
    });
    if (changed) notifyChanged();

    return changed;
  }
}

class _NoteTagBucket {
  _NoteTagBucket(this.name);

  String name;
  final Set<NoteTagRef> refs = <NoteTagRef>{};
}
