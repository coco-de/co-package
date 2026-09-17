import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

ScribbleModeState _shapeModeState() {
  final info = InkGroupInfo(selectedInk: InkModes.shape);
  info.setStrokeBox({InkModes.shape: 1.0});
  return ScribbleModeState(inkGroupInfo: info);
}

PointerDownEvent _down(Offset pos) => PointerDownEvent(
  pointer: 1,
  position: pos,
  kind: ui.PointerDeviceKind.stylus,
);

PointerMoveEvent _move(Offset pos) => PointerMoveEvent(
  pointer: 1,
  position: pos,
  kind: ui.PointerDeviceKind.stylus,
);

PointerUpEvent _up(Offset pos) => PointerUpEvent(
  pointer: 1,
  position: pos,
  kind: ui.PointerDeviceKind.stylus,
);

/// 사각형 궤적을 그린다 (변마다 충분한 포인트 생성)
void _drawRectangle(ScribbleNotifier notifier, ScribbleModeState mode) {
  notifier.onPointerDown(_down(const Offset(0, 0)), mode);
  // 위변: (0,0) -> (100,0)
  for (var x = 10; x <= 100; x += 10) {
    notifier.onPointerUpdate(_move(Offset(x.toDouble(), 0)), mode);
  }
  // 오른변: (100,0) -> (100,100)
  for (var y = 10; y <= 100; y += 10) {
    notifier.onPointerUpdate(_move(Offset(100, y.toDouble())), mode);
  }
  // 아래변: (100,100) -> (0,100)
  for (var x = 90; x >= 0; x -= 10) {
    notifier.onPointerUpdate(_move(Offset(x.toDouble(), 100)), mode);
  }
  // 왼변: (0,100) -> (0,5)
  for (var y = 90; y >= 5; y -= 10) {
    notifier.onPointerUpdate(_move(Offset(0, y.toDouble())), mode);
  }
  notifier.onPointerUp(_up(const Offset(0, 5)), mode);
}

void main() {
  group('도형 변환 undo 단위', () {
    test('도형 1개 그리기는 undo 1회로 전부 제거된다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState();

      _drawRectangle(notifier, mode);

      final strokes = notifier.state.scribble.strokes;
      expect(strokes.length, 1);

      final shapeType = strokes.first.shapeType;
      expect(shapeType, isNotEmpty);
      expect(shapeType, isNot('pending'));

      // 손그림 중간 상태가 히스토리에 남아 있으면 undo 1회 시
      // 변환 전 손그림이 복원된다. 1회 undo로 빈 상태가 되어야 한다.
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.currentScribble.strokes, isEmpty);

      notifier.dispose();
    });

    test('도형 변환 후 redo로 변환된 도형이 복원된다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState();

      _drawRectangle(notifier, mode);
      final transformed = notifier.state.scribble.strokes.first;

      notifier.undo();
      notifier.redo();

      final restored = notifier.currentScribble.strokes.first;
      expect(restored.shapeType, transformed.shapeType);
      expect(restored.points.length, transformed.points.length);

      notifier.dispose();
    });

    test('변환된 도형 스트로크에는 원본 손그림 점이 포함되지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState();

      _drawRectangle(notifier, mode);

      // 사각형 궤적은 약 40개의 점으로 그려졌지만, 변환 결과는
      // 코너 기반 기하(또는 타원 점)만 담아야 한다.
      final points = notifier.state.scribble.strokes.first.points;
      expect(points.length, lessThan(20));

      notifier.dispose();
    });
  });
}
