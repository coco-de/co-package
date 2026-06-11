import 'dart:ui' as ui;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

ScribbleModeState _modeState(String ink, {double strokeWidth = 2.0}) {
  final info = InkGroupInfo(selectedInk: ink);
  info.setStrokeBox({ink: strokeWidth});
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

/// 곡선을 그린 뒤 정지 상태로 [hold]만큼 경과시킨다.
void _drawAndHold(
  ScribbleNotifier notifier,
  ScribbleModeState mode,
  FakeAsync async,
  Duration hold,
) {
  notifier.onPointerDown(_down(const Offset(10, 10)), mode);
  notifier.onPointerUpdate(_move(const Offset(30, 20)), mode);
  notifier.onPointerUpdate(_move(const Offset(50, 45)), mode);
  notifier.onPointerUpdate(_move(const Offset(70, 60)), mode);
  async.elapse(hold);
  async.flushMicrotasks();
}

/// 현재 activeLine의 포인트 목록을 반환한다.
List<Point> _activePoints(ScribbleNotifier notifier) {
  final drawing = notifier.state as Drawing;
  final activeLine = drawing.activeLine;
  expect(activeLine, isNotNull);
  return activeLine!.points;
}

void main() {
  group('일반 펜 2초 정지 시 직선 변환', () {
    for (final ink in [InkModes.pen, InkModes.pencil, InkModes.fixedPen]) {
      test('$ink: 2초 정지 후 activeLine이 첫 점과 마지막 점만 남는다', () {
        fakeAsync((async) {
          final notifier = ScribbleNotifier();
          final mode = _modeState(ink);

          _drawAndHold(
            notifier,
            mode,
            async,
            ScribbleNotifier.kPenStraightenDelay,
          );

          final points = _activePoints(notifier);
          final first = points.first;
          final last = points.last;
          expect(points.length, 2);
          expect(first.x, 10);
          expect(first.y, 10);
          expect(last.x, 70);
          expect(last.y, 60);

          notifier.dispose();
        });
      });
    }

    for (final ink in [InkModes.pen, InkModes.pencil, InkModes.fixedPen]) {
      test('$ink: 1.5초 정지 시점에는 아직 직선 변환되지 않는다', () {
        fakeAsync((async) {
          final notifier = ScribbleNotifier();
          final mode = _modeState(ink);

          _drawAndHold(
            notifier,
            mode,
            async,
            const Duration(milliseconds: 1500),
          );

          expect(_activePoints(notifier).length, greaterThan(2));

          // 추가로 0.5초가 지나면(총 2초) 직선 변환된다
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();
          final drawing = notifier.state as Drawing;
          expect(drawing.activeLine!.points.length, 2);

          notifier.dispose();
        });
      });
    }

    test('marker: 기존 1.5초 정지 동작이 유지된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.marker, strokeWidth: 5.0);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kMarkerStraightenDelay,
        );

        expect(_activePoints(notifier).length, 2);

        notifier.dispose();
      });
    });

    test('pen: 직선 변환 후 이동 시 끝점만 갱신된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kPenStraightenDelay,
        );

        notifier.onPointerUpdate(_move(const Offset(150, 90)), mode);

        final points = _activePoints(notifier);
        final first = points.first;
        final last = points.last;
        expect(points.length, 2);
        expect(first.x, 10);
        expect(first.y, 10);
        expect(last.x, 150);
        expect(last.y, 90);

        notifier.dispose();
      });
    });

    test('pen: 임계값 이상 이동을 계속하면 직선 변환이 트리거되지 않는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        notifier.onPointerDown(_down(const Offset(0, 0)), mode);
        for (var t = 0; t < 3000; t += 200) {
          notifier.onPointerUpdate(
            _move(Offset(t.toDouble(), t.toDouble())),
            mode,
          );
          async.elapse(const Duration(milliseconds: 200));
        }

        expect(_activePoints(notifier).length, greaterThan(2));

        notifier.dispose();
      });
    });

    test('shape 잉크는 2초 정지해도 직선 변환되지 않는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.shape, strokeWidth: 1.0);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kPenStraightenDelay,
        );

        expect(_activePoints(notifier).length, greaterThan(2));

        notifier.dispose();
      });
    });

    test('pen: onPointerUp 후 타이머가 정리되어 추가 이벤트 없이 종료된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        notifier.onPointerDown(_down(const Offset(0, 0)), mode);
        notifier.onPointerUpdate(_move(const Offset(10, 10)), mode);
        expect(notifier.debugStraightenTimerActive, isTrue);

        notifier.onPointerUp(_up(const Offset(10, 10)), mode);
        expect(notifier.debugStraightenTimerActive, isFalse);

        // 타이머가 정리되었으면 2초가 지나도 직선 변환이 일어나지 않는다
        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();

        final drawing = notifier.state as Drawing;
        expect(drawing.activeLine, isNull);
        expect(drawing.scribble.strokes.length, 1);

        notifier.dispose();
      });
    });

    test('pen: 직선 변환 후 onPointerUp 시 2점 직선이 커밋된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kPenStraightenDelay,
        );
        notifier.onPointerUp(_up(const Offset(70, 60)), mode);

        final drawing = notifier.state as Drawing;
        final strokes = drawing.scribble.strokes;
        expect(drawing.activeLine, isNull);
        expect(strokes.length, 1);
        expect(strokes.first.points.length, 2);

        notifier.dispose();
      });
    });

    test('pen: 직선 변환 후 up 위치가 달라도 직선이 꺾이지 않는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kPenStraightenDelay,
        );
        // 펜을 떼는 순간 미끄러짐: up 위치가 마지막 move와 다름
        notifier.onPointerUp(_up(const Offset(90, 30)), mode);

        final drawing = notifier.state as Drawing;
        final points = drawing.scribble.strokes.first.points;
        expect(points.length, 2);
        expect(points.first.x, 10);
        expect(points.first.y, 10);
        expect(points.last.x, 70);
        expect(points.last.y, 60);

        notifier.dispose();
      });
    });

    test('pen: 직선 변환 후 onPointerCancel 시에도 2점 직선이 커밋된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        _drawAndHold(
          notifier,
          mode,
          async,
          ScribbleNotifier.kPenStraightenDelay,
        );
        notifier.onPointerCancel(
          const PointerCancelEvent(
            pointer: 1,
            position: Offset(95, 25),
            kind: ui.PointerDeviceKind.stylus,
          ),
          mode,
        );

        final drawing = notifier.state as Drawing;
        expect(drawing.scribble.strokes.first.points.length, 2);

        notifier.dispose();
      });
    });

    test('드로잉 중 두 번째 손가락이 닿으면(핀치 시작) 직선화 타이머가 취소된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _modeState(InkModes.pen);

        notifier.onPointerDown(_down(const Offset(10, 10)), mode);
        notifier.onPointerUpdate(_move(const Offset(25, 20)), mode);
        notifier.onPointerUpdate(_move(const Offset(40, 40)), mode);
        notifier.onPointerUpdate(_move(const Offset(55, 50)), mode);
        expect(notifier.debugStraightenTimerActive, isTrue);

        // 두 번째 손가락 down (핀치 시작)
        notifier.onPointerDown(
          const PointerDownEvent(
            pointer: 2,
            position: Offset(200, 200),
            kind: ui.PointerDeviceKind.touch,
          ),
          mode,
        );
        expect(notifier.debugStraightenTimerActive, isFalse);

        // 핀치 도중 2초가 지나도 직선화가 발생하지 않는다
        async.elapse(ScribbleNotifier.kPenStraightenDelay);
        async.flushMicrotasks();
        expect(_activePoints(notifier).length, greaterThan(2));

        notifier.dispose();
      });
    });
  });
}
