// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/stroke/pen_pressure_response.dart';

/// 펜 스트로크의 필압 옵션이 **실제 입력 기기**로 정해지는지 검증한다
/// (kobic UB-633 / unibook#12549).
///
/// 종전에는 `allowedPointersMode != penOnly` 로 가짜(속도 기반) 필압을 켜서
/// - 손·펜 겸용 모드의 스타일러스는 하드웨어 필압이 버려졌고
/// - 펜 전용 모드의 필압 없는 스타일러스는 균일선이 됐다.
void main() {
  PointerDownEvent down({
    required PointerDeviceKind kind,
    double pressure = 1.0,
    double pressureMin = 1.0,
    double pressureMax = 1.0,
  }) => PointerDownEvent(
    kind: kind,
    position: const Offset(10, 10),
    pressure: pressure,
    pressureMin: pressureMin,
    pressureMax: pressureMax,
  );

  // 필압 범위를 보고하는 스타일러스 (Galaxy S Pen 척도)
  PointerDownEvent pressureStylus({double pressure = 0.3}) => down(
    kind: PointerDeviceKind.stylus,
    pressure: pressure,
    pressureMin: 0.0,
  );

  Stroke? activeLineOf(ScribbleNotifier n) {
    final s = n.state;

    return s is Drawing ? s.activeLine : null;
  }

  Stroke? drawPenStroke(
    PointerDownEvent event, {
    required ScribblePointerMode pointerMode,
    void Function(ScribbleModeNotifier)? selectInk,
  }) {
    final notifier = ScribbleNotifier();
    final modeNotifier = ScribbleModeNotifier();
    addTearDown(notifier.dispose);
    addTearDown(modeNotifier.dispose);

    modeNotifier.setAllowedPointersMode(pointerMode);
    if (selectInk != null) {
      selectInk(modeNotifier);
    } else {
      modeNotifier.setPen();
    }
    modeNotifier.setStrokeWidth(4.0);
    notifier.onPointerDown(event, modeNotifier.state);

    return activeLineOf(notifier);
  }

  group('펜 — 하드웨어 필압 스타일러스', () {
    test('펜 전용 모드: 하드웨어 필압을 쓰고 응답 thinning 을 저장한다', () {
      final line = drawPenStroke(
        pressureStylus(),
        pointerMode: ScribblePointerMode.penOnly,
      );

      expect(line?.options.simulatePressure, isFalse);
      expect(line?.options.thinning, PenPressureResponse.hardwareThinning);
    });

    test('손·펜 겸용 모드에서도 스타일러스는 하드웨어 필압을 쓴다', () {
      // 종전에는 이 경로가 simulatePressure=true 였다 — 스타일러스 필압이
      // 버려지고 속도로만 두께가 변했다.
      final line = drawPenStroke(
        pressureStylus(),
        pointerMode: ScribblePointerMode.all,
      );

      expect(line?.options.simulatePressure, isFalse);
      expect(line?.options.thinning, PenPressureResponse.hardwareThinning);
    });

    test('첫 포인트의 필압이 응답 곡선으로 기록된다', () {
      final line = drawPenStroke(
        pressureStylus(pressure: 0.3),
        pointerMode: ScribblePointerMode.penOnly,
      );

      expect(
        line?.points.first.p,
        closeTo(PenPressureResponse.curve.transform(0.3), 1e-9),
      );
    });
  });

  group('펜 — 하드웨어 필압이 없는 입력', () {
    test('펜 전용 모드의 필압 없는 스타일러스는 속도로 필압을 흉내 낸다', () {
      // 종전에는 simulatePressure=false + 고정 필압 0.5 → 균일선이었다
      final line = drawPenStroke(
        down(kind: PointerDeviceKind.stylus),
        pointerMode: ScribblePointerMode.penOnly,
      );

      expect(line?.options.simulatePressure, isTrue);
      expect(line?.options.thinning, PenPressureResponse.simulatedThinning);
    });

    test('필압 없는 입력의 기록 필압은 중립값 0.5 그대로다', () {
      final line = drawPenStroke(
        down(kind: PointerDeviceKind.stylus),
        pointerMode: ScribblePointerMode.penOnly,
      );

      expect(line?.points.first.p, 0.5);
    });

    test('손가락 터치는 필압 범위가 있어도 속도로 흉내 낸다 (종전과 동일)', () {
      final line = drawPenStroke(
        down(kind: PointerDeviceKind.touch, pressure: 0.3, pressureMin: 0.0),
        pointerMode: ScribblePointerMode.all,
      );

      expect(line?.options.simulatePressure, isTrue);
      expect(line?.options.thinning, PenPressureResponse.simulatedThinning);
      // 터치 필압은 곡선을 태우지 않는다 — 시뮬레이션 시작값을 보존한다
      expect(line?.points.first.p, closeTo(0.3, 1e-9));
    });

    test('마우스는 속도로 흉내 낸다 (종전과 동일)', () {
      final line = drawPenStroke(
        down(kind: PointerDeviceKind.mouse),
        pointerMode: ScribblePointerMode.all,
      );

      expect(line?.options.simulatePressure, isTrue);
      expect(line?.options.thinning, PenPressureResponse.simulatedThinning);
    });
  });

  group('균일 계열은 필압과 무관하다 (#7160 회귀 방지)', () {
    test('uniformPen 은 하드웨어 필압 스타일러스여도 균일 두께다', () {
      final line = drawPenStroke(
        pressureStylus(),
        pointerMode: ScribblePointerMode.penOnly,
        selectInk: (m) => m.setUniformPen(),
      );

      expect(line?.options.thinning, 0.0);
      expect(line?.options.simulatePressure, isFalse);
    });

    test('fixedPen 은 하드웨어 필압 스타일러스여도 균일 두께다', () {
      final line = drawPenStroke(
        pressureStylus(),
        pointerMode: ScribblePointerMode.penOnly,
        selectInk: (m) => m.setFixedPen(),
      );

      expect(line?.options.thinning, 0.0);
      expect(line?.options.simulatePressure, isFalse);
    });
  });
}
