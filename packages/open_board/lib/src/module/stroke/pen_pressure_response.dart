// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// 스타일러스 하드웨어 필압을 스트로크 두께로 옮기는 응답 규약
/// (kobic UB-633 / unibook#12549).
///
/// ## 왜 선형이 아닌가
///
/// 기기가 보고하는 필압은 척도가 기기마다 다르다. Flutter iOS 엔진은
/// `UITouch.force` 를 `pressure` 로, `maximumPossibleForce` 를 `pressureMax`
/// 로 그대로 넘기고(`FlutterViewController.mm`), Android 는
/// `MotionEvent.getPressure()` 와 그 기기의 `AXIS_PRESSURE` 범위를 넘긴다
/// (`AndroidTouchProcessor.java`). 이 패키지는 둘 다
/// `(pressure - min) / (max - min)` 으로 정규화한다.
///
/// Apple 은 `force == 1.0` 을 "평균적인 터치" 로 정의하고, Apple Pencil 의
/// `maximumPossibleForce` 는 약 4.17 이다. 그래서 iPad 에서는 **평소 필기가
/// 정규화 범위의 약 24% 에 몰린다** — Apple 프레임워크 엔지니어가
/// `maximumPossibleForce` 로 나누지 말라고 권고한 바로 그 형태다
/// (https://developer.apple.com/forums/thread/31775).
/// 선형 매핑 + thinning 0.7 에서는 이 구간이 선택한 굵기의 약 64% 로
/// 그려지고, 필압을 바꿔도 두께 차이가 1px 안팎에 그친다 — "펜 필압 감지가
/// 미세하다(기기에 따라 차이 큼)" 는 보고(UB-633)의 원인이다.
///
/// ## 응답 곡선
///
/// [PenPressureCurve] 는 2차 ease-out(`1 - (1 - t)²`)이다.
/// - 낮은 필압에서 기울기가 2 — 평소 필기 구간의 두께 변화를 키운다
/// - 1 에 가까울수록 기울기가 0 으로 줄어 **포화 없이** 끝까지 변한다
/// - 기기 간 척도 차이(곱셈)를 줄인다 — 평소 필기 구간에서 2배 차이가
///   약 1.7~1.9배로 좁혀진다
///
/// Apple Pencil 평균 필압(정규화 0.24)은 0.42 로 기록되어, [hardwareThinning]
/// 과 함께 선택한 굵기의 약 86% 로 그려진다(종전 64%).
///
/// ## 적용 시점 — 입력을 기록할 때만
///
/// 곡선은 포인트를 **기록할 때** 적용되고 thinning 은 스트로크에 저장된다.
/// 렌더 공식(`getStrokeRadius`)은 바꾸지 않으므로 이미 저장된 필기는 모양이
/// 바뀌지 않는다.
abstract final class PenPressureResponse {
  /// 하드웨어 필압으로 그린 펜 스트로크의 thinning.
  ///
  /// 곡선이 평소 필기를 선택 굵기 근처로 올리므로, 가벼운 필압과 강한 필압의
  /// 대비가 종전보다 줄지 않도록 필압이 두께에 미치는 폭을 넓힌다. 필압 0 의
  /// 반지름은 `size × 0.05` 로, 스트로크 시작이 사라지지 않는 하한을 남긴다.
  static const double hardwareThinning = 0.9;

  /// 필압이 없어 속도로 흉내 내는 펜 스트로크의 thinning (종전 값 유지).
  static const double simulatedThinning = 0.7;

  /// 하드웨어 필압 응답 곡선.
  static const Curve curve = PenPressureCurve();

  /// [event] 가 하드웨어 필압을 제공하는가.
  ///
  /// 판정은 **포인터 모드가 아니라 실제 입력 기기**로 한다. 스타일러스
  /// 계열이면서 기기가 필압 범위를 보고할 때만 참이다.
  /// - 손가락 터치: Android 는 접촉 면적 기반 값을 필압으로 보고하지만 필기
  ///   압력이 아니다 → 속도 시뮬레이션 대상
  /// - 범위가 없는 스타일러스(`pressureMin == pressureMax`): 필압 하드웨어가
  ///   없다 → 속도 시뮬레이션 대상. 균일선으로 두면 '필압 감지' 가 아무 일도
  ///   하지 않는다
  /// - 웹의 hover: 필압이 정의되지 않는다
  static bool providesHardwarePressure(PointerEvent event) {
    if (kIsWeb && event is PointerHoverEvent) return false;
    final isStylus =
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    return isStylus && event.pressureMax > event.pressureMin;
  }
}

/// 스타일러스 필압 응답 곡선 — 2차 ease-out `1 - (1 - t)²`.
///
/// [Curves.easeOutQuad] 는 3차 베지어 근사라 값이 조금 다르다. 저장되는
/// 필압이 이 곡선으로 결정되므로 정확한 식을 쓴다.
class PenPressureCurve extends Curve {
  const PenPressureCurve();

  @override
  double transformInternal(double t) {
    final rest = 1 - t;

    return 1 - rest * rest;
  }
}
