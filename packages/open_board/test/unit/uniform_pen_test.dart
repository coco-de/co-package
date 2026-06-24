// 상태 전이 검증이라 setX 후 매번 다른 state 를 읽으므로 변수 추출 불가.
// ignore_for_file: prefer-moving-to-variable
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

import '../helpers/test_helpers.dart';

/// BrushMode 표준안(kobic #7160) 회귀 방지.
///
/// 펜 3종(균일/필압/화면비례)이 `StrokeOptions`(size 보정·thinning·
/// simulatePressure)로 서로 다르게 계산되는지 검증한다.
void main() {
  group('UniformPen — InkModes 상수', () {
    test('InkModes.uniformPen 값이 "uniformPen"이다', () {
      expect(InkModes.uniformPen, 'uniformPen');
    });

    test('ScribbleTool.uniformPen이 InkModes.uniformPen과 동일하다', () {
      expect(ScribbleTool.uniformPen, InkModes.uniformPen);
    });
  });

  group('UniformPen — InkGroupInfo', () {
    test('uniformPen 기본 두께가 0.5이다', () {
      final info = InkGroupInfo(selectedInk: InkModes.uniformPen);
      expect(info.seletedStrokeWidth, 0.5);
    });

    test('uniformPen 기본 색상이 설정되어 있다', () {
      final info = InkGroupInfo(selectedInk: InkModes.uniformPen);
      expect(info.selectedColor, isA<Color>());
    });
  });

  group('UniformPen — ScribbleModeNotifier', () {
    late ScribbleModeNotifier notifier;

    setUp(() {
      notifier = ScribbleModeNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('setUniformPen()으로 uniformPen 모드로 전환된다', () {
      notifier.setUniformPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.uniformPen);
    });

    test('setUniformPen() 후 allowedPointersMode가 유지된다', () {
      notifier.setAllowedPointersMode(.penOnly);
      notifier.setUniformPen();
      expect(notifier.state.allowedPointersMode, ScribblePointerMode.penOnly);
    });

    test('균일/필압/화면비례 3종 ink 가 서로 다르게 전환된다', () {
      notifier.setUniformPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.uniformPen);

      notifier.setPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);

      notifier.setFixedPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);
    });
  });

  group('UniformPen — 두께 정책(options.size, #7160)', () {
    // 핵심 회귀 방지: 확대(scaleFactor)에 대한 굵기 정책이 모드별로 달라야 한다.
    test('uniformPen(균일)은 scaleFactor 를 무시한다 — 콘텐츠 고정 두께', () {
      final info = InkGroupInfo(selectedInk: InkModes.uniformPen)
        ..setStrokeBox({InkModes.uniformPen: 2.0});
      final state = ScribbleModeState(scaleFactor: 2.0, inkGroupInfo: info);
      // 보정 없음 → strokeWidth 그대로
      expect(state.options.size, closeTo(2.0, 0.001));
    });

    test('pen(필압)도 scaleFactor 를 무시한다 — 콘텐츠 고정 두께', () {
      final info = InkGroupInfo(selectedInk: InkModes.pen)
        ..setStrokeBox({InkModes.pen: 2.0});
      final state = ScribbleModeState(scaleFactor: 2.0, inkGroupInfo: info);
      expect(state.options.size, closeTo(2.0, 0.001));
    });

    test('fixedPen(화면비례)만 scaleFactor 로 보정한다 — 물리 두께 유지', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen)
        ..setStrokeBox({InkModes.fixedPen: 2.0});
      final state = ScribbleModeState(scaleFactor: 2.0, inkGroupInfo: info);
      // 2.0 / 2.0 = 1.0 (화면상 물리 두께 일정)
      expect(state.options.size, closeTo(1.0, 0.001));
    });
  });

  group('UniformPen — StrokePaintDelegate 렌더링', () {
    test('uniformPen 스트로크를 에러 없이 렌더링한다', () {
      final stroke = createStroke(ink: 'uniformPen', width: 2.0);
      final delegate = StrokePaintDelegate(
        strokes: [stroke],
        scaleFactor: 1.0,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawStroke 에서 uniformPen 분기가 동작한다', () {
      final delegate = StrokePaintDelegate(strokes: [], scaleFactor: 2.0);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'uniformPen')),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });
}
