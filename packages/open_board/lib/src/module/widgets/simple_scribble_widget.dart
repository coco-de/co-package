// import 'dart:developer' show log; // 🚀 성능 최적화: 디버그 로그 제거
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';

/// ✨ 간편한 사용을 위한 SimpleScribbleWidget
///
/// 내부적으로 ScribbleController를 관리하여 복잡한 notifier 설정 없이
/// 간단하게 필기 기능을 사용할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// final controller = ScribbleController();
///
/// SimpleScribbleWidget(
///   controller: controller,
///   child: YourWidget(),
///   onScribbleChanged: (scribble) => print('필기 변경됨'),
/// )
///
/// // 편리한 컨트롤
/// controller.clear();
/// controller.undo();
/// controller.setTool(ScribbleTool.pen);
///
/// // 이미지 캡처
/// final image = await widget.captureAsImage();
/// ```
final class SimpleScribbleWidget extends StatefulWidget {
  /// 필기 컨트롤러 (선택적 - 없으면 자동 생성)
  final ScribbleController? controller;

  /// 자식 위젯 (선택적) - 이 위젝 위에 필기 레이어가 오버레이됩니다
  final Widget child;

  /// 필기 데이터 변경 시 호출되는 콜백
  final void Function(Scribble scribble)? onScribbleChanged;

  /// 필기 완료 시 호출되는 콜백
  final void Function(Scribble scribble)? onScribbleFinished;

  /// 도구 변경 시 호출되는 콜백
  final void Function(String tool)? onToolChanged;

  /// 자식 위젯 크기 변경 시 호출되는 콜백
  final void Function(Size size)? onChildSizeChanged;

  /// 🆕 스케일 변화 시 호출되는 콜백 (PDF 품질 조정용)
  final void Function(double scale)? onScaleChanged;

  /// 🆕 변환 매트릭스 변화 시 호출되는 콜백
  final Function(Matrix4 transform)? onTransformChanged;

  /// 🆕 인터랙션 업데이트 콜백
  final void Function(
    bool isBlockVerticalDrag,
    bool isReachedTopBoundary,
    bool isReachedBottomBoundary,
    bool isReachedLeftBoundary, // 🆕 좌측 경계 상태 추가
    bool isReachedRightBoundary, // 🆕 우측 경계 상태 추가
    Offset? gestureDirection, // 🆕 제스처 방향 정보 (X, Y축)
  )?
  onInteractionUpdate;

  /// 🖊️ 손모드 그리기 상태 변경 콜백
  final void Function(bool isHandModeDrawingActive)? onHandModeDrawingChanged;

  /// 초기 필기 데이터
  final Scribble? initialScribble;

  /// 초기 도구
  final String initialTool;

  /// 초기 색상
  final Color initialColor;

  /// 초기 브러시 크기
  final double initialStrokeWidth;

  /// 필기 활성화 여부
  final bool isScribbleEnabled;

  /// 최대 확대 비율
  final double maxScale;

  /// Pan 제스처 방향 제어
  final PanDirection panDirection;

  /// 허용된 포인터 모드 (기본: 펜만 허용하여 손필기 방지)
  final ScribblePointerMode allowedPointersMode;

  /// 🔥 새로운 파라미터: 화면 전체 사용 여부
  final bool useFullScreen;

  /// 🆕 새로운 파라미터: 최소 캔버스 크기
  final Size? minCanvasSize;

  /// 🆕 논리 컨텐츠 크기(PDF 논리 사이즈). 지정 시 내부 ScribbleWidget에 전달
  final Size? contentLogicalSize;

  /// 🆕 외부에서 주입하는 초기 스케일(선택)
  final double? initialScale;

  const SimpleScribbleWidget({
    super.key,
    required this.child,
    this.controller,
    this.onScribbleChanged,
    this.onScribbleFinished,
    this.onToolChanged,
    this.onChildSizeChanged,
    this.onScaleChanged,
    this.onTransformChanged,
    this.onInteractionUpdate,
    this.onHandModeDrawingChanged,
    this.initialScribble,
    this.initialTool = 'pen',
    this.initialColor = Colors.black,
    this.initialStrokeWidth = 2.0,
    this.isScribbleEnabled = true,
    this.maxScale = 6.0,
    this.panDirection =
        PanDirection.horizontal, // 🎯 기본값: 가로 pan 허용 (PageView 스와이프)
    this.allowedPointersMode = ScribblePointerMode.penOnly, // 🚫 손필기 방지: 펜만 허용
    this.useFullScreen = true, // 🔥 기본값: 화면 전체 사용
    this.minCanvasSize, // 🆕 최소 캔버스 크기
    this.contentLogicalSize,
    this.initialScale,
  });

  @override
  State<SimpleScribbleWidget> createState() => _SimpleScribbleWidgetState();
}

final class _SimpleScribbleWidgetState extends State<SimpleScribbleWidget> {
  late ScribbleController _controller;
  bool _isControllerOwned = false; // 내부에서 생성한 컨트롤러인지 여부
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  /// 컨트롤러 초기화
  void _initializeController() {
    if (widget.controller != null) {
      // 외부에서 제공된 컨트롤러 사용
      _controller = widget.controller!;
      _isControllerOwned = false;
    } else {
      // 내부에서 컨트롤러 생성
      _controller = ScribbleController(
        initialScribble: widget.initialScribble,
        initialTool: widget.initialTool,
        initialColor: widget.initialColor,
        initialStrokeWidth: widget.initialStrokeWidth,
        onScribbleChanged: widget.onScribbleChanged,
        onScribbleFinished: widget.onScribbleFinished,
        onToolChanged: widget.onToolChanged,
      );
      _isControllerOwned = true;

      // 🚫 손필기 방지: 펜만 허용하도록 설정
      _controller.modeNotifier.setAllowedPointersMode(
        widget.allowedPointersMode,
      );
    }

    // 외부 콜백이 있다면 컨트롤러에 추가 설정
    if (widget.onScribbleChanged != null) {
      _controller.onScribbleChanged = widget.onScribbleChanged;
    }
    if (widget.onScribbleFinished != null) {
      _controller.onScribbleFinished = widget.onScribbleFinished;
    }
    if (widget.onToolChanged != null) {
      _controller.onToolChanged = widget.onToolChanged;
    }
  }

