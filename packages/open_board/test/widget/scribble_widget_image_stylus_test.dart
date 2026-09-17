import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/image/image_drawable_factory.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이미지 모드에서 스타일러스 탭이 이미지 선택 대신 스트로크 드로잉으로
/// 오인식되던 회귀 방지 테스트 (kobic #8101).
///
/// `ScribbleWidget._processPointerDown()` 는 기존에 `text`/`lasso` 모드만
/// 별도 분기했고, `image` 모드는 펜/지우개 등 실제 그리기 도구와 같은 분기로
/// 처리되어 `_canStartDrawing()`(현재 도구가 아니라 `DrawingPointerMode`만
/// 검사)이 true 를 반환하면 `handleNormalDrawingMode()` 가 호출되어 빈
/// 스트로크가 그려지고 이미지 탭이 선택으로 이어지지 않았다. 기본
/// `DrawingPointerMode` 가 `penOnly` 라 스타일러스에서만 이 경로를 탔다.
void main() {
  group('ScribbleWidget 이미지 모드 + 스타일러스 (kobic #8101)', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      scribbleNotifier.addImageDrawable(
        ImageDrawableFactory.create(
          id: 'img-1',
          source: 'file:///tmp/a.png',
          position: const Offset(100, 100),
          size: const Size(120, 120),
        ),
      );
      modeNotifier = ScribbleModeNotifier()..setImage();
      // 기본값이자, 스타일러스에서만 버그가 재현되는 정책을 명시적으로 고정.
      DrawingState().pointerMode.value = DrawingPointerMode.penOnly;
      // `_buildStylusPanBlocker()`는 전역 DrawingState.selectedTool 을 읽는다
      // (modeNotifier 의 InkModes 와는 별개 소스) — 실제 앱에서 이미지 도구를
      // 선택하면 둘 다 image 로 동기화되므로 테스트에서도 함께 맞춘다.
      DrawingState().selectedTool.value = DrawingTool.image;
    });

    tearDown(() {
      DrawingState().pointerMode.value = DrawingPointerMode.penOnly;
      DrawingState().selectedTool.value = DrawingTool.pencil;
      scribbleNotifier.dispose();
      modeNotifier.dispose();
    });

    Widget buildTestWidget() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: ScribbleWidget(
            notifier: scribbleNotifier,
            modeNotifier: modeNotifier,
            child: const SizedBox(width: 300, height: 400),
          ),
        ),
      ),
    );

    testWidgets(
      'should_select_image_via_stylus_tap_without_drawing_stray_stroke',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 이미지 중심(160, 160)을 스타일러스로 탭.
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.stylus,
        );
        await gesture.down(const Offset(160, 160));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // 이미지 선택 핸들(삭제/변형)이 나타나야 한다.
        expect(
          find.byIcon(Icons.close),
          findsOneWidget,
          reason: '스타일러스 탭으로 이미지가 선택되어 삭제 핸들이 보여야 한다',
        );
        expect(find.byIcon(Icons.open_in_full), findsOneWidget);

        // 이미지 탭이 스트로크로 오인식되어 빈 획이 그려지지 않아야 한다.
        expect(scribbleNotifier.currentState.scribble.strokes, isEmpty);
      },
    );
  });
}
