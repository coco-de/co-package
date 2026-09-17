import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/widgets/scribble_render_layers.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart'
    show StrokeCountNotifier;
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';

/// [ScribbleRenderLayers.buildImageLayer] 도구별 상호작용 가능 여부 회귀 테스트
/// (kobic #7888) — 이미지 도구뿐 아니라 올가미 도구에서도 이미지를 탭해
/// 선택/변형 핸들을 띄울 수 있어야 하고, 그 외 도구(예: 펜)에서는 여전히
/// 정적 렌더링만 하고 제스처를 무시해야 한다.
void main() {
  Widget host({
    required ScribbleNotifier notifier,
    required ScribbleModeNotifier modeNotifier,
    required ScribbleWidgetState widgetState,
  }) {
    final layers = ScribbleRenderLayers(
      scribbleNotifier: notifier,
      modeNotifier: modeNotifier,
      widgetState: widgetState,
      strokeCountNotifier: StrokeCountNotifier(),
      background: null,
      backgroundChild: null,
      size: const Size(400, 400),
      drawPen: true,
      drawEraser: true,
    );

    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              children: [layers.buildImageLayer()],
            ),
          ),
        ),
      ),
    );
  }

  ScribbleNotifier notifierWithImage() {
    final notifier = ScribbleNotifier();
    notifier.addImageDrawable(
      ImageDrawableFactory.create(
        id: 'img-1',
        source: 'file:///tmp/a.png',
        position: const Offset(100, 100),
        size: const Size(120, 120),
      ),
    );
    return notifier;
  }

  testWidgets('올가미 모드에서 이미지를 탭하면 선택 핸들이 나타난다', (tester) async {
    final notifier = notifierWithImage();
    addTearDown(notifier.dispose);
    final modeNotifier = ScribbleModeNotifier();
    addTearDown(modeNotifier.dispose);
    modeNotifier.setSelectedInk(InkModes.lasso);

    await tester.pumpWidget(
      host(
        notifier: notifier,
        modeNotifier: modeNotifier,
        widgetState: ScribbleWidgetState(),
      ),
    );

    // 이미지 중심(160, 160) 탭.
    await tester.tapAt(const Offset(160, 160));
    await tester.pump();

    expect(
      find.byIcon(Icons.close),
      findsOneWidget,
      reason: '올가미 모드에서도 삭제 핸들이 보여야 한다',
    );
    expect(find.byIcon(Icons.open_in_full), findsOneWidget);
  });

  testWidgets('펜 모드에서는 이미지를 탭해도 선택 핸들이 나타나지 않는다', (tester) async {
    final notifier = notifierWithImage();
    addTearDown(notifier.dispose);
    final modeNotifier = ScribbleModeNotifier();
    addTearDown(modeNotifier.dispose);
    modeNotifier.setSelectedInk(InkModes.pen);

    await tester.pumpWidget(
      host(
        notifier: notifier,
        modeNotifier: modeNotifier,
        widgetState: ScribbleWidgetState(),
      ),
    );

    await tester.tapAt(const Offset(160, 160));
    await tester.pump();

    expect(
      find.byIcon(Icons.close),
      findsNothing,
      reason: '펜 모드에서는 이미지 레이어가 IgnorePointer 로 막혀야 한다',
    );
    expect(find.byIcon(Icons.open_in_full), findsNothing);
  });
}
