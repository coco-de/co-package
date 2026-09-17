// Story: S13.6 (#103) — SMIL 미디어 오버레이 파서 (gap #6 파싱분)

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

const _smil = '''
<smil xmlns="http://www.w3.org/ns/SMIL" version="3.0">
  <body>
    <seq>
      <par>
        <text src="ch1.xhtml#s1"/>
        <audio src="ch1.mp3" clipBegin="0s" clipEnd="5.2s"/>
      </par>
      <par>
        <text src="ch1.xhtml#s2"/>
        <audio src="ch1.mp3" clipBegin="5.2s" clipEnd="0:10.5"/>
      </par>
    </seq>
  </body>
</smil>
''';

void main() {
  const parser = SmilParser();

  group('S13.6 — SmilParser.parse', () {
    test('par를 순서대로 평탄 추출 (text + audio + clip)', () {
      final mo = parser.parse(_smil);
      expect(mo.pars, hasLength(2));
      expect(mo.pars[0].textSrc, 'ch1.xhtml#s1');
      expect(mo.pars[0].audioSrc, 'ch1.mp3');
      expect(mo.pars[0].clipBegin, Duration.zero);
      expect(mo.pars[0].clipEnd, const Duration(milliseconds: 5200));
      expect(mo.pars[1].clipBegin, const Duration(milliseconds: 5200));
      expect(
          mo.pars[1].clipEnd, const Duration(seconds: 10, milliseconds: 500));
    });

    test('text 없는 par는 제외', () {
      const smil = '<smil xmlns="http://www.w3.org/ns/SMIL"><body>'
          '<par><audio src="a.mp3"/></par>'
          '<par><text src="ch.xhtml#x"/></par></body></smil>';
      final mo = parser.parse(smil);
      expect(mo.pars, hasLength(1));
      expect(mo.pars.first.textSrc, 'ch.xhtml#x');
    });

    test('audio 없는 par도 허용(텍스트만)', () {
      const smil = '<smil xmlns="http://www.w3.org/ns/SMIL"><body>'
          '<par><text src="ch.xhtml#x"/></par></body></smil>';
      final mo = parser.parse(smil);
      expect(mo.pars.single.audioSrc, isNull);
      expect(mo.pars.single.clipBegin, Duration.zero);
    });

    test('잘못된 XML은 empty', () {
      expect(parser.parse('<nope').isEmpty, isTrue);
    });
  });

  group('S13.6 — clock value 파싱', () {
    test('timecount: s/ms/min/h/bare', () {
      expect(SmilParser.parseClock('5.2s'), const Duration(milliseconds: 5200));
      expect(SmilParser.parseClock('234ms'), const Duration(milliseconds: 234));
      expect(SmilParser.parseClock('1.5min'), const Duration(seconds: 90));
      expect(SmilParser.parseClock('2h'), const Duration(hours: 2));
      expect(SmilParser.parseClock('12'), const Duration(seconds: 12));
    });

    test('clock notation: mm:ss / hh:mm:ss', () {
      expect(SmilParser.parseClock('02:03'),
          const Duration(minutes: 2, seconds: 3));
      expect(SmilParser.parseClock('1:02:03.5'),
          const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 500));
    });

    test('null/빈 값/비정상은 null', () {
      expect(SmilParser.parseClock(null), isNull);
      expect(SmilParser.parseClock(''), isNull);
      expect(SmilParser.parseClock('abc'), isNull);
    });
  });
}
