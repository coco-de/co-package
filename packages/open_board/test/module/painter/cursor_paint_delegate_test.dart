import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/painter/cursor_paint_delegate.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

import '../../helpers/test_helpers.dart';

class _MockCanvas extends Mock implements ui.Canvas {}

Point _point(double x, double y) => Point()
  ..x = x
  ..y = y;

ScribbleModeState _modeState(String selectedInk) => ScribbleModeState(
      inkGroupInfo: InkGroupInfo(selectedInk: selectedInk),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const Offset(0, 0));
    registerFallbackValue(Paint());
  });

  group('CursorPaintDelegate#paint', () {
    test('지우개 모드 + Erasing 상태 + pointerPosition 존재 시 커서를 그린다',
        () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Erasing(
          scribble: createScribble(),
          pointerPosition: _point(120, 240),
        ),
        modeState: _modeState(InkModes.erase),
        drawEraser: true,
      );

      delegate.paint(canvas, const Size(400, 600));

      verify(() => canvas.save()).called(1);
      verify(() => canvas.drawCircle(any(), any(), any())).called(1);
      verify(() => canvas.restore()).called(1);
    });

    test('펜 모드로 전환됐는데 state가 stale Erasing이어도 커서를 그리지 않는다 (regression: #167)',
        () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Erasing(
          scribble: createScribble(),
          pointerPosition: _point(120, 240),
        ),
        modeState: _modeState(InkModes.pen),
        drawEraser: true,
      );

      delegate.paint(canvas, const Size(400, 600));

      verifyNever(() => canvas.drawCircle(any(), any(), any()));
    });

    test('마커 모드로 전환된 경우에도 stale Erasing 커서를 그리지 않는다',
        () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Erasing(
          scribble: createScribble(),
          pointerPosition: _point(50, 50),
        ),
        modeState: _modeState(InkModes.marker),
        drawEraser: true,
      );

      delegate.paint(canvas, const Size(400, 600));

      verifyNever(() => canvas.drawCircle(any(), any(), any()));
    });

    test('drawEraser가 false면 지우개 모드여도 커서를 그리지 않는다', () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Erasing(
          scribble: createScribble(),
          pointerPosition: _point(10, 10),
        ),
        modeState: _modeState(InkModes.erase),
        drawEraser: false,
      );

      delegate.paint(canvas, const Size(400, 600));

      verifyNever(() => canvas.drawCircle(any(), any(), any()));
    });

    test('Drawing 상태일 때는 모드와 관계없이 커서를 그리지 않는다', () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Drawing(
          scribble: createScribble(),
          pointerPosition: _point(80, 80),
        ),
        modeState: _modeState(InkModes.erase),
        drawEraser: true,
      );

      delegate.paint(canvas, const Size(400, 600));

      verifyNever(() => canvas.drawCircle(any(), any(), any()));
    });

    test('pointerPosition이 null이면 커서를 그리지 않는다', () {
      final canvas = _MockCanvas();
      final delegate = CursorPaintDelegate(
        state: Erasing(scribble: createScribble()),
        modeState: _modeState(InkModes.erase),
        drawEraser: true,
      );

      delegate.paint(canvas, const Size(400, 600));

      verifyNever(() => canvas.drawCircle(any(), any(), any()));
    });
  });
}
