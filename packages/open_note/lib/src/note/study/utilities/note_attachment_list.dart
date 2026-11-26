import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/note_attachment.dart';

/// The ordered attachments of a note.
///
/// JSON: `{"items": [NoteAttachment…]}`. Reading skips entries without an id or
/// source, and repeated ids. Listeners are notified only when something
/// changes; every change method does nothing after [dispose].
class NoteAttachmentList extends ChangeNotifier {
  /// [idFactory] and [clock] stamp the attachments [add] creates. Unusable
  /// [items] (no id or source, repeated id) are skipped.
  NoteAttachmentList({
    Iterable<NoteAttachment> items = const [],
    this.idFactory = generateNoteId,
    this.clock = systemNoteClock,
  }) {
    for (final item in items) {
      if (_isUsable(item)) _items.add(item);
    }
  }

  /// Reads [value] leniently (see the class comment).
  factory NoteAttachmentList.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
  }) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteAttachmentList(
      items: NoteJson.mapList(json, 'items').map(NoteAttachment.fromJson),
      idFactory: idFactory,
      clock: clock,
    );
  }

  /// Mints the ids of attachments [add] creates.
  final NoteIdFactory idFactory;

  /// Dates them.
  final NoteClock clock;

  final List<NoteAttachment> _items = [];
  bool _disposed = false;

  /// The attachments, in order.
  List<NoteAttachment> get items => UnmodifiableListView(_items);

  /// The attachment with [id], or `null`.
  NoteAttachment? find(String id) {
    final index = _indexOf(id);

    return index < 0 ? null : _items[index];
  }

  /// The attachments of [kind], in order.
  List<NoteAttachment> byKind(NoteAttachmentKind kind) => [
    for (final item in _items)
      if (item.kind == kind) item,
  ];

  /// Appends a new attachment and returns it, or `null` when [source] is blank.
  /// A blank [title] defaults to the source.
  NoteAttachment? add({
    required NoteAttachmentKind kind,
    required String source,
    String title = '',
  }) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;
    final name = title.trim();
    final attachment = NoteAttachment(
      id: idFactory(),
      kind: kind,
      source: trimmed,
      createdAt: clock(),
      title: name.isEmpty ? trimmed : name,
    );

    return insert(attachment) ? attachment : null;
  }

  /// Inserts an existing attachment at [index] (clamped; the end by default),
  /// for example to restore a removed one. Returns `false` when its id or
  /// source is empty or the id is taken.
  bool insert(NoteAttachment attachment, {int? index}) {
    if (_disposed || !_isUsable(attachment)) return false;
    final at = (index ?? _items.length).clamp(0, _items.length);
    _items.insert(at, attachment);
    notifyListeners();

    return true;
  }

  /// Removes the attachment with [id]; the host deletes any file.
  bool remove(String id) {
    final index = _indexOf(id);
    if (_disposed || index < 0) return false;
    _items.removeAt(index);
    notifyListeners();

    return true;
  }

  /// Renames to the trimmed [title]; blank titles are ignored.
  bool rename(String id, String title) {
    final index = _indexOf(id);
    final trimmed = title.trim();
    if (_disposed || index < 0 || trimmed.isEmpty) return false;
    if (_items[index].title == trimmed) return false;
    _items[index] = _items[index].copyWith(title: trimmed);
    notifyListeners();

    return true;
  }

  /// Moves the attachment at [oldIndex] so that it ends up at [newIndex]
  /// (clamped to the list). Returns whether anything moved.
  bool move(int oldIndex, int newIndex) {
    if (_disposed || oldIndex < 0 || oldIndex >= _items.length) return false;
    final target = newIndex.clamp(0, _items.length - 1);
    if (target == oldIndex) return false;
    _items.insert(target, _items.removeAt(oldIndex));
    notifyListeners();

    return true;
  }

  /// The JSON form described in the class comment.
  JsonMap toJson() => {
    'items': [for (final item in _items) item.toJson()],
  };

  bool _isUsable(NoteAttachment attachment) =>
      attachment.id.isNotEmpty &&
      attachment.source.isNotEmpty &&
      find(attachment.id) == null;

  int _indexOf(String id) => _items.indexWhere((item) => item.id == id);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
