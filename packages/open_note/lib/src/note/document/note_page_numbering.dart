import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// How a note numbers its pages.
///
/// By default page *n* is numbered *n*. When numbering [startsAtPageId] some
/// later page, the pages before it are front matter labelled
/// `<frontMatterPrefix><n>` (`0-1`, `0-2`, …) and that page gets
/// [firstNumber].
///
/// JSON: `{"startsAtPageId": String?, "firstNumber": int,
/// "frontMatterPrefix": String}`.
@immutable
class NotePageNumbering {
  const NotePageNumbering({
    this.startsAtPageId,
    this.firstNumber = 1,
    this.frontMatterPrefix = '0-',
  });

  factory NotePageNumbering.fromJson(Object? value) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};

    return NotePageNumbering(
      startsAtPageId: NoteJson.stringOrNull(json, 'startsAtPageId'),
      firstNumber: NoteJson.integer(json, 'firstNumber', 1),
      frontMatterPrefix: NoteJson.string(json, 'frontMatterPrefix', '0-'),
    );
  }

  /// The page numbering starts at; null numbers from the first page.
  final String? startsAtPageId;
  final int firstNumber;
  final String frontMatterPrefix;

  /// The label of the page at [index] in [pageIds]. A [startsAtPageId] that is
  /// not in the list is ignored.
  String labelOf(List<String> pageIds, int index) {
    assert(index >= 0 && index < pageIds.length, 'index out of range');
    final start = startsAtPageId == null ? 0 : pageIds.indexOf(startsAtPageId!);
    final origin = start < 0 ? 0 : start;
    if (index < origin) return '$frontMatterPrefix${index + 1}';

    return '${firstNumber + index - origin}';
  }

  NotePageNumbering copyWith({
    String? Function()? startsAtPageId,
    int? firstNumber,
    String? frontMatterPrefix,
  }) => NotePageNumbering(
    startsAtPageId: startsAtPageId == null
        ? this.startsAtPageId
        : startsAtPageId(),
    firstNumber: firstNumber ?? this.firstNumber,
    frontMatterPrefix: frontMatterPrefix ?? this.frontMatterPrefix,
  );

  JsonMap toJson() => {
    if (startsAtPageId != null) 'startsAtPageId': startsAtPageId,
    'firstNumber': firstNumber,
    'frontMatterPrefix': frontMatterPrefix,
  };

  @override
  bool operator ==(Object other) =>
      other is NotePageNumbering &&
      other.startsAtPageId == startsAtPageId &&
      other.firstNumber == firstNumber &&
      other.frontMatterPrefix == frontMatterPrefix;

  @override
  int get hashCode =>
      Object.hash(startsAtPageId, firstNumber, frontMatterPrefix);
}
