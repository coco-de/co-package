// Compat Patch — open_epub 1.0
// Story: S1.15 — sparse-NCX 자동 보정
// BDD: F4.3 (sparse-NCX 자동 보정), F9 (진단 기록)
// RFC-8: 목차가 가리키는 고유 spine이 전체의 절반 미만이면 누락 항목을 추가.

import '../../../domain/entity/epub_outline.dart';
import '../patch_catalog.dart';

class SparseNcxPatch implements EpubPatch {
  const SparseNcxPatch();

  @override
  String get patchId => 'sparse-ncx';

  @override
  String get description => 'NCX 누락된 spine 항목을 목차에 자동 추가';

  @override
  PatchSeverity get severity => PatchSeverity.medium;

  @override
  PatchResult? apply(EpubBook book) {
    final spineHrefs = [
      for (final item in book.spine)
        if (item.linear) item.href,
    ];
    if (spineHrefs.length < 2) return null;

    final covered = <String>{};
    _collectHrefs(book.outline.items, covered);

    // 완전히 빈 목차는 empty-toc(S1.18)가 담당한다.
    if (covered.isEmpty) return null;

    // 트리거: 목차가 가리키는 고유 spine이 전체의 절반 미만(RFC-8).
    if (covered.length * 2 >= spineHrefs.length) return null;

    final seen = <String>{};
    final missing = [
      for (final href in spineHrefs)
        if (!covered.contains(href) && seen.add(href)) href,
    ];
    if (missing.isEmpty) return null;

    final additions = [
      for (final href in missing)
        EpubOutlineItem(title: _fallbackTitle(href), spineHref: href),
    ];
    final patched = PatchedEpubBook.from(book).copyWith(
      outline: EpubOutline(items: [...book.outline.items, ...additions]),
    );
    return PatchResult(
      book: patched,
      impact: {
        'added': additions.length,
        'spineCount': spineHrefs.length,
        'coveredBefore': covered.length,
      },
    );
  }

  void _collectHrefs(List<EpubOutlineItem> items, Set<String> out) {
    for (final item in items) {
      out.add(item.spineHref);
      _collectHrefs(item.children, out);
    }
  }

  /// href에서 사람이 읽을 임시 제목 생성 (파일명에서 확장자 제거).
  String _fallbackTitle(String href) {
    final name = href.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
