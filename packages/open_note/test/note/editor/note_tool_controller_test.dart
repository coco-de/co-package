import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/module/scribble_mode.notifier.dart';
import 'package:open_note/src/module/state/drawing_state.dart';
import 'package:open_note/src/module/state/scribble_input_options.dart';
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/editor/note_tool_controller.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/layer/note_layered_page_view.dart';
import 'package:open_note/src/note/tools/tools.dart';

import '../support/note_test_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NoteToolController tools;
  late ScribbleModeNotifier mode;

  setUp(() {
    tools = NoteToolController();
    mode = ScribbleModeNotifier();
  });

  tearDown(() {
    tools.dispose();
    mode.dispose();
    final drawing = DrawingState();
    drawing.selectedTool.value = DrawingTool.pen;
    drawing.pointerMode.value = DrawingPointerMode.penOnly;
  });

  group('엔진에 반영', () {
    test('bind 하면 활성 프리셋(검정 펜)을 전역 상태와 모드에 적용한다', () {
      tools.bind(mode);

      expect(tools.currentTool, NoteInkTypes.pen);
      expect(DrawingState().selectedTool.value, DrawingTool.pen);
      expect(mode.state.inkGroupInfo.selectedInk, 'pen');
      expect(mode.state.inkGroupInfo.selectedColor, const Color(0xFF000000));
      expect(mode.state.inkGroupInfo.seletedStrokeWidth, 0.5);
      expect(mode.state.inputOptions.lineStyle, isEmpty);
    });

    test('펜 설정 · 선 스타일 · 지우개 · 올가미 · 보정은 입력 옵션이 된다', () {
      tools
        ..bind(mode)
        ..penSettings = const NotePenSettings(
          motionSmoothing: 8,
          stabilization: 0.5,
          pressureSensitivity: 1,
        )
        ..setLineStyle('dashed:1.4:1.6')
        ..eraserSettings = const NoteEraserSettings(
          mode: NoteEraserMode.pixel,
          size: 30,
          pressureSwitchEnabled: true,
          pressureThreshold: 0.7,
        )
        ..lassoSettings = const NoteLassoSettings(
          shape: NoteLassoShape.rectangle,
        )
        ..holdToSnapShapes = true;

      final options = mode.state.inputOptions;
      expect(options.pen.smoothing, 0.8);
      expect(options.pen.streamline, closeTo(0.5, 1e-9));
      expect(options.pen.thinningScale, 1.5);
      expect(options.pen.pressureGamma, 2);
      expect(options.lineStyle, 'dashed:1.4:1.6');
      expect(options.eraserMode, ScribbleEraserMode.pixel);
      expect(options.pressureEraser, isTrue);
      expect(options.pressureEraserThreshold, 0.7);
      expect(options.rectangleLasso, isTrue);
      expect(options.holdToSnapShapes, isTrue);
      // 필압 지우개가 쓰는 지우개 두께 = 크기의 절반.
      expect(mode.state.inkGroupInfo.strokeWidthOf('erase'), 15);
      expect(mode.state.inkGroupInfo.selectedInk, 'pen');
    });

    test('손가락 필기는 포인터 모드를 바꾼다', () {
      tools.bind(mode);
      expect(mode.state.allowedPointersMode, ScribblePointerMode.penOnly);

      tools.fingerDrawing = true;

      expect(mode.state.allowedPointersMode, ScribblePointerMode.all);
    });

    test('색 · 두께는 도구마다 기억한다', () {
      tools
        ..bind(mode)
        ..setColor(const Color(0xFF112233))
        ..setWidth(3)
        ..selectTool(NoteInkTypes.pencil)
        ..setWidth(5)
        ..selectTool(NoteInkTypes.pen);

      expect(tools.color, const Color(0xFF112233));
      expect(tools.width, 3);
      expect(mode.state.inkGroupInfo.seletedStrokeWidth, 3);
      expect(tools.widthOf(NoteInkTypes.pencil), 5);
    });

    test('지우개 두께 설정은 지우개 크기를 바꾸고 올가미는 색을 무시한다', () {
      tools
        ..bind(mode)
        ..selectTool(NoteInkTypes.erase)
        ..setWidth(40);
      expect(tools.eraserSettings.size, 40);
      expect(mode.state.inkGroupInfo.seletedStrokeWidth, 20);

      var notified = 0;
      tools
        ..selectTool(NoteInkTypes.lasso)
        ..addListener(() => notified++)
        ..setColor(const Color(0xFFFF0000))
        ..setWidth(9);
      expect(notified, 0);
    });
  });

  group('도구 전환 · 프리셋 · 펜슬 제스처', () {
    test('이전 도구와 지우개 토글', () {
      tools
        ..bind(mode)
        ..selectTool(NoteInkTypes.marker)
        ..previousTool();
      expect(tools.currentTool, NoteInkTypes.pen);

      tools.toggleEraser();
      expect(tools.currentTool, NoteInkTypes.erase);
      tools.toggleEraser();
      expect(tools.currentTool, NoteInkTypes.pen);
    });

    test('지우개만 쓰다 토글하면 펜으로 돌아간다', () {
      final eraserFirst = NoteToolController(
        presets: NoteToolPresetStore(),
        ink: NoteInkTypes.erase,
      );
      addTearDown(eraserFirst.dispose);

      eraserFirst.toggleEraser();

      expect(eraserFirst.currentTool, NoteInkTypes.pen);
    });

    test('프리셋 적용 · 순환 · 저장', () {
      tools.bind(mode);
      final red = tools.presets.find(NoteToolPresetStore.redPenId)!;

      tools.applyPreset(red);
      expect(tools.color, red.color);
      expect(mode.state.inkGroupInfo.seletedStrokeWidth, red.width);

      tools.cyclePreset();
      expect(tools.presets.activeId, NoteToolPresetStore.bluePenId);
      expect(tools.color, tools.presets.active!.color);

      tools
        ..selectTool(NoteInkTypes.pencil)
        ..setLineStyle('wavy:1:6');
      final saved = tools.saveAsPreset(name: '물결')!;
      expect(saved.ink, NoteInkTypes.pencil);
      expect(saved.lineStyle, 'wavy:1:6');
      tools.selectTool(NoteInkTypes.lasso);
      expect(tools.saveAsPreset(), isNull);
    });

    test('펜슬 제스처는 매핑한 동작을 실행한다', () {
      var undone = 0;
      var palette = 0;
      tools
        ..bind(mode)
        ..onUndo = (() => undone++)
        ..onShowToolPalette = (() => palette++)
        ..selectTool(NoteInkTypes.marker);

      tools.dispatcher.dispatch(NotePencilGesture.doubleTap);
      expect(tools.currentTool, NoteInkTypes.pen);
      tools.dispatcher.dispatch(NotePencilGesture.squeeze);
      expect(palette, 1);

      tools.dispatcher.map = const NotePencilGestureMap(
        doubleTap: NotePencilAction.toggleEraser,
        squeeze: NotePencilAction.undo,
      );
      tools.dispatcher.dispatch(NotePencilGesture.doubleTap);
      expect(tools.currentTool, NoteInkTypes.erase);
      tools.dispatcher.dispatch(NotePencilGesture.squeeze);
      expect(undone, 1);
    });
  });

  testWidgets('획을 시작해도 고른 프리셋이 유지된다 (전역 상태 덮어쓰기 회귀)', (tester) async {
    final layers = NoteLayerStack();
    addTearDown(layers.dispose);
    // 다른 화면이 남긴 전역 도구가 있어도, 컨트롤러가 적용한 값이 이긴다.
    DrawingState().selectedTool.value = DrawingTool.marker;
    tools.bind(mode);
    final blue = tools.presets.find(NoteToolPresetStore.bluePenId)!;
    tools.applyPreset(blue);
    tools.setLineStyle('dotted:0.1:1.6');

    await tester.pumpWidget(
      noteTestHost(
        NoteLayeredPageView(
          layers: layers,
          modeNotifier: mode,
          pageSize: const NotePageSize(300, 400),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final gesture = await tester.startGesture(
      const Offset(400, 200),
      kind: PointerDeviceKind.stylus,
    );
    await gesture.moveTo(const Offset(430, 230));
    await gesture.moveTo(const Offset(460, 260));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    final stroke = layers.activeNotifier.currentScribble.strokes.single;
    expect(stroke.ink, 'pen');
    expect(stroke.color, blue.color.toARGB32(), reason: '파란 펜 프리셋');
    expect(stroke.width, blue.width);
    expect(stroke.lineStyle, 'dotted:0.1:1.6');
    expect(layers.activeNotifier.state, isA<Drawing>());
  });

  test('닫힌 노트의 레이어는 전역 상태에 남지 않는다', () {
    final layers = NoteLayerStack();
    DrawingState().setLastActiveScribbleNotifier(layers.activeNotifier);

    layers.dispose();

    expect(DrawingState().lastActiveScribbleNotifier, isNull);
    expect(() => tools.bind(mode), returnsNormally);
  });

  test('도구를 적용해도 다른 필기 화면의 상태는 건드리지 않는다', () {
    final other = ScribbleNotifier()..setEraser();
    addTearDown(other.dispose);
    DrawingState().setLastActiveScribbleNotifier(other);

    tools
      ..bind(mode)
      ..selectTool(NoteInkTypes.erase)
      ..selectTool(NoteInkTypes.pencil);

    expect(other.state, isA<Erasing>());
    expect(mode.state.inkGroupInfo.selectedInk, NoteInkTypes.pencil);
    expect(
      mode.state.inkGroupInfo.strokeWidthOf(NoteInkTypes.erase),
      tools.eraserSettings.size / 2,
    );
  });
}
