import 'dart:ui' as ui;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

ScribbleModeState _markerModeState() {
  final info = InkGroupInfo(selectedInk: InkModes.marker);
  info.setStrokeBox({InkModes.marker: 5.0});
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

void main() {
  group('마커 펜 1.5초 정지 시 직선 변환', () {
    test('1.5초 정지 후 activeLine이 첫 점과 마지막 점만 남는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _markerModeState();

        notifier.onPointerDown(_down(const Offset(10, 10)), mode);
        notifier.onPointerUpdate(_move(const Offset(20, 20)), mode);
        notifier.onPointerUpdate(_move(const Offset(40, 40)), mode);
        notifier.onPointerUpdate(_move(const Offset(60, 60)), mode);

        // 정지 상태로 1.5초 경과 (이동 임계값 미만의 미세 흔들림)
        notifier.onPointerUpdate(_move(const Offset(60.5, 60.5)), mode);
        async.elapse(const Duration(milliseconds: 1500));
        async.flushMicrotasks();

        final drawing = notifier.state as Drawing;
        expect(drawing.activeLine, isNotNull);
        expect(drawing.activeLine!.points.length, 2);
        expect(drawing.activeLine!.points.first.x, 10);
        expect(drawing.activeLine!.points.first.y, 10);

        notifier.dispose();
      });
    });

    test('1.5초 정지 후 끝점 이동 시 직선 끝점만 갱신된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _markerModeState();

        notifier.onPointerDown(_down(const Offset(0, 0)), mode);
        notifier.onPointerUpdate(_move(const Offset(30, 30)), mode);
        notifier.onPointerUpdate(_move(const Offset(50, 50)), mode);

        async.elapse(const Duration(milliseconds: 1500));
        async.flushMicrotasks();

        // 직선화 후 추가 이동: 끝점만 따라가야 함
        notifier.onPointerUpdate(_move(const Offset(120, 80)), mode);

        final drawing = notifier.state as Drawing;
        expect(drawing.activeLine!.points.length, 2);
        expect(drawing.activeLine!.points.first.x, 0);
        expect(drawing.activeLine!.points.first.y, 0);
        expect(drawing.activeLine!.points.last.x, 120);
        expect(drawing.activeLine!.points.last.y, 80);

        notifier.dispose();
      });
    });

    test('임계값 이상 이동을 계속하면 직선 변환이 트리거되지 않는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _markerModeState();

        notifier.onPointerDown(_down(const Offset(0, 0)), mode);

        // 200ms 간격으로 충분한 이동을 계속 발생시켜 타이머가 재시작되도록 함
        for (var t = 0; t < 2000; t += 200) {
          notifier.onPointerUpdate(_move(Offset(t.toDouble(), t.toDouble())), mode);
          async.elapse(const Duration(milliseconds: 200));
        }

        final drawing = notifier.state as Drawing;
        // 직선 변환이 발생하지 않았다면 곡선용 다수의 포인트가 남아 있어야 함
        expect(drawing.activeLine!.points.length, greaterThan(2));

        notifier.dispose();
      });
    });

    test('마커가 아닌 펜은 1.5초 정지해도 직선 변환되지 않는다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final info = InkGroupInfo(selectedInk: InkModes.pen);
        info.setStrokeBox({InkModes.pen: 2.0});
        final mode = ScribbleModeState(inkGroupInfo: info);

        notifier.onPointerDown(_down(const Offset(5, 5)), mode);
        notifier.onPointerUpdate(_move(const Offset(20, 20)), mode);
        notifier.onPointerUpdate(_move(const Offset(40, 40)), mode);
        notifier.onPointerUpdate(_move(const Offset(60, 60)), mode);

        async.elapse(const Duration(milliseconds: 1500));
        async.flushMicrotasks();

        final drawing = notifier.state as Drawing;
        // 펜은 직선화되지 않으므로 모든 포인트가 보존됨
        expect(drawing.activeLine!.points.length, greaterThan(2));

        notifier.dispose();
      });
    });

    test('onPointerUp 후 타이머가 정리되어 추가 이벤트 없이 종료된다', () {
      fakeAsync((async) {
        final notifier = ScribbleNotifier();
        final mode = _markerModeState();

        notifier.onPointerDown(_down(const Offset(0, 0)), mode);
        notifier.onPointerUpdate(_move(const Offset(10, 10)), mode);
        notifier.onPointerUp(_up(const Offset(10, 10)), mode);

        // 타이머가 정리되었으면 1.5초가 지나도 예외 없이 정상 통과
        async.elapse(const Duration(milliseconds: 2000));
        async.flushMicrotasks();

        notifier.dispose();
      });
    });
  });
}
