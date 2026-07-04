// Story: S13.7 (#104) — compat-patch EPUB3 nav 결함 보정 (gap #10a)

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

String _nav(String bodyInner) =>
    '<html xmlns="http://www.w3.org/1999/xhtml" '
    'xmlns:epub="http://www.idpf.org/2007/ops"><body>$bodyInner</body></html>';

void main() {
  const parser = NavParser();

  group('S13.7 — NavParser.parseDiagnosed 결함 복원', () {
    test('정상 nav는 결함 없음', () {
      final r = parser.parseDiagnosed(_nav(
          '<nav epub:type="toc"><ol><li><a href="a.xhtml">A</a></li></ol></nav>'));
      expect(r.defects, isEmpty);
      expect(r.outline.items, hasLength(1));
    });

    test('epub:type="toc" 없으면 첫 nav 복원 + nonstandardTocType', () {
      final r = parser.parseDiagnosed(
          _nav('<nav><ol><li><a href="a.xhtml">A</a></li></ol></nav>'));
      expect(r.defects, contains(NavParseResult.nonstandardTocType));
      expect(r.outline.items, hasLength(1)); // 복원됨
    });

    test('불완전 항목(빈 href)은 건너뛰고 incompleteEntries', () {
      final r = parser.parseDiagnosed(_nav('<nav epub:type="toc"><ol>'
          '<li><a href="ok.xhtml">OK</a></li>'
          '<li><a href="">깨짐</a></li>'
          '</ol></nav>'));
      expect(r.defects, contains(NavParseResult.incompleteEntries));
      expect(r.outline.items, hasLength(1));
      expect(r.outline.items.first.title, 'OK');
    });

    test('링크 없는 <span> 헤더 + 하위 목차 → 섹션 그룹 복원 + spanHeading', () {
      final r = parser.parseDiagnosed(_nav('<nav epub:type="toc"><ol>'
          '<li><span>Part 1</span><ol>'
          '<li><a href="c1.xhtml">1장</a></li>'
          '<li><a href="c2.xhtml">2장</a></li>'
          '</ol></li>'
          '</ol></nav>'));
      expect(r.defects, contains(NavParseResult.spanHeading));
      expect(r.outline.items, hasLength(1));
      final group = r.outline.items.first;
      expect(group.title, 'Part 1');
      expect(group.children, hasLength(2));
      expect(group.spineHref, 'c1.xhtml'); // 첫 자식으로 대체
    });

    test('parse()는 결함이 있어도 복원된 목차 반환(회귀)', () {
      final outline = parser
          .parse(_nav('<nav><ol><li><a href="a.xhtml">A</a></li></ol></nav>'));
      expect(outline.items, hasLength(1));
    });
  });

  group('S13.7 — repository 진단 기록', () {
    Uint8List epubWithNav(String navBodyInner) => zipEpub({
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
    <dc:title>navdefect</dc:title><dc:identifier id="b">urn:uuid:nd</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="a.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>''',
          'OEBPS/nav.xhtml': _nav(navBodyInner),
          'OEBPS/a.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>A</p></body></html>',
        });

    test('비표준 toc type이 진단(AppliedPatch)에 기록된다', () async {
      final session = await EpubBookSession.open(EpubSource.bytes(
          epubWithNav('<nav><ol><li><a href="a.xhtml">A</a></li></ol></nav>')));
      final codes =
          session.diagnostics.appliedPatches.map((p) => p.patchId).toList();
      expect(codes, contains(NavParseResult.nonstandardTocType));
      expect(session.outline.items, hasLength(1)); // 복원됨
      await session.dispose();
    });
  });
}
