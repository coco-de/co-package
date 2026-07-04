// Story: S13.3 (#100) — page-progression-direction + BookCapabilities (gap #3)

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

String _opf({String ppd = '', String extraManifest = ''}) => '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>caps</dc:title><dc:identifier id="b">urn:uuid:caps</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    $extraManifest
  </manifest>
  <spine$ppd><itemref idref="c1"/></spine>
</package>''';

void main() {
  const parser = OpfParser();

  group('S13.3 — parseCapabilities: PPD', () {
    test('rtl 파싱', () {
      final caps = parser
          .parseCapabilities(_opf(ppd: ' page-progression-direction="rtl"'));
      expect(caps.pageProgressionDirection, EpubPageProgression.rtl);
      expect(caps.isRightToLeft, isTrue);
    });

    test('ltr 파싱', () {
      final caps = parser
          .parseCapabilities(_opf(ppd: ' page-progression-direction="ltr"'));
      expect(caps.pageProgressionDirection, EpubPageProgression.ltr);
      expect(caps.isRightToLeft, isFalse);
    });

    test('미명시/default는 auto', () {
      expect(parser.parseCapabilities(_opf()).pageProgressionDirection,
          EpubPageProgression.auto);
      expect(
          parser
              .parseCapabilities(
                  _opf(ppd: ' page-progression-direction="default"'))
              .pageProgressionDirection,
          EpubPageProgression.auto);
    });
  });

  group('S13.3 — parseCapabilities: hasMediaOverlay', () {
    test('SMIL 리소스 있으면 true', () {
      final caps = parser.parseCapabilities(_opf(
          extraManifest:
              '<item id="mo" href="ch1.smil" media-type="application/smil+xml"/>'));
      expect(caps.hasMediaOverlay, isTrue);
    });

    test('media-overlay 참조 있으면 true', () {
      final caps = parser.parseCapabilities(_opf(
          extraManifest:
              '<item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml" media-overlay="mo"/>'));
      expect(caps.hasMediaOverlay, isTrue);
    });

    test('없으면 false + writingMode 기본 horizontalTb', () {
      final caps = parser.parseCapabilities(_opf());
      expect(caps.hasMediaOverlay, isFalse);
      expect(caps.writingMode, EpubWritingMode.horizontalTb);
    });
  });

  group('S13.3 — 세션 노출 (session.capabilities)', () {
    Uint8List rtlEpub() => zipEpub({
          'mimetype': 'application/epub+zip',
          'META-INF/container.xml': '''
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf"
      media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
          'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>rtl</dc:title><dc:identifier id="b">urn:uuid:rtl</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="mo" href="ch1.smil" media-type="application/smil+xml"/>
  </manifest>
  <spine page-progression-direction="rtl"><itemref idref="c1"/></spine>
</package>''',
          'OEBPS/ch1.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>본문</p></body></html>',
          'OEBPS/ch1.smil': '<smil/>',
        });

    test('RTL + 미디어오버레이 신호가 세션에 노출된다', () async {
      final session = await EpubBookSession.open(EpubSource.bytes(rtlEpub()));
      expect(session.capabilities.isRightToLeft, isTrue);
      expect(session.capabilities.hasMediaOverlay, isTrue);
      await session.dispose();
    });
  });
}
