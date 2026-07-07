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
