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
  return Uint8List.fromList(encoded);
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

/// 파일 맵(String 또는 `List<int>`)을 ZIP 바이트로 인코딩한다. 이미지 등
/// 바이너리 항목이 필요한 책 픽스처용.
Uint8List zipEpubBinary(Map<String, Object> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes =
        content is String ? utf8.encode(content) : content as List<int>;
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

/// 1×1 투명 PNG 바이트 (이미지 렌더 검증용).
Uint8List onePixelPng() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );

/// Fixed Layout (pre-paginated) EPUB 3. 4페이지, viewport 600×800,
/// page-spread-left/right 슬롯 포함 (F3 spread/줌 검증용).
Uint8List fixedLayoutEpub3() {
  String page(String body) => '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><meta name="viewport" content="width=600, height=800"/></head>
  <body><p>$body</p></body>
</html>
''';
  return zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>고정 레이아웃 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0006</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
    <meta property="rendition:spread">auto</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
    <item id="p3" href="p3.xhtml" media-type="application/xhtml+xml"/>
    <item id="p4" href="p4.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="p1"/>
    <itemref idref="p2" properties="page-spread-left"/>
    <itemref idref="p3" properties="page-spread-right"/>
    <itemref idref="p4"/>
  </spine>
</package>
''',
    'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="p1.xhtml">1쪽</a></li></ol>
    </nav>
  </body>
</html>
''',
    'OEBPS/p1.xhtml': page('1쪽'),
    'OEBPS/p2.xhtml': page('2쪽'),
    'OEBPS/p3.xhtml': page('3쪽'),
    'OEBPS/p4.xhtml': page('4쪽'),
  });
}

/// 본문에 script/iframe이 포함된 책 (보안 sanitize 검증용).
Uint8List epubWithScriptAndIframe() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>스크립트 포함 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0007</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol><li><a href="ch1.xhtml">1장</a></li></ol></nav></body>
</html>
''',
      'OEBPS/ch1.xhtml': '''
<html xmlns="http://www.w3.org/1999/xhtml"><body>
  <p>안전한 본문</p>
  <script src="https://evil.example/x.js"></script>
  <script>alert('xss')</script>
  <iframe src="https://evil.example/frame"></iframe>
</body></html>
''',
    });

/// 본문에 이미지가 포함된 책 (이미지 로딩/placeholder 검증용).
Uint8List epubWithImages() => zipEpubBinary({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>이미지 포함 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0008</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="i1" href="img/pic.png" media-type="image/png"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol><li><a href="ch1.xhtml">1장</a></li></ol></nav></body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>그림</p><img src="img/pic.png"/></body></html>',
      'OEBPS/img/pic.png': onePixelPng(),
    });

/// 검색 가능한 한국어 본문 3챕터 책 (F6 검색 검증용).
Uint8List searchableEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>검색 테스트 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0009</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c3" href="ch3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
    <itemref idref="c3"/>
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
        <li><a href="ch3.xhtml">3장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>고래는 바다에 산다. 바다는 넓다.</p></body></html>',
      'OEBPS/ch2.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>사자는 초원의 왕이다. 초원은 바다처럼 넓다.</p></body></html>',
      'OEBPS/ch3.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>독수리는 하늘을 난다.</p></body></html>',
    });

/// 목차가 전혀 없는 EPUB 3 (nav 없음, NCX 없음 — empty-toc 진단 트리거).
Uint8List noTocEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>목차 없는 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0010</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''',
      'OEBPS/ch1.xhtml': '<html><body>1</body></html>',
      'OEBPS/ch2.xhtml': '<html><body>2</body></html>',
    });

/// Media Overlays(SMIL) EPUB 3. spine ch1은 `media-overlay`로 SMIL과 연결되고,
/// SMIL은 하위 디렉토리(OEBPS/smil/)에 있어 par src의 경로 해석(OPF 기준)을
/// 검증한다. ch2는 MO 없음(회귀). (S15.1, gap #6 배선)
Uint8List mediaOverlayEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>낭독 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-mo-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"
        media-overlay="c1_mo"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c1_mo" href="smil/ch1.smil"
        media-type="application/smil+xml"/>
    <item id="aud1" href="audio/ch1.mp3" media-type="audio/mpeg"/>
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
  <body><nav epub:type="toc"><ol>
    <li><a href="ch1.xhtml">1장</a></li>
  </ol></nav></body>
</html>
''',
      // SMIL은 smil/ 하위 → text/audio src는 SMIL 기준 상대(`../`).
      'OEBPS/smil/ch1.smil': '''
<?xml version="1.0" encoding="UTF-8"?>
<smil xmlns="http://www.w3.org/ns/SMIL" version="3.0">
  <body>
    <seq>
      <par>
        <text src="../ch1.xhtml#s1"/>
        <audio src="../audio/ch1.mp3" clipBegin="0s" clipEnd="2.5s"/>
      </par>
      <par>
        <text src="../ch1.xhtml#s2"/>
        <audio src="../audio/ch1.mp3" clipBegin="2.5s" clipEnd="5s"/>
      </par>
    </seq>
  </body>
</smil>
''',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p id="s1">첫 문장.</p><p id="s2">둘째 문장.</p></body></html>',
      'OEBPS/ch2.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>MO 없는 장.</p></body></html>',
      'OEBPS/audio/ch1.mp3': 'FAKE_AUDIO_BYTES',
    });

/// 챕터 수와 문단 수를 지정한 큰 책 (열기 성능 smoke 검증용).
Uint8List largeEpub3({int chapters = 30, int paragraphsPerChapter = 100}) {
  final files = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
  };
  final manifest = StringBuffer();
  final spine = StringBuffer();
  final navItems = StringBuffer();
  for (var i = 1; i <= chapters; i++) {
    manifest.writeln(
        '<item id="c$i" href="ch$i.xhtml" media-type="application/xhtml+xml"/>');
    spine.writeln('<itemref idref="c$i"/>');
    navItems.writeln('<li><a href="ch$i.xhtml">$i장</a></li>');
    final body = StringBuffer();
    for (var p = 0; p < paragraphsPerChapter; p++) {
      body.writeln('<p>$i장 $p번째 문단 — 성능 검증을 위한 본문 텍스트입니다.</p>');
    }
    files['OEBPS/ch$i.xhtml'] =
        '<html xmlns="http://www.w3.org/1999/xhtml"><body>$body</body></html>';
  }
  files['OEBPS/content.opf'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>큰 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0011</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    $manifest
  </manifest>
  <spine>
    $spine
  </spine>
</package>
''';
  files['OEBPS/nav.xhtml'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>$navItems</ol></nav></body>
</html>
''';
  return zipEpub(files);
}
