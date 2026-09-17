// Story: S14.1 (#105) — RTL page-progression 읽기 방향 해석 (gap #4)
//
// EpubReader가 책의 page-progression-direction(capabilities) 또는 명시
// readingDirection override로 넘김 방향을 결정하는지 end-to-end 검증한다.
// paged 모드(reflowable)에서 PageView.reverse에 반영되는지 확인.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub_engine/testing.dart';

void main() {
  group('EpubReader — RTL 읽기 방향 해석 (S14.1)', () {
    testWidgets('책 PPD=rtl → auto(override 없음)로 넘김 반전', (tester) async {
      await _pumpReader(tester, source: _rtlEpub(), paged: true);
      expect(_pageView(tester).reverse, isTrue);
    });

    testWidgets('책 PPD=ltr(기본) → 넘김 정방향', (tester) async {
      await _pumpReader(tester, source: searchableEpub3(), paged: true);
      expect(_pageView(tester).reverse, isFalse);
    });

    testWidgets('override=ltr가 책 PPD=rtl를 덮어쓴다', (tester) async {
      await _pumpReader(
        tester,
        source: _rtlEpub(),
        paged: true,
        readingDirection: EpubPageProgression.ltr,
      );
      expect(_pageView(tester).reverse, isFalse);
    });

    testWidgets('override=rtl가 책 PPD=ltr를 덮어쓴다', (tester) async {
      await _pumpReader(
        tester,
        source: searchableEpub3(),
        paged: true,
        readingDirection: EpubPageProgression.rtl,
      );
      expect(_pageView(tester).reverse, isTrue);
    });
  });
}

// -------- helpers --------

Future<void> _pumpReader(
  WidgetTester tester, {
  required Uint8List source,
  required bool paged,
  EpubPageProgression? readingDirection,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(source),
          paged: paged,
          readingDirection: readingDirection,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PageView _pageView(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView));

/// spine에 page-progression-direction="rtl"을 명시한 인메모리 EPUB 3.
Uint8List _rtlEpub() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>RTL 테스트 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-rtl-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine page-progression-direction="rtl">
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc"><ol><li><a href="ch1.xhtml">1</a></li></ol></nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>アラビア語やヘブライ語の本。</p></body></html>',
      'OEBPS/ch2.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>右から左へ読む。</p></body></html>',
    });
