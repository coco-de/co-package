// Story: S1.6 (#12) — PaginationStrategy tests

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';
import 'package:open_epub/src/presentation/engine/reflowable/pagination_strategy.dart';

void main() {
  group('SinglePagePerSpineStrategy', () {
    const strategy = SinglePagePerSpineStrategy();

    test('spine N개 → N 페이지', () {
      final spine = _fakeSpine(['a.xhtml', 'b.xhtml', 'c.xhtml']);
      final result = strategy.paginate(
        spine: spine,
        viewportWidth: 400,
        viewportHeight: 600,
        fontSize: 16,
        lineHeight: 1.5,
      );
      expect(result.pageCount, 3);
      for (var i = 0; i < 3; i++) {
        expect(result.pages[i].spineIndex, i);
        expect(result.pages[i].startCharOffset, 0);
        expect(result.pages[i].endCharOffset, -1);
      }
    });

    test('빈 spine → 0 페이지', () {
      final result = strategy.paginate(
        spine: const [],
        viewportWidth: 400,
        viewportHeight: 600,
        fontSize: 16,
        lineHeight: 1.5,
      );
      expect(result.pageCount, 0);
      expect(result.pages, isEmpty);
    });

    test('viewport / fontSize / lineHeight 값과 무관 (default strategy)', () {
      final spine = _fakeSpine(['a.xhtml', 'b.xhtml']);
      final r1 = strategy.paginate(
        spine: spine,
        viewportWidth: 100,
        viewportHeight: 100,
        fontSize: 8,
        lineHeight: 1.0,
      );
      final r2 = strategy.paginate(
        spine: spine,
        viewportWidth: 4000,
        viewportHeight: 4000,
        fontSize: 32,
        lineHeight: 3.0,
      );
      expect(r1.pageCount, r2.pageCount);
    });
  });
}

List<EpubSpineItem> _fakeSpine(List<String> hrefs) => hrefs
    .map((h) =>
        EpubSpineItem(idref: h, href: h, mediaType: 'application/xhtml+xml'))
    .toList();
