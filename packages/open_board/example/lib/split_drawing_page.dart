import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:open_board/open_board.dart';

/// 좌우 2분할 독립 필기 영역 + 하나의 플로팅 도구 데모.
///
/// 두 개의 독립 [ScribbleController]를 좌우로 배치하고, 하나의
/// [ScribbleFloatingToolbar]로 양쪽을 동시에 제어합니다. 각
/// [ScribbleWidget]은 마운트 시 [DrawingState] 싱글톤에 자동 등록되므로,
/// 플로팅 도구의 도구/색상/두께 변경이 두 영역에 함께 반영됩니다.
class SplitDrawingPage extends StatefulWidget {
  const SplitDrawingPage({super.key});

  @override
  State<SplitDrawingPage> createState() => _SplitDrawingPageState();
}

class _SplitDrawingPageState extends State<SplitDrawingPage> {
  final DrawingState _drawingState = DrawingState();
  late final ScribbleController _left;
  late final ScribbleController _right;

  @override
  void initState() {
    super.initState();
    _left = ScribbleController();
    _right = ScribbleController();

    _drawingState.selectedTool.value = DrawingTool.pen;
    _drawingState.selectedColor.value = Colors.black;
    _drawingState.selectedThickness.value = 2.0;
    _drawingState.pointerMode.value = DrawingPointerMode.mouseOnly;
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  // ===== AI 에이전트 검증용 입력 주입 (디버그 데모 전용) =====
  //
  // 런타임 구동 도구(marionette)는 합성 탭만 보낼 수 있어 자유 드로잉
  // 제스처를 만들 수 없다. 아래 버튼들은 notifier에 stylus 포인터
  // 이벤트 시퀀스를 주입해 실제 입력 파이프라인(그리기/지우기)을
  // 프로그래매틱으로 재현한다.
  int _injectSeq = 1;

  void _injectStroke(ScribbleController controller, Offset start) {
    final n = controller.scribbleNotifier;
    final m = controller.modeNotifier;
    _drawingState.setLastActiveScribbleNotifier(n);
    _drawingState.applyToModeNotifier(m);
    n.setStrokeInk();

    final pointer = _injectSeq++;
    n.onPointerDown(
      PointerDownEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: start,
      ),
      m.state,
    );
    for (var i = 1; i <= 14; i++) {
      n.onPointerUpdate(
        PointerMoveEvent(
          kind: PointerDeviceKind.stylus,
          pointer: pointer,
          position: start + Offset(i * 10.0, math.sin(i / 2) * 30),
        ),
        m.state,
      );
    }
    n.onPointerUp(
      PointerUpEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: start + const Offset(140, 0),
      ),
      m.state,
    );
    debugPrint(
      '[inject] strokes=${n.currentScribble.strokes.length} '
      'canUndo=${n.canUndo} '
      'lastActiveSame=${identical(_drawingState.lastActiveScribbleNotifier, n)} '
      'globalCanUndo=${_drawingState.canUndoNotifier.value}',
    );
    _drawingState.updateUndoRedoState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          '[inject:post2] globalCanUndo=${_drawingState.canUndoNotifier.value} '
          'notifierCanUndo=${n.canUndo}',
        );
      });
    });
    setState(() {});
  }

  void _injectErase(ScribbleController controller, Offset start) {
    final n = controller.scribbleNotifier;
    final m = controller.modeNotifier;
    _drawingState.setLastActiveScribbleNotifier(n);
    m.setEraser();
    n.setEraser();

    final pointer = _injectSeq++;
    n.onPointerDown(
      PointerDownEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: start,
      ),
      m.state,
    );
    for (var i = 1; i <= 14; i++) {
      n.onPointerUpdate(
        PointerMoveEvent(
          kind: PointerDeviceKind.stylus,
          pointer: pointer,
          position: start + Offset(i * 10.0, 0),
        ),
        m.state,
      );
    }
    n.onPointerUp(
      PointerUpEvent(
        kind: PointerDeviceKind.stylus,
        pointer: pointer,
        position: start + const Offset(140, 0),
      ),
      m.state,
    );
    // 도구 복원
    m.setPen();
    n.setStrokeInk();
    _drawingState.updateUndoRedoState();
    setState(() {});
  }

  Widget _canvas(ScribbleController controller, String label) {
    return ScribbleWidget(
      notifier: controller.scribbleNotifier,
      modeNotifier: controller.modeNotifier,
      repaintBoundaryKey: controller.repaintBoundaryKey,
      panDirection: PanDirection.none,
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black12, fontSize: 64),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분할 필기 — 하나의 플로팅 도구'),
        actions: [
          IconButton(
            key: const ValueKey('test_status'),
            icon: const Icon(Icons.info_outline),
            tooltip: 'TestStatus',
            onPressed: () {
              final l = _left.scribbleNotifier;
              final r = _right.scribbleNotifier;
              debugPrint(
                '[status] A(strokes=${l.currentScribble.strokes.length} '
                'undo=${l.canUndo} redo=${l.canRedo}) '
                'B(strokes=${r.currentScribble.strokes.length} '
                'undo=${r.canUndo} redo=${r.canRedo}) '
                'global(undo=${_drawingState.canUndoNotifier.value} '
                'redo=${_drawingState.canRedoNotifier.value}) '
                'lastActive=${identical(_drawingState.lastActiveScribbleNotifier, r) ? "B" : identical(_drawingState.lastActiveScribbleNotifier, l) ? "A" : "?"}',
              );
            },
          ),
          IconButton(
            key: const ValueKey('test_redo'),
            icon: const Icon(Icons.redo_outlined),
            tooltip: 'TestRedo',
            onPressed: () {
              _drawingState.redo();
              setState(() {});
            },
          ),
          IconButton(
            key: const ValueKey('test_draw_a'),
            icon: const Icon(Icons.draw_outlined),
            tooltip: 'TestDrawA',
            onPressed: () => _injectStroke(_left, const Offset(120, 380)),
          ),
          IconButton(
            key: const ValueKey('test_draw_b'),
            icon: const Icon(Icons.draw),
            tooltip: 'TestDrawB',
            onPressed: () => _injectStroke(_right, const Offset(120, 300)),
          ),
          IconButton(
            key: const ValueKey('test_erase_b'),
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'TestEraseB',
            onPressed: () => _injectErase(_right, const Offset(110, 300)),
          ),
          IconButton(
            key: const ValueKey('test_erase_b_empty'),
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'TestEraseBEmpty',
            onPressed: () => _injectErase(_right, const Offset(110, 520)),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _drawingState.canUndoNotifier,
            builder: (context, canUndo, _) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo ? _drawingState.undo : null,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _drawingState.canRedoNotifier,
            builder: (context, canRedo, _) => IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: canRedo ? _drawingState.redo : null,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(child: _canvas(_left, 'A')),
              const VerticalDivider(width: 1),
              Expanded(child: _canvas(_right, 'B')),
            ],
          ),
          const Positioned.fill(child: ScribbleFloatingToolbar()),
          // ─────────────────────────────────────────────────────────
          // CoUI 통합 변형 (open-board + coco-de/coui 가 함께 있는 환경)
          //
          // open-board lib/ 는 CoUI 를 의존하지 않습니다(독립 배포).
          // 두 레포가 함께 있는 통합 앱에서 example/pubspec.yaml 에
          //   coui_flutter: { path: <coui>/packages/coui_flutter }
          // 를 추가하면, 아래처럼 CoUI `CoDraggablePanel` 셸을 주입해
          // 동일한 도구 패널을 디자인 시스템 룩으로 띄울 수 있습니다.
          //
          //   import 'package:coui_flutter/coui_flutter.dart';
          //
          //   Positioned.fill(
          //     child: ScribbleFloatingToolbar(
          //       draggable: false, // CoDraggablePanel 드래그에 위임
          //       containerBuilder: (context, content) => CoDraggablePanel(
          //         initialDock: CoreDockEdge.right,
          //         child: content,
          //       ),
          //     ),
          //   )
          // ─────────────────────────────────────────────────────────
        ],
      ),
    );
  }
}
