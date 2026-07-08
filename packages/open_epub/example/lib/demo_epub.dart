// 공개 데모(웹 배포 포함)에서 항상 로드 가능한 최소 합성 EPUB.
//
// "1.0 코어 데모"·"하이라이트 데모"는 예전에 `assets/example.epub`을
// 참조했으나 이 파일은 저장소에 커밋된 적이 없어(로컬에만 있던 픽스처),
// 클린 체크아웃(CI·GitHub Pages 빌드 포함)에서는 항상 asset 로드에
// 실패했다(#235). 여기서 순수 Dart로 생성하면 어떤 배포 환경에서도
// 외부 파일 없이 동일하게 동작한다.
//
// EPUB3 샘플 라이브러리(sample_book.dart)의 8종 큐레이션 실제 도서는
// 대용량/저작권 사유로 여전히 로컬 전용 `assets/*.epub` 픽스처를 쓴다 —
// 이 파일이 대체하는 대상이 아니다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

Uint8List _zipEpub(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// 목차 + 2챕터로 구성된 최소 EPUB3 데모 책.
Uint8List buildDemoEpub() => _zipEpub({
  'mimetype': 'application/epub+zip',
  'META-INF/container.xml': '''
<?xml version="1.0"?>
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
    <dc:title>open_epub 데모 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:open-epub-demo-0001</dc:identifier>
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
      '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
      '<p>고래는 바다에 산다. 바다는 넓다.</p></body></html>',
  'OEBPS/ch2.xhtml':
      '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
      '<p>사자는 초원의 왕이다.</p></body></html>',
});

/// A4 페이지 논리 크기(96dpi 기준, 210×297mm → px). Fixed Layout 데모/테스트가
/// 공유하는 상수 — [EpubReader]는 spine XHTML의 `<meta name="viewport">`에서
/// 이 값을 읽어 페이지 논리 좌표 공간을 결정한다.
const double kA4PageWidth = 794;
const double kA4PageHeight = 1123;

/// A4 크기 Fixed Layout(pre-paginated) 데모 책 — 3페이지, 페이지마다 실제 렌더
/// 크기를 본문에 표시해 A4 비율/줌이 올바른지 눈으로 확인할 수 있다.
/// `buildDemoEpub()`와 마찬가지로 외부 asset 없이 순수 Dart로 생성한다(#235와
/// 동일한 이유 — 클린 체크아웃/웹 배포에서도 항상 로드 가능).
Uint8List buildFixedLayoutA4DemoEpub() {
  String page(int index, String body) =>
      '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta name="viewport"
        content="width=${kA4PageWidth.toInt()}, height=${kA4PageHeight.toInt()}"/>
  </head>
  <body>
    <p>$index / 3쪽 — A4 (${kA4PageWidth.toInt()}×${kA4PageHeight.toInt()})</p>
    <p>$body</p>
  </body>
</html>
''';
  return _zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': '''
<?xml version="1.0"?>
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
    <dc:title>Fixed Layout A4 데모 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:open-epub-demo-fixed-a4-0001</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
    <meta property="rendition:spread">none</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
    <item id="p3" href="p3.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="p1"/>
    <itemref idref="p2"/>
    <itemref idref="p3"/>
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
        <li><a href="p1.xhtml">1쪽</a></li>
        <li><a href="p2.xhtml">2쪽</a></li>
        <li><a href="p3.xhtml">3쪽</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
    'OEBPS/p1.xhtml': page(1, '표지 — 이 책은 페이지마다 A4 크기로 고정되어 있다.'),
    'OEBPS/p2.xhtml': page(2, '두 번째 페이지도 같은 논리 크기를 유지한다.'),
    'OEBPS/p3.xhtml': page(3, '마지막 페이지. 핀치 줌으로 확대/축소해 볼 수 있다.'),
  });
}
