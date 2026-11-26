import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// What a template list shows before the template itself is fetched.
///
/// JSON: `{id, name, kind, thumbnailSource?, tags: [..]}`.
/// [NoteTemplateDescriptor.fromJson] never throws: missing texts are empty, an
/// unknown kind is `blank` and non-string tags are dropped.
@immutable
class NoteTemplateDescriptor {
  /// Identifier passed to `NoteTemplateSource.fetch`.
  final String id;

  /// Display name.
  final String name;

  /// Kind of the template.
  final NotePaperKind kind;

  /// Opaque string of a preview picture, or `null`.
  final String? thumbnailSource;

  /// Search keywords (unmodifiable).
  final List<String> tags;

  NoteTemplateDescriptor({
    required this.id,
    required this.name,
    required this.kind,
    this.thumbnailSource,
    List<String> tags = const [],
  }) : tags = List.unmodifiable(tags);

  /// The descriptor of [template].
  factory NoteTemplateDescriptor.of(
    NotePaperTemplate template, {
    String? thumbnailSource,
    List<String> tags = const [],
  }) => NoteTemplateDescriptor(
    id: template.id,
    name: template.name,
    kind: template.kind,
    thumbnailSource: thumbnailSource,
    tags: tags,
  );

  /// Reads [toJson].
  factory NoteTemplateDescriptor.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NoteTemplateDescriptor(
      id: NoteJson.string(json, 'id'),
      name: NoteJson.string(json, 'name'),
      kind: NoteJson.enumByName(
        NotePaperKind.values,
        json['kind'],
        NotePaperKind.blank,
      ),
      thumbnailSource: NoteJson.stringOrNull(json, 'thumbnailSource'),
      tags: NoteJson.stringList(json, 'tags'),
    );
  }

  /// A copy with some fields replaced. [clearThumbnailSource] removes the
  /// preview.
  NoteTemplateDescriptor copyWith({
    String? id,
    String? name,
    NotePaperKind? kind,
    String? thumbnailSource,
    bool clearThumbnailSource = false,
    List<String>? tags,
  }) => NoteTemplateDescriptor(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    thumbnailSource: clearThumbnailSource
        ? null
        : thumbnailSource ?? this.thumbnailSource,
    tags: tags ?? this.tags,
  );

  /// The JSON form (see the class documentation).
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    if (thumbnailSource != null) 'thumbnailSource': thumbnailSource,
    'tags': tags,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteTemplateDescriptor &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.thumbnailSource == thumbnailSource &&
      listEquals(other.tags, tags);

  @override
  int get hashCode =>
      Object.hash(id, name, kind, thumbnailSource, Object.hashAll(tags));

  @override
  String toString() => 'NoteTemplateDescriptor($id, ${kind.name})';
}
