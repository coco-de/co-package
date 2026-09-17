// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/lasso/lasso_selection_manager.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

import '../helpers/test_helpers.dart';

/// 올가미/변형 회귀 테스트.
///
/// 필기 기능 전면 재검토에서 확정된 결함들의 회귀 방지:
/// - 올가미 이동이 undo 히스토리와 공유된 protobuf Point를 in-place 수정해
///   undo가 원위치를 복원하지 못하는 문제 (copy-on-write로 보호)
/// - undo/redo로 스트로크 목록이 바뀌어도 인덱스 기반 선택이 리셋되지 않아
///   엉뚱한 스트로크가 이동/삭제되는 문제 (onHistoryApplied 콜백)
/// - 공개 resetLassoState()가 텍스트 선택을 초기화하지 않는 문제
void main() {
  /// (25,25) 부근의 점 스트로크 1개와 그것을 감싸는 올가미 스트로크
  Scribble scribbleWithLassoSelection() => createScribble(
    strokes: [
      createStroke(
        points: createLinePoints(fromX: 20, fromY: 20, toX: 30, toY: 30),
      ),
      createStroke(
        ink: InkModes.lasso,
        points: createPoints([
          [0, 0],
          [50, 0],
          [50, 50],
          [0, 50],
          [0, 1],
        ]),
      ),
    ],
  );

  group('올가미 이동 — undo 히스토리 보호 (copy-on-write)', () {
    testWidgets('이동 후 undo하면 스트로크가 원위치로 복원된다', (tester) async {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox(width: 400, height: 400);
            },
          ),
        ),
      );

      final manager = LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

      // 스트로크를 히스토리에 커밋 후 올가미로 선택
      notifier.setScribble(scribble: scribbleWithLassoSelection());
      manager.selectElementsInLassoIfNeeded();
      expect(manager.selectedStrokeIds, isNotEmpty);

      // 원본 좌표 기록 (deep copy로 분리)
      final originalFirstPoint = notifier
          .currentScribble
          .strokes
          .first
          .points
          .first
          .deepCopy();

      // 박스 드래그로 (100, 100) 이동
      manager.onMoveStart(
        DragStartDetails(globalPosition: const Offset(25, 25)),
        capturedContext,
      );
      manager.onMoveUpdate(
        DragUpdateDetails(globalPosition: const Offset(125, 125)),
        capturedContext,
      );
      manager.onMoveEnd(DragEndDetails());

      // 이동이 실제로 적용되었는지 확인
      final moved = notifier.currentScribble.strokes.first.points.first;
      expect(moved.x, isNot(closeTo(originalFirstPoint.x, 0.001)));

      // undo → 원위치 복원 (in-place 수정이 히스토리 스냅샷을 오염시켰다면
      // 복원된 좌표도 이동된 값이 되어 실패한다)
      notifier.undo();
      final restored = notifier.currentScribble.strokes.first.points.first;
      expect(
        restored.x,
        closeTo(originalFirstPoint.x, 0.001),
        reason: '변형이 히스토리와 공유된 Point를 in-place 수정하면 undo가 원위치를 복원하지 못한다',
      );
      expect(restored.y, closeTo(originalFirstPoint.y, 0.001));
    });
  });

  group('올가미 이동 완료 시 onScribbleFinished 발화 (kobic#10836)', () {
    testWidgets('이동 완료 시 onScribbleFinished 가 한 번만 호출된다', (tester) async {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox(width: 400, height: 400);
            },
          ),
        ),
      );

      var finishedCallCount = 0;
      notifier.onScribbleFinished = () => finishedCallCount++;
      final manager = LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

      notifier.setScribble(scribble: scribbleWithLassoSelection());
      finishedCallCount = 0; // 위 setScribble 호출분은 이 테스트의 관심사가 아니다
      manager.selectElementsInLassoIfNeeded();
      expect(manager.selectedStrokeIds, isNotEmpty);

      manager.onMoveStart(
        DragStartDetails(globalPosition: const Offset(25, 25)),
        capturedContext,
      );
      expect(finishedCallCount, 0, reason: '이동 시작만으로는 완료 콜백이 울리면 안 된다');

      manager.onMoveUpdate(
        DragUpdateDetails(globalPosition: const Offset(125, 125)),
        capturedContext,
      );
      expect(
        finishedCallCount,
        0,
        reason:
            '이동 진행 중(매 프레임)에는 완료 콜백이 울리면 안 된다 — 위반하면 '
            'onScribbleChanged 처럼 진행 중 프레임과 완료 시점을 구분할 수 없어져 '
            '호스트 앱의 제스처 손상 방지 로직(kobic#10836)이 무력화된다',
      );

      manager.onMoveEnd(DragEndDetails());
      expect(finishedCallCount, 1, reason: '이동이 히스토리에 커밋된 시점에 정확히 한 번 울려야 한다');
    });

    test('선택된 스트로크가 없으면 onScribbleFinished 를 호출하지 않는다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      var finishedCallCount = 0;
      notifier.onScribbleFinished = () => finishedCallCount++;
      final manager = LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

      manager.onMoveEnd(DragEndDetails());

      expect(finishedCallCount, 0);
    });
  });

  group('올가미 크기조절/회전 완료 시 onScribbleFinished 발화 (kobic#10836)', () {
    testWidgets('크기조절/회전 완료 시 onScribbleFinished 가 한 번만 호출된다', (tester) async {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox(width: 400, height: 400);
            },
          ),
        ),
      );

      var finishedCallCount = 0;
      notifier.onScribbleFinished = () => finishedCallCount++;
      final manager = LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

      notifier.setScribble(scribble: scribbleWithLassoSelection());
      finishedCallCount = 0; // 위 setScribble 호출분은 이 테스트의 관심사가 아니다
      manager.selectElementsInLassoIfNeeded();
      expect(manager.selectedStrokeIds, isNotEmpty);

      manager.onResizeRotateStart(
        DragStartDetails(globalPosition: const Offset(20, 30)),
        capturedContext,
      );
      expect(finishedCallCount, 0, reason: '변형 시작만으로는 완료 콜백이 울리면 안 된다');

      manager.onResizeRotateUpdate(
        DragUpdateDetails(globalPosition: const Offset(10, 40)),
        capturedContext,
      );
      expect(finishedCallCount, 0, reason: '변형 진행 중(매 프레임)에는 완료 콜백이 울리면 안 된다');

      manager.onResizeRotateEnd(DragEndDetails());
      expect(finishedCallCount, 1, reason: '변형이 히스토리에 커밋된 시점에 정확히 한 번 울려야 한다');
    });
  });

  group('undo/redo 시 인덱스 기반 선택 무효화', () {
    test('onHistoryApplied 콜백이 undo 시 호출된다', () async {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      var callCount = 0;
      notifier.onHistoryApplied = () => callCount++;

      notifier.setScribble(
        scribble: createScribble(
          strokes: [
            createStroke(points: [createPoint(x: 1, y: 1)]),
          ],
        ),
      );
      notifier.undo();
      await Future<void>.delayed(Duration.zero);

      expect(callCount, 1);

      notifier.redo();
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 2);
    });
  });

  group('resetLassoState — 텍스트 선택 잔존 방지', () {
    test('공개 resetLassoState()가 텍스트 선택도 초기화한다', () {
      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      final manager = LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

      // 텍스트 + 스트로크를 올가미로 선택
      final scribble = scribbleWithLassoSelection()
        ..textDrawables.add(createTextDrawable(x: 25, y: 25));
      notifier.setScribble(scribble: scribble, addToUndoHistory: false);
      manager.selectElementsInLassoIfNeeded();
      expect(manager.selectedTextIds, isNotEmpty);

      manager.resetLassoState();

      expect(manager.selectedStrokeIds, isEmpty);
      expect(
        manager.selectedTextIds,
        isEmpty,
        reason: '선택 해제 후에도 텍스트 선택이 내부에 잔존하면 안 된다',
      );
    });
  });
}
