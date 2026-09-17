// Story: S1.19 (#35) — TextIndexBuilder / 검색 tests
// BDD: F7.1

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/compat/patch_catalog.dart' show PatchedEpubBook;
import 'package:open_epub_engine/src/data/search/text_index_builder.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';
import 'package:open_epub_engine/src/domain/entity/epub_outline.dart';
import 'package:open_epub_engine/src/domain/entity/epub_spine_item.dart';

PatchedEpubBook _book() => PatchedEpubBook(
      metadata: const EpubMetadata(title: 't', epubVersion: '3.0'),
      spine: const [
        EpubSpineItem(idref: 'c1', href: 'ch1.xhtml', mediaType: 'x'),
        EpubSpineItem(idref: 'c2', href: 'ch2.xhtml', mediaType: 'x'),
      ],
      outline: EpubOutline.empty,
    );

void main() {
  const builder = TextIndexBuilder();

  test('여러 spine에서 모든 출현 위치를 찾는다', () async {
    final index = await builder.build(_book(), spineTexts: {
      'ch1.xhtml': 'hello world foo',
      'ch2.xhtml': 'foo bar foo',
    });
    final hits = await index.search('foo');
    expect(hits, hasLength(3));
    expect(hits.map((h) => h.spineHref),
        ['ch1.xhtml', 'ch2.xhtml', 'ch2.xhtml']);
    expect(hits.first.charOffset, 12); // 'hello world ' = 12
  });

  test('대소문자를 무시한다', () async {
    final index = await builder.build(_book(), spineTexts: {
      'ch1.xhtml': 'The Quick Brown Fox',
    });
    expect(await index.search('quick'), hasLength(1));
    expect(await index.search('QUICK'), hasLength(1));
  });

  test('빈 질의는 빈 결과', () async {
    final index = await builder.build(_book(), spineTexts: {
      'ch1.xhtml': 'anything',
    });
    expect(await index.search('  '), isEmpty);
  });

  test('snippet은 주변 문맥을 포함한다', () async {
    final index = await builder.build(_book(), spineTexts: {
      'ch1.xhtml': "${'a' * 50}NEEDLE${'b' * 50}",
    });
    final hits = await index.search('NEEDLE');
    expect(hits.single.snippet, contains('NEEDLE'));
    expect(hits.single.snippet, startsWith('…'));
    expect(hits.single.snippet, endsWith('…'));
  });

  group('소문자 캐싱 (S9.7 #71)', () {
    test('build 시 1회 계산하고 여러 번 search해도 재계산하지 않는다', () async {
      final index = await builder.build(_book(), spineTexts: {
        'ch1.xhtml': 'The Quick BROWN Fox',
        'ch2.xhtml': 'Foo BAR foo',
      });
      final lowered1 = debugLoweredTexts(index);
      expect(lowered1, ['the quick brown fox', 'foo bar foo']);

      // 여러 번 검색한 뒤에도 동일 String 인스턴스가 그대로 재사용되어야 한다.
      // search()가 toLowerCase()를 재실행했다면 새 인스턴스가 되어 identity가 깨진다.
      await index.search('quick');
      await index.search('foo');
      await index.search('BAR');
      final lowered2 = debugLoweredTexts(index);
      expect(lowered2, hasLength(lowered1.length));
      for (var i = 0; i < lowered1.length; i++) {
        expect(identical(lowered1[i], lowered2[i]), isTrue,
            reason: 'search()는 캐시된 소문자 텍스트를 재계산하지 않아야 한다');
      }
    });

    test('반복 검색 결과가 변경 전과 동일하다(회귀)', () async {
      final index = await builder.build(_book(), spineTexts: {
        'ch1.xhtml': 'Hello WORLD foo',
        'ch2.xhtml': 'foo BAR Foo',
      });
      final first = await index.search('foo');
      final second = await index.search('foo');
      expect(second, hasLength(3));
      expect(
        second.map((h) => (h.spineHref, h.charOffset)),
        first.map((h) => (h.spineHref, h.charOffset)),
      );
    });
  });
}
