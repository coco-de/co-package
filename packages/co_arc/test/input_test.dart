import 'dart:async';

import 'package:co_arc/co_arc.dart';
import 'package:test/test.dart';

// 읽기 편하도록 바이트 별칭.
const esc = 0x1b;
const o = 0x4f; // 'O'
const bracket = 0x5b; // '['
const up = 0x41; // 'A'
const down = 0x42; // 'B'
const right = 0x43; // 'C'
const left = 0x44; // 'D'

void main() {
  group('Ss3ArrowRemapper.feed', () {
    late Ss3ArrowRemapper r;
    setUp(() => r = Ss3ArrowRemapper());

    test('AC1: SS3 화살표(ESC O A~D)를 CSI(ESC [ A~D)로 바꾼다', () {
      expect(r.feed([esc, o, up]), [esc, bracket, up]);
      expect(r.feed([esc, o, down]), [esc, bracket, down]);
      expect(r.feed([esc, o, right]), [esc, bracket, right]);
      expect(r.feed([esc, o, left]), [esc, bracket, left]);
      expect(r.hasPending, isFalse);
    });

    test('AC2: [ESC] + [O, A]로 갈라져 와도 ESC [ A로 합쳐진다', () {
      expect(r.feed([esc]), isEmpty); // 아직 판정 불가 — 보관
      expect(r.hasPending, isTrue);
      expect(r.feed([o, up]), [esc, bracket, up]);
      expect(r.hasPending, isFalse);
    });

    test('AC2: [ESC, O] + [A]로 갈라져 와도 ESC [ A로 합쳐진다', () {
      expect(r.feed([esc, o]), isEmpty); // ESC O까지만 — 보관
      expect(r.hasPending, isTrue);
      expect(r.feed([up]), [esc, bracket, up]);
      expect(r.hasPending, isFalse);
    });

    test('AC3: SS3 home·end·F1~F4는 변형 없이 통과한다', () {
      // H(home) F(end) P Q R S(F1~F4) — dart_tui가 이미 올바로 처리한다.
      for (final k in [0x48, 0x46, 0x50, 0x51, 0x52, 0x53]) {
        expect(Ss3ArrowRemapper().feed([esc, o, k]), [
          esc,
          o,
          k,
        ], reason: 'ESC O ${String.fromCharCode(k)}는 그대로여야 한다');
      }
    });

    test('AC4: 일반 글자는 바이트 그대로 통과한다', () {
      final bytes = 'jkqr'.codeUnits;
      expect(r.feed(bytes), bytes);
    });

    test('AC4: CSI 화살표(ESC [ A)는 손대지 않는다', () {
      // 이미 정상 모드 형식이라 그대로 통과 — 이중 변환 금지.
      expect(r.feed([esc, bracket, up]), [esc, bracket, up]);
    });

    test('AC4: bracketed paste 블록이 바이트 그대로 통과한다', () {
      // ESC [ 2 0 0 ~  ... 본문 ...  ESC [ 2 0 1 ~
      final paste = <int>[
        esc, bracket, 0x32, 0x30, 0x30, 0x7e, // \x1b[200~
        ...'hello world'.codeUnits,
        esc, bracket, 0x32, 0x30, 0x31, 0x7e, // \x1b[201~
      ];
      expect(r.feed(paste), paste);
    });

    test('lone ESC는 보관됐다가 flush로 원형 배출된다 (Escape 키 보존)', () {
      expect(r.feed([esc]), isEmpty);
      expect(r.hasPending, isTrue);
      // 이어지는 바이트가 없으면 lone Escape — 원형 그대로 흘려보낸다.
      expect(r.flush(), [esc]);
      expect(r.hasPending, isFalse);
      expect(r.flush(), isEmpty); // 비운 뒤엔 아무것도 없음
    });

    test('ESC O 뒤가 끊긴 채 스트림이 끝나면 flush가 ESC O를 배출한다', () {
      expect(r.feed([esc, o]), isEmpty);
      expect(r.flush(), [esc, o]);
    });

    test('화살표 뒤에 일반 바이트가 붙어도 한 청크에서 함께 처리된다', () {
      // ESC O A 다음 'x' — 화살표만 재매핑하고 나머지는 그대로.
      expect(r.feed([esc, o, up, 0x78]), [esc, bracket, up, 0x78]);
    });
  });

  group('remapSs3ArrowKeys (스트림)', () {
    test('스트림을 통과시키면 화살표는 재매핑되고 나머지는 보존된다', () async {
      final source = Stream<List<int>>.fromIterable([
        [esc, o, up], // 화살표 → 재매핑
        'jk'.codeUnits, // 글자 → 보존
        [esc, o, 0x48], // home → 통과
      ]);
      final collected = <int>[];
      await for (final chunk in remapSs3ArrowKeys(source)) {
        collected.addAll(chunk);
      }
      expect(collected, [
        esc, bracket, up, // ESC [ A
        ...'jk'.codeUnits,
        esc, o, 0x48, // ESC O H 그대로
      ]);
    });

    test('lone ESC는 flushDelay 뒤에 원형으로 배출된다', () async {
      // 화살표 조각이 이어지지 않으면 Escape 키로서 흘러나와야 한다.
      final source = Stream<List<int>>.fromIterable([
        [esc],
      ]);
      final collected = <int>[];
      await for (final chunk in remapSs3ArrowKeys(
        source,
        flushDelay: const Duration(milliseconds: 1),
      )) {
        collected.addAll(chunk);
      }
      expect(collected, [esc]);
    });
  });
}
