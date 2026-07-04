// Story: S15.4 (#111) — 세로쓰기 조판 헬퍼 유닛 테스트 (gap #4 조판분)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/reflowable/vertical_text_block.dart';

void main() {
  group('verticalColumns', () {
    test('vertical-rl: 첫 글자 컬럼이 오른쪽(리스트 끝)', () {
      // '12345', perColumn 2 → chunks [12][34][5], vertical-rl 시각순=역순
      final cols = verticalColumns('12345', 2);
      expect(cols, ['5', '34', '12']); // 좌→우: 마지막 글자 컬럼이 왼쪽
    });

    test('vertical-lr: 첫 글자 컬럼이 왼쪽(리스트 시작)', () {
      final cols = verticalColumns('12345', 2, leftToRight: true);
      expect(cols, ['12', '34', '5']);
    });

    test('빈 텍스트 → [\'\']', () {
      expect(verticalColumns('', 3), ['']);
    });

    test('perColumn 0 이하는 1로 클램프', () {
      expect(verticalColumns('ab', 0), ['b', 'a']); // step 1, vertical-rl 역순
    });

    test('CJK 문자(rune 단위) 분할', () {
      final cols = verticalColumns('가나다', 2, leftToRight: true);
      expect(cols, ['가나', '다']);
    });
  });

  group('declaresVerticalWriting / isVerticalLr', () {
    test('vertical-rl 인라인 선언 감지', () {
      expect(
        declaresVerticalWriting('<body style="writing-mode: vertical-rl">'),
        isTrue,
      );
      expect(isVerticalLr('<body style="writing-mode: vertical-rl">'), isFalse);
    });

    test('vertical-lr 감지', () {
      expect(declaresVerticalWriting('writing-mode:vertical-lr'), isTrue);
      expect(isVerticalLr('writing-mode:vertical-lr'), isTrue);
    });

    test('horizontal-tb / 미선언은 false', () {
      expect(declaresVerticalWriting('writing-mode: horizontal-tb'), isFalse);
      expect(declaresVerticalWriting('<p>일반 본문</p>'), isFalse);
    });

    test('대소문자/공백 무관', () {
      expect(
        declaresVerticalWriting('WRITING-MODE : VERTICAL-RL'),
        isTrue,
      );
    });
  });

  group('isSimpleTextContent', () {
    test('텍스트만 → true', () {
      expect(isSimpleTextContent('<p>본문 텍스트</p>'), isTrue);
    });

    test('이미지/SVG/수식/표 있으면 false(가로 폴백)', () {
      expect(isSimpleTextContent('<p>x</p><img src="a.png"/>'), isFalse);
      expect(isSimpleTextContent('<svg></svg>'), isFalse);
      expect(isSimpleTextContent('<math></math>'), isFalse);
      expect(isSimpleTextContent('<table></table>'), isFalse);
    });
  });
}
