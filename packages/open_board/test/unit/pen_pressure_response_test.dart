// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/stroke_calculator.dart';
import 'package:open_board/src/module/stroke/pen_pressure_response.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';

/// 펜 필압 응답 규약 회귀 방지 (kobic UB-633 / unibook#12549).
///
/// "필압 감지가 미세하다(기기에 따라 차이 큼)" 는 보고의 원인은 평소 필기
/// 압력이 정규화 범위 아래쪽에 몰리는데 그것을 선형으로 두께에 옮긴 것이다.
/// Apple Pencil 은 `maximumPossibleForce` 가 약 4.17 이고 Apple 이 정의한
/// "평균 터치" 는 force 1.0 이라, 평소 필기가 정규화 0.24 근처가 된다.
void main() {
  // Apple Pencil 의 pressureMax(= UITouch.maximumPossibleForce)
  const applePencilMaxForce = 4.1666666666666667;

  // 종전 매핑 — 선형 곡선 + thinning 0.7 (비교 기준선)
  const legacyThinning = 0.7;

  double legacyRadius(double normalized) =>
      getStrokeRadius(1, legacyThinning, normalized);

  double newRadius(double normalized) => getStrokeRadius(
    1,
    PenPressureResponse.hardwareThinning,
    PenPressureResponse.curve.transform(normalized),
  );

  PointerDownEvent stylusDown({
    required double pressure,
    double pressureMax = 1.0,
    PointerDeviceKind kind = PointerDeviceKind.stylus,
  }) => PointerDownEvent(
    kind: kind,
    position: const Offset(10, 10),
    pressure: pressure,
    pressureMin: 0.0,
    pressureMax: pressureMax,
  );

  group('PenPressureCurve — 2차 ease-out', () {
    const curve = PenPressureCurve();

    test('양 끝을 보존한다 (0 → 0, 1 → 1)', () {
      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(1.0), 1.0);
    });

    test('정확한 식 1 - (1 - t)² 을 따른다', () {
      expect(curve.transform(0.5), closeTo(0.75, 1e-12));
      expect(curve.transform(0.24), closeTo(0.4224, 1e-12));
      expect(curve.transform(0.12), closeTo(0.2256, 1e-12));
    });

    test('단조 증가하고 입력보다 작아지지 않는다 (필압을 약하게 만들지 않음)', () {
      var previous = -1.0;
      for (var i = 0; i <= 100; i++) {
        final t = i / 100;
        final value = curve.transform(t);
        expect(value, greaterThan(previous), reason: 't=$t 에서 단조 증가 위반');
        expect(value, greaterThanOrEqualTo(t), reason: 't=$t 에서 입력보다 작음');
        previous = value;
      }
    });

    test('기기 척도가 2배 차이 나도 기록 필압 차이는 2배보다 작다', () {
      // 같은 손힘을 기기 A 는 t, 기기 B 는 2t 로 보고하는 경우
      for (final t in [0.06, 0.12, 0.24, 0.36, 0.48]) {
        final ratio = curve.transform(2 * t) / curve.transform(t);
        expect(ratio, lessThan(2.0), reason: 't=$t');
      }
    });
  });

  group('providesHardwarePressure — 실제 입력 기기로 판정', () {
    test('필압 범위를 보고하는 스타일러스는 하드웨어 필압이다', () {
      expect(
        PenPressureResponse.providesHardwarePressure(stylusDown(pressure: 0.3)),
        isTrue,
      );
    });

    test('뒤집은 스타일러스(지우개 끝)도 스타일러스 계열이다', () {
      expect(
        PenPressureResponse.providesHardwarePressure(
          stylusDown(pressure: 0.3, kind: PointerDeviceKind.invertedStylus),
        ),
        isTrue,
      );
    });

    test('필압 범위가 없는 스타일러스는 하드웨어 필압이 아니다', () {
      // pressureMin == pressureMax — 필압 하드웨어가 없는 스타일러스
      const event = PointerDownEvent(
        kind: PointerDeviceKind.stylus,
        position: Offset(10, 10),
      );

      expect(PenPressureResponse.providesHardwarePressure(event), isFalse);
    });

    test('손가락 터치는 필압 범위가 있어도 하드웨어 필압이 아니다', () {
      // Android 는 접촉 면적 기반 값을 0..1 필압으로 보고한다 — 필기 압력이 아니다
      expect(
        PenPressureResponse.providesHardwarePressure(
          stylusDown(pressure: 0.3, kind: PointerDeviceKind.touch),
        ),
        isFalse,
      );
    });

    test('마우스는 하드웨어 필압이 아니다', () {
      expect(
        PenPressureResponse.providesHardwarePressure(
          stylusDown(pressure: 0.5, kind: PointerDeviceKind.mouse),
        ),
        isFalse,
      );
    });
  });

  group('UB-633 회귀 — Apple Pencil 척도에서 필압이 드러난다', () {
    // force 는 Apple 정의 기준 — 1.0 이 평균 터치
    double normalizedForce(double force) => force / applePencilMaxForce;

    test('평균 필압(force 1.0)이 선택 굵기에 가깝게 그려진다', () {
      final typical = normalizedForce(1.0);

      // 종전: 반지름 0.318 × size → 지름이 선택 굵기의 약 64%
      expect(legacyRadius(typical), closeTo(0.318, 0.001));
      // 수정: 반지름 0.43 × size → 지름이 선택 굵기의 약 86%
      expect(newRadius(typical), closeTo(0.430, 0.001));
    });

    test('평소 필압 구간(force 0.5 → 1.5)의 두께 변화폭이 종전의 1.8배 이상이다', () {
      final light = normalizedForce(0.5);
      final firm = normalizedForce(1.5);

      final legacyDelta = legacyRadius(firm) - legacyRadius(light);
      final newDelta = newRadius(firm) - newRadius(light);

      expect(legacyDelta, closeTo(0.168, 0.001));
      expect(newDelta, greaterThanOrEqualTo(legacyDelta * 1.8));
    });

    test('가벼운 필압과 강한 필압의 대비가 종전보다 줄지 않는다', () {
      final light = normalizedForce(0.5);
      final firm = normalizedForce(1.5);

      final legacyContrast = legacyRadius(firm) / legacyRadius(light);
      final newContrast = newRadius(firm) / newRadius(light);

      expect(newContrast, greaterThanOrEqualTo(legacyContrast));
    });

    test('필압 0 에서도 스트로크가 사라지지 않는 하한을 남긴다', () {
      expect(newRadius(0.0), closeTo(0.05, 1e-12));
    });

    test('StrokeProcessor 가 Apple Pencil 이벤트를 곡선으로 기록한다', () {
      const processor = StrokeProcessor(
        pressureCurve: PenPressureResponse.curve,
      );

      final point = processor.createPointFromEvent(
        stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce),
      );

      expect(point.p, closeTo(0.4224, 1e-9));
    });
  });
}
