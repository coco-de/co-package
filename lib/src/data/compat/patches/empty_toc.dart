// Compat Patch — open_epub 1.0
// Story: S1.18 (#34) — empty-toc 보정
// BDD: F4.4, F9 (empty-toc → spine 기반 fallback)

import '../../../domain/entity/epub_outline.dart';
import '../patch_catalog.dart';

/// NCX/nav 모두 비어 목차가 전무할 때, linear spine을 기반으로 평면 목차를
/// 자동 생성한다. (sparse-ncx는 '부분' 목차를 보강, empty-toc는 '전무' 케이스)
class EmptyTocPatch implements EpubPatch {
  const EmptyTocPatch();
  @override
  String get patchId => 'empty-toc';
  @override
  String get description => 'NCX/nav 모두 비어 있을 때 spine 기반 자동 목차 생성';
  @override
  PatchSeverity get severity => PatchSeverity.high;

  @override
  PatchResult? apply(EpubBook book) {
    if (book.outline.items.isNotEmpty) return null;

    final items = [
      for (final s in book.spine)
        if (s.linear) EpubOutlineItem(title: _title(s.href), spineHref: s.href),
    ];
    if (items.isEmpty) return null;

    final patched =
        PatchedEpubBook.from(book).copyWith(outline: EpubOutline(items: items));
    return PatchResult(book: patched, impact: {'generated': items.length});
  }

  /// href에서 사람이 읽을 임시 제목 생성 (파일명에서 확장자 제거).
  String _title(String href) {
    final name = href.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
