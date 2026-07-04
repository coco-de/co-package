// Story: S15.1 (#112) — Media Overlay 배선 (manifest→SMIL→spine) 테스트
// gap #6 배선분

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:open_epub_engine/testing.dart';
import 'package:test/test.dart';

void main() {
  group('S15.1 — OpfParser: manifest media-overlay → spine.mediaOverlayHref', () {
    const parser = OpfParser();

    test('media-overlay 속성이 SMIL href로 해석되어 spine에 채워진다', () {
      const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title>
    <dc:identifier id="bookid">urn:x</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"
        media-overlay="c1_mo"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c1_mo" href="smil/ch1.smil" media-type="application/smil+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''';
      final result = parser.parse(opf);
      final ch1 = result.spine[0];
      final ch2 = result.spine[1];
      expect(ch1.mediaOverlayHref, 'smil/ch1.smil');
      expect(ch2.mediaOverlayHref, isNull); // MO 없음 회귀
    });

    test('media-overlay가 없으면 mediaOverlayHref는 null', () {
      final result = parser.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title><dc:identifier id="b">x</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''');
      expect(result.spine.single.mediaOverlayHref, isNull);
    });

    test('깨진 media-overlay id(해당 manifest 없음)는 null로 안전 처리', () {
      final result = parser.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="b">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>t</dc:title><dc:identifier id="b">x</dc:identifier>
  </metadata>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"
        media-overlay="missing"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''');
      expect(result.spine.single.mediaOverlayHref, isNull);
    });
  });

  group('S15.1 — session.loadMediaOverlay (온디맨드 SMIL 로드·파싱·경로 정규화)', () {
    test('MO spine → par 목록 반환, src는 OPF 기준 상대로 정규화', () async {
      final session =
          await EpubBookSession.open(EpubSource.bytes(mediaOverlayEpub3()));
      addTearDown(session.dispose);

      // capabilities는 MO 존재를 신호한다(S13.3).
      expect(session.capabilities.hasMediaOverlay, isTrue);

      final overlay = await session.loadMediaOverlay('ch1.xhtml');
      expect(overlay.isEmpty, isFalse);
      expect(overlay.pars, hasLength(2));

      final p0 = overlay.pars[0];
      // SMIL이 smil/ 하위 → ../ch1.xhtml#s1 → OPF 기준 'ch1.xhtml#s1'
      expect(p0.textSrc, 'ch1.xhtml#s1');
      expect(p0.audioSrc, 'audio/ch1.mp3');
      expect(p0.clipBegin, Duration.zero);
      expect(p0.clipEnd, const Duration(milliseconds: 2500));

      final p1 = overlay.pars[1];
      expect(p1.textSrc, 'ch1.xhtml#s2');
      expect(p1.clipBegin, const Duration(milliseconds: 2500));
      expect(p1.clipEnd, const Duration(seconds: 5));
    });

    test('정규화된 audioSrc는 resources.readBytes로 바로 읽을 수 있다', () async {
      final session =
          await EpubBookSession.open(EpubSource.bytes(mediaOverlayEpub3()));
      addTearDown(session.dispose);
      final overlay = await session.loadMediaOverlay('ch1.xhtml');
      final bytes = session.resources.readBytes(overlay.pars.first.audioSrc!);
      expect(bytes, isNotNull);
    });

    test('MO 없는 spine → empty', () async {
      final session =
          await EpubBookSession.open(EpubSource.bytes(mediaOverlayEpub3()));
      addTearDown(session.dispose);
      final overlay = await session.loadMediaOverlay('ch2.xhtml');
      expect(overlay.isEmpty, isTrue);
    });

    test('MO 없는 일반 책 → empty (회귀)', () async {
      final session = await EpubBookSession.open(EpubSource.bytes(validEpub3()));
      addTearDown(session.dispose);
      final overlay = await session.loadMediaOverlay('ch1.xhtml');
      expect(overlay.isEmpty, isTrue);
      expect(session.capabilities.hasMediaOverlay, isFalse);
    });
  });
}
