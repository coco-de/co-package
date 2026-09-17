// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

/// fixedPen 회귀 방지 테스트.
///
/// PR #114, #117, #118, #121, #126, #131에서 반복적으로 수정된 5가지 핵심
/// 동작을 통합 단위 테스트로 잠궈둔다. 향후 동일 영역의 회귀를 즉시 검출.
void main() {
  PointerDownEvent stylusDown(double x, double y) =>
      PointerDownEvent(kind: PointerDeviceKind.stylus, position: Offset(x, y));

  Stroke? activeLineOf(ScribbleNotifier n) {
    final s = n.state;
    return s is Drawing ? s.activeLine : null;
  }

  group('FixedPen 회귀 방지 — 그릴 당시 화면 픽셀 두께 (#1, #3)', () {
    test('줌 1.0에서 슬라이더 4.0 → options.size == 4.0', () {
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(4.0);
      notifier.onPointerDown(stylusDown(10, 10), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.size, closeTo(4.0, 1e-9));
    });

    test('줌 2.0에서 슬라이더 4.0 → options.size == 2.0 (캔버스 좌표 보정)', () {
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setScaleFactor(2.0);
      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(4.0);
      notifier.onPointerDown(stylusDown(10, 10), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.size, closeTo(2.0, 1e-9));
    });

    test('서로 다른 줌 (0.5/1.0/2.0/3.0)에서 같은 슬라이더 → 화면 픽셀 동일', () {
      const slider = 6.0;
      for (final zoom in [0.5, 1.0, 2.0, 3.0]) {
        final notifier = ScribbleNotifier();
        final modeNotifier = ScribbleModeNotifier();
        addTearDown(notifier.dispose);
        addTearDown(modeNotifier.dispose);

        modeNotifier.setScaleFactor(zoom);
        modeNotifier.setFixedPen();
        modeNotifier.setStrokeWidth(slider);
        notifier.onPointerDown(stylusDown(0, 0), modeNotifier.state);

        final canvasSize = activeLineOf(notifier)!.options.size;
        // canvas 좌표 size * 줌 = 화면 픽셀 = 슬라이더 값
        expect(
          canvasSize * zoom,
          closeTo(slider, 1e-9),
          reason:
              'zoom=$zoom 에서 canvasSize($canvasSize) * scaleFactor 가 슬라이더($slider)와 같아야 한다',
        );
      }
    });
  });

  group('FixedPen 회귀 방지 — 균일 두께 (#4)', () {
    test('fixedPen으로 그릴 때 options.thinning == 0.0', () {
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(4.0);
      notifier.onPointerDown(stylusDown(10, 10), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.thinning, 0.0);
    });

    test('fixedPen으로 그릴 때 options.simulatePressure == false', () {
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(4.0);
      notifier.onPointerDown(stylusDown(10, 10), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.simulatePressure, isFalse);
    });

    test('pen 모드(thinning=0.7) vs fixedPen 모드(thinning=0.0) 분기 검증', () {
      final downEvent = stylusDown(10, 10);

      // pen
      final penNotifier = ScribbleNotifier();
      final penMode = ScribbleModeNotifier();
      addTearDown(penNotifier.dispose);
      addTearDown(penMode.dispose);
      penMode.setPen();
      penMode.setStrokeWidth(4.0);
      penNotifier.onPointerDown(downEvent, penMode.state);

      // fixedPen
      final fixedNotifier = ScribbleNotifier();
      final fixedMode = ScribbleModeNotifier();
      addTearDown(fixedNotifier.dispose);
      addTearDown(fixedMode.dispose);
      fixedMode.setFixedPen();
      fixedMode.setStrokeWidth(4.0);
      fixedNotifier.onPointerDown(downEvent, fixedMode.state);

      expect(activeLineOf(penNotifier)?.options.thinning, 0.7);
      expect(activeLineOf(fixedNotifier)?.options.thinning, 0.0);
    });

    test('fixedPen은 penOnly 모드와 무관하게 simulatePressure=false', () {
      // simulatePressure 공식: 균일 계열(fixedPen·uniformPen)이 아니고 입력
      // 기기가 하드웨어 필압을 주지 않을 때만 true (kobic UB-633 — 종전의
      // pointerMode 기준 판정을 대체) → fixedPen이면 항상 false
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setAllowedPointersMode(ScribblePointerMode.all);
      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(4.0);
      notifier.onPointerDown(stylusDown(10, 10), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.simulatePressure, isFalse);
    });
  });

  group('FixedPen 회귀 방지 — 슬라이더 즉시 반영 (#5, PR #118)', () {
    test('setFixedPen → setStrokeWidth(2) → 첫 stroke size=2', () {
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(2.0);
      notifier.onPointerDown(stylusDown(0, 0), modeNotifier.state);

      expect(activeLineOf(notifier)?.options.size, closeTo(2.0, 1e-9));
    });

    test('슬라이더 변경(2→8) 후 다음 stroke에 즉시 반영', () {
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(modeNotifier.dispose);

      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(2.0);

      final downEvent = stylusDown(0, 0);

      // 첫 스트로크
      final firstNotifier = ScribbleNotifier();
      addTearDown(firstNotifier.dispose);
      firstNotifier.onPointerDown(downEvent, modeNotifier.state);
      expect(activeLineOf(firstNotifier)?.options.size, closeTo(2.0, 1e-9));

      // 슬라이더 변경
      modeNotifier.setStrokeWidth(8.0);

      // 두 번째 스트로크
      final secondNotifier = ScribbleNotifier();
      addTearDown(secondNotifier.dispose);
      secondNotifier.onPointerDown(downEvent, modeNotifier.state);
      expect(activeLineOf(secondNotifier)?.options.size, closeTo(8.0, 1e-9));
    });

    test(
      '도구 전환 후 setStrokeWidth — fixedPen에 새 width 적용 (PR #118 order fix)',
      () {
        // PR #118: 도구 전환과 strokeWidth 설정 순서 fix
        // setPen → setStrokeWidth → setFixedPen → setStrokeWidth 시
        // 최종 fixedPen 모드에 마지막 width가 유지되어야 함
        final notifier = ScribbleNotifier();
        final modeNotifier = ScribbleModeNotifier();
        addTearDown(notifier.dispose);
        addTearDown(modeNotifier.dispose);

        modeNotifier.setPen();
        modeNotifier.setStrokeWidth(2.0);

        modeNotifier.setFixedPen();
        modeNotifier.setStrokeWidth(6.0);

        final inkInfo = modeNotifier.state.inkGroupInfo;
        expect(inkInfo.selectedInk, InkModes.fixedPen);
        expect(inkInfo.seletedStrokeWidth, 6.0);

        notifier.onPointerDown(stylusDown(0, 0), modeNotifier.state);
        expect(activeLineOf(notifier)?.options.size, closeTo(6.0, 1e-9));
      },
    );

    test('스트로크 생성은 modeState의 width를 매 호출마다 직접 읽는다', () {
      // setFixedPen 후 width를 여러 번 변경해도, onPointerDown 직전의 값이 사용되어야 함
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(modeNotifier.dispose);
      modeNotifier.setFixedPen();

      for (final width in [1.0, 3.5, 7.0, 12.0]) {
        modeNotifier.setStrokeWidth(width);

        final n = ScribbleNotifier();
        addTearDown(n.dispose);
        n.onPointerDown(stylusDown(0, 0), modeNotifier.state);

        expect(
          activeLineOf(n)?.options.size,
          closeTo(width, 1e-9),
          reason: 'width=$width 에서 onPointerDown 시 새 값이 즉시 반영되어야 한다',
        );
      }
    });
  });

  group('FixedPen 회귀 방지 — stroke.width 메타데이터 보존', () {
    test('생성된 stroke에 슬라이더 값이 stroke.width로 저장된다 (frozen 캡처)', () {
      // PR #126: 각 스트로크가 draw-time 픽셀 크기를 영속 보존
      final notifier = ScribbleNotifier();
      final modeNotifier = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(modeNotifier.dispose);

      modeNotifier.setScaleFactor(2.0);
      modeNotifier.setFixedPen();
      modeNotifier.setStrokeWidth(5.0);
      notifier.onPointerDown(stylusDown(0, 0), modeNotifier.state);

      final activeLine = activeLineOf(notifier);
      // stroke.width 는 슬라이더 값 자체 (zoom-invariant 의도 픽셀)
      expect(activeLine?.width, closeTo(5.0, 1e-9));
      // options.size 는 캔버스 좌표 보정값
      expect(activeLine?.options.size, closeTo(2.5, 1e-9));
    });
  });
}
