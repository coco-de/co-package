// import 'dart:developer' show log; // 🚀 성능 최적화: 디버그 로그 제거

import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart'
    show LinkTargetResolver;
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
  const SimpleScribbleWidget({
    super.key,
    required this.child,
    this.controller,
    this.transformationController,
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
    this.allowedPointersMode = ScribblePointerMode.penOnly, // 🆕 최소 캔버스 크기
    this.contentLogicalSize,
    this.linkTargetResolver,
  });

  /// 텍스트 주석 링크 타깃 입력 UI 제공자 (kobic #9838).
  ///
  /// 호스트 앱이 자신의 디자인 시스템으로 다이얼로그를 그리도록 위임한다.
  /// 미주입 시 내장 Material 다이얼로그로 폴백하므로 단독 사용도 동작한다.
  final LinkTargetResolver? linkTargetResolver;

  /// 필기 컨트롤러 (선택적 - 없으면 자동 생성)
  final ScribbleController? controller;

  /// 🆕 InteractiveViewer 변환 컨트롤러 (선택적 - 없으면 자동 생성).
  /// 외부에서 주입하면 [ScribbleWidget] 내부 [InteractiveViewer]가 이 컨트롤러로
  /// transform을 공유하므로, 외곽 [InteractiveViewer]와의 줌·패닝 동기화가
  /// 가능하다.
  final TransformationController? transformationController;

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

  /// 🆕 논리 컨텐츠 크기(PDF 논리 사이즈). 지정 시 내부 ScribbleWidget에 전달
  final Size? contentLogicalSize;

  @override
  State<SimpleScribbleWidget> createState() => _SimpleScribbleWidgetState();
}

final class _SimpleScribbleWidgetState extends State<SimpleScribbleWidget> {
  late ScribbleController _controller;
  bool _isControllerOwned = false; // 내부에서 생성한 컨트롤러인지 여부

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
    }

    // 허용 포인터 모드 설정 (외부/내부 컨트롤러 모두 적용)
    _controller.modeNotifier.setAllowedPointersMode(
      widget.allowedPointersMode,
    );

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

  @override
  Widget build(BuildContext context) {
    // 🔧 디버깅: 성능 최적화를 위해 빌드 로그 제거 (필요시에만 활성화)

    // ✨ ScribbleWidget 자체에서 RepaintBoundary/크기 관리 → LayoutBuilder 불필요
    return ScribbleWidget(
      notifier: _controller.scribbleNotifier,
      modeNotifier: _controller.modeNotifier,
      repaintBoundaryKey:
          _controller.repaintBoundaryKey, // ✨ controller의 key 전달
      transformationController: widget.transformationController,
      contentLogicalSize: widget.contentLogicalSize,
      linkTargetResolver: widget.linkTargetResolver,
      // onScribbleChanged는 _initializeController에서 컨트롤러 리스너로
      // 이미 연결되어 모든 변경을 전달한다. 여기서 onScribble로도 감싸
      // 전달하면 같은 변경에 대해 사용자 콜백이 두 번 호출된다.
      onScribble: null,
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
      child: widget.child, // 🔥 child 전달 - 마지막에 위치
    );
  }
}
