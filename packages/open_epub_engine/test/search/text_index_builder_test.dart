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
}
