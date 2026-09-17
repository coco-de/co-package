// Story: S13.2 (#99) — rendition:viewport / rendition:orientation 파싱 (gap #1)

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

String _opf({String meta = '', String version = '3.0'}) => '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="$version" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>rendition</dc:title>
    <dc:identifier id="b">urn:uuid:r</dc:identifier>
    $meta
  </metadata>
  <manifest><item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/></manifest>
  <spine><itemref idref="c1"/></spine>
</package>''';

void main() {
  const parser = OpfParser();

  group('S13.2 — rendition:orientation', () {
    test('landscape/portrait 파싱', () {
      expect(
        parser
            .parse(_opf(
                meta:
                    '<meta property="rendition:orientation">landscape</meta>'))
            .metadata
            .orientation,
        EpubOrientation.landscape,
      );
      expect(
        parser
            .parse(_opf(
                meta: '<meta property="rendition:orientation">portrait</meta>'))
            .metadata
            .orientation,
        EpubOrientation.portrait,
      );
    });

    test('미명시/비표준은 auto', () {
      expect(parser.parse(_opf()).metadata.orientation, EpubOrientation.auto);
      expect(
        parser
            .parse(_opf(
                meta: '<meta property="rendition:orientation">weird</meta>'))
            .metadata
            .orientation,
        EpubOrientation.auto,
      );
    });
  });

  group('S13.2 — rendition:viewport', () {
    test('width/height 파싱', () {
      final vp = parser
          .parse(_opf(
              meta:
                  '<meta property="rendition:viewport">width=1200, height=1600</meta>'))
          .metadata
          .viewport;
      expect(vp, const EpubViewport(width: 1200, height: 1600));
    });

    test('미명시는 null', () {
      expect(parser.parse(_opf()).metadata.viewport, isNull);
    });

    test('불완전(width만)은 null', () {
      final vp = parser
          .parse(_opf(
              meta: '<meta property="rendition:viewport">width=800</meta>'))
          .metadata
          .viewport;
      expect(vp, isNull);
    });
  });

  test('S13.2 — 기존 layout/spread 회귀 없음', () {
    final md = parser
        .parse(_opf(
            meta: '<meta property="rendition:layout">pre-paginated</meta>'
                '<meta property="rendition:spread">both</meta>'))
        .metadata;
    expect(md.layout, EpubLayout.fixedLayout);
    expect(md.spread, EpubSpread.both);
    expect(md.orientation, EpubOrientation.auto);
  });
}
