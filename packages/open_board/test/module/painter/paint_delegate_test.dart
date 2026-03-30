import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/models/lasso_selection_state.dart';
import 'package:open_board/src/module/painter/cursor_paint_delegate.dart';
import 'package:open_board/src/module/painter/lasso_paint_delegate.dart';
import 'package:open_board/src/module/painter/paint_delegate.dart';
import 'package:open_board/src/module/painter/shape_paint_delegate.dart';
import 'package:open_board/src/module/painter/stroke_paint_delegate.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

import '../../helpers/test_helpers.dart';

InkGroupInfo _defaultInkGroupInfo() =>
    InkGroupInfo(selectedInk: InkModes.pencil);

void main() {
  group('PaintDelegate 인터페이스', () {
    test('StrokePaintDelegate는 PaintDelegate를 구현한다', () {
      final delegate = StrokePaintDelegate(strokes: []);
      expect(delegate, isA<PaintDelegate>());
    });

    test('ShapePaintDelegate는 PaintDelegate를 구현한다', () {
      final delegate = ShapePaintDelegate(strokes: []);
      expect(delegate, isA<PaintDelegate>());
    });

    test('LassoPaintDelegate는 PaintDelegate를 구현한다', () {
      final delegate = LassoPaintDelegate(
        allStrokes: [],
        selectedStrokeIds: [],
        showLassoOverlay: false,
      );
      expect(delegate, isA<PaintDelegate>());
    });

    test('CursorPaintDelegate는 PaintDelegate를 구현한다', () {
      final delegate = CursorPaintDelegate(
        state: Drawing(scribble: createScribble()),
        modeState: ScribbleModeState(
          inkGroupInfo: _defaultInkGroupInfo(),
        ),
        drawEraser: false,
      );
      expect(delegate, isA<PaintDelegate>());
    });
  });

  group('StrokePaintDelegate', () {
    test('빈 스트로크 목록으로 paint 호출 시 에러 없음', () {
      final delegate = StrokePaintDelegate(strokes: []);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('펜 스트로크를 렌더링한다', () {
      final stroke = createStroke(ink: 'pen');
      final delegate = StrokePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('연필 스트로크를 렌더링한다', () {
      final stroke = createStroke(ink: 'pencil');
      final delegate = StrokePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('마커 스트로크를 렌더링한다', () {
      final stroke = createStroke(ink: 'marker');
      final delegate = StrokePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('여러 스트로크를 순서대로 렌더링한다', () {
      final strokes = [
        createStroke(ink: 'pen'),
        createStroke(ink: 'pencil'),
        createStroke(ink: 'marker'),
      ];
      final delegate = StrokePaintDelegate(strokes: strokes);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawStroke는 잉크 타입에 따라 분기한다', () {
      final delegate = StrokePaintDelegate(strokes: []);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // 각 잉크 타입 개별 호출
      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'pen')),
        returnsNormally,
      );
      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'pencil')),
        returnsNormally,
      );
      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'marker')),
        returnsNormally,
      );
      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'erase')),
        returnsNormally,
      );
      expect(
        () => delegate.drawStroke(canvas, createStroke(ink: 'shape')),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });

  group('ShapePaintDelegate', () {
    test('빈 스트로크 목록으로 paint 호출 시 에러 없음', () {
      final delegate = ShapePaintDelegate(strokes: []);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('직선(line) 도형을 렌더링한다', () {
      final stroke = createStroke(
        shapeType: 'line',
        points: createLinePoints(fromX: 0, fromY: 0, toX: 100, toY: 100),
      );
      final delegate = ShapePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('원(circle) 도형을 렌더링한다', () {
      // 간단한 원형 점 생성
      final circlePoints = createPoints([
        [50, 100], [60, 115], [70, 125], [85, 130], [100, 130],
        [115, 125], [125, 115], [130, 100], [125, 85], [115, 75],
        [100, 70], [85, 75], [75, 85], [65, 90], [55, 95],
      ]);

      final stroke = createStroke(
        shapeType: 'circle',
        points: circlePoints,
      );
      final delegate = ShapePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('polyline 도형을 렌더링한다', () {
      final stroke = createStroke(
        shapeType: 'polyline',
        points: createLinePoints(),
      );
      final delegate = ShapePaintDelegate(strokes: [stroke]);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('점이 부족한 도형은 무시한다', () {
      final stroke = createStroke(
        shapeType: 'line',
        points: [createPoint(x: 10, y: 10)], // 1개 점만
      );
      final delegate = ShapePaintDelegate(strokes: []);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke;

      expect(
        () => delegate.drawShape(canvas, paint, stroke),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });

  group('LassoPaintDelegate', () {
    test('빈 상태에서 paint 호출 시 에러 없음', () {
      final delegate = LassoPaintDelegate(
        allStrokes: [],
        selectedStrokeIds: [],
        showLassoOverlay: false,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('올가미 스트로크가 있을 때 렌더링한다', () {
      final lassoStroke = createStroke(
        ink: 'lasso',
        points: createPoints([
          [10, 10], [100, 10], [100, 100], [10, 100],
        ]),
      );
      final delegate = LassoPaintDelegate(
        allStrokes: [lassoStroke],
        selectedStrokeIds: [],
        showLassoOverlay: false,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('선택된 스트로크를 렌더링한다', () {
      final stroke = createStroke(ink: 'pen');
      final delegate = LassoPaintDelegate(
        allStrokes: [stroke],
        selectedStrokeIds: [0],
        showLassoOverlay: false,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('올가미 오버레이를 렌더링한다', () {
      final stroke = createStroke(ink: 'pen');
      final delegate = LassoPaintDelegate(
        allStrokes: [stroke],
        selectedStrokeIds: [0],
        showLassoOverlay: true,
        lassoSelectionState: LassoSelectionState(
          boundingBox: const Rect.fromLTWH(10, 10, 100, 100),
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('drawDashedPath는 점선 경로를 그린다', () {
      final delegate = LassoPaintDelegate(
        allStrokes: [],
        selectedStrokeIds: [],
        showLassoOverlay: false,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 100);
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke;

      expect(
        () => delegate.drawDashedPath(canvas, path, paint, [10.0, 6.0]),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });

  group('CursorPaintDelegate', () {
    test('지우개 모드가 아닐 때는 아무것도 그리지 않는다', () {
      final delegate = CursorPaintDelegate(
        state: Drawing(scribble: createScribble()),
        modeState: ScribbleModeState(
          inkGroupInfo: _defaultInkGroupInfo(),
        ),
        drawEraser: false,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('포인터 위치 없이 호출 시 에러 없음', () {
      final delegate = CursorPaintDelegate(
        state: Erasing(scribble: createScribble()),
        modeState: ScribbleModeState(
          inkGroupInfo: _defaultInkGroupInfo(),
        ),
        drawEraser: true,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('지우개 모드에서 포인터 위치가 있으면 포인터를 그린다', () {
      final delegate = CursorPaintDelegate(
        state: Erasing(
          scribble: createScribble(),
          pointerPosition: Point(x: 100, y: 100),
        ),
        modeState: ScribbleModeState(
          inkGroupInfo: _defaultInkGroupInfo(),
        ),
        drawEraser: true,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => delegate.paint(canvas, const Size(400, 600)),
        returnsNormally,
      );

      recorder.endRecording();
    });
  });
}
