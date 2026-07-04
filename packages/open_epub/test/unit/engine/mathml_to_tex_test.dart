// Story: S14.2 (#106) — MathML → TeX 변환기 유닛 테스트 (gap #5)

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:open_epub/src/presentation/engine/reflowable/mathml_to_tex.dart';

void main() {
  group('mathmlToTex — presentation 변환', () {
    test('mn 숫자', () {
      expect(mathmlToTex(_math('<mn>2</mn>')), '2');
    });

    test('mi 식별자 + mo 연산자 juxtaposition', () {
      expect(
        mathmlToTex(_math('<mrow><mi>x</mi><mo>+</mo><mn>1</mn></mrow>')),
        'x + 1',
      );
    });

    test('mfrac → \\frac', () {
      expect(
        mathmlToTex(_math('<mfrac><mn>1</mn><mn>2</mn></mfrac>')),
        r'\frac{1}{2}',
      );
    });

    test('msup → 지수', () {
      expect(
        mathmlToTex(_math('<msup><mi>x</mi><mn>2</mn></msup>')),
        r'{x}^{2}',
      );
    });

    test('msub → 아래첨자', () {
      expect(
        mathmlToTex(_math('<msub><mi>a</mi><mn>1</mn></msub>')),
        r'{a}_{1}',
      );
    });

    test('msubsup → 아래+위 첨자', () {
      expect(
        mathmlToTex(
          _math('<msubsup><mi>x</mi><mn>1</mn><mn>2</mn></msubsup>'),
        ),
        r'{x}_{1}^{2}',
      );
    });

    test('msqrt / mroot', () {
      expect(mathmlToTex(_math('<msqrt><mn>2</mn></msqrt>')), r'\sqrt{2}');
      expect(
        mathmlToTex(_math('<mroot><mn>8</mn><mn>3</mn></mroot>')),
        r'\sqrt[3]{8}',
      );
    });

    test('그리스 문자·연산자 유니코드 매핑', () {
      expect(mathmlToTex(_math('<mi>π</mi>')), r'\pi'); // π
      expect(mathmlToTex(_math('<mo>×</mo>')), r'\times'); // ×
      expect(mathmlToTex(_math('<mo>≤</mo>')), r'\leq'); // ≤
      expect(mathmlToTex(_math('<mo>−</mo>')), '-'); // −(U+2212)
    });

    test('보이지 않는 연산자(InvisibleTimes)는 제거', () {
      // a ⁢ b (InvisibleTimes U+2062) → 'a b'
      final tex = mathmlToTex(
        _math('<mrow><mi>a</mi><mo>⁢</mo><mi>b</mi></mrow>'),
      );
      expect(tex, 'a b');
    });

    test('mfenced → \\left( ... \\right)', () {
      final tex = mathmlToTex(
        _math('<mfenced><mi>x</mi><mi>y</mi></mfenced>'),
      );
      expect(tex, r'\left( x, y \right)');
    });

    test('중첩 — 분수 안 지수', () {
      final tex = mathmlToTex(_math(
        '<mfrac><msup><mi>x</mi><mn>2</mn></msup><mn>2</mn></mfrac>',
      ));
      expect(tex, r'\frac{{x}^{2}}{2}');
    });
  });

  group('mathmlToTex — annotation / alttext 우선순위', () {
    test('annotation application/x-tex를 최우선 사용', () {
      final tex = mathmlToTex(_math(
        '<semantics><mrow><mi>x</mi></mrow>'
        '<annotation encoding="application/x-tex">\\frac{a}{b}</annotation>'
        '</semantics>',
      ));
      expect(tex, r'\frac{a}{b}');
    });

    test('presentation 변환 불가 시 alttext 폴백', () {
      // 자식 없는 math + alttext → 변환 비어서 alttext 사용
      expect(mathmlToTex(_mathRaw('<math alttext="E=mc^2"></math>')), 'E=mc^2');
    });
  });

  group('mathmlToTex — 폴백(null)', () {
    test('빈 math → null', () {
      expect(mathmlToTex(_mathRaw('<math></math>')), isNull);
    });

    test('공백만 있는 math → null', () {
      expect(mathmlToTex(_mathRaw('<math>   </math>')), isNull);
    });
  });
}

// -------- helpers --------

/// `<math>$inner</math>`를 파싱해 math 요소를 반환.
dom.Element _math(String inner) => _mathRaw('<math>$inner</math>');

dom.Element _mathRaw(String mathHtml) {
  final doc = html.parse(mathHtml);
  final el = doc.querySelector('math');
  if (el == null) {
    throw StateError('math element not found in: $mathHtml');
  }
  return el;
}
