import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/utilities/internal/note_utility_json.dart';

/// What a [NoteAttachment] is. The names are persisted.
enum NoteAttachmentKind {
  /// A sound file.
  audio,

  /// A video file.
  video,

  /// Any other file, such as a PDF; unknown kinds read as this.
  document,

  /// A URL.
  link,
}

/// A file or link attached to a note. The host opens or plays it.
///
/// JSON: `{"id": String, "kind": "audio"|"video"|"document"|"link",
/// "source": String, "title": String, "createdAt": ISO-8601 String}`. Reading
/// never fails: missing or bad values become `''` and the Unix epoch, and an
/// unknown kind reads as `document`.
@immutable
class NoteAttachment {
  /// Creates an attachment; [title] may be empty.
  const NoteAttachment({
    required this.id,
    required this.kind,
    required this.source,
    required this.createdAt,
    this.title = '',
  });

  /// Reads [value] leniently (see the class comment).
  factory NoteAttachment.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteAttachment(
      id: NoteJson.string(json, 'id'),
      kind: NoteJson.enumByName(
        NoteAttachmentKind.values,
        json['kind'],
        NoteAttachmentKind.document,
      ),
      source: NoteJson.string(json, 'source'),
      createdAt: NoteUtilityJson.time(json, 'createdAt'),
      title: NoteJson.string(json, 'title'),
    );
  }

  /// Unique within a list.
  final String id;

  /// What it is.
  final NoteAttachmentKind kind;

  /// Where it is, as the host defines it: a path, a key or, for links, a URL.
  final String source;

  /// When it was attached.
  final DateTime createdAt;

  /// Display name; may be empty.
  final String title;

  /// A copy with the given values replaced.
  NoteAttachment copyWith({
    String? id,
    NoteAttachmentKind? kind,
    String? source,
    DateTime? createdAt,
    String? title,
  }) => NoteAttachment(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    title: title ?? this.title,
  );

  /// The JSON form described in the class comment.
  JsonMap toJson() => {
    'id': id,
    'kind': kind.name,
    'source': source,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteAttachment &&
      other.id == id &&
      other.kind == kind &&
      other.source == source &&
      other.createdAt == createdAt &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, kind, source, createdAt, title);

  @override
  String toString() => 'NoteAttachment($id, ${kind.name}, $title)';
}
