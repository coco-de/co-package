// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

import '../helpers/test_helpers.dart';

/// 포인터 이벤트 수명주기 회귀 테스트.
///
/// 입력 파이프라인 전면 재검토에서 확정된 버그들의 회귀 방지:
/// 1. 소유하지 않은 포인터의 up/move가 활성 스트로크를 오염시키는 문제
/// 2. onPointerCancel이 activePointerIds를 정리하지 못하는 문제
/// 3. 터치/펜 up 후 pointerPosition(지우개 커서)이 잔상으로 남는 문제
/// 4. 지우개 anchor 50px 지연으로 곡선 지우기 시 닿지 않은 스트로크가
///    현(chord) 절단으로 삭제되는 문제
void main() {
  PointerDownEvent down(
    double x,
    double y, {
    PointerDeviceKind kind = PointerDeviceKind.stylus,
    int pointer = 1,
  }) => PointerDownEvent(kind: kind, pointer: pointer, position: Offset(x, y));

  PointerMoveEvent move(
    double x,
    double y, {
    PointerDeviceKind kind = PointerDeviceKind.stylus,
    int pointer = 1,
  }) => PointerMoveEvent(kind: kind, pointer: pointer, position: Offset(x, y));

  PointerUpEvent up(
    double x,
    double y, {
    PointerDeviceKind kind = PointerDeviceKind.stylus,
    int pointer = 1,
  }) => PointerUpEvent(kind: kind, pointer: pointer, position: Offset(x, y));

  PointerCancelEvent cancel(
    double x,
    double y, {
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int pointer = 1,
  }) =>
      PointerCancelEvent(kind: kind, pointer: pointer, position: Offset(x, y));

  Stroke? activeLineOf(ScribbleNotifier n) {
    final s = n.state;
    return s is Drawing ? s.activeLine : null;
  }

  group('포인터 소유권 가드 — 두 번째 손가락의 up/move 무시', () {
    test('소유하지 않은 포인터의 up은 활성 스트로크를 종료시키지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(down(10, 10, pointer: 1), mode.state);
      notifier.onPointerUpdate(move(30, 30, pointer: 1), mode.state);

      // 팜/두 번째 손가락의 up (멀리 떨어진 좌표)
      notifier.onPointerUp(
        up(500, 500, kind: PointerDeviceKind.touch, pointer: 2),
        mode.state,
      );

      // 활성 라인은 유지되고 소유 포인터도 그대로
      expect(activeLineOf(notifier), isNotNull);
      expect(notifier.currentState.activePointerIds, [1]);
      expect(notifier.currentScribble.strokes, isEmpty);
    });

    test('소유 포인터의 up으로 정상 완료되며 비소유 up의 좌표가 포함되지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(down(10, 10, pointer: 1), mode.state);
      notifier.onPointerUpdate(move(30, 30, pointer: 1), mode.state);
      notifier.onPointerUp(
        up(500, 500, kind: PointerDeviceKind.touch, pointer: 2),
        mode.state,
      );
      notifier.onPointerUp(up(40, 40, pointer: 1), mode.state);

      expect(notifier.currentScribble.strokes.length, 1);
      expect(notifier.currentState.activePointerIds, isEmpty);
      final maxX = notifier.currentScribble.strokes.first.points
          .map((p) => p.x)
          .reduce((a, b) => a > b ? a : b);
      expect(maxX, lessThan(100), reason: '비소유 포인터의 (500,500) 점프 점이 섞이면 안 된다');
    });

    test('소유하지 않은 포인터의 move는 활성 라인에 점을 추가하지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(down(10, 10, pointer: 1), mode.state);
      final before = activeLineOf(notifier)!.points.length;

      notifier.onPointerUpdate(
        move(400, 400, kind: PointerDeviceKind.touch, pointer: 2),
        mode.state,
      );

      expect(activeLineOf(notifier)!.points.length, before);
    });
  });

  group('onPointerCancel — activePointerIds 정리', () {
    test('cancel은 포인터 id를 제거하고 그리던 라인을 정리한다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(
        down(10, 10, kind: PointerDeviceKind.touch, pointer: 7),
        mode.state,
      );
      expect(notifier.currentState.activePointerIds, [7]);

      notifier.onPointerCancel(cancel(20, 20, pointer: 7), mode.state);

      expect(notifier.currentState.activePointerIds, isEmpty);
      expect(activeLineOf(notifier), isNull);
    });

    test('cancel 후 다음 터치 down이 정상적으로 새 라인을 시작한다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(
        down(10, 10, kind: PointerDeviceKind.touch, pointer: 7),
        mode.state,
      );
      notifier.onPointerCancel(cancel(20, 20, pointer: 7), mode.state);

      // 고아 id가 남아 있으면 touch down의 멀티터치 가드에서 거부된다.
      notifier.onPointerDown(
        down(50, 50, kind: PointerDeviceKind.touch, pointer: 8),
        mode.state,
      );

      expect(activeLineOf(notifier), isNotNull);
      expect(notifier.currentState.activePointerIds, [8]);
    });

    test('소유하지 않은 포인터의 cancel은 활성 스트로크에 영향이 없다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setPen();
      mode.setStrokeWidth(4.0);

      notifier.onPointerDown(down(10, 10, pointer: 1), mode.state);
      notifier.onPointerCancel(cancel(300, 300, pointer: 2), mode.state);

      expect(activeLineOf(notifier), isNotNull);
      expect(notifier.currentState.activePointerIds, [1]);
    });
  });

  group('지우개 커서 잔상 — 터치/펜 up 후 pointerPosition 정리', () {
    test('터치로 지우개 사용 후 up하면 pointerPosition이 null이 된다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      notifier.setEraser();

      notifier.onPointerDown(
        down(10, 10, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );
      notifier.onPointerUpdate(
        move(20, 20, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );
      expect(notifier.currentState.pointerPosition, isNotNull);

      notifier.onPointerUp(
        up(20, 20, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );

      expect(
        notifier.currentState.pointerPosition,
        isNull,
        reason: '터치 기기는 hover가 없어 여기서 지우지 않으면 회색 커서 원이 잔상으로 남는다',
      );
    });

    test('스타일러스 cancel 후에도 pointerPosition이 null이 된다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      notifier.setEraser();

      notifier.onPointerDown(
        down(10, 10, kind: PointerDeviceKind.stylus, pointer: 1),
        mode.state,
      );
      notifier.onPointerUpdate(
        move(20, 20, kind: PointerDeviceKind.stylus, pointer: 1),
        mode.state,
      );

      notifier.onPointerCancel(
        cancel(20, 20, kind: PointerDeviceKind.stylus, pointer: 1),
        mode.state,
      );

      expect(notifier.currentState.pointerPosition, isNull);
    });

    test('마우스 up은 pointerPosition을 유지한다 (hover 커서 표시 유지)', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      notifier.setEraser();

      notifier.onPointerDown(
        down(10, 10, kind: PointerDeviceKind.mouse, pointer: 1),
        mode.state,
      );
      notifier.onPointerUpdate(
        move(20, 20, kind: PointerDeviceKind.mouse, pointer: 1),
        mode.state,
      );

      notifier.onPointerUp(
        up(20, 20, kind: PointerDeviceKind.mouse, pointer: 1),
        mode.state,
      );

      expect(notifier.currentState.pointerPosition, isNotNull);
    });
  });

  group('지우개 anchor — 곡선 지우기 시 chord 절단 방지', () {
    /// 반지름 25 반원호(중심 (25,0), (0,0)→(50,0))를 따라 지우개를 움직인다.
    /// 원 중심 부근 (25,1)의 점은 궤적에서 약 24px 떨어져 있어 닿지 않지만,
    /// anchor가 (0,0)에 고정되면 마지막 현 (0,0)→(50,0)이 점을 통과해 버린다.
    test('원호 궤적 안쪽의 닿지 않은 스트로크는 삭제되지 않는다', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(1.0);

      notifier.setScribble(
        scribble: createScribble(
          strokes: [
            createStroke(
              points: [createPoint(x: 25, y: 1)],
              options: createStrokeOptions(size: 1.0, thinning: 0.0),
            ),
          ],
        ),
      );
      notifier.setEraser();

      // 반원호를 따라 move 이벤트 주입 (180° → 0°, 5° 간격)
      notifier.onPointerDown(
        down(0, 0, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );
      // 호 위의 점: (25 + 25cosθ, 25sinθ), θ: 180°(시작점 (0,0)) → 0°((50,0))
      for (int deg = 175; deg >= 0; deg -= 5) {
        final rad = deg * math.pi / 180.0;
        final x = 25 + 25 * math.cos(rad);
        final y = 25 * math.sin(rad);
        notifier.onPointerUpdate(
          move(x, y, kind: PointerDeviceKind.touch, pointer: 1),
          mode.state,
        );
      }

      expect(
        notifier.currentScribble.strokes.length,
        1,
        reason: '지우개가 닿지 않은 원호 안쪽 스트로크가 chord 절단으로 삭제되면 안 된다',
      );
    });

    test('이벤트 간 갭 보간은 유지된다 — 직선 경로 위 스트로크는 삭제', () {
      final notifier = ScribbleNotifier();
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(2.0);

      notifier.setScribble(
        scribble: createScribble(
          strokes: [
            createStroke(
              points: [createPoint(x: 20, y: 50)],
              options: createStrokeOptions(size: 1.0, thinning: 0.0),
            ),
          ],
        ),
      );
      notifier.setEraser();

      // 다운 (0,50) 후 40px 떨어진 (40,50)으로 한 번에 move —
      // 두 위치를 잇는 선분이 (20,50)을 통과하므로 삭제되어야 한다.
      notifier.onPointerDown(
        down(0, 50, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );
      notifier.onPointerUpdate(
        move(40, 50, kind: PointerDeviceKind.touch, pointer: 1),
        mode.state,
      );

      expect(notifier.currentScribble.strokes, isEmpty);
    });
  });

  // 5. 손(팬)모드 전환처럼 포인터 exit 이벤트 없이 커서를 숨겨야 하는 경우,
  //    clearCursor 로 pointerPosition 잔상을 제거한다 (kobic UB-108).
  group('clearCursor (UB-108 손/팬 모드 커서 잔상)', () {
    test('Erasing 상태의 pointerPosition을 제거한다', () {
      final notifier = ScribbleNotifier();
      notifier.state = Erasing(
        scribble: createScribble(),
        pointerPosition: createPoint(x: 10, y: 20),
      );

      notifier.clearCursor();

      expect(notifier.state.pointerPosition, isNull);
      expect(notifier.state, isA<Erasing>());
    });

    test('pointerPosition이 이미 없으면 상태를 바꾸지 않는다 (no-op)', () {
      final notifier = ScribbleNotifier();
      notifier.state = Erasing(scribble: createScribble());
      final before = notifier.state;

      notifier.clearCursor();

      expect(notifier.state.pointerPosition, isNull);
      expect(identical(notifier.state, before), isTrue);
    });
  });
}
