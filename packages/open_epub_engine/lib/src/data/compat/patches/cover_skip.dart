// Compat Patch — open_epub 1.0
// Story: S1.16 (#32) — cover-skip 보정
// BDD: F9.2 (cover-skip 보정)

import '../patch_catalog.dart';

/// spine 첫 항목이 표지(cover)로 보이면 본문 흐름에서 제외한다.
///
/// EpubBook 수준에서 가능한 휴리스틱: 첫 spine 항목의 idref/href가 'cover'를
/// 포함하거나 properties에 'cover-image'가 있으면 표지로 간주한다.
class CoverSkipPatch implements EpubPatch {
  const CoverSkipPatch();
  @override
  String get patchId => 'cover-skip';
  @override
  String get description => 'spine 첫 항목이 cover면 본문에서 제외';
  @override
  PatchSeverity get severity => PatchSeverity.low;

  @override
  PatchResult? apply(EpubBook book) {
    if (book.spine.length < 2) return null;
    final first = book.spine.first;
    final isCover = first.idref.toLowerCase().contains('cover') ||
        first.href.toLowerCase().contains('cover') ||
        first.properties.contains('cover-image');
    if (!isCover) return null;

    final patched =
        PatchedEpubBook.from(book).copyWith(spine: book.spine.sublist(1));
    return PatchResult(book: patched, impact: {'removed': first.href});
  }
}
