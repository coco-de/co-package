// Compat Patch — open_epub 1.0
// Story: S1.17 (#33) — broken-spine-href 보정
// BDD: F9.2 (broken-spine-href 보정)
//
// 주의: OpfParser가 파싱 단계에서 이미 manifest에 없는 spine itemref를 제외하므로
// EpubBook.spine에는 깨진 항목이 남지 않는다. 따라서 본 보정은 EpubBook 수준에서
// 가능한 무결성 작업 — 즉 "존재하지 않는 spine을 가리키는 죽은 목차 링크"를
// 정리하는 책임으로 구현한다.

import '../../../domain/entity/epub_outline.dart';
import '../patch_catalog.dart';

class BrokenSpineHrefPatch implements EpubPatch {
  const BrokenSpineHrefPatch();
  @override
  String get patchId => 'broken-spine-href';
  @override
  String get description => '존재하지 않는 spine을 가리키는 목차 링크 제거';
  @override
  PatchSeverity get severity => PatchSeverity.high;

  @override
  PatchResult? apply(EpubBook book) {
    if (book.outline.items.isEmpty) return null;
    final spineHrefs = {for (final s in book.spine) s.href};

    var removed = 0;
    List<EpubOutlineItem> prune(List<EpubOutlineItem> items) {
      final out = <EpubOutlineItem>[];
      for (final item in items) {
        final children = prune(item.children);
        if (spineHrefs.contains(item.spineHref)) {
          out.add(
            EpubOutlineItem(
              title: item.title,
              spineHref: item.spineHref,
              charOffset: item.charOffset,
              children: children,
            ),
          );
        } else {
          removed++;
          out.addAll(children); // 죽은 부모는 버리되 살아있는 자식은 승격
        }
      }
      return out;
    }

    final pruned = prune(book.outline.items);
    if (removed == 0) return null;

    final patched =
        PatchedEpubBook.from(book).copyWith(outline: EpubOutline(items: pruned));
    return PatchResult(book: patched, impact: {'removedDeadLinks': removed});
  }
}
