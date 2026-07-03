// Story: S12.3 (#96) — 재앵커 우선순위 charOffset→CFI + hot-swap 온디맨드 재앵커.
// ADR-010: charOffset이 anchor-of-record, CFI는 out-of-range 시 fuzzy fallback.

import 'dart:typed_data';

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/src/cfi/epub_cfi_mapper.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

void main() {
  const mapper = EpubCfiMapper();
  const extractor = SpineTextExtractor();

  group('S12.3 — clampCharOffset', () {
    const xhtml = '<html><body><p>hello</p></body></html>'; // plain "hello" (5)
    test('범위 밖은 길이로 clamp, 범위 내는 유지', () {
      expect(mapper.clampCharOffset(xhtml, 99), equals(5));
      expect(mapper.clampCharOffset(xhtml, 3), equals(3));
      expect(mapper.clampCharOffset(xhtml, -1), equals(0));
    });
  });

  group('S12.3 — reanchorAcrossContent (ADR-010 우선순위)', () {
    // old: 100 A + "TARGET" (2번째 문단). new: "AA" + "TARGET".
    final oldXhtml =
        '<html><body><p>${'A' * 100}</p><p>TARGET</p></body></html>';
    const newXhtml = '<html><body><p>AA</p><p>TARGET</p></body></html>';

    test('charOffset이 새 콘텐츠 범위 내면 그대로(anchor-of-record)', () {
      // 범위 내 offset은 CFI 개입 없이 유지
      expect(
        mapper.reanchorAcrossContent(
            oldXhtml: oldXhtml, oldCharOffset: 3, newXhtml: newXhtml),
        equals(3),
      );
    });

    test('out-of-range면 CFI가 구조적으로 재앵커(clamp보다 정확)', () {
      final oldPlain = extractor.extractPlainText(oldXhtml);
      final newPlain = extractor.extractPlainText(newXhtml);
      // old charOffset 102 = 2번째 문단 "TARGET"의 'R'
      expect(oldPlain[102], equals('R'));
      expect(102, greaterThan(newPlain.length)); // 새 콘텐츠(8)엔 범위 밖

      final reanchored = mapper.reanchorAcrossContent(
          oldXhtml: oldXhtml, oldCharOffset: 102, newXhtml: newXhtml);

      // 순진한 clamp라면 끝(8)로 갔겠지만, CFI는 같은 구조 위치('R')를 복원
      expect(newPlain[reanchored], equals('R'));
      expect(reanchored, equals(4)); // "AATARGET"[4] = 'R'
    });

    test('CFI 해석 불가(구조 불일치)면 clamp로 폴백', () {
      const noMatch = '<html><body><p>x</p></body></html>'; // plain "x" (1)
      final reanchored = mapper.reanchorAcrossContent(
          oldXhtml: oldXhtml, oldCharOffset: 102, newXhtml: noMatch);
      expect(reanchored, equals(1)); // 2번째 문단 없음 → clamp(102→1)
    });
  });

  group('S12.3 — 세션 hot-swap 재앵커 (F3-Edge2)', () {
    Uint8List epubWith(String bodyInner) => zipEpub({
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
    <dc:title>swap</dc:title><dc:identifier id="b">urn:uuid:swap</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>''',
          'OEBPS/nav.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body><nav '
                  'xmlns:epub="http://www.idpf.org/2007/ops" epub:type="toc">'
                  '<ol><li><a href="ch1.xhtml">1</a></li></ol></nav></body></html>',
          'OEBPS/ch1.xhtml':
              '<html xmlns="http://www.w3.org/1999/xhtml"><body>$bodyInner</body></html>',
        });

    test('out-of-range charOffset이 swap 후 새 콘텐츠 범위로 재앵커된다', () async {
      // old: 긴 첫 문단 + "TARGET"; new: 짧은 첫 문단 + "TARGET"
      final oldSrc =
          EpubSource.bytes(epubWith('<p>${'A' * 100}</p><p>TARGET</p>'));
      final newBytes = epubWith('<p>AA</p><p>TARGET</p>');

      final session = await EpubBookSession.open(oldSrc);
      // 2번째 문단 'R'(offset 102)로 이동 — old에선 유효
      await session.jumpTo(const EpubReflowablePosition(
        spineHref: 'ch1.xhtml',
        progress: 0.9,
        charOffset: 102,
      ));

      await session.swapSource(EpubSource.bytes(newBytes));

      final pos = session.position;
      expect(pos, isA<EpubReflowablePosition>());
      final reflow = pos as EpubReflowablePosition;
      expect(reflow.spineHref, equals('ch1.xhtml'));
      // 스테일 102가 아니라 새 콘텐츠(8) 범위로 재앵커
      final newPlain = extractor
          .extractPlainText('<html><body><p>AA</p><p>TARGET</p></body></html>');
      expect(reflow.charOffset, lessThanOrEqualTo(newPlain.length));
      expect(reflow.charOffset, equals(4)); // CFI로 'R' 복원
      await session.dispose();
    });

    test('open 시 out-of-range charOffset은 콘텐츠 길이로 clamp (F1-Edge2)', () async {
      // 저장된 위치의 charOffset이 (콘텐츠 변경 등으로) 현재 본문보다 크면
      // open 시 clamp된다. old 콘텐츠가 없으므로 CFI 아닌 clamp.
      final session = await EpubBookSession.open(
        EpubSource.bytes(epubWith('<p>AA</p><p>TARGET</p>')), // plain 8
        initialPosition: const EpubReflowablePosition(
          spineHref: 'ch1.xhtml',
          progress: 0.9,
          charOffset: 500, // 범위 밖
        ),
      );
      final reflow = session.position as EpubReflowablePosition;
      expect(reflow.spineHref, equals('ch1.xhtml'));
      expect(reflow.charOffset, equals(8)); // 평문 길이로 clamp
      await session.dispose();
    });

    test('동일 콘텐츠로 swap 시 charOffset 보존', () async {
      final body = '<p>${'A' * 100}</p><p>TARGET</p>';
      final session = await EpubBookSession.open(
        EpubSource.bytes(epubWith(body)),
      );
      await session.jumpTo(const EpubReflowablePosition(
        spineHref: 'ch1.xhtml',
        progress: 0.9,
        charOffset: 102,
      ));
      await session.swapSource(EpubSource.bytes(epubWith(body)));
      final reflow = session.position as EpubReflowablePosition;
      // 범위 내 → anchor-of-record 유지
      expect(reflow.charOffset, equals(102));
      await session.dispose();
    });
  });
}
