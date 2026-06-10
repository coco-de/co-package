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
