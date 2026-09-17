// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';

import '../helpers/test_helpers.dart';

/// 언두/히스토리 입도 회귀 테스트.
///
/// 필기 기능 전면 재검토에서 확정된 히스토리 결함들의 회귀 방지:
/// - 지우개가 move마다/up마다 히스토리에 push해 undo 단위가 깨지고
///   maxHistoryLength(30) 잠식·redo 스택 파괴가 일어나는 문제
/// - 페이지 로드가 히스토리에 push되어 undo 한 번으로 빈 화면이 되는 문제
/// - 생성자 이중 state 할당으로 생성 직후 canUndo == true가 되는 문제
/// - 텍스트 드래그 중간 업데이트가 히스토리를 가득 채우는 문제
/// - 올가미 선택 스트로크가 히스토리에 들어가 undo 시 윤곽선이 복원되는 문제
void main() {
  PointerDownEvent down(double x, double y, {int pointer = 1}) =>
      PointerDownEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: Offset(x, y),
      );

  PointerMoveEvent move(double x, double y, {int pointer = 1}) =>
      PointerMoveEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: Offset(x, y),
      );

  PointerUpEvent up(double x, double y, {int pointer = 1}) => PointerUpEvent(
    kind: PointerDeviceKind.stylus,
    pointer: pointer,
    position: Offset(x, y),
  );

  /// y 좌표가 서로 다른 가로 스트로크 N개를 가진 Scribble
  Scribble strokesAt(List<double> ys) => createScribble(
    strokes: [
      for (final y in ys)
        createStroke(
          points: [createPoint(x: 50, y: y)],
          options: createStrokeOptions(size: 1.0, thinning: 0.0),
        ),
    ],
  );

  group('지우개 제스처 입도 — 한 제스처 = undo 1단위', () {
    test('한 번의 드래그로 3개를 지워도 undo 1회로 전부 복원된다', () {
      final notifier = ScribbleNotifier(scribble: strokesAt([10, 30, 50]));
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(4.0);
      notifier.setEraser();

      // 세 스트로크를 차례로 통과하는 수직 드래그
      notifier.onPointerDown(down(50, 0), mode.state);
      for (double y = 5; y <= 55; y += 5) {
        notifier.onPointerUpdate(move(50, y), mode.state);
      }
      expect(notifier.currentScribble.strokes, isEmpty, reason: '실시간 지우기 동작');
      notifier.onPointerUp(up(50, 55), mode.state);

      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(
        notifier.currentScribble.strokes.length,
        3,
        reason: '제스처 전체가 undo 1단위여야 한다 (move마다 항목이 쌓이면 안 됨)',
      );
    });

    test('빈 위치 지우개 탭은 히스토리에 push되지 않아 redo 스택이 보존된다', () {
      final notifier = ScribbleNotifier(scribble: strokesAt([10, 30]));
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(2.0);
      notifier.setEraser();

      // 스트로크 1개를 지우고 undo로 복원 대기 상태를 만든다
      notifier.onPointerDown(down(50, 8), mode.state);
      notifier.onPointerUpdate(move(50, 12), mode.state);
      notifier.onPointerUp(up(50, 12), mode.state);
      expect(notifier.currentScribble.strokes.length, 1);
      notifier.undo();
      expect(notifier.currentScribble.strokes.length, 2);
      expect(notifier.canRedo, isTrue);

      // 아무것도 없는 빈 공간을 지우개로 탭
      notifier.onPointerDown(down(300, 300), mode.state);
      notifier.onPointerUp(up(300, 300), mode.state);

      expect(
        notifier.canRedo,
        isTrue,
        reason: '아무것도 지우지 못한 빈 탭이 redo 스택을 파괴하면 안 된다',
      );
      notifier.redo();
      expect(notifier.currentScribble.strokes.length, 1);
    });

    test('30회를 초과하는 긴 지우기 제스처 후에도 이전 상태가 복구 가능하다', () {
      // 스트로크 35개 — move마다 push되면 maxHistoryLength(30)를 초과해
      // 지우기 이전 상태가 evict되어 복구가 불가능해진다.
      final ys = List<double>.generate(35, (i) => 10.0 + i * 10.0);
      final notifier = ScribbleNotifier(scribble: strokesAt(ys));
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setEraser();
      mode.setStrokeWidth(4.0);
      notifier.setEraser();

      notifier.onPointerDown(down(50, 0), mode.state);
      for (double y = 5; y <= 360; y += 5) {
        notifier.onPointerUpdate(move(50, y), mode.state);
      }
      notifier.onPointerUp(up(50, 360), mode.state);
      expect(notifier.currentScribble.strokes, isEmpty);

      notifier.undo();
      expect(
        notifier.currentScribble.strokes.length,
        35,
        reason: '긴 지우기 제스처가 히스토리 한도를 잠식해 복구 불가가 되면 안 된다',
      );
    });
  });

  group('페이지 로드 baseline — loadScribble이 undo 히스토리를 오염시키지 않음', () {
    test('loadScribble 직후 canUndo == false, undo해도 데이터 불변', () {
      final controller = ScribbleController();
      addTearDown(controller.dispose);

      controller.loadScribble(strokesAt([10, 30]));

      expect(
        controller.canUndo,
        isFalse,
        reason: '로드 직후 undo가 가능하면 빈 baseline으로 되돌아가 데이터가 유실된다',
      );
      controller.undo();
      expect(controller.currentScribble.strokes.length, 2);
    });

    test('로드 후 첫 스트로크를 undo하면 로드된 데이터로 복원된다 (빈 화면 아님)', () {
      final controller = ScribbleController();
      addTearDown(controller.dispose);

      controller.loadScribble(strokesAt([10]));

      // 첫 스트로크 추가 (setScribble 경유로 시뮬레이션)
      final withNew = strokesAt([10, 99]);
      controller.scribbleNotifier.setScribble(scribble: withNew);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(
        controller.currentScribble.strokes.length,
        1,
        reason: 'undo는 로드된 데이터로 돌아가야지 빈 화면이 되면 안 된다',
      );
    });

    test('resetHistory: false는 baseline을 보존한다 (라이브/리플레이 경로)', () {
      final controller = ScribbleController();
      addTearDown(controller.dispose);

      controller.loadScribble(strokesAt([10]));
      controller.loadScribble(strokesAt([10, 20]), resetHistory: false);

      // 외부 갱신은 히스토리에 들어가지 않는다
      expect(controller.canUndo, isFalse);
      expect(controller.currentScribble.strokes.length, 2);
    });
  });

  group('생성자 baseline — 직접 생성 경로 보정', () {
    test('ScribbleNotifier() 생성 직후 canUndo == false', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);
      expect(notifier.canUndo, isFalse);
    });

    test('scribble을 넘긴 생성 직후에도 canUndo == false', () {
      final notifier = ScribbleNotifier(scribble: strokesAt([10]));
      addTearDown(notifier.dispose);
      expect(notifier.canUndo, isFalse);
    });

    test('생성 후 첫 변경은 즉시 undo 가능하고, undo 후 두 번째 undo는 없다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      notifier.setScribble(scribble: strokesAt([10]));
      expect(notifier.canUndo, isTrue);

      notifier.undo();
      expect(notifier.currentScribble.strokes, isEmpty);
      expect(
        notifier.canUndo,
        isFalse,
        reason: '생성자 이중 state 할당으로 빈 undo 단계가 남아 있으면 안 된다',
      );
      expect(notifier.canRedo, isTrue);
    });
  });

  group('텍스트 중간 업데이트 — addToUndoHistory: false', () {
    test('중간 업데이트 50회는 히스토리를 채우지 않고, 확정 1회만 undo 단위가 된다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      // 기존 스트로크 1개 커밋 (이게 undo로 복원 가능해야 함)
      notifier.setScribble(scribble: strokesAt([10]));

      final text = createTextDrawable(x: 50, y: 50);
      notifier.addTextDrawable(text);

      // 드래그 중간 프레임 50회 (히스토리 미추가)
      for (int i = 1; i <= 50; i++) {
        final moved = text.deepCopy()..x = 50.0 + i;
        notifier.updateTextDrawable(text.id, moved, addToUndoHistory: false);
      }
      // 드래그 종료 확정 1회
      final finalText = text.deepCopy()..x = 100.0;
      notifier.updateTextDrawable(text.id, finalText);

      // undo 1회: 드래그 시작 전 위치로 한 번에 복귀
      notifier.undo();
      expect(notifier.currentScribble.textDrawables.first.x, 50.0);

      // undo 2회: 텍스트 추가 취소
      notifier.undo();
      expect(notifier.currentScribble.textDrawables, isEmpty);

      // undo 3회: 스트로크 제거 — 중간 프레임이 히스토리를 잠식했다면 불가능
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.currentScribble.strokes, isEmpty);
    });
  });

  group('올가미 선택 — 히스토리 오염 방지', () {
    test('올가미 선택 동작은 undo 단계를 소모하지 않는다', () {
      final notifier = ScribbleNotifier(scribble: strokesAt([50]));
      final mode = ScribbleModeNotifier();
      addTearDown(notifier.dispose);
      addTearDown(mode.dispose);
      mode.setLassoSelection();

      // 스트로크(50,50 부근)를 감싸는 올가미를 그린다
      notifier.onPointerDown(down(30, 30), mode.state);
      for (final p in const [
        Offset(70, 30),
        Offset(70, 70),
        Offset(30, 70),
        Offset(30, 31),
      ]) {
        notifier.onPointerUpdate(move(p.dx, p.dy), mode.state);
      }
      notifier.onPointerUp(up(30, 30), mode.state);

      expect(
        notifier.canUndo,
        isFalse,
        reason: '선택용 올가미 스트로크가 undo 히스토리에 들어가면 안 된다',
      );
    });

    test('히스토리에 들어간 올가미 스트로크는 undo 복원 시 정화된다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      // 과거 버전이 남긴 것처럼 올가미 포함 상태를 히스토리에 직접 push
      final withLasso = createScribble(
        strokes: [
          createStroke(points: [createPoint(x: 1, y: 1)]),
          createStroke(
            points: [createPoint(x: 2, y: 2)],
            ink: InkModes.lasso,
          ),
        ],
      );
      notifier.setScribble(scribble: withLasso);
      notifier.setScribble(scribble: strokesAt([99]));

      notifier.undo();

      expect(
        notifier.currentScribble.strokes.any(
          (s) => s.ink == InkModes.lasso,
        ),
        isFalse,
        reason: 'undo로 복원된 상태에 올가미 윤곽선이 콘텐츠처럼 남으면 안 된다',
      );
      expect(notifier.currentScribble.strokes.length, 1);
    });
  });

  group('clear() — 텍스트/이미지 전용 페이지', () {
    test('텍스트만 있는 페이지에서도 전체 지우기가 동작한다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      notifier.addTextDrawable(createTextDrawable());
      expect(notifier.currentScribble.textDrawables, isNotEmpty);

      notifier.clear();

      expect(notifier.currentScribble.textDrawables, isEmpty);
      expect(notifier.canUndo, isTrue, reason: 'clear는 undo 가능해야 한다');
    });

    test('완전히 빈 페이지에서 clear()는 no-op (히스토리 미추가)', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      notifier.clear();

      expect(notifier.canUndo, isFalse);
    });
  });
}
