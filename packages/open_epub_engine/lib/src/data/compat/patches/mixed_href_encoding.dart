// Compat Patch — open_epub 1.0
// Story: S1.18 (#34) — mixed-href-encoding 보정
// BDD: F9 (href percent-encoding 정규화)

import '../../../domain/entity/epub_outline.dart';
import '../../../domain/entity/epub_spine_item.dart';
import '../patch_catalog.dart';

/// spine/목차 href에 percent-encoding(`%`)이 섞여 있으면 디코딩하여 정규화한다.
/// (예: `ch%2001.xhtml` → `ch 01.xhtml`) ZIP entry는 통상 디코딩된 실제 파일명을
/// 쓰므로 본문 매칭 일관성을 높인다.
class MixedHrefEncodingPatch implements EpubPatch {
  const MixedHrefEncodingPatch();
  @override
  String get patchId => 'mixed-href-encoding';
  @override
  String get description => 'spine/목차 href의 percent-encoding 정규화(디코딩)';
  @override
  PatchSeverity get severity => PatchSeverity.low;

  @override
  PatchResult? apply(EpubBook book) {
    final hasEncoded = book.spine.any((s) => s.href.contains('%')) ||
        _anyEncoded(book.outline.items);
    if (!hasEncoded) return null;

    var count = 0;
    String dec(String href) {
      if (!href.contains('%')) return href;
      try {
        final decoded = Uri.decodeFull(href);
        if (decoded != href) count++;
        return decoded;
      } on Object {
        return href; // 잘못된 인코딩은 원본 유지
      }
    }

    final newSpine = [
      for (final s in book.spine)
        EpubSpineItem(
          idref: s.idref,
          href: dec(s.href),
          mediaType: s.mediaType,
          linear: s.linear,
          properties: s.properties,
        ),
    ];

    List<EpubOutlineItem> decOutline(List<EpubOutlineItem> items) => [
          for (final i in items)
            EpubOutlineItem(
              title: i.title,
              spineHref: dec(i.spineHref),
              charOffset: i.charOffset,
              children: decOutline(i.children),
            ),
        ];
    final newOutline = EpubOutline(items: decOutline(book.outline.items));

    if (count == 0) return null;

    final patched = PatchedEpubBook.from(book)
        .copyWith(spine: newSpine, outline: newOutline);
    return PatchResult(book: patched, impact: {'normalized': count});
  }

  bool _anyEncoded(List<EpubOutlineItem> items) {
    for (final i in items) {
      if (i.spineHref.contains('%')) return true;
      if (_anyEncoded(i.children)) return true;
    }
    return false;
  }
}
