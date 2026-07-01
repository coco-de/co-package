import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

ScribbleModeState _shapeModeState({String target = ''}) {
  final info = InkGroupInfo(selectedInk: InkModes.shape, shapeType: target);
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

/// 시작점→끝점으로 드래그(중간 move 포함)해 결정적 도형을 그린다.
void _dragShape(
  ScribbleNotifier notifier,
  ScribbleModeState mode,
  Offset start,
  Offset end,
) {
  notifier.onPointerDown(_down(start), mode);
  final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  notifier.onPointerUpdate(_move(mid), mode);
  notifier.onPointerUpdate(_move(end), mode);
  notifier.onPointerUp(_up(end), mode);
}

void main() {
  group('결정적 도형 드로잉 (타겟 shapeType)', () {
    for (final target in [
      ShapeTargets.line,
      ShapeTargets.ellipse,
      ShapeTargets.rectangle,
    ]) {
      test('$target 타겟은 시작·끝 2점으로 확정되고 자동 인식을 거치지 않는다', () {
        final notifier = ScribbleNotifier();
        final mode = _shapeModeState(target: target);

        _dragShape(notifier, mode, const Offset(10, 20), const Offset(110, 80));

        final strokes = notifier.state.scribble.strokes;
        expect(strokes.length, 1);

        final stroke = strokes.first;
        expect(stroke.shapeType, target);
        expect(stroke.points.length, 2);
        expect(stroke.points.first.x, 10);
        expect(stroke.points.first.y, 20);
        expect(stroke.points.last.x, 110);
        expect(stroke.points.last.y, 80);
        // 자동 인식(ShapeDetector) 이 만드는 세그먼트/다점 기하가 없어야 한다.
        expect(stroke.segments, isEmpty);

        notifier.dispose();
      });
    }

    test('결정적 도형 1개는 undo 1회로 전부 제거된다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState(target: ShapeTargets.rectangle);

      _dragShape(notifier, mode, const Offset(0, 0), const Offset(100, 60));

      expect(notifier.state.scribble.strokes.length, 1);
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.currentScribble.strokes, isEmpty);

      notifier.dispose();
    });

    test('드래그 중 activeLine 은 시작점→현재점 2점 rubber-band 로 유지된다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState(target: ShapeTargets.ellipse);

      notifier.onPointerDown(_down(const Offset(0, 0)), mode);
      notifier.onPointerUpdate(_move(const Offset(30, 40)), mode);
      notifier.onPointerUpdate(_move(const Offset(60, 80)), mode);

      final active = (notifier.state as Drawing).activeLine;
      expect(active, isNotNull);
      expect(active!.points.length, 2);
      expect(active.shapeType, ShapeTargets.ellipse);
      expect(active.points.first.x, 0);
      expect(active.points.last.x, 60);
      expect(active.points.last.y, 80);

      notifier.dispose();
    });

    test('드래그 없이(시작==끝) 탭하면 도형이 만들어지지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState(target: ShapeTargets.rectangle);

      notifier.onPointerDown(_down(const Offset(50, 50)), mode);
      notifier.onPointerUp(_up(const Offset(50, 50)), mode);

      expect(notifier.state.scribble.strokes, isEmpty);

      notifier.dispose();
    });

    test('타겟 없음(자유 도형)은 기존 자동 인식 경로를 유지한다', () {
      final notifier = ScribbleNotifier();
      final mode = _shapeModeState();

      // 사각형 궤적을 손그림으로 그린다.
      notifier.onPointerDown(_down(const Offset(0, 0)), mode);
      for (var x = 10; x <= 100; x += 10) {
        notifier.onPointerUpdate(_move(Offset(x.toDouble(), 0)), mode);
      }
      for (var y = 10; y <= 100; y += 10) {
        notifier.onPointerUpdate(_move(Offset(100, y.toDouble())), mode);
      }
      for (var x = 90; x >= 0; x -= 10) {
        notifier.onPointerUpdate(_move(Offset(x.toDouble(), 100)), mode);
      }
      for (var y = 90; y >= 5; y -= 10) {
        notifier.onPointerUpdate(_move(Offset(0, y.toDouble())), mode);
      }
      notifier.onPointerUp(_up(const Offset(0, 5)), mode);

      final stroke = notifier.state.scribble.strokes.first;
      // 자동 인식이 동작해 'pending' 이 아닌 실제 도형으로 변환된다.
      expect(stroke.shapeType, isNotEmpty);
      expect(stroke.shapeType, isNot('pending'));
      // 결정적 2점 rubber-band 가 아니라 인식 기하(다점/세그먼트)여야 한다.
      expect(stroke.points.length, greaterThan(2));

      notifier.dispose();
    });
  });
}
