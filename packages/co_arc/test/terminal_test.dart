import 'package:co_arc/co_arc.dart';
import 'package:test/test.dart';

void main() {
  group('resetCursorKeyMode', () {
    test('DECCKM을 끄고 keypad를 numeric으로 되돌린다 (terminfo rmkx)', () {
      final out = StringBuffer();
      resetCursorKeyMode(out);

      // \x1b[?1l = DECCKM off. 이게 빠지면 자식(config.sh)이 켜 둔
      // application cursor key 모드가 남아 방향키가 SS3로 바뀐다.
      expect(out.toString(), contains('\x1b[?1l'));
      // \x1b> = keypad numeric. smkx가 켠 \x1b=의 짝이다.
      expect(out.toString(), contains('\x1b>'));
    });

    test('DECCKM을 켜는 시퀀스를 실수로 내보내지 않는다', () {
      // \x1b[?1h는 정반대(모드 ON)라 한 글자 오타로 버그를 되살린다.
      expect(normalCursorKeysSequence, isNot(contains('\x1b[?1h')));
      expect(normalCursorKeysSequence, isNot(contains('\x1b=')));
    });

    test('rmkx 두 시퀀스 외에는 아무 바이트도 섞이지 않는다', () {
      // _ScriptExitMsg 처리 중 커맨드로 나가므로 렌더 프레임 사이에 끼어든다.
      // 인쇄 가능한 문자가 하나라도 섞이면 그대로 화면에 찍혀 잔상이 남는다.
      final rest = normalCursorKeysSequence
          .replaceFirst('\x1b[?1l', '')
          .replaceFirst('\x1b>', '');
      expect(rest, isEmpty, reason: 'rmkx 외의 바이트가 섞였습니다: ${rest.codeUnits}');
    });

    test('시퀀스만 쓰고 다른 출력을 덧붙이지 않는다', () {
      final out = StringBuffer();
      resetCursorKeyMode(out);
      expect(out.toString(), normalCursorKeysSequence);
    });
  });
}