  @override
  void didUpdateWidget(SimpleScribbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 컨트롤러가 변경된 경우 재초기화
    if (widget.controller != oldWidget.controller) {
      if (_isControllerOwned) {
        _controller.dispose();
      }
      _initializeController();
    }
  }

  @override
  void dispose() {
    // 내부에서 생성한 컨트롤러만 dispose
    if (_isControllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// 현재 필기 위젯을 이미지로 캡처합니다.
  ///
  /// [pixelRatio]는 이미지 해상도를 결정합니다 (기본값: 3.0).
  /// [format]은 이미지 형식을 지정합니다 (기본값: PNG).
  ///
  /// 반환값은 이미지 데이터가 포함된 ByteData입니다.
  Future<ByteData?> captureImage({
    double pixelRatio = 3.0,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    try {
      // RenderRepaintBoundary 객체 가져오기
      final RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // 이미지로 변환
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // ByteData로 변환
      final ByteData? byteData = await image.toByteData(format: format);

      return byteData;
    } on Exception catch (error) {
      debugPrint('❌ 위젯 캡처 실패: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔧 디버깅: 성능 최적화를 위해 빌드 로그 제거 (필요시에만 활성화)

    // ✨ ScribbleWidget 자체에서 RepaintBoundary/크기 관리 → LayoutBuilder 불필요
    return ScribbleWidget(
      notifier: _controller.scribbleNotifier,
      modeNotifier: _controller.modeNotifier,
      repaintBoundaryKey:
          _controller.repaintBoundaryKey, // ✨ controller의 key 전달
      contentLogicalSize: widget.contentLogicalSize,
      initialScale: widget.initialScale,
      onScribble: widget.onScribbleChanged != null
          ? (notifier) {
              // ✅ 빈 스트로크도 저장 필요 (지우개로 전부 삭제한 경우)
              // 무한루프는 ScribbleNotifier의 중복 감지로 방지
              final scribble = notifier.currentScribble;
              widget.onScribbleChanged!(scribble);
            }
          : null,
      onScribbleFinished: widget.onScribbleFinished != null
          ? (notifier) {
              final scribble = notifier.currentScribble;
              widget.onScribbleFinished!(scribble);
            }
          : null,
      onChildSizeChanged: widget.onChildSizeChanged,
      onScaleChanged: widget.onScaleChanged,
      onTransformChanged: widget.onTransformChanged,
      onInteractionUpdate: widget.onInteractionUpdate,
      onHandModeDrawingChanged: widget.onHandModeDrawingChanged,
      isScribbleEnable: widget.isScribbleEnabled,
      maxScale: widget.maxScale, // 🔧 매개변수로 받은 maxScale 값 사용
      panDirection: widget.panDirection, // 🎯 Pan 제스처 방향 제어 전달
      // 기타 기본값들
      drawPen: true,
      drawEraser: true,
      pressureFactor: 0.5,
      speedFactor: 0.1,
      minWidthFactor: 0.3,
      child: widget.child, // 🔥 child 전달 - 마지막에 위치
    );
  }
}

/// ✨ 컨트롤러 없이 바로 사용할 수 있는 간편 위젯
///
/// 가장 간단한 사용법을 위한 위젯입니다.
///
/// 사용 예시:
/// ```dart
/// QuickScribbleWidget(
///   child: YourWidget(),
///   onSave: (scribbleData) => saveToDatabase(scribbleData),
/// )
/// ```
final class QuickScribbleWidget extends StatefulWidget {
  /// 자식 위젯 (필수)
  final Widget child;

  /// 필기 저장 콜백
  final Function(Scribble scribble)? onSave;

  /// 로드할 필기 데이터
  final Scribble? loadScribble;

  const QuickScribbleWidget({
    super.key,
    required this.child,
    this.onSave,
    this.loadScribble,
  });

  @override
  State<QuickScribbleWidget> createState() => _QuickScribbleWidgetState();
}

final class _QuickScribbleWidgetState extends State<QuickScribbleWidget> {
  late ScribbleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScribbleController(initialScribble: widget.loadScribble);

    // 🚫 손필기 방지: 펜만 허용하도록 설정
    _controller.modeNotifier.setAllowedPointersMode(
      ScribblePointerMode.penOnly,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 현재 필기 데이터 저장
  void _saveScribble() {
    if (_controller.isEmpty) return;
    widget.onSave?.call(_controller.currentScribble);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✨ 간단한 툴바
        if (widget.onSave != null)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _controller.canUndo ? _controller.undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _controller.canRedo ? _controller.redo : null,
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _controller.isEmpty ? null : _controller.clear,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _controller.isEmpty ? null : _saveScribble,
              ),
            ],
          ),

        // ✨ 필기 영역
        Expanded(
          child: SimpleScribbleWidget(
            controller: _controller,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// 컨트롤러에 대한 접근을 제공하는 헬퍼 위젯
class ScribbleControllerProvider extends InheritedWidget {
  final ScribbleController controller;

  const ScribbleControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static ScribbleController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScribbleControllerProvider>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(ScribbleControllerProvider oldWidget) {
    return oldWidget.controller != controller;
  }
}
