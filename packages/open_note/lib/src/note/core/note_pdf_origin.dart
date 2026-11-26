import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_page_size.dart';

/// The PDF page an imported note page shows, so the text on it can still be
/// selected through a `NotePdfTextLayer`.
///
/// JSON schema: `{"document", "page", "size": {"w", "h"}, "picture"?}`.
@immutable
class NotePdfOrigin {
  const NotePdfOrigin({
    required this.document,
    required this.pageIndex,
    required this.size,
    this.picture,
  }) : assert(pageIndex >= 0, 'pageIndex is 0-based');

  /// The app's key of the PDF (the importer uses the file name).
  final String document;

  /// 0-based page of the PDF.
  final int pageIndex;

  /// The PDF page size; text run boxes are given in it.
  final NotePageSize size;

  /// The picture of the page on the note, set when the page is made. Text is
  /// offered only while the note page's paper still shows it.
  final String? picture;

  /// Null when [value] has no document or a negative page.
  static NotePdfOrigin? fromJson(Object? value) {
    final json = NoteJson.asMap(value);
    if (json == null) return null;
    final document = NoteJson.string(json, 'document');
    final page = NoteJson.integer(json, 'page', -1);
    if (document.isEmpty || page < 0) return null;

    return NotePdfOrigin(
      document: document,
      pageIndex: page,
      size: NotePageSize.fromJson(json['size']),
      picture: NoteJson.stringOrNull(json, 'picture'),
    );
  }

  NotePdfOrigin copyWith({String? document, String? picture}) => NotePdfOrigin(
    document: document ?? this.document,
    pageIndex: pageIndex,
    size: size,
    picture: picture ?? this.picture,
  );

  JsonMap toJson() => {
    'document': document,
    'page': pageIndex,
    'size': size.toJson(),
    if (picture != null) 'picture': picture,
  };

  @override
  bool operator ==(Object other) =>
      other is NotePdfOrigin &&
      other.document == document &&
      other.pageIndex == pageIndex &&
      other.size == size &&
      other.picture == picture;

  @override
  int get hashCode => Object.hash(document, pageIndex, size, picture);

  @override
  String toString() => 'NotePdfOrigin($document, $pageIndex)';
}
