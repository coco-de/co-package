import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';

void main() {
  group('isWithinPinchScaleDeadZone (kobic #11816, UB-482)', () {
    test('제스처 시작 직후(누적 비율 1.0)는 dead-zone 이내다', () {
      expect(isWithinPinchScaleDeadZone(1), isTrue);
    });

    test('손끝 간격이 살짝 벌어져도(1% 확대) dead-zone 이내로 억제한다', () {
      expect(isWithinPinchScaleDeadZone(1.01), isTrue);
    });

    test('손끝 간격이 살짝 좁아져도(1% 축소) dead-zone 이내로 억제한다', () {
      expect(isWithinPinchScaleDeadZone(0.99), isTrue);
    });

    test('dead-zone 경계값(정확히 3%)은 포함하지 않는다 — 이내(exclusive) 판정', () {
      // (1.03 - 1).abs() == 0.03 == kPinchScaleDeadZone → `<` 이므로 false.
      expect(isWithinPinchScaleDeadZone(1.03), isFalse);
    });

    test('dead-zone 을 명확히 넘는 확대(10%)는 핀치로 인정한다', () {
      expect(isWithinPinchScaleDeadZone(1.1), isFalse);
    });

    test('dead-zone 을 명확히 넘는 축소(10%)는 핀치로 인정한다', () {
      expect(isWithinPinchScaleDeadZone(0.9), isFalse);
    });

    test('deadZone 파라미터를 직접 지정하면 그 값을 기준으로 판정한다', () {
      // 기본 3%로는 통과(false)할 5% 편차도, 임계값을 10%로 넓히면
      // dead-zone 이내(true)로 판정되어야 한다 — 파라미터가 실제로
      // 판정에 반영됨을 회귀로 고정한다.
      const wideDeadZone = 0.1;
      expect(isWithinPinchScaleDeadZone(1.05), isFalse);
      expect(isWithinPinchScaleDeadZone(1.05, deadZone: wideDeadZone), isTrue);
    });
  });
}
