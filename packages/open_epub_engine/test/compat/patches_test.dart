// Story: S1.16 (#32), S1.17 (#33), S1.18 (#34) — 보정 patch tests
// BDD: F9.2 (보정 적용)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/compat/patch_catalog.dart';
import 'package:open_epub_engine/src/data/compat/patches/broken_spine_href.dart';
import 'package:open_epub_engine/src/data/compat/patches/cover_skip.dart';
import 'package:open_epub_engine/src/data/compat/patches/empty_toc.dart';
import 'package:open_epub_engine/src/data/compat/patches/mixed_href_encoding.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';

PatchedEpubBook _book({
  required List<EpubSpineItem> spine,
  EpubOutline outline = EpubOutline.empty,
}) =>
    PatchedEpubBook(
      metadata: const EpubMetadata(title: 't', epubVersion: '3.0'),
      spine: spine,
      outline: outline,
    );

const _c1 = EpubSpineItem(idref: 'c1', href: 'ch1.xhtml', mediaType: 'x');
const _c2 = EpubSpineItem(idref: 'c2', href: 'ch2.xhtml', mediaType: 'x');

void main() {
  group('CoverSkipPatch (S1.16)', () {
    test('첫 spine이 cover면 제외', () {
      final b = _book(spine: const [
        EpubSpineItem(idref: 'cover', href: 'cover.xhtml', mediaType: 'x'),
        _c1,
      ]);
      final r = const CoverSkipPatch().apply(b);
      expect(r, isNotNull);
      expect(r!.book.spine.map((s) => s.href), ['ch1.xhtml']);
      expect(r.impact['removed'], 'cover.xhtml');
    });

    test('cover가 아니면 null', () {
      expect(const CoverSkipPatch().apply(_book(spine: const [_c1, _c2])),
          isNull);
    });
  });

  group('EmptyTocPatch (S1.18)', () {
    test('목차가 없으면 spine 기반 생성', () {
      final r = const EmptyTocPatch().apply(_book(spine: const [_c1, _c2]));
      expect(r!.book.outline.items.map((i) => i.spineHref),
          ['ch1.xhtml', 'ch2.xhtml']);
      expect(r.impact['generated'], 2);
    });

    test('목차가 있으면 null', () {
      final b = _book(
        spine: const [_c1],
        outline: const EpubOutline(
          items: [EpubOutlineItem(title: '1장', spineHref: 'ch1.xhtml')],
        ),
      );
      expect(const EmptyTocPatch().apply(b), isNull);
    });
  });

  group('BrokenSpineHrefPatch (S1.17)', () {
    test('존재하지 않는 spine을 가리키는 죽은 링크 제거', () {
      final b = _book(
        spine: const [_c1],
        outline: const EpubOutline(items: [
          EpubOutlineItem(title: '1장', spineHref: 'ch1.xhtml'),
          EpubOutlineItem(title: '죽음', spineHref: 'gone.xhtml'),
        ]),
      );
      final r = const BrokenSpineHrefPatch().apply(b);
      expect(r!.book.outline.items.map((i) => i.spineHref), ['ch1.xhtml']);
      expect(r.impact['removedDeadLinks'], 1);
    });

    test('모든 링크가 유효하면 null', () {
      final b = _book(
        spine: const [_c1],
        outline: const EpubOutline(
          items: [EpubOutlineItem(title: '1장', spineHref: 'ch1.xhtml')],
        ),
      );
      expect(const BrokenSpineHrefPatch().apply(b), isNull);
    });
  });

  group('MixedHrefEncodingPatch (S1.18)', () {
    test('percent-encoding href 디코딩', () {
      final b = _book(spine: const [
        EpubSpineItem(idref: 'c1', href: 'ch%2001.xhtml', mediaType: 'x'),
      ]);
      final r = const MixedHrefEncodingPatch().apply(b);
      expect(r!.book.spine.first.href, 'ch 01.xhtml');
      expect(r.impact['normalized'], 1);
    });

    test('인코딩이 없으면 null', () {
      expect(const MixedHrefEncodingPatch().apply(_book(spine: const [_c1])),
          isNull);
    });
  });

  // invalid-rendition-layout / missing-mimetype은 raw OPF/ZIP 컨텍스트가 필요해
  // 카탈로그에서 제거되고 EpubRepositoryImpl이 진단을 직접 기록한다(#34).
  // → test/unit/repository/epub_repository_impl_test.dart 의 'raw-레벨 보정 진단' 참조.
}
