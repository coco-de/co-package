// Story: S1.1 (#7) — OPF parser tests
// Story: S1.4 (#10) — rendition:layout / rendition:spread extraction
// BDD: F1.1, F3

import 'package:test/test.dart';
import 'package:open_epub_engine/src/data/parser/opf_parser.dart';
import 'package:open_epub_engine/src/domain/entity/epub_capabilities.dart';
import 'package:open_epub_engine/src/domain/entity/epub_metadata.dart';

void main() {
  const parser = OpfParser();

  group('OpfParser.parse — EPUB 2', () {
    const epub2Opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>사용자 매뉴얼</dc:title>
    <dc:creator opf:role="aut">홍길동</dc:creator>
    <dc:language>ko</dc:language>
    <dc:identifier id="bookid">urn:uuid:1234</dc:identifier>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch01" href="ch01.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch02" href="ch02.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="cover" linear="no"/>
    <itemref idref="ch01"/>
    <itemref idref="ch02"/>
  </spine>
</package>''';

    test('metadata 추출 (title/version/language/author/identifier)', () {
      final r = parser.parse(epub2Opf);
      expect(r.metadata.title, '사용자 매뉴얼');
      expect(r.metadata.epubVersion, '2.0');
      expect(r.metadata.language, 'ko');
      expect(r.metadata.author, '홍길동');
      expect(r.metadata.identifier, 'urn:uuid:1234');
      // EPUB 2에는 rendition meta가 없으므로 default 유지
      expect(r.metadata.layout, EpubLayout.reflowable);
      expect(r.metadata.spread, EpubSpread.auto);
    });

    test('spine 3개 추출 (manifest와 join, 순서 유지)', () {
      final r = parser.parse(epub2Opf);
      expect(r.spine, hasLength(3));
      expect(r.spine[0].idref, 'cover');
      expect(r.spine[0].href, 'cover.xhtml');
      expect(r.spine[0].mediaType, 'application/xhtml+xml');
      expect(r.spine[0].linear, isFalse);
      expect(r.spine[1].idref, 'ch01');
      expect(r.spine[1].linear, isTrue);
      expect(r.spine[2].idref, 'ch02');
    });
  });

  group('OpfParser.parse — EPUB 3', () {
    const epub3Opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid"
         prefix="rendition: http://www.idpf.org/vocab/rendition/#">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Picture Book</dc:title>
    <dc:language>en</dc:language>
    <dc:identifier id="bookid">urn:uuid:abcd</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
    <meta property="rendition:spread">auto</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="p1" properties="page-spread-left"/>
    <itemref idref="p2" properties="page-spread-right rendition:page-spread-center"/>
  </spine>
</package>''';

    test('version 3.0 인식', () {
      final r = parser.parse(epub3Opf);
      expect(r.metadata.epubVersion, '3.0');
    });

    test('properties 속성 공백 split', () {
      final r = parser.parse(epub3Opf);
      expect(r.spine, hasLength(2));
      expect(r.spine[0].properties, ['page-spread-left']);
      expect(r.spine[1].properties, [
        'page-spread-right',
        'rendition:page-spread-center',
      ]);
    });
  });

  group('OpfParser.parse — error cases', () {
    test('잘못된 XML이면 OpfParseException', () {
      expect(() => parser.parse('not <xml>'), throwsA(isA<OpfParseException>()));
    });

    test('root가 <package>가 아니면 OpfParseException', () {
      expect(
        () => parser.parse('<?xml version="1.0"?><root/>'),
        throwsA(isA<OpfParseException>()),
      );
    });

    test('OPF namespace가 아니면 OpfParseException', () {
      const wrongNs = '''
<?xml version="1.0"?>
<package xmlns="http://example.com/wrong" version="2.0"/>
''';
      expect(() => parser.parse(wrongNs), throwsA(isA<OpfParseException>()));
    });

    test('metadata가 없으면 OpfParseException', () {
      const noMetadata = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <manifest/>
  <spine/>
</package>''';
      expect(
        () => parser.parse(noMetadata),
        throwsA(isA<OpfParseException>()),
      );
    });

    test('title이 없으면 OpfParseException', () {
      const noTitle = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:language>en</dc:language>
  </metadata>
  <manifest/>
  <spine/>
</package>''';
      expect(() => parser.parse(noTitle), throwsA(isA<OpfParseException>()));
    });

    test('manifest가 없으면 OpfParseException', () {
      const noManifest = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>x</dc:title>
  </metadata>
  <spine/>
</package>''';
      expect(
        () => parser.parse(noManifest),
        throwsA(isA<OpfParseException>()),
      );
    });

    test('spine이 없으면 OpfParseException', () {
      const noSpine = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>x</dc:title>
  </metadata>
  <manifest/>
</package>''';
      expect(() => parser.parse(noSpine), throwsA(isA<OpfParseException>()));
    });
  });

  group('OpfParser.parse — broken-spine-href tolerant', () {
    test('manifest에 매칭되지 않는 itemref는 결과에서 제외 (S1.17 영역 보존)', () {
      const opf = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>x</dc:title>
  </metadata>
  <manifest>
    <item id="ok" href="ok.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ok"/>
    <itemref idref="ghost"/>
  </spine>
</package>''';
      final r = parser.parse(opf);
      expect(r.spine, hasLength(1));
      expect(r.spine[0].idref, 'ok');
    });
  });

  group('OpfParser.parse — S1.4 rendition meta', () {
    String wrapOpf(String renditionMetas) => '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>x</dc:title>
    $renditionMetas
  </metadata>
  <manifest><item id="a" href="a.xhtml" media-type="application/xhtml+xml"/></manifest>
  <spine><itemref idref="a"/></spine>
</package>''';

    test('rendition:layout="pre-paginated" → EpubLayout.fixedLayout', () {
      final r = parser.parse(
        wrapOpf('<meta property="rendition:layout">pre-paginated</meta>'),
      );
      expect(r.metadata.layout, EpubLayout.fixedLayout);
    });

    test('rendition:layout="reflowable" → EpubLayout.reflowable', () {
      final r = parser.parse(
        wrapOpf('<meta property="rendition:layout">reflowable</meta>'),
      );
      expect(r.metadata.layout, EpubLayout.reflowable);
    });

    test('rendition:layout 비표준 값 → reflowable fallback', () {
      final r = parser.parse(
        wrapOpf('<meta property="rendition:layout">galaxy</meta>'),
      );
      expect(r.metadata.layout, EpubLayout.reflowable);
    });

    test('rendition:spread 5종 매핑', () {
      final cases = {
        'none': EpubSpread.none,
        'both': EpubSpread.both,
        'auto': EpubSpread.auto,
        'landscape': EpubSpread.landscape,
        'portrait': EpubSpread.portrait,
      };
      for (final entry in cases.entries) {
        final r = parser.parse(
          wrapOpf('<meta property="rendition:spread">${entry.key}</meta>'),
        );
        expect(
          r.metadata.spread,
          entry.value,
          reason: 'rendition:spread="${entry.key}"',
        );
      }
    });

    test('rendition:spread 비표준 값 → auto fallback', () {
      final r = parser.parse(
        wrapOpf('<meta property="rendition:spread">cosmic</meta>'),
      );
      expect(r.metadata.spread, EpubSpread.auto);
    });

    test('rendition meta가 전혀 없으면 default (reflowable + auto)', () {
      final r = parser.parse(wrapOpf(''));
      expect(r.metadata.layout, EpubLayout.reflowable);
      expect(r.metadata.spread, EpubSpread.auto);
    });

    test('Fixed Layout EPUB + spread:both 조합', () {
      final r = parser.parse(wrapOpf('''
        <meta property="rendition:layout">pre-paginated</meta>
        <meta property="rendition:spread">both</meta>
      '''));
      expect(r.metadata.layout, EpubLayout.fixedLayout);
      expect(r.metadata.spread, EpubSpread.both);
    });
  });

  group('OpfParser.parse — page-spread-left/right (S1.1 회귀 + S1.4 확인)', () {
    test('itemref properties에 page-spread-left가 보존', () {
      const opf = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>x</dc:title>
    <meta property="rendition:layout">pre-paginated</meta>
  </metadata>
  <manifest>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="p1" properties="page-spread-left"/>
    <itemref idref="p2" properties="page-spread-right"/>
  </spine>
</package>''';
      final r = parser.parse(opf);
      expect(r.spine[0].properties, contains('page-spread-left'));
      expect(r.spine[1].properties, contains('page-spread-right'));
    });
  });

  group('OpfParser.parseBundle — 단일 파싱 통합 (S9.5 #69)', () {
    // nav(EPUB3) + rendition:layout + rtl spine + SMIL(media-overlay) 을 모두
    // 포함해 parseBundle의 5개 필드를 개별 메서드와 교차검증한다.
    const richOpf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Bundle Book</dc:title>
    <dc:language>ko</dc:language>
    <dc:identifier id="bookid">urn:uuid:bundle</dc:identifier>
    <meta property="rendition:layout">galaxy</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="c1" href="c1.xhtml" media-type="application/xhtml+xml" media-overlay="mo1"/>
    <item id="c2" href="c2.xhtml" media-type="application/xhtml+xml"/>
    <item id="mo1" href="c1.smil" media-type="application/smil+xml"/>
  </manifest>
  <spine toc="ncx" page-progression-direction="rtl">
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>''';

    test('parseBundle 결과가 개별 메서드 결과와 동일하다', () {
      final bundle = parser.parseBundle(richOpf);
      final parsed = parser.parse(richOpf);
      final tocRefs = parser.tocRefs(richOpf);
      final rawLayout = parser.rawRenditionLayout(richOpf);
      final caps = parser.parseCapabilities(richOpf);

      expect(bundle.metadata.title, parsed.metadata.title);
      expect(bundle.metadata.identifier, parsed.metadata.identifier);
      expect(bundle.metadata.epubVersion, parsed.metadata.epubVersion);
      // 비표준 rendition:layout은 parse에서 reflowable fallback, raw는 원문 보존.
      expect(bundle.metadata.layout, parsed.metadata.layout);
      expect(bundle.rawRenditionLayout, rawLayout);
      expect(bundle.rawRenditionLayout, 'galaxy');

      expect(bundle.spine.map((s) => s.idref), parsed.spine.map((s) => s.idref));
      expect(bundle.spine.map((s) => s.href), parsed.spine.map((s) => s.href));

      expect(bundle.tocRefs.navHref, tocRefs.navHref);
      expect(bundle.tocRefs.ncxHref, tocRefs.ncxHref);
      expect(bundle.tocRefs.navHref, 'nav.xhtml');
      expect(bundle.tocRefs.ncxHref, 'toc.ncx');

      expect(
        bundle.capabilities.pageProgressionDirection,
        caps.pageProgressionDirection,
      );
      expect(bundle.capabilities.hasMediaOverlay, caps.hasMediaOverlay);
      expect(bundle.capabilities.pageProgressionDirection, EpubPageProgression.rtl);
      expect(bundle.capabilities.hasMediaOverlay, isTrue);
    });

    test('대형 manifest에서도 spine/toc가 개별 파싱과 일치한다', () {
      final items = StringBuffer();
      final itemrefs = StringBuffer();
      for (var i = 0; i < 500; i++) {
        items.writeln(
          '<item id="p$i" href="p$i.xhtml" media-type="application/xhtml+xml"/>',
        );
        itemrefs.writeln('<itemref idref="p$i"/>');
      }
      final bigOpf = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Big</dc:title>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    $items
  </manifest>
  <spine>
    $itemrefs
  </spine>
</package>''';
      final bundle = parser.parseBundle(bigOpf);
      final parsed = parser.parse(bigOpf);
      expect(bundle.spine, hasLength(500));
      expect(bundle.spine.map((s) => s.idref), parsed.spine.map((s) => s.idref));
      expect(bundle.tocRefs.navHref, 'nav.xhtml');
    });

    test('parseBundle도 잘못된 OPF에서 OpfParseException을 던진다', () {
      expect(
        () => parser.parseBundle('not <xml>'),
        throwsA(isA<OpfParseException>()),
      );
      expect(
        () => parser.parseBundle('<?xml version="1.0"?><root/>'),
        throwsA(isA<OpfParseException>()),
      );
    });
  });
}
