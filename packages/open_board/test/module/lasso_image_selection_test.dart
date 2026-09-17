// 🐦 Flutter imports:
import 'package:flutter/material.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:open_board/src/module/image/image_drawable_extensions.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/lasso/lasso_selection_manager.dart';
import 'package:open_board/src/module/scribble.notifier.dart';

/// 올가미 도구 + 이미지 선택 회귀 테스트 (kobic #7888).
///
/// 배경: 이미지는 이미지 도구(`InkModes.image`)에서만 선택/이동/크기조절이
/// 가능했다. 다른 도구로 전환한 뒤 올가미 도구로 다시 돌아와도 이미지를
/// 재선택할 수 없었다. 올가미 도구에서도 이미지 레이어가 상호작용
/// 가능하도록 확장하면서, 이미지를 직접 터치했을 때 올가미 자유선 그리기가
/// 함께 시작되는 회귀를 방지하기 위한 가드([LassoSelectionManager.
/// handleLassoModePointerDown] 최상단 단락회로)를 검증한다.
void main() {
  late BuildContext capturedContext;

  Future<void> pumpHost(WidgetTester tester) async {
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
  }

  LassoSelectionManager buildManager(ScribbleNotifier notifier) =>
      LassoSelectionManager(
        scribbleNotifier: notifier,
        onStateChanged: () {},
        transformationController: TransformationController(),
        onModeChanged: null,
      );

  group('올가미 모드에서 기존 이미지 터치', () {
    testWidgets('이미지 위 터치는 true를 반환하고 올가미 상태를 건드리지 않는다', (tester) async {
      await pumpHost(tester);

      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);
      notifier.addImageDrawable(
        ImageDrawableFactory.create(
          id: 'img-1',
          source: 'file:///tmp/a.png',
          position: const Offset(100, 100),
          size: const Size(120, 120),
        ),
      );

      final manager = buildManager(notifier);

      final handled = manager.handleLassoModePointerDown(
        const PointerDownEvent(position: Offset(160, 160)), // 이미지 중심
        capturedContext,
      );

      expect(handled, isTrue, reason: '이미지 위 터치는 이미지 레이어에 위임되어야 한다');
      expect(
        manager.selectedStrokeIds,
        isEmpty,
        reason: '올가미 자체 선택 상태가 만들어지면 안 된다',
      );
      expect(manager.showLassoOverlay, isFalse);
      expect(
        notifier.currentScribble.strokes,
        isEmpty,
        reason: '올가미 자유선 그리기가 함께 시작되면 안 된다',
      );
    });

    testWidgets('이미지가 없는 위치의 터치는 기존과 동일하게 false를 반환한다', (tester) async {
      await pumpHost(tester);

      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);
      notifier.addImageDrawable(
        ImageDrawableFactory.create(
          id: 'img-1',
          source: 'file:///tmp/a.png',
          position: const Offset(100, 100),
          size: const Size(120, 120),
        ),
      );

      final manager = buildManager(notifier);

      final handled = manager.handleLassoModePointerDown(
        const PointerDownEvent(position: Offset(10, 10)), // 이미지 밖
        capturedContext,
      );

      expect(handled, isFalse, reason: '이미지 밖 터치는 일반 올가미 그리기로 넘어가야 한다');
    });

    testWidgets('숨겨진(hidden) 이미지는 터치를 가로채지 않는다', (tester) async {
      await pumpHost(tester);

      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);
      notifier.addImageDrawable(
        ImageDrawableFactory.create(
          id: 'img-1',
          source: 'file:///tmp/a.png',
          position: const Offset(100, 100),
          size: const Size(120, 120),
        ).copyWithHidden(true),
      );

      final manager = buildManager(notifier);

      final handled = manager.handleLassoModePointerDown(
        const PointerDownEvent(position: Offset(160, 160)),
        capturedContext,
      );

      expect(handled, isFalse);
    });

    testWidgets('이미지가 전혀 없으면 기존 동작(false)이 유지된다', (tester) async {
      await pumpHost(tester);

      final notifier = ScribbleNotifier();
      addTearDown(notifier.dispose);

      final manager = buildManager(notifier);

      final handled = manager.handleLassoModePointerDown(
        const PointerDownEvent(position: Offset(160, 160)),
        capturedContext,
      );

      expect(handled, isFalse);
    });
  });
}
