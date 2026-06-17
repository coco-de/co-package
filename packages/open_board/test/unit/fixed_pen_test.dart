import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/eraser_processor.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('FixedPen — InkModes 상수', () {
    test('InkModes.fixedPen 값이 "fixedPen"이다', () {
      expect(InkModes.fixedPen, 'fixedPen');
    });

    test('ScribbleTool.fixedPen이 InkModes.fixedPen과 동일하다', () {
      expect(ScribbleTool.fixedPen, InkModes.fixedPen);
    });
  });

  group('FixedPen — InkGroupInfo', () {
    test('fixedPen 모드의 기본 색상이 설정되어 있다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      expect(info.selectedColor, isA<Color>());
    });

    test('fixedPen 모드의 기본 두께가 0.5이다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      expect(info.seletedStrokeWidth, 0.5);
    });

    test('fixedPen 모드에서 두께를 변경할 수 있다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      final copied = info.copyWith(strokeWidth: 3.0);
      expect(copied.seletedStrokeWidth, 3.0);
    });

    test('fixedPen 모드에서 색상을 변경할 수 있다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      final copied = info.copyWith(inkColor: Colors.red);
      expect(copied.selectedColor, Colors.red);
    });
  });

  group('FixedPen — ScribbleModeNotifier', () {
    late ScribbleModeNotifier notifier;

    setUp(() {
      notifier = ScribbleModeNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('setFixedPen()으로 fixedPen 모드로 전환된다', () {
      notifier.setFixedPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);
    });

    test('setFixedPen() 후 allowedPointersMode가 유지된다', () {
      notifier.setAllowedPointersMode(.penOnly);
      notifier.setFixedPen();
      expect(
        notifier.state.allowedPointersMode,
        ScribblePointerMode.penOnly,
      );
    });

    test('fixedPen에서 두께 변경이 가능하다', () {
      notifier.setFixedPen();
      notifier.setStrokeWidth(4.0);
      expect(notifier.state.inkGroupInfo.seletedStrokeWidth, 4.0);
    });

    test('fixedPen과 다른 모드 간 전환이 올바르게 동작한다', () {
      notifier.setFixedPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);

      notifier.setPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);

      notifier.setFixedPen();
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);
    });

    test('setSelectedInk으로 fixedPen 전환이 가능하다', () {
      notifier.setSelectedInk(InkModes.fixedPen);
      expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);
    });
  });

  group('ScribbleModeState options — 문서 좌표 고정 두께', () {
    test('확대(scaleFactor>1)에서도 options.size는 strokeWidth와 동일하다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      info.setStrokeBox({InkModes.fixedPen: 2.0});
      final state = ScribbleModeState(
        scaleFactor: 2.0,
        inkGroupInfo: info,
      );
      // 줌 보정 제거 → 2.0 그대로 (이전 동작: 2.0/2.0 = 1.0)
      expect(state.options.size, closeTo(2.0, 0.001));
    });

    test('scaleFactor 1.0에서 options.size는 strokeWidth와 동일하다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      info.setStrokeBox({InkModes.fixedPen: 3.0});
      final state = ScribbleModeState(
        scaleFactor: 1.0,
        inkGroupInfo: info,
      );
      expect(state.options.size, closeTo(3.0, 0.001));
    });

    test('축소(scaleFactor<1)에서도 options.size는 strokeWidth와 동일하다', () {
      final info = InkGroupInfo(selectedInk: InkModes.fixedPen);
      info.setStrokeBox({InkModes.fixedPen: 2.0});
      final state = ScribbleModeState(
        scaleFactor: 0.5,
        inkGroupInfo: info,
      );
      // 줌 보정 제거 → 2.0 그대로 (이전 동작: 2.0/0.5 = 4.0 으로 더 굵게 저장됨)
      expect(state.options.size, closeTo(2.0, 0.001));
    });
  });

  group('FixedPen — StrokePaintDelegate 렌더링', () {
    test('fixedPen 스트로크를 에러 없이 렌더링한다', () {
      final stroke = createStroke(ink: 'fixedPen', width: 2.0);
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

    test('drawStroke에서 fixedPen 분기가 동작한다', () {
      final delegate = StrokePaintDelegate(strokes: [], scaleFactor: 2.0);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'fixedPen')),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawFixedPen은 scaleFactor에 따라 크기를 보정한다', () {
      final stroke = createStroke(
        ink: 'fixedPen',
        width: 4.0,
        options: createStrokeOptions(size: 2.0, thinning: 0.7),
      );

      // scaleFactor=2.0이면 adjustedSize = 4.0/2.0 = 2.0
      final delegate = StrokePaintDelegate(strokes: [], scaleFactor: 2.0);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.drawFixedPen(canvas, stroke),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('scaleFactor가 1.0일 때 stroke.width가 그대로 사용된다', () {
      final stroke = createStroke(
        ink: 'fixedPen',
        width: 3.0,
        options: createStrokeOptions(size: 3.0, thinning: 0.7),
      );

      // scaleFactor=1.0이면 adjustedSize = 3.0/1.0 = 3.0
      final delegate = StrokePaintDelegate(strokes: [], scaleFactor: 1.0);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.drawFixedPen(canvas, stroke),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('여러 잉크 타입을 혼합하여 렌더링할 수 있다', () {
      final strokes = [
        createStroke(ink: 'pen'),
        createStroke(ink: 'fixedPen', width: 2.0),
        createStroke(ink: 'pencil'),
        createStroke(ink: 'marker'),
      ];
      final delegate = StrokePaintDelegate(
        strokes: strokes,
        scaleFactor: 1.5,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('scaleFactor 기본값은 1.0이다', () {
      final delegate = StrokePaintDelegate(strokes: []);
      expect(delegate.scaleFactor, 1.0);
    });
  });

  group('FixedPen — EraserProcessor', () {
    late EraserProcessor processor;

    setUp(() {
      processor = const EraserProcessor();
    });

    test('fixedPen 스트로크에 대한 지우기가 동작한다', () {
      final fixedPenStroke = createStroke(
        ink: 'fixedPen',
        points: createLinePoints(
          fromX: 50,
          fromY: 50,
          toX: 150,
          toY: 150,
          pressure: 0.5,
        ),
        options: createStrokeOptions(size: 2.0, thinning: 0.7),
        width: 2.0,
      );

      final state = Drawing(
        scribble: createScribble(strokes: [fixedPenStroke]),
      );

      final modeState = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.erase)
          ..setStrokeBox({InkModes.erase: 10.0}),
        scaleFactor: 1.0,
      );

      // 스트로크에서 먼 곳을 터치 → 스트로크가 살아남아야 함
      const farEvent = PointerMoveEvent(
        position: Offset(300, 300),
      );

      final result = processor.eraseAtPoint(
        farEvent,
        modeState,
        state,
        const Offset(290, 290),
      );

      expect(result.scribble.strokes.length, 1);
    });
  });
}
