import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/note_folder_icons.dart';
import 'package:open_note/src/note/library/internal/note_library_dates.dart';

/// A folder of the library. Folders form a tree through [parentId]; siblings
/// are ordered by [order].
///
/// Timestamps compare by the instant they denote.
///
/// JSON schema:
/// ```json
/// {
///   "id": "…",
///   "name": "School",
///   "iconKey": "school",
///   "parentId": "…",
///   "order": 0,
///   "createdAt": "2026-01-01T10:00:00.000Z"
/// }
/// ```
/// `parentId` is omitted for a top-level folder.
@immutable
class NoteFolder {
  /// Creates a folder.
  const NoteFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.iconKey = NoteFolderIcons.folder,
    this.parentId,
    this.order = 0,
  }) : assert(order >= 0, 'order must not be negative');

  /// The identifier notes refer to with [NoteSummary.folderId].
  final String id;

  /// The name shown to the user; may be empty.
  final String name;

  /// One of [NoteFolderIcons.keys]. Unknown keys (from a newer version) are
  /// kept and drawn as a plain folder.
  final String iconKey;

  /// The containing folder, or `null` for a top-level folder.
  final String? parentId;

  /// The position among its siblings, from 0.
  final int order;

  /// When the folder was created.
  final DateTime createdAt;

  /// Decodes the JSON form; `null` when [value] is not an object with a
  /// non-empty `id`. A negative `order` is 0, a blank `iconKey` is a folder and
  /// a missing `createdAt` is the Unix epoch.
  static NoteFolder? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final id = NoteJson.string(json, 'id');
    if (id.isEmpty) return null;
    final iconKey = NoteJson.string(json, 'iconKey');
    final parentId = NoteJson.string(json, 'parentId');
    final order = NoteJson.integer(json, 'order');

    return NoteFolder(
      id: id,
      name: NoteJson.string(json, 'name'),
      iconKey: iconKey.isEmpty ? NoteFolderIcons.folder : iconKey,
      parentId: parentId.isEmpty ? null : parentId,
      order: order < 0 ? 0 : order,
      createdAt:
          NoteLibraryDates.tryFromJson(json['createdAt']) ??
          NoteLibraryDates.epoch,
    );
  }

  /// A copy with some fields replaced. Pass `parentId: () => null` to move the
  /// folder to the top level.
  NoteFolder copyWith({
    String? id,
    String? name,
    String? iconKey,
    ValueGetter<String?>? parentId,
    int? order,
    DateTime? createdAt,
  }) => NoteFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    parentId: parentId == null ? this.parentId : parentId(),
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
  );

  /// The persisted form (see the class documentation).
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'iconKey': iconKey,
    'parentId': ?parentId,
    'order': order,
    'createdAt': NoteLibraryDates.toJson(createdAt),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteFolder &&
      other.id == id &&
      other.name == name &&
      other.iconKey == iconKey &&
      other.parentId == parentId &&
      other.order == order &&
      other.createdAt.isAtSameMomentAs(createdAt);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    parentId,
    order,
    createdAt.microsecondsSinceEpoch,
  );

  @override
  String toString() => 'NoteFolder($id, "$name")';
}
