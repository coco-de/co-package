// Test fixtures — open_epub 1.0
// 메모리에서 최소 EPUB ZIP 컨테이너를 생성한다 (S1.20/S1.21 end-to-end 검증용).

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 파일 맵을 ZIP(EPUB 컨테이너) 바이트로 인코딩한다.
Uint8List zipEpub(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded!);
}

const String _containerXml = '''
<?xml version="1.0"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

/// EPUB 3 (nav.xhtml 목차, 2개 챕터) 정상 책.
Uint8List validEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>테스트 책</dc:title>
    <dc:language>ko</dc:language>
    <dc:creator>홍길동</dc:creator>
    <dc:identifier id="bookid">urn:uuid:test-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
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
    <nav epub:type="toc">
      <ol>
        <li><a href="ch1.xhtml">1장</a></li>
        <li><a href="ch2.xhtml">2장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>1장</p></body></html>',
      'OEBPS/ch2.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>2장</p></body></html>',
    });

/// [validEpub3]와 spine 구조(ch1/ch2)는 같고 제목만 다른 책 (hot-swap 위치 보존 검증).
Uint8List swappedEpub3() => zipEpub({
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>교체된 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0003</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
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
    <nav epub:type="toc">
      <ol>
        <li><a href="ch1.xhtml">1장</a></li>
        <li><a href="ch2.xhtml">2장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html><body>a</body></html>',
      'OEBPS/ch2.xhtml': '<html><body>b</body></html>',
    });

/// 챕터가 ch1 하나뿐인 책 (hot-swap 시 ch2 위치 소실 → fallback 검증).
Uint8List singleChapterEpub3() => zipEpub({
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>단일 챕터 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0004</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="ch1.xhtml">1장</a></li></ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html><body>only</body></html>',
    });

/// 비표준 rendition:layout 값을 가진 EPUB 3 (invalid-rendition-layout 진단 트리거).
Uint8List invalidRenditionEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>비표준 rendition 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0005</dc:identifier>
    <meta property="rendition:layout">weird-value</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="ch1.xhtml">1장</a></li></ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html><body>x</body></html>',
    });

/// EPUB 2 (NCX 목차가 4개 spine 중 1개만 커버 → sparse-ncx 보정 트리거).
Uint8List sparseNcxEpub2() => zipEpub({
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>EPUB2 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0002</dc:identifier>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c3" href="ch3.xhtml" media-type="application/xhtml+xml"/>
    <item id="c4" href="ch4.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="c1"/>
    <itemref idref="c2"/>
    <itemref idref="c3"/>
    <itemref idref="c4"/>
  </spine>
</package>
''',
      'OEBPS/toc.ncx': '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="n1">
      <navLabel><text>1장</text></navLabel>
      <content src="ch1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>
''',
      'OEBPS/ch1.xhtml': '<html><body>1</body></html>',
      'OEBPS/ch2.xhtml': '<html><body>2</body></html>',
      'OEBPS/ch3.xhtml': '<html><body>3</body></html>',
      'OEBPS/ch4.xhtml': '<html><body>4</body></html>',
    });
