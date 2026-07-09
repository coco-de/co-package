import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/image/image_drawable_layer.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';

void main() {
  // 결정적 테스트를 위해 파일 로드 대신 1x1 투명 provider 를 주입한다.
  ImageProvider fakeResolver(String source) =>
      const AssetImage('__test_fake__');

  Widget host({
    required ScribbleNotifier notifier,
    required ScribbleWidgetState widgetState,
    required bool interactive,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 500,
            height: 500,
            child: ImageDrawableLayer(
              notifier: notifier,
              widgetState: widgetState,
              interactive: interactive,
              imageProviderResolver: fakeResolver,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('이미지가 없으면 아무것도 렌더링하지 않는다', (tester) async {
    final notifier = ScribbleNotifier();
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      host(
        notifier: notifier,
        widgetState: ScribbleWidgetState(),
        interactive: true,
      ),
    );

    expect(find.byType(Image), findsNothing);
  });

  testWidgets('이미지가 있으면 렌더링하고, 탭하면 변형/삭제 핸들이 나타난다', (tester) async {
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

    await tester.pumpWidget(
      host(
        notifier: notifier,
        widgetState: ScribbleWidgetState(),
        interactive: true,
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    // 선택 전에는 핸들 없음.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.open_in_full), findsNothing);

    // 이미지 중심(160, 160)을 탭해 선택.
    await tester.tapAt(const Offset(160, 160));
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget); // 삭제 핸들
    expect(find.byIcon(Icons.open_in_full), findsOneWidget); // 변형 핸들
  });

  testWidgets('비활성(interactive=false) 모드에서는 렌더만 하고 핸들이 없다', (tester) async {
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

    final widgetState = ScribbleWidgetState()..selectedImageId = 'img-1';

    await tester.pumpWidget(
      host(notifier: notifier, widgetState: widgetState, interactive: false),
    );

    expect(find.byType(Image), findsOneWidget);
    // 비활성 모드에서는 선택 핸들을 만들지 않는다.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.open_in_full), findsNothing);
  });

  testWidgets(
    '선택된 이미지를 드래그하는 동안 widgetState.isImageTransforming 이 true 로 유지되고 '
    '종료 시 해제된다 (페이지 뷰어 pan 전달 차단 신호, kobic #8101)',
    (tester) async {
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
      final widgetState = ScribbleWidgetState();

      await tester.pumpWidget(
        host(notifier: notifier, widgetState: widgetState, interactive: true),
      );

      // 이미지 중심(160, 160)을 탭해 선택.
      await tester.tapAt(const Offset(160, 160));
      await tester.pump();
      expect(widgetState.selectedImageId, 'img-1');
      expect(widgetState.isImageTransforming, isFalse);

      // 선택된 이미지를 드래그 — 페이지 뷰어(InteractiveViewer)의 pan 전달을
      // 차단하는 신호(`isImageTransforming`)가 드래그 도중 켜져 있어야 한다.
      final gesture = await tester.startGesture(const Offset(160, 160));
      await gesture.moveBy(const Offset(30, 10));
      await tester.pump();
      expect(widgetState.isImageTransforming, isTrue);

      await gesture.up();
      await tester.pump();
      expect(widgetState.isImageTransforming, isFalse);
    },
  );

  testWidgets('삭제 핸들 탭 시 이미지가 제거된다', (tester) async {
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

    await tester.pumpWidget(
      host(
        notifier: notifier,
        widgetState: ScribbleWidgetState(),
        interactive: true,
      ),
    );

    await tester.tapAt(const Offset(160, 160));
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(notifier.getCurrentImageDrawables(), isEmpty);
    expect(find.byType(Image), findsNothing);
  });
}
