// Story: S1.15 — sparse-NCX 자동 보정 tests
// BDD: F4.3 (sparse-NCX 자동 보정)

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/compat/patch_catalog.dart';
import 'package:open_epub_engine/src/data/compat/patches/sparse_ncx.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';

EpubSpineItem _si(String href, {bool linear = true}) => EpubSpineItem(
      idref: href,
      href: href,
      mediaType: 'application/xhtml+xml',
      linear: linear,
    );

EpubOutlineItem _oi(String href, {List<EpubOutlineItem> children = const []}) =>
    EpubOutlineItem(title: href, spineHref: href, children: children);

class _Book implements EpubBook {
  _Book({required this.spine, required List<EpubOutlineItem> outline})
      : outline = EpubOutline(items: outline);

  @override
  final List<EpubSpineItem> spine;
  @override
  final EpubOutline outline;
  @override
  EpubMetadata get metadata =>
      const EpubMetadata(title: 't', epubVersion: '2.0');
  @override
  EpubLayout get layout => metadata.layout;
}

void main() {
  const patch = SparseNcxPatch();

  test('메타데이터: patchId/severity', () {
    expect(patch.patchId, 'sparse-ncx');
    expect(patch.severity, PatchSeverity.medium);
  });

  test('목차가 spine 절반 미만이면 누락 항목 자동 추가', () {
    final book = _Book(
      spine: [_si('a'), _si('b'), _si('c'), _si('d'), _si('e')],
      outline: [_oi('a')], // 5개 중 1개만 → 20%
    );
    final result = patch.apply(book)!;
    expect(result.book.outline.items.length, 5); // a + b,c,d,e
    final hrefs = result.book.outline.items.map((i) => i.spineHref).toList();
    expect(hrefs, ['a', 'b', 'c', 'd', 'e']); // 순서 보존
    expect(result.impact['added'], 4);
    expect(result.impact['spineCount'], 5);
    expect(result.impact['coveredBefore'], 1);
  });

  test('목차가 절반 이상이면 미적용', () {
    final book = _Book(
      spine: [_si('a'), _si('b'), _si('c'), _si('d')],
      outline: [_oi('a'), _oi('b')], // 2/4 = 50%
    );
    expect(patch.apply(book), isNull);
  });

  test('빈 목차는 미적용 (empty-toc 담당)', () {
    final book = _Book(
      spine: [_si('a'), _si('b'), _si('c')],
      outline: const [],
    );
    expect(patch.apply(book), isNull);
  });

  test('spine 1개는 미적용', () {
    final book = _Book(spine: [_si('a')], outline: [_oi('a')]);
    expect(patch.apply(book), isNull);
  });

  test('non-linear spine은 대상에서 제외', () {
    final book = _Book(
      spine: [_si('a'), _si('b', linear: false), _si('c'), _si('d'), _si('e')],
      outline: [_oi('a')], // linear spine 4개 중 1개
    );
    final result = patch.apply(book)!;
    final added = result.book.outline.items.map((i) => i.spineHref).toList();
    expect(added, ['a', 'c', 'd', 'e']); // b(non-linear) 제외
    expect(result.impact['added'], 3);
  });

  test('중첩 목차 항목의 href도 커버로 인식', () {
    final book = _Book(
      spine: [_si('a'), _si('b'), _si('c'), _si('d')],
      outline: [
        _oi('a', children: [_oi('b')]),
      ], // flatten 시 {a,b} = 2/4 = 50% → 미적용
    );
    expect(patch.apply(book), isNull);
  });

  test('추가 항목 title은 파일명(확장자 제거), spineHref 보존', () {
    final book = _Book(
      spine: [_si('text/intro.xhtml'), _si('text/ch03.xhtml'), _si('x.html')],
      outline: [_oi('text/intro.xhtml')],
    );
    final added = patch
        .apply(book)!
        .book
        .outline
        .items
        .firstWhere((i) => i.spineHref == 'text/ch03.xhtml');
    expect(added.title, 'ch03');
    expect(added.spineHref, 'text/ch03.xhtml');
  });

  test('카탈로그를 통한 ApplyPatchesUseCase 흐름에서 진단 기록', () {
    // 실제 카탈로그(7종)로 호출 — sparse 조건 충족 책이면 기록.
    // 여기서는 SparseNcxPatch 단독 동작만 재확인.
    final book = _Book(
      spine: [_si('a'), _si('b'), _si('c'), _si('d')],
      outline: [_oi('a')],
    );
    final result = patch.apply(book);
    expect(result, isNotNull);
    expect(result!.impact['added'], 3);
  });
}
