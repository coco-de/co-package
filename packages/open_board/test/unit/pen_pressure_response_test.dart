// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
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
/// "평균 터치" 는 force 1.0 이라, `maximumPossibleForce` 로 나누면 평소
/// 필기가 정규화 0.24 근처가 된다.
///
/// 재보고(2026-09-22, 1.947.0): 곡선만으로는 iPad 가 여전히 균일선이었다.
/// 그래서 iOS 는 `force` 를 Apple 정의대로 절대값으로 읽는다 —
/// `force / appleFullScaleForce(2.0)` 로 평균 터치를 0.5 에 둔다. 이 파일의
/// 마지막 두 그룹이 그 축을 고정한다 (Android 기록값 불변 포함).
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

  group('UB-633 1차 — maximumPossibleForce 비율 매핑 위에서도 곡선이 필압을 키운다', () {
    // 이 그룹은 곡선 자체의 효과를 **비율 매핑**(Android·웹 경로와 같은
    // 식) 위에서 고정한다. iOS 는 이제 이 매핑을 타지 않는다 — 아래
    // 'UB-633 재보고' 그룹 참조. 수치는 1차 수정(PR #290) 당시의 근거다.
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

    test('iOS 가 아닌 플랫폼은 pressureMax 비율을 곡선에 태운다', () {
      // flutter_test 의 기본 플랫폼은 Android — 비율 경로다.
      expect(defaultTargetPlatform, isNot(TargetPlatform.iOS));
      const processor = StrokeProcessor(
        pressureCurve: PenPressureResponse.curve,
      );

      final point = processor.createPointFromEvent(
        stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce),
      );

      expect(point.p, closeTo(0.4224, 1e-9));
    });
  });

  group('reportsAppleForceUnits · normalize — 플랫폼별 척도 해석', () {
    void runOnIos() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    }

    test('iOS 에서 pressureMax > 1 인 스타일러스는 Apple force 단위다', () {
      runOnIos();
      expect(
        PenPressureResponse.reportsAppleForceUnits(
          stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce),
        ),
        isTrue,
      );
    });

    test('iOS 라도 pressureMax == 1 이면 이미 정규화된 값 — 이중 보정하지 않는다', () {
      runOnIos();
      final event = stylusDown(pressure: 0.3);

      expect(PenPressureResponse.reportsAppleForceUnits(event), isFalse);
      expect(PenPressureResponse.normalize(event), closeTo(0.3, 1e-12));
    });

    test('iOS 가 아니면 pressureMax 가 커도 비율 매핑이다 (Android 불변)', () {
      expect(defaultTargetPlatform, isNot(TargetPlatform.iOS));
      final event = stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce);

      expect(PenPressureResponse.reportsAppleForceUnits(event), isFalse);
      expect(
        PenPressureResponse.normalize(event),
        closeTo(1.0 / applePencilMaxForce, 1e-12),
      );
    });

    test('Android S Pen 값은 종전 그대로 통과한다 (기록값 불변)', () {
      for (final pressure in [0.0, 0.1, 0.3, 0.5, 0.75, 1.0]) {
        final event = stylusDown(pressure: pressure);
        // 종전 식과 정확히 같아야 한다 — 이 축이 흔들리면 Galaxy 필기가 바뀐다
        final legacy = (event.pressure - event.pressureMin) /
            (event.pressureMax - event.pressureMin);

        expect(
          PenPressureResponse.normalize(event),
          legacy,
          reason: 'p=$pressure',
        );
      }
    });

    test('Android 의 범위 초과·미만 값은 [0, 1] 로 클램프된다', () {
      expect(PenPressureResponse.normalize(stylusDown(pressure: 1.2)), 1.0);
      expect(PenPressureResponse.normalize(stylusDown(pressure: -0.1)), 0.0);
    });

    test('iOS: 평균 터치(force 1.0)가 정확히 0.5 에 놓인다', () {
      runOnIos();
      expect(
        PenPressureResponse.normalize(
          stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce),
        ),
        closeTo(0.5, 1e-12),
      );
    });

    test('iOS: appleFullScaleForce 이상은 1.0 으로 포화하고 0 은 0 이다', () {
      runOnIos();
      double n(double force) => PenPressureResponse.normalize(
        stylusDown(pressure: force, pressureMax: applePencilMaxForce),
      );

      expect(n(0.0), 0.0);
      expect(n(PenPressureResponse.appleFullScaleForce), 1.0);
      expect(n(applePencilMaxForce), 1.0);
      expect(n(0.5), closeTo(0.25, 1e-12));
    });
  });

  group('UB-633 재보고 — iPad 필압이 Galaxy S Pen 과 같은 자리에서 벌어진다', () {
    void runOnIos() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    }

    // 종전(1차 수정) iOS 매핑 — maximumPossibleForce 비율 위의 곡선
    double previousIosRadius(double force) => getStrokeRadius(
      1,
      PenPressureResponse.hardwareThinning,
      PenPressureResponse.curve.transform(force / applePencilMaxForce),
    );

    double iosRadius(double force) => getStrokeRadius(
      1,
      PenPressureResponse.hardwareThinning,
      PenPressureResponse.curve.transform(
        PenPressureResponse.normalize(
          stylusDown(pressure: force, pressureMax: applePencilMaxForce),
        ),
      ),
    );

    test('iPad 평균 필기(force 1.0)와 S Pen 중간 필압(0.5)이 같은 두께로 기록된다', () {
      const processor = StrokeProcessor(
        pressureCurve: PenPressureResponse.curve,
      );
      // Android(기본 플랫폼) S Pen 중간 필압
      final sPen = processor.createPointFromEvent(stylusDown(pressure: 0.5));

      runOnIos();
      final pencil = processor.createPointFromEvent(
        stylusDown(pressure: 1.0, pressureMax: applePencilMaxForce),
      );

      expect(pencil.p, closeTo(0.75, 1e-12));
      expect(pencil.p, closeTo(sPen.p, 1e-12));
      // 종전 iOS 기록값(0.4224)과 **다르다** — 분리의 직접 증거
      expect(pencil.p, isNot(closeTo(0.4224, 1e-3)));
    });

    test('평소 필압 구간(force 0.5 → 1.5)의 두께 변화폭이 1차 수정보다 넓다', () {
      runOnIos();
      final previousDelta = previousIosRadius(1.5) - previousIosRadius(0.5);
      final delta = iosRadius(1.5) - iosRadius(0.5);

      expect(previousDelta, closeTo(0.328, 0.001));
      expect(delta, closeTo(0.45, 0.001));
      expect(delta, greaterThan(previousDelta * 1.3));
    });

    test('세게(force 2.0 = 평균의 2배)가 최대 두께에 닿는다 — 종전엔 4.17 이 필요했다', () {
      runOnIos();
      // 종전: force 2.0 은 반지름 0.71 — 최대(0.95)에 못 미치고 4.17 에서야 닿았다
      expect(previousIosRadius(2.0), closeTo(0.707, 0.001));
      expect(previousIosRadius(applePencilMaxForce), closeTo(0.95, 1e-9));
      // 수정: 평균의 2배에서 최대 두께
      expect(iosRadius(2.0), closeTo(0.95, 1e-12));
    });

    test('가볍게(force 0.3)는 여전히 가늘고, 가볍게↔세게의 두께 폭은 종전보다 넓다', () {
      runOnIos();
      // 가벼운 필압이 굵어져 대비를 잃지 않는다 (선택 굵기의 60% 이하)
      expect(iosRadius(0.3), lessThanOrEqualTo(0.30));
      // 반지름 폭(세게 − 가볍게): 종전 0.53 → 0.65
      final previousSpan = previousIosRadius(2.0) - previousIosRadius(0.3);
      final span = iosRadius(2.0) - iosRadius(0.3);
      expect(previousSpan, closeTo(0.531, 0.001));
      expect(span, closeTo(0.650, 0.001));
      expect(span, greaterThan(previousSpan));
    });
  });
}
