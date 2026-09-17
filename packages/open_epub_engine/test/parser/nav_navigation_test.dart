// Story: S13.1 (#98) — landmarks / page-list 파싱 (gap #2)

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

const _navWithAll = '''
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc"><ol>
      <li><a href="ch1.xhtml">1장</a></li>
    </ol></nav>
    <nav epub:type="landmarks"><ol>
      <li><a epub:type="cover" href="cover.xhtml">표지</a></li>
      <li><a epub:type="bodymatter" href="ch1.xhtml#start">본문 시작</a></li>
    </ol></nav>
    <nav epub:type="page-list"><ol>
      <li><a href="ch1.xhtml#p1">1</a></li>
      <li><a href="ch1.xhtml#p2">2</a></li>
    </ol></nav>
  </body>
</html>
''';

void main() {
  const parser = NavParser();

  group('S13.1 — NavParser.parseNavigation', () {
    test('landmarks 추출 (type + title + href, fragment 보존)', () {
      final nav = parser.parseNavigation(_navWithAll);
      expect(nav.landmarks, hasLength(2));
      expect(nav.landmarks[0],
          const EpubLandmark(type: 'cover', title: '표지', href: 'cover.xhtml'));
      expect(nav.landmarks[1].type, equals('bodymatter'));
      expect(nav.landmarks[1].href, equals('ch1.xhtml#start')); // fragment 유지
    });

    test('page-list 추출 (label + href)', () {
      final nav = parser.parseNavigation(_navWithAll);
      expect(nav.pageList, hasLength(2));
      expect(nav.pageList[0],
          const EpubPageTarget(label: '1', href: 'ch1.xhtml#p1'));
      expect(nav.pageList[1].label, equals('2'));
    });

    test('landmarks/page-list 없으면 empty', () {
      const tocOnly = '<html xmlns="http://www.w3.org/1999/xhtml" '
          'xmlns:epub="http://www.idpf.org/2007/ops"><body>'
          '<nav epub:type="toc"><ol><li><a href="a.xhtml">A</a></li></ol></nav>'
          '</body></html>';
      final nav = parser.parseNavigation(tocOnly);
      expect(nav.isEmpty, isTrue);
      expect(nav.landmarks, isEmpty);
      expect(nav.pageList, isEmpty);
    });

    test('잘못된 XML은 empty (예외 아님)', () {
      expect(parser.parseNavigation('<not xml').isEmpty, isTrue);
    });

    test('toc 파싱은 회귀 없음', () {
      final outline = parser.parse(_navWithAll);
      expect(outline.items, hasLength(1));
      expect(outline.items.first.title, equals('1장'));
    });
  });

  group('S13.1 — 세션 노출 (session.navigation)', () {
    Uint8List epubWithNav(String navBody) => zipEpub({
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
    <dc:title>nav</dc:title><dc:identifier id="b">urn:uuid:nav</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="cov" href="cover.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="cov"/><itemref idref="c1"/></spine>
</package>''',
          'OEBPS/nav.xhtml': navBody,
          'OEBPS/ch1.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>본문</p></body></html>',
          'OEBPS/cover.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>표지</p></body></html>',
        });

    test('landmarks/page-list이 세션에 노출된다', () async {
      final session = await EpubBookSession.open(
          EpubSource.bytes(epubWithNav(_navWithAll)));
      expect(session.navigation.landmarks, hasLength(2));
      expect(session.navigation.pageList, hasLength(2));
      expect(session.navigation.landmarks.first.type, equals('cover'));
      // toc는 outline으로 그대로 노출(회귀 없음)
      expect(session.outline.items, hasLength(1));
      await session.dispose();
    });
  });
}
