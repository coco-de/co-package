// Story: S12.4 (#97) — 외부 CFI interop: EpubReflowablePosition ↔ 표준 전체-책 CFI.

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

Uint8List _twoChapterEpub() => zipEpub({
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
    <dc:title>interop</dc:title><dc:identifier id="b">urn:uuid:interop</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/><itemref idref="c2"/></spine>
</package>''',
      'OEBPS/nav.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body><nav '
              'xmlns:epub="http://www.idpf.org/2007/ops" epub:type="toc"><ol>'
              '<li><a href="ch1.xhtml">1</a></li>'
              '<li><a href="ch2.xhtml">2</a></li></ol></nav></body></html>',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>Chapter one intro text</p></body></html>',
      'OEBPS/ch2.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<h2>Second</h2><p>Hello brave new world.</p></body></html>',
    });

void main() {
  const extractor = SpineTextExtractor();

  group('S12.4 — export/import round-trip', () {
    late EpubBookSession session;

    setUp(() async {
      session = await EpubBookSession.open(EpubSource.bytes(_twoChapterEpub()));
    });
    tearDown(() => session.dispose());

    test('ch2 위치 export → 표준 형식 CFI', () {
      final ch2 = session.readSpineXhtml('ch2.xhtml')!;
      final plain = extractor.extractPlainText(ch2);
      final off = plain.indexOf('world');
      final cfi = session.exportPositionCfi(EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 1,
        charOffset: off,
      ));
      expect(cfi, isNotNull);
      // ch2 = spineIndex 1 → /6/4[c2]!, indirection 포함
      expect(cfi, startsWith('epubcfi(/6/4[c2]!'));
      expect(cfi, contains('!'));
    });

    test('export → import 왕복이 spineHref + charOffset 보존', () {
      final ch2 = session.readSpineXhtml('ch2.xhtml')!;
      final plain = extractor.extractPlainText(ch2);
      final off = plain.indexOf('world');
      final original = EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 1,
        charOffset: off,
      );
      final cfi = session.exportPositionCfi(original)!;
      final back = session.importPositionCfi(cfi);
      expect(back, isNotNull);
      expect(back!.spineHref, equals('ch2.xhtml'));
      expect(back.charOffset, equals(off));
      expect(plain.substring(back.charOffset, back.charOffset + 5),
          equals('world'));
    });

    test('ch1(spineIndex 0) → /6/2 형식', () {
      final cfi = session.exportPositionCfi(const EpubReflowablePosition(
        spineHref: 'ch1.xhtml',
        progress: 0,
        charOffset: 0,
      ));
      expect(cfi, startsWith('epubcfi(/6/2[c1]!'));
      final back = session.importPositionCfi(cfi!);
      expect(back!.spineHref, equals('ch1.xhtml'));
    });
  });

  group('S12.4 — import 실패/폴백', () {
    late EpubBookSession session;
    setUp(() async {
      session = await EpubBookSession.open(EpubSource.bytes(_twoChapterEpub()));
    });
    tearDown(() => session.dispose());

    test('spine step 없는 문서-내 CFI는 null', () {
      expect(session.importPositionCfi('epubcfi(/4/2:3)'), isNull);
    });

    test('잘못된 CFI는 null', () {
      expect(session.importPositionCfi('nonsense'), isNull);
    });

    test('idref 폴백: step index가 범위 밖이어도 [idref]로 매칭', () {
      // 실제 ch2 CFI에서 spine step 숫자만 범위 밖(998)으로 손상 → 문서 경로는
      // 유효하게 유지. index로는 못 찾지만 [c2] idref로 ch2를 복원해야 한다.
      final real = session.exportPositionCfi(const EpubReflowablePosition(
        spineHref: 'ch2.xhtml',
        progress: 1,
        charOffset: 0,
      ))!;
      final tampered = real.replaceFirst('/6/4[c2]!', '/6/998[c2]!');
      final back = session.importPositionCfi(tampered);
      expect(back, isNotNull);
      expect(back!.spineHref, equals('ch2.xhtml'));
    });
  });
}
