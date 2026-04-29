import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/core/utils/measure_size.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/lasso/lasso_selection_manager.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/text_interaction_manager.dart';
import 'package:open_board/src/module/text/text_painter.dart';
import 'package:open_board/src/module/utils/image_capture_utils.dart';
// 새로 생성한 클래스들 import
import 'package:open_board/src/module/widgets/pointer_event_handler.dart';
import 'package:open_board/src/module/widgets/scribble_render_layers.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';

/// 페이지 네비게이션 방향 enum
enum PageNavigationDirection { previous, next }

/// 🎯 Pan 제스처 방향 제어 enum
enum PanDirection {
  /// 가로 방향 pan만 허용 (PageView 스와이프용)
  horizontal,

  /// 세로 방향 pan만 허용 (스크롤용)
  vertical,

  /// 모든 방향 pan 허용
  both,

  /// pan 제스처 완전 비활성화
  none,
}

/// StrokeCountNotifier는 스트로크 개수 변경 시 위젯을 리페인트하기 위한 ValueNotifier입니다.
class StrokeCountNotifier extends ValueNotifier<bool> {
  bool _disposed = false;

  StrokeCountNotifier() : super(false);

  void toggle() {
    if (!_disposed) {
      value = !value;
    }
  }

  void active() {
    if (!_disposed) {
      value = true;
    }
  }

  void deactive() {
    if (!_disposed) {
      value = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// ✨ ScribbleWidget - 어떤 위젯 위에든 필기 가능한 캔버스
///
/// **사용법:**
/// - 자식 위젯(child)을 제공하면 그 크기에 자동으로 맞춰 필기 영역이 생성됩니다
/// - 자식 위젯 위에 투명한 필기 레이어가 오버레이됩니다
/// - InteractiveViewer가 자동으로 화면에 맞게 스케일링합니다
///
/// ```dart
/// ScribbleWidget(
///   notifier: notifier,
///   modeNotifier: modeNotifier,
///   child: Container(
///     width: 300,
///     height: 400,
///     child: Text('이 위젯 위에 필기할 수 있어요!'),
///   ),
/// )
/// ```
///
/// **특징:**
/// - 어떤 크기의 위젯이든 자동으로 화면에 맞게 조정
/// - 원본 필기 데이터는 child 크기 기준으로 저장 (데이터 무결성 보장)
/// - 줌인/줌아웃, 팬 등 인터랙션 자동 지원
// ignore: must_be_immutable
final class ScribbleWidget extends StatefulWidget {
  ScribbleWidget({
    super.key,
    required this.notifier,
    required this.modeNotifier,
    this.background,
    this.backgroundChild,
    required this.child, // ✨ 자식 위젯: 이 위젯의 크기가 필기 영역 크기가 됩니다
    this.onScribble,
    this.onScribbleFinished,
    this.isScribbleEnable = true,
    this.drawPen = true,
    this.drawEraser = true,
    this.pressureFactor = 0.5,
    this.speedFactor = 0.1,
    this.minWidthFactor = 0.3,
    this.maxScale = 3.0,
    this.panDirection = PanDirection.horizontal, // 🎯 기본값: 가로 pan 허용
    this.onInteractionUpdate,
    this.onHandModeDrawingChanged,
    this.onSelectionComplete,
    this.onTransformComplete,
    this.onModeChanged,
    this.onChildSizeChanged, // ✨ 자식 크기 변경 콜백
    this.onScaleChanged,
    this.onTransformChanged,
    this.repaintBoundaryKey, // ✨ 외부에서 제공 가능한 GlobalKey
    this.transformationController, // 🆕 외부 주입 가능한 변환 컨트롤러
    this.contentLogicalSize, // 🆕 논리 컨텐츠 크기
    this.initialScale,
  });

  /// 위젯을 UI 이미지로 변환
  static Future<ui.Image> widgetToUiImage(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) {
    return ImageCaptureUtils.widgetToUiImage(
      widget,
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
      targetSize: targetSize,
    );
  }

  /// ✨ 이미지 캡처를 위한 GlobalKey - 외부에서 접근 가능
  final GlobalKey? repaintBoundaryKey;

  /// 🆕 논리 컨텐츠 크기(PDF 논리 사이즈 등). 지정 시 필기 좌표계의 기준 크기로 사용
  /// child의 실제 렌더 크기나 뷰포트 크기와 무관하게 고정 좌표계를 유지합니다.
  final Size? contentLogicalSize;

  /// 🆕 외부에서 주입하는 초기 스케일(선택). 주어지면 첫 프레임에 우선 적용
  final double? initialScale;

  /// ✨ 크기 결정 방식:
  /// 1. child가 있으면 → child 크기 자동 측정하여 사용
  /// 2. child가 없으면 → 화면 크기 사용

  final ScribbleNotifier notifier;
  final ScribbleModeNotifier modeNotifier;
  final bool isScribbleEnable;
  final bool drawPen;
  final bool drawEraser;
  final double pressureFactor;
  final double speedFactor;
  final double minWidthFactor;
  final double maxScale;
  final PanDirection panDirection; // 🎯 Pan 제스처 방향 제어
  final ui.Image? background;

  final Widget? backgroundChild;

  /// ✨ 자식 위젯: 이 위젯 위에 투명한 필기 레이어가 오버레이됩니다.
  ///
  /// child가 제공되면:
  /// - 자식 위젯의 크기가 자동으로 측정되어 필기 영역 크기로 사용됩니다.
  /// - size, fixedWidth, numberOfSplit 매개변수는 무시됩니다.
  /// - 자식 위젯은 배경으로 표시되고, 그 위에 투명한 필기 캔버스가 오버레이됩니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// ScribbleWidget(
  ///   notifier: notifier,
  ///   modeNotifier: modeNotifier,
  ///   child: Container(
  ///     width: 300,
  ///     height: 200,
  ///     child: Text('이 텍스트 위에 필기할 수 있어요!'),
  ///   ),
  /// )
  /// ```
  final Widget child;
  final Function(ScribbleNotifier notifier)? onScribble;
  final Function(ScribbleNotifier notifier)? onScribbleFinished;

  final Function(Size childSize)? onChildSizeChanged; // ✨ 새로운 콜백

  /// 🆕 스케일 변화 시 호출되는 콜백 (PDF 품질 조정용)
  final Function(double scale)? onScaleChanged;

  /// 🆕 변환 매트릭스 변화 시 호출되는 콜백
  final Function(Matrix4 transform)? onTransformChanged;
  final Function(List<int> selectedStrokeIds, Matrix4 transformMatrix)?
  onSelectionComplete;
  final Function(List<int> selectedStrokeIds, Matrix4 transformMatrix)?
  onTransformComplete;

  final Function(bool isSelecting, bool isTransforming)? onModeChanged;

  final void Function(
    bool isBlockVerticalDrag,
    bool isReachedTopBoundary,
    bool isReachedBottomBoundary,
    bool isReachedLeftBoundary, // 🆕 좌측 경계 상태 추가
    bool isReachedRightBoundary, // 🆕 우측 경계 상태 추가
    Offset? gestureDirection, // 🆕 제스처 방향 정보 추가
  )?
  onInteractionUpdate;

  /// 🖊️ 손모드 그리기 상태 변경 콜백
  final void Function(bool isHandModeDrawingActive)? onHandModeDrawingChanged;

  TransformationController? transformationController;

  @override
  State<ScribbleWidget> createState() => _ScribbleWidgetState();

  /// Fallback 이미지 캡처 메서드
  Future<ByteData> captureFromWidget(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) {
    return ImageCaptureUtils.captureFromWidget(
      widget,
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
      targetSize: targetSize,
    );
  }
}

/// ScribbleWidget의 State 클래스 - 리팩토링된 버전
final class _ScribbleWidgetState extends State<ScribbleWidget> {
  // 기본 컨트롤러들
  TransformationController? transformationController;
  late StrokeCountNotifier strokeCountNotifier;
  late ValueNotifier<bool> isInteractiveNotifier;
  int strokeCount = 0;

  // scribble_tools 패턴용 상태 변수들
  bool isZoomedIn = false;
  bool isBlockVerticalDrag = false;
  bool isReachedTopBoundary = false;
  bool isReachedBottomBoundary = false;
  bool isReachedLeftBoundary = false;
  bool isReachedRightBoundary = false;

  // ✅ 확대/축소 상태 보존을 위한 변수들
  final double _previousInitScale = 1.0;
  bool _isFirstBuild = true;

  // 🧭 화면 방향 변화 감지용 상태
  Orientation? _lastOrientation;

  // ✨ 자식 위젯 크기 추적을 위한 변수들
  Size? _childSize;
  bool _isChildSizeMeasured = false;

  // ✨ LayoutBuilder 기반 스케일링을 위한 변수들
  double _previousScaleToFit = 1.0;

  // 🆕 스케일 변화 감지를 위한 변수들
  double _lastReportedScale = 1.0;
  Matrix4? _lastReportedTransform;

  // 🖊️ 손모드 그리기 상태 추적 (스크롤 제어용)
  bool _isHandModeDrawingActive = false;

  // 🆕 사용자 상호작용 감지 및 초기 피팅 스냅 제어 플래그
  bool _hasUserInteracted = false;
  Size? _lastAppliedBaseContentSize;

  // 새로운 헬퍼 클래스들
  late ScribbleWidgetState widgetState;
  late PointerEventHandler pointerHandler;
  late ScribbleRenderLayers renderLayers;
  late TextInteractionManager textManager;
  late LassoSelectionManager lassoManager;

  // 🎯 Listener context 저장 (박스 이동 시 동일한 좌표계 사용)
  BuildContext? _listenerContext;

  // 🎨 하이라이트 모드에서의 포인터 종류 추적 (펜/손 구분)
  late ValueNotifier<ui.PointerDeviceKind?> _currentPointerKindForHighlighter;

  // 🤚 멀티터치 상태 추적 (2손가락 이상 터치 시 IgnorePointer 비활성화)
  late ValueNotifier<bool> _isMultiTouchNotifier;

  // 🖊️ 스타일러스 활성 상태 추적 — 펜 hover/down 시 true.
  //   scribble layer의 hit-test를 동적으로 토글하여, 펜 입력은 캡처하고
  //   그 외(마우스/터치)는 child PdfViewer로 통과시켜 onLinkTap 동작 보장.
  late ValueNotifier<bool> _isStylusActiveNotifier;
  Timer? _stylusInactiveTimer;

  @override
  void initState() {
    super.initState();

    // 🌍 DrawingState 등록은 ScribbleController에서 자동으로 처리됨 ✅
    // (중복 등록 코드 제거됨)

    // 🎯 Undo/Redo 후 화면 업데이트 콜백 등록
    final drawingState = DrawingState();
    drawingState.registerUndoRedoUpdateCallback(_forceRepaint);

    // 🔄 DrawingState의 도구 변경 감지 리스너 추가
    drawingState.selectedTool.addListener(_onDrawingToolChanged);

    // 등록 후 즉시 강제 동기화 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      drawingState.forceSyncAll();
    });

    // 기본 notifier 초기화
    strokeCountNotifier = StrokeCountNotifier();
    isInteractiveNotifier = ValueNotifier(true);
    _currentPointerKindForHighlighter = ValueNotifier<ui.PointerDeviceKind?>(
      null,
    );
    _isMultiTouchNotifier = ValueNotifier(false);
    _isStylusActiveNotifier = ValueNotifier(false);

    // 🖊️ 글로벌 PointerRouter로 스타일러스 hover/down 감지.
    //   hit-test와 무관하게 모든 PointerEvent를 받아, scribble layer가
    //   IgnorePointer(true) 상태여도 펜 활성 여부를 추적할 수 있다.
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalStylusPointer,
    );

    // transformationController 먼저 초기화 (매니저들이 의존하므로)
    transformationController =
        widget.transformationController ?? TransformationController();

    // 🆕 스케일 변화 감지 리스너 추가
    _setupScaleChangeListeners();

    // 상태 관리 객체 초기화
    widgetState = ScribbleWidgetState();
    _initializeTextSettings();

    // 포인터 이벤트 핸들러 초기화
    pointerHandler = PointerEventHandler(
      scribbleNotifier: widget.notifier,
      modeNotifier: widget.modeNotifier,
      transformationController: transformationController,
      onStateChanged: () {
        // 🔒 dispose 후 setState 호출 방지 (메모리 크래시 방지)
        if (mounted) {
          setState(() {});
        }
      },
      onScribble: widget.onScribble ?? (_) {},
      onScribbleFinished: (notifier) {
        // 필기 완료 후 Undo/Redo 상태 업데이트
        final drawingState = DrawingState();
        drawingState.updateUndoRedoState();

        // 기존 콜백 호출
        widget.onScribbleFinished?.call(notifier);

        // 올가미 드로잉 완료 후 바운딩 박스 표시
        if (widget.modeNotifier.state.inkGroupInfo.selectedInk ==
            InkModes.lasso) {
          lassoManager.selectElementsInLassoIfNeeded();
          _syncLassoManagerState();
          (strokeCountNotifier).toggle();
          // 🔒 dispose 후 setState 호출 방지
          if (mounted) {
            setState(() {});
          }
        }
      },
    );

    // 렌더링 레이어 초기화
    renderLayers = ScribbleRenderLayers(
      scribbleNotifier: widget.notifier,
      modeNotifier: widget.modeNotifier,
      widgetState: widgetState,
      strokeCountNotifier: strokeCountNotifier,
      background: widget.background,
      backgroundChild: widget.backgroundChild,
      size: null, // child가 있으면 자동으로 크기 측정됨
      drawPen: widget.drawPen,
      drawEraser: widget.drawEraser,
      pressureFactor: widget.pressureFactor,
      speedFactor: widget.speedFactor,
      minWidthFactor: widget.minWidthFactor,
    );

    // 매니저들 초기화
    _initializeManagers();

    // 기존 텍스트 불러오기 (매니저 초기화 후)
    _loadTextDrawablesFromNotifier();
  }

  void _initializeTextSettings() {
    final currentColor = widget.modeNotifier.state.inkGroupInfo.selectedColor;
    final currentSize =
        widget.modeNotifier.state.inkGroupInfo.seletedStrokeWidth;

    widgetState.textSettings = TextSettings(
      textStyle: TextStyle(
        fontSize: currentSize,
        color: currentColor,
        fontWeight: .normal,
      ),
      textAlignment: .center,
    );
  }

  void _initializeManagers() {
    // 텍스트 매니저 초기화
    textManager = TextInteractionManager(
      scribbleNotifier: widget.notifier,
      modeNotifier: widget.modeNotifier,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      context: context,
      transformationController: transformationController,
      repaintBoundaryKey: widget.repaintBoundaryKey,
      widgetState: widgetState,
      onTextSelected: (textDrawable) {
        lassoManager.resetLassoState();
      },
      onTextEdit: (textDrawable) {},
      onTextUpdated: (textDrawable) {},
      onTextDeselected: () {},
    );

    // 올가미 매니저 초기화
    lassoManager = LassoSelectionManager(
      scribbleNotifier: widget.notifier,
      modeNotifier: widget.modeNotifier,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      transformationController: transformationController,
      onSelectionComplete: widget.onSelectionComplete,
      onTransformComplete: widget.onTransformComplete,
      onModeChanged: widget.onModeChanged,
    );
  }

  void _loadTextDrawablesFromNotifier() {
    // TextInteractionManager의 텍스트 데이터 동기화
    textManager.syncWithScribble();
  }

  /// 🆕 스케일 변화 감지 리스너 설정
  void _setupScaleChangeListeners() {
    transformationController?.addListener(_onTransformationChanged);
  }

  /// 🆕 변환 매트릭스 변화 시 호출되는 메서드
  void _onTransformationChanged() {
    final currentTransform = transformationController?.value;
    if (currentTransform == null) return;

    final currentScale = currentTransform.getMaxScaleOnAxis();

    // 스케일 변화 감지 (5% 이상 변화 시에만 콜백 호출)
    const scaleThreshold = 0.05;
    if ((currentScale - _lastReportedScale).abs() > scaleThreshold) {
      _lastReportedScale = currentScale;
      widget.onScaleChanged?.call(currentScale);
    }

    // 변환 매트릭스 변화 감지
    if (_lastReportedTransform == null ||
        !_isMatrix4Equal(currentTransform, _lastReportedTransform!)) {
      _lastReportedTransform = currentTransform.clone();
      widget.onTransformChanged?.call(currentTransform);
    }
  }

  /// Matrix4 비교 헬퍼 메서드
  bool _isMatrix4Equal(Matrix4 a, Matrix4 b) {
    for (int i = 0; i < 16; i++) {
      if ((a.storage[i] - b.storage[i]).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  /// 🎯 Undo/Redo 후 강제 화면 업데이트
  void _forceRepaint() {
    if (mounted) {
      // 1. strokeCountNotifier 활성화하여 CustomPainter 다시 그리기
      strokeCountNotifier.active();

      // 2. setState 호출하여 위젯 트리 다시 빌드
      setState(() {});

      // 3. 다음 프레임에서 비활성화 후 다시 활성화 (확실한 repaint 트리거)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          strokeCountNotifier.deactive();
          // 한 프레임 후 다시 활성화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              strokeCountNotifier.active();
            }
          });
        }
      });
    }
  }

  /// 모드 변경 시 호출되는 메서드
  void _onModeChanged(String newMode) {
    // 🚨 모든 오버레이 정리 (이전 모드의 상태 완전 초기화)
    _hideAllOverlays();

    // 🔤 텍스트 모드 특별 처리
    if (newMode != InkModes.text) {
      if (textManager.showTextOverlay ||
          widgetState.selectedTextDrawable != null) {
        textManager.hideTextOverlay();
        widgetState.selectedTextDrawable = null;
      }
    }

    // 🎯 올가미 모드 특별 처리
    if (newMode != InkModes.lasso) {
      // 올가미 오버레이 상태 정리
      if (widgetState.showLassoOverlay) {
        widgetState.showLassoOverlay = false;
        lassoManager.resetLassoState();
        _syncLassoManagerState();
      }

      // 🚨 올가미 스트로크 제거 (조건 없이 항상 실행)
      widget.notifier.removeLassoStrokes();
    }

    // 🖊️ 지우개 모드 특별 처리 (ScribbleNotifier 상태 동기화)
    if (newMode == InkModes.erase) {
      widget.notifier.setEraser();
    } else if (_previousMode == InkModes.erase && newMode != InkModes.erase) {
      widget.notifier.setStrokeInk();
    }

    // 🔄 상태 업데이트
    setState(() {});
  }

  /// 🔄 DrawingState 도구 변경 감지 (즉시 반영)
  void _onDrawingToolChanged() {
    final currentDrawingTool = DrawingState().selectedTool.value;
    final currentMode = _convertDrawingToolToMode(currentDrawingTool);

    // 🎯 즉시 모드 변경 처리
    _onModeChanged(currentMode);

    // 🔄 modeNotifier도 동기화 (DrawingState → modeNotifier)
    if (widget.modeNotifier.state.inkGroupInfo.selectedInk != currentMode) {
      widget.modeNotifier.setSelectedInk(currentMode);
    }
  }

  /// 🔄 DrawingTool을 InkModes로 변환
  String _convertDrawingToolToMode(DrawingTool tool) {
    return switch (tool) {
      .pen => InkModes.pen,
      .pencil => InkModes.pencil,
      .marker => InkModes.marker,
      .fixedPen => InkModes.fixedPen,
      .highlighter => InkModes.marker, // 하이라이터는 마커로 처리
      .text => InkModes.text,
      .lasso => InkModes.lasso,
      .erase => InkModes.erase,
      .shape => InkModes.shape,
    };
  } // ✨ child 크기 변경 콜백 처리

  void _onChildSizeChanged(Size newSize) {
    if (_childSize != newSize) {
      setState(() {
        _childSize = newSize;
        _isChildSizeMeasured = true;
      });

      // 외부 콜백 호출
      widget.onChildSizeChanged?.call(newSize);
    }
  } // ✨ 효과적인 크기 반환 (child 우선, 없으면 기존 로직)

  // ✨ child가 있을 때의 오버레이 구조 빌드 - 실제 크기 기반 안정적 시스템
  Widget _buildChildOverlay() {
    return OrientationBuilder(
      builder: (_, orientation) {
        final hasOrientationChanged =
            _lastOrientation != null && _lastOrientation != orientation;
        _lastOrientation = orientation;

        if (hasOrientationChanged) {
          // 방향 전환 시 캐시 무효화로 스케일 재계산 유도
          _lastScaleCalculationKey = null;
          _cachedScaleToFit = null;
          _cachedAdjustedScaleToFit = null;
          _cachedDisplaySize = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // ✅ 제약 보정: 무한 제약이면 MediaQuery 크기로 대체
            final mediaSize = MediaQuery.of(context).size;
            final boundedWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : mediaSize.width;
            final boundedHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : mediaSize.height;
            final scribbleWidgetSize = Size(boundedWidth, boundedHeight);

            // 사전 측정이 완료된 상태만 들어오도록 보장됨 (_isChildReady == true)
            if (!_isChildReady) {
              // 안전장치: 예외 상황에서는 최소 위젯 반환
              return const SizedBox.shrink();
            }

            // 🛑 폴백 크기 렌더링 방지: 실제 콘텐츠 논리 크기가 준비될 때까지 렌더 지연
            if (widget.contentLogicalSize == null) {
              debugPrint(
                '⏳ [Child] waiting for actual contentLogicalSize. Skip rendering fallback.',
              );
              return SizedBox(
                width: scribbleWidgetSize.width,
                height: scribbleWidgetSize.height,
              );
            }

            // 스케일 기준 크기: 논리 컨텐츠 크기 우선, 없으면 측정된 child 크기 사용
            Size baseContentSize = widget.contentLogicalSize ?? _childSize!;
            if (baseContentSize.width <= 0 || baseContentSize.height <= 0) {
              // 0 또는 음수 크기 보호
              baseContentSize = const Size(1, 1);
            }

            // 🚀 성능 최적화: 디버그 모드에서도 불필요한 문자열 생성 제거
            // 크기 변화 추적은 내부 상태 관리용으로만 유지
            final currentSizeKey =
                '${baseContentSize.width}_${baseContentSize.height}_${scribbleWidgetSize.width}_${scribbleWidgetSize.height}';
            if (_lastLoggedSizeKey != currentSizeKey) {
              _lastLoggedSizeKey = currentSizeKey;
            }

            // 🚀 성능 최적화: 스케일 계산 캐싱으로 불필요한 재계산 방지
            final scaleCalculationKey = currentSizeKey; // 이미 생성된 키 재사용

            double scaleToFit;
            double adjustedScaleToFit;
            Size displaySize;

            if (_lastScaleCalculationKey == scaleCalculationKey &&
                _cachedScaleToFit != null &&
                _cachedAdjustedScaleToFit != null &&
                _cachedDisplaySize != null) {
              scaleToFit = _cachedScaleToFit!;
              adjustedScaleToFit = _cachedAdjustedScaleToFit!;
              displaySize = _cachedDisplaySize!;
            } else {
              final fit = _computeFit(
                contentSize: baseContentSize,
                viewportSize: scribbleWidgetSize,
              );
              scaleToFit = fit.rawScale; // width/height 우선 기준 스케일
              adjustedScaleToFit = fit.fitScale; // contain 기준 스케일
              displaySize = fit.displaySize;

              _lastScaleCalculationKey = scaleCalculationKey;
              _cachedScaleToFit = scaleToFit;
              _cachedAdjustedScaleToFit = adjustedScaleToFit;
              _cachedDisplaySize = displaySize;
            }

            // 🔥 필기 좌표계용 고정 크기 (PdfImagePainter와 동일)
            final fixedContentSize = baseContentSize;

            // 🔥 BoxFit.contain 중앙 정렬: 남은 공간을 양쪽에 균등 배치
            final fixedContentOffsetX = math.max(
              (scribbleWidgetSize.width - displaySize.width) / 2,
              0.0,
            );
            final fixedContentOffsetY = math.max(
              (scribbleWidgetSize.height - displaySize.height) / 2,
              0.0,
            );

            // 🔎 디버그 로그: child-present 계산 추적
            final orientation = MediaQuery.of(context).orientation;
            final ctrl = transformationController;
            final currentMatrix = ctrl?.value ?? Matrix4.identity();
            final currentScale = currentMatrix.getMaxScaleOnAxis();
            final currentTranslation = currentMatrix.getTranslation();
            debugPrint(
              '📐 [Child] orientation=$orientation viewport=${scribbleWidgetSize.width.toStringAsFixed(1)}x${scribbleWidgetSize.height.toStringAsFixed(1)}',
            );
            debugPrint(
              '📄 [Child] content=${fixedContentSize.width.toStringAsFixed(1)}x${fixedContentSize.height.toStringAsFixed(1)}',
            );
            debugPrint(
              '🔢 [Child] scale(rawFit=${scaleToFit.toStringAsFixed(4)}, fit=${adjustedScaleToFit.toStringAsFixed(4)})',
            );
            debugPrint(
              '🧩 [Child] display=${displaySize.width.toStringAsFixed(1)}x${displaySize.height.toStringAsFixed(1)} offset=(${fixedContentOffsetX.toStringAsFixed(1)},${fixedContentOffsetY.toStringAsFixed(1)})',
            );
            // transformationController 초기화 전에 찍는 현재값
            debugPrint(
              '🎛️ [Child] ctrlScale(pre)=${currentScale.toStringAsFixed(4)} ctrlTrans=(${currentTranslation.x.toStringAsFixed(1)},${currentTranslation.y.toStringAsFixed(1)})',
            );

            // transformationController 초기화
            transformationController ??= TransformationController();

            // 초기/재피팅 단일 경로
            final previousScaleToFit = _getPreviousScaleToFit();
            final scaleChangeRatio = previousScaleToFit == 0
                ? double.infinity
                : scaleToFit / previousScaleToFit;
            final isSignificantChange =
                scaleChangeRatio < 0.7 || scaleChangeRatio > 1.5;

            // 🆕 실제 컨텐츠 크기 변경(예: A4 → 실제 PDF) 여부 계산
            final contentSizeChanged =
                _lastAppliedBaseContentSize == null ||
                (_lastAppliedBaseContentSize!.width - baseContentSize.width)
                        .abs() >
                    0.5 ||
                (_lastAppliedBaseContentSize!.height - baseContentSize.height)
                        .abs() >
                    0.5;

            if (_isFirstBuild ||
                (contentSizeChanged && !_hasUserInteracted) ||
                hasOrientationChanged ||
                isSignificantChange) {
              // 레이아웃 사전-피팅 방식: 컨트롤러는 1.0 유지
              transformationController!.value = Matrix4.identity();
              _isFirstBuild = false;
            }

            if (contentSizeChanged && !_hasUserInteracted) {
              // 컨트롤러는 1.0 유지
              transformationController!.value = Matrix4.identity();
            }
            _lastAppliedBaseContentSize = baseContentSize;

            // 현재 adjustedScaleToFit 저장 (다음 크기 변경 시 비교용)
            _savePreviousScaleToFit(adjustedScaleToFit);

            // 🔥 스케일 범위 설정 (레이아웃 사전 피팅이므로 min=1.0)
            final safeMinScale = 1.0;
            final candidateMax = safeMinScale * (1.0 + widget.maxScale);
            final safeMaxScale = candidateMax > safeMinScale
                ? candidateMax
                : safeMinScale + 0.001; // 최대 스케일도 최소보다 크게 보정

            debugPrint(
              '🎚️ [Child] min=${safeMinScale.toStringAsFixed(4)} max=${safeMaxScale.toStringAsFixed(4)}',
            );

            // 🆕 보정: 사용자 상호작용 전에도 1.0 유지
            if (!_hasUserInteracted) {
              final currEnsure = transformationController!.value
                  .getMaxScaleOnAxis();
              if (!currEnsure.isFinite || (currEnsure - 1.0).abs() > 0.01) {
                transformationController!.value = Matrix4.identity();
              }
            }

            // ✨ 🔥 핵심 수정: InteractiveViewer에서 실제 크기 기준 좌표계 사용 + 컨텐츠 가운데 정렬
            return InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: .zero,
              minScale: safeMinScale, // 🔥 BoxFit.contain으로 전체 컨텐츠가 보이는 최소 스케일
              maxScale: safeMaxScale, // 🔥 기본 스케일의 3.0배 최대 스케일
              constrained: false,
              // 🎯 정교한 제스처 제어: pan 비활성화로 PageView 스와이프 허용, scale은 허용
              panEnabled: _shouldEnablePan(), // 🚫 필기 모드에서 수평 pan 비활성화
              scaleEnabled: _shouldEnableScale(), // ✅ 확대/축소는 허용
              // 🚨 MouseTracker 버그 방지: 중복 콜백 제거 및 안전한 콜백 처리
              onInteractionStart: widget.onInteractionUpdate != null
                  ? (ScaleStartDetails detail) {
                      try {
                        // 🆕 사용자가 제스처를 시작했음을 기록하여 자동 스냅 중단
                        _hasUserInteracted = true;
                        widget.onInteractionUpdate?.call(
                          true,
                          isReachedTopBoundary,
                          isReachedBottomBoundary,
                          isReachedLeftBoundary, // 🆕 좌측 경계 상태
                          isReachedRightBoundary, // 🆕 우측 경계 상태
                          null, // 시작 시에는 제스처 속도 없음
                        );
                      } on Exception {
                        // MouseTracker 버그 방지: 콜백 오류 무시
                      }
                    }
                  : null,
              onInteractionUpdate: (ScaleUpdateDetails details) {
                try {
                  // 🎯 핵심: _handleScaleInteraction 호출 추가!
                  _handleScaleInteraction(details, _getPreviousInitScale());

                  // 🚫 필기 중에는 페이지 넘김 제스처 차단
                  if (widget.onInteractionUpdate != null &&
                      !_isCurrentlyDrawing()) {
                    widget.onInteractionUpdate?.call(
                      isBlockVerticalDrag,
                      isReachedTopBoundary,
                      isReachedBottomBoundary,
                      isReachedLeftBoundary, // 🆕 좌측 경계 상태
                      isReachedRightBoundary, // 🆕 우측 경계 상태
                      details.focalPointDelta, // 제스처 속도 정보
                    );
                  }
                } on Exception catch (error, stackTrace) {
                  log('❌ 두 번째 InteractiveViewer 인터랙션 오류: $error');
                  log('❌ 스택트레이스: $stackTrace');
                  // 🔧 디버깅: 예외 발생 시에도 추가 정보 로그
                  log('🔧 콜백 존재 여부: ${widget.onInteractionUpdate != null}');
                  log(
                    '🔧 예외 발생 지점에서 경계 상태: L=$isReachedLeftBoundary, R=$isReachedRightBoundary',
                  );
                  log('🔧 제스처 정보: ${details.focalPointDelta}');

                  // 🚨 예외가 발생해도 계속 진행하지 말고 다시 던지기
                  rethrow;
                }
              },
              onInteractionEnd:
                  (widget.onInteractionUpdate != null && !_isCurrentlyDrawing())
                  ? (ScaleEndDetails detail) {
                      try {
                        // 🚫 필기 중이 아닐 때만 페이지 넘김 제스처 처리
                        if (!_isCurrentlyDrawing()) {
                          widget.onInteractionUpdate?.call(
                            isBlockVerticalDrag,
                            isReachedTopBoundary,
                            isReachedBottomBoundary,
                            isReachedLeftBoundary, // 🆕 좌측 경계 상태
                            isReachedRightBoundary, // 🆕 우측 경계 상태
                            null, // 종료 시에는 제스처 속도 없음
                          );
                        }
                      } on Exception {
                        // MouseTracker 버그 방지: 콜백 오류 무시
                      }
                    }
                  : null,
              // 🔥 핵심 개선: 화면 전체 크기로 설정하고 PDF 컨텐츠는 가운데 정렬
              child: SizedBox(
                width: scribbleWidgetSize.width,
                height: scribbleWidgetSize.height,
                child: Stack(
                  children: [
                    // 1. 배경: PDF 컨텐츠를 가운데 정렬 (고정된 크기 기준)
                    Positioned(
                      left: fixedContentOffsetX,
                      top: fixedContentOffsetY,
                      child: SizedBox.fromSize(
                        size: displaySize, // ✨ BoxFit.contain으로 계산된 표시 크기 사용
                        child: FittedBox(
                          fit: .contain, // BoxFit.contain 명시적 적용
                          child: SizedBox.fromSize(
                            size:
                                fixedContentSize, // 🔥 고정된 컨텐츠 크기 사용 (필기 일관성 보장)
                            child: RepaintBoundary(
                              key: widget.repaintBoundaryKey,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. 필기 레이어: 고정된 PDF 영역에서만 필기 가능하도록 클리핑
                    // 🤚 IgnorePointer 정책 (C안 정공법):
                    //   ScribbleWidget이 항상 모든 입력을 받아야 InteractiveViewer가
                    //   두 손가락 핀치 줌을 처리할 수 있다.
                    //   - 펜 그리기: 내부 Listener의 onPointerDown(stylus)이 캡처
                    //   - 두 손가락 핀치: InteractiveViewer가 처리 (scaleEnabled=true)
                    //   - 단일 손가락 탭: 외부에서 좌표 변환 + PDF 링크 forward
                    //   - 손가락 좌우 스와이프: pdf_viewer_widget의 외부 Listener에서 처리
                    //
                    //   이전 동작(제거됨): .penOnly + stylus 비활성 시 IgnorePointer(true)로
                    //   손가락을 PDF로 통과시킴. 그러나 첫 손가락이 PDF에 흡수되어
                    //   InteractiveViewer가 두 손가락 핀치를 인식 못 하는 핵심 버그였음.
                    Positioned(
                      left: fixedContentOffsetX,
                      top: fixedContentOffsetY,
                      child: SizedBox.fromSize(
                        size: displaySize,
                        child: FittedBox(
                          fit: .contain,
                          child: SizedBox.fromSize(
                            size: fixedContentSize, // 🔥 고정된 컨텐츠 크기 사용
                            child: ClipRect(
                              // 🔥 필기 영역을 고정된 크기로 제한
                              child: RepaintBoundary(
                                // 🚀 성능 최적화: 필기 레이어 독립적 리페인트
                                child: _buildScribbleLayer(fixedContentSize),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } // ✨ 필기 레이어만 빌드 (투명 배경)

  Widget _buildScribbleLayer(Size targetSize) {
    // 🎯 하이라이트 모드 감지 (DrawingState 변경 감지)
    final drawingState = DrawingState();

    return ValueListenableBuilder<DrawingTool>(
      valueListenable: drawingState.selectedTool,
      builder: (context, selectedTool, child) {
        final isHighlighterMode = selectedTool == .highlighter;

        // ⚡ 포인터 종류를 ValueListenableBuilder로 감시하여 즉시 반영
        return ValueListenableBuilder<ui.PointerDeviceKind?>(
          valueListenable: _currentPointerKindForHighlighter,
          builder: (context, currentPointerKind, child) {
            // 🎨 하이라이터 모드에서는 펜/손 입력을 투과시켜 PDF 텍스트 선택 허용
            // 핸드드로잉 모드(mouseOnly)에서는 마우스도 텍스트 선택을 위해 투과
            // 필기 모드에서는 펜 입력을 캡처하여 필기에 사용
            final isMouseOnlyMode =
                drawingState.pointerMode.value == .mouseOnly;
            final shouldIgnoreForTextSelection =
                isHighlighterMode &&
                (currentPointerKind == ui.PointerDeviceKind.stylus ||
                    currentPointerKind == ui.PointerDeviceKind.touch ||
                    (isMouseOnlyMode &&
                        currentPointerKind == ui.PointerDeviceKind.mouse));

            debugPrint(
              '🎨 [하이라이트] mode: $selectedTool, kind: $currentPointerKind, ignoreForTextSelection: $shouldIgnoreForTextSelection',
            );

            // 🎯 포인터 종류 감지를 위한 최상위 Listener
            // ⚡ onPointerDown에서 펜/마우스/손 모두 감지
            // ⚠️ 중요: IgnorePointer의 ignoring 값이 빌드 시점에 결정되므로 첫 이벤트는 이전 상태로 처리될 수 있음
            // 해결: Builder로 감싸서 최신 ValueNotifier 값을 직접 참조
            return Listener(
              // 🎨 hit-test behavior 정책:
              //   - 하이라이트 모드: .deferToChild
              //       자식이 IgnorePointer(true)이면 자기도 hit-test에서 빠져
              //       Stack의 hit-test가 PDF Positioned(아래)로 내려간다.
              //       PDF의 자체 InteractiveViewer(pdfrx)가 핀치 줌·패닝·
              //       텍스트 선택을 모두 처리하도록 위임.
              //   - 그 외 모드: .translucent
              //       child(PDF) hit-test 통과 + 자기 onPointer로 멀티터치 카운트.
              //       펜 그리기 캡처는 내부 Listener의 stylus 핸들러가 처리.
              //
              // 이전 시도(.translucent 고정)는 ScribbleLayer 영역 전체가 항상
              // hit으로 등록되어 PDF Positioned로 hit가 도달하지 못하던 회귀의
              // 원인이었다.
              behavior: isHighlighterMode ? .deferToChild : .translucent,
              // 🔧 멀티터치 카운트 갱신은 모드 무관하게 항상 동작.
              // (이전: isHighlighterMode일 때만 동작 → pencil 모드에서
              //  isMultiTouch가 갱신되지 않아 InteractiveViewer 핀치 줌이
              //  영영 활성화되지 않는 핵심 버그였음)
              onPointerDown: (event) {
                // 멀티터치 카운트 (모든 필기/하이라이트 모드 공통 — 핀치 줌)
                if (event.kind == ui.PointerDeviceKind.touch) {
                  pointerHandler.incrementTouch();
                  _isMultiTouchNotifier.value = pointerHandler.isMultiTouch();
                  if (pointerHandler.isMultiTouch()) {
                    setState(() {});
                  }
                }
                // 하이라이트 모드 전용: 포인터 종류 감지 (텍스트 선택 분기용)
                if (isHighlighterMode) {
                  if (event.kind == ui.PointerDeviceKind.stylus ||
                      event.kind == ui.PointerDeviceKind.mouse ||
                      event.kind == ui.PointerDeviceKind.touch) {
                    _currentPointerKindForHighlighter.value = event.kind;
                  }
                }
              },
              onPointerUp: (event) {
                if (event.kind == ui.PointerDeviceKind.touch) {
                  pointerHandler.decrementTouch();
                  _isMultiTouchNotifier.value = pointerHandler.isMultiTouch();
                  if (!pointerHandler.isMultiTouch()) {
                    setState(() {});
                  }
                }
              },
              onPointerCancel: (event) {
                if (event.kind == ui.PointerDeviceKind.touch) {
                  pointerHandler.decrementTouch();
                  _isMultiTouchNotifier.value = pointerHandler.isMultiTouch();
                  if (!pointerHandler.isMultiTouch()) {
                    setState(() {});
                  }
                }
              },
              // 🤚 하이라이트 모드 IgnorePointer 정책:
              //   하이라이트 모드에서는 ScribbleLayer 자식(Stack RenderLayers +
              //   내부 Listener)을 항상 차단한다. 외부 Listener의 behavior가
              //   .deferToChild이므로 자식이 hit 아니면 외부 Listener도
              //   hit이 아니게 되어 Stack이 PDF Positioned(아래)로 hit-test를
              //   진행한다.
              //
              //   - 하이라이트 모드:
              //       IgnorePointer(true) + Listener(.deferToChild)
              //       → ScribbleLayer 영역 전체가 hit-test에서 빠짐
              //       → PDF가 핀치 줌·패닝·텍스트 선택을 자체 처리(pdfrx)
              //   - 비하이라이트 모드:
              //       IgnorePointer(false) — 펜 그리기는 내부 Listener의
              //       stylus 캡처가 처리
              child: IgnorePointer(
                ignoring: isHighlighterMode,
                child: ValueListenableBuilder<bool>(
                  valueListenable: strokeCountNotifier,
                  builder: (context, value, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isInteractiveNotifier,
                      builder: (context, isInteractive, child) {
                        // 🔄 ScribbleNotifier 상태 변경을 감지하여 UI 업데이트
                        return ValueListenableBuilder<ScribbleState>(
                          valueListenable: widget.notifier,
                          builder: (context, state, child) {
                            return Builder(
                              builder: (listenerContext) {
                                // 🎯 Listener context 저장 (박스 이동에서 동일 좌표계 사용)
                                _listenerContext = listenerContext;

                                return Listener(
                                  // ⚡ 항상 .translucent로 설정하여 child(PDF/이미지 등) 위젯이
                                  // 자체 hit-test를 통해 onTap/onLinkTap 콜백을 처리할 수 있게 한다.
                                  //
                                  // 이전 동작: 필기 모드(isScribbleEnable=true)에서 .opaque로 모든
                                  //   포인터를 가로채 PDF의 onLinkTap이 호출되지 않음.
                                  // 현재 동작: allowedPointersMode가 캡처 대상으로 인정하는 포인터
                                  //   (예: penOnly → stylus)는 onPointerDown 핸들러가 처리하고,
                                  //   인정하지 않는 포인터(손가락/마우스 등)는 child로 자연스럽게
                                  //   통과되어 PdfViewer의 링크 탭/텍스트 선택이 동작한다.
                                  behavior: .translucent,
                                  // 🎨 하이라이트 모드에서 각 이벤트에서 포인터 종류를 직접 확인하여 즉시 처리
                                  // ⚡ 최상위 Listener에서 이미 포인터 종류를 감지했으므로, 여기서는 차단만 처리
                                  onPointerDown: widget.isScribbleEnable
                                      ? (event) {
                                          // ⚡ 하이라이트 모드에서 손/펜/마우스(핸드모드)면 차단
                                          // 🔧 단, 터치 카운트는 항상 관리하여 멀티터치 줌/팬 지원
                                          if (isHighlighterMode) {
                                            if (event.kind ==
                                                    ui
                                                        .PointerDeviceKind
                                                        .touch ||
                                                event.kind ==
                                                    ui
                                                        .PointerDeviceKind
                                                        .stylus ||
                                                (isMouseOnlyMode &&
                                                    event.kind ==
                                                        ui
                                                            .PointerDeviceKind
                                                            .mouse)) {
                                              // 🔧 터치 카운트는 외부 Listener에서 관리
                                              // (IgnorePointer 차단 방지)
                                              return;
                                            }
                                          }
                                          try {
                                            _handlePointerDown(event);
                                          } on Exception {
                                            // 예외 처리
                                          }
                                        }
                                      : null,
                                  onPointerMove: widget.isScribbleEnable
                                      ? (event) {
                                          // ⚡ 하이라이트 모드에서 손/펜/마우스(핸드모드)면 차단
                                          if (isHighlighterMode &&
                                              (event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .touch ||
                                                  event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .stylus ||
                                                  (isMouseOnlyMode &&
                                                      event.kind ==
                                                          ui
                                                              .PointerDeviceKind
                                                              .mouse))) {
                                            return;
                                          }
                                          try {
                                            _handlePointerMove(event);
                                          } on Exception {
                                            // 예외 처리
                                          }
                                        }
                                      : null,
                                  onPointerUp: widget.isScribbleEnable
                                      ? (event) {
                                          // ⚡ 하이라이트 모드에서 손/펜/마우스(핸드모드)면 차단
                                          // 🔧 터치 카운트는 외부 Listener에서 관리
                                          if (isHighlighterMode &&
                                              (event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .touch ||
                                                  event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .stylus ||
                                                  (isMouseOnlyMode &&
                                                      event.kind ==
                                                          ui
                                                              .PointerDeviceKind
                                                              .mouse))) {
                                            return;
                                          }
                                          try {
                                            _handlePointerUp(event);
                                          } on Exception {
                                            // 예외 처리
                                          }
                                        }
                                      : null,
                                  onPointerCancel: widget.isScribbleEnable
                                      ? (event) {
                                          // ⚡ 하이라이트 모드에서 손/펜/마우스(핸드모드)면 차단
                                          // 🔧 터치 카운트는 외부 Listener에서 관리
                                          if (isHighlighterMode &&
                                              (event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .touch ||
                                                  event.kind ==
                                                      ui
                                                          .PointerDeviceKind
                                                          .stylus ||
                                                  (isMouseOnlyMode &&
                                                      event.kind ==
                                                          ui
                                                              .PointerDeviceKind
                                                              .mouse))) {
                                            return;
                                          }
                                          try {
                                            _handlePointerCancel(event);
                                          } on Exception {
                                            // 예외 처리
                                          }
                                        }
                                      : null,
                                  onPointerHover: widget.isScribbleEnable
                                      ? (event) {
                                          // ⚡ 하이라이트 모드에서 마우스(핸드모드)면 차단 (hover는 주로 마우스에서 발생)
                                          if (isHighlighterMode &&
                                              isMouseOnlyMode &&
                                              event.kind ==
                                                  ui.PointerDeviceKind.mouse) {
                                            return;
                                          }
                                          try {
                                            _onPointerHover(event);
                                          } on Exception {
                                            // 예외 처리
                                          }
                                        }
                                      : null,
                                  // 🔍 SizedBox 사용: Container(color: transparent)는
                                  // 내부적으로 DecoratedBox로 변환되어 hit-test에 포함됨.
                                  // 이 경우 PDF 영역 전체를 덮어 child PdfViewer의
                                  // 링크 hit-test를 가로채므로 onLinkTap이 호출되지 않음.
                                  // SizedBox는 RenderConstrainedBox로 hit-test를 child에
                                  // 위임하므로, 빈 영역에서는 자연스럽게 PDF로 통과됨.
                                  child: SizedBox(
                                    width: targetSize.width,
                                    height: targetSize.height,
                                    child: Stack(
                                      children: renderLayers.buildAllLayers(
                                        onDelete: () => _removeSelectedStrokes(
                                          widgetState.selectedStrokeIds,
                                        ),
                                        onResizeRotateStart:
                                            _onResizeRotateStart,
                                        onResizeRotateUpdate:
                                            _onResizeRotateUpdate,
                                        onResizeRotateEnd: _onResizeRotateEnd,
                                        onMoveStart: _onMoveStart,
                                        onMoveUpdate: _onMoveUpdate,
                                        onMoveEnd: _onMoveEnd,
                                        onTextDelete: _onTextDelete,
                                        onTextTransformStart:
                                            _onTextTransformStart,
                                        onTextTransformUpdate:
                                            _onTextTransformUpdate,
                                        onTextTransformEnd: _onTextTransformEnd,
                                        onTextMoveStart: _onTextMoveStart,
                                        onTextMoveUpdate: _onTextMoveUpdate,
                                        onTextMoveEnd: _onTextMoveEnd,
                                        showTextOverlay:
                                            textManager.showTextOverlay ||
                                            widgetState.selectedTextDrawable !=
                                                null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🎯 스케일 상호작용 처리 (실제 크기 기반 개선된 방식)
  void _handleScaleInteraction(ScaleUpdateDetails details, double initScale) {
    if (transformationController == null) {
      return;
    }

    // child 크기가 아직 측정되지 않았으면 건너뜀
    if (!_isChildReady) {
      return;
    }

    // 🔥 올바른 뷰포트 경계 계산: 화면에 실제로 보이는 영역 기준

    // 1. 현재 화면 크기 기준 뷰포트 높이 계산
    final renderBoxContext = context.findRenderObject() as RenderBox?;
    final actualViewportHeight =
        renderBoxContext?.size.height ?? MediaQuery.of(context).size.height;
    final actualViewportWidth =
        renderBoxContext?.size.width ?? MediaQuery.of(context).size.width;

    // 2. 화면 상단(0,0)과 하단(0, viewportHeight)의 이미지 내 좌표 계산
    final viewportTopInImage = transformationController!
        .toScene(const Offset(0, 0))
        .dy;
    final viewportBottomInImage = transformationController!
        .toScene(Offset(0, actualViewportHeight))
        .dy;

    // 3. 화면 좌측(0,0)과 우측(viewportWidth, 0)의 이미지 내 좌표 계산
    // toScene()을 사용하여 화면 좌표를 컨텐츠 좌표로 변환
    // 📌 중요: toScene()은 화면에 렌더링된 크기 기준 좌표계를 반환함 (원본 크기 아님)
    final viewportLeftInContent = transformationController!
        .toScene(const Offset(0, 0))
        .dx;
    final viewportRightInContent = transformationController!
        .toScene(Offset(actualViewportWidth, 0))
        .dx;

    // 5. 경계 계산
    // 📌 핵심: 확대되었을 때는 화면의 오른쪽 끝에 도달하면 페이지 넘김을 허용
    // 이렇게 하면 확대 상태에서도 자연스럽게 페이지를 넘길 수 있음

    // 🎯 정확한 경계 계산: 뷰포트가 이미지 경계에 도달했는지 확인
    // 📌 개선: 확대 시 화면 끝에 도달하면 페이지 넘김 허용 (자연스러운 UX)

    // 상단 경계: 뷰포트 상단이 이미지 상단 근처에 도달
    final topBoundaryReached = viewportTopInImage <= 10;

    // 하단 경계: 뷰포트 하단이 이미지 하단 근처에 도달
    final bottomBoundaryReached =
        viewportBottomInImage >= actualViewportHeight - 10;

    // 좌측 경계: 뷰포트 좌측이 이미지 좌측 근처에 도달
    final leftBoundaryReached = viewportLeftInContent <= 10;

    // 우측 경계: 화면의 오른쪽 끝에 도달하면 경계로 인식
    // (확대 시에도 자연스럽게 페이지 넘김 가능)
    final rightBoundaryReached =
        viewportRightInContent >= actualViewportWidth - 10;

    // 🔥 실제 이미지 경계 기준 판단 로직 적용
    isReachedTopBoundary = topBoundaryReached;
    isReachedBottomBoundary = bottomBoundaryReached;
    isReachedLeftBoundary = leftBoundaryReached;
    isReachedRightBoundary = rightBoundaryReached;

    if (isZoomedIn && !(isReachedTopBoundary || isReachedBottomBoundary)) {
      // 스크롤 방향에 따른 드래그 제어
      if (details.focalPointDelta.direction > 0 && isReachedTopBoundary) {
        isBlockVerticalDrag = false;
      } else if (details.focalPointDelta.direction < 0 &&
          isReachedBottomBoundary) {
        isBlockVerticalDrag = false;
      } else {
        isBlockVerticalDrag = true;
      }
    } else {
      isBlockVerticalDrag = false;
    }
  }

  // ✨ LayoutBuilder 기반 스케일링을 위한 헬퍼 메서드들
  double _getPreviousScaleToFit() => _previousScaleToFit;

  void _savePreviousScaleToFit(double scaleToFit) {
    _previousScaleToFit = scaleToFit;
  }

  // 🔧 fit 계산 구조체
  ({double rawScale, double fitScale, Size displaySize}) _computeFit({
    required Size contentSize,
    required Size viewportSize,
  }) {
    final widthScaleRaw = viewportSize.width / contentSize.width;
    final scaledHeightByWidth = contentSize.height * widthScaleRaw;
    final heightScaleRaw = viewportSize.height / contentSize.height;
    final widthScale = widthScaleRaw.isFinite && widthScaleRaw > 0
        ? widthScaleRaw
        : 1.0;
    final heightScale = heightScaleRaw.isFinite && heightScaleRaw > 0
        ? heightScaleRaw
        : 1.0;
    final useWidthFit = scaledHeightByWidth <= viewportSize.height;

    final scaleToFit = useWidthFit ? widthScale : heightScale;
    double fit = math.min(widthScale, heightScale);
    if (!fit.isFinite || fit <= 0) fit = 0.001;
    Size display = Size(contentSize.width * fit, contentSize.height * fit);
    if (!display.width.isFinite || !display.height.isFinite) {
      display = Size(
        math.min(viewportSize.width, viewportSize.width),
        math.min(viewportSize.height, viewportSize.height),
      );
    }
    return (rawScale: scaleToFit, fitScale: fit, displaySize: display);
  }

  // 🔧 컨트롤러에 fit 적용(단일 진입점)
  // 사전-피팅 모드에서는 컨트롤러 스케일 조정이 필요 없음

  /// 🖋️ 현재 펜으로 그리기 중인지 확인 (정교한 조건)
  bool _isPenDrawing() {
    // 1. 필기 모드가 비활성화되어 있으면 → false (스크롤 허용)
    if (!widget.isScribbleEnable) {
      return false;
    }

    // 2. 드래그 중이 아니면 → false (스크롤 허용)
    if (!pointerHandler.isDragging) {
      return false;
    }

    // 3. 포인터 모드에 따른 터치 처리
    final currentPointerKind = pointerHandler.currentPointerKind;
    final drawingState = DrawingState();
    final pointerMode = drawingState.pointerMode.value;

    // 🔧 손가락 터치 모드에서는 터치 드로잉 허용
    if (currentPointerKind == ui.PointerDeviceKind.touch) {
      // mouseOnly 모드(손가락 모드)에서는 터치 드로잉 허용
      if (pointerMode == .mouseOnly) {
        // 🔧 텍스트/올가미 변형 중이면 그리기 차단하여 충돌 방지
        if (textManager.isDraggingText ||
            textManager.isTransformingText ||
            lassoManager.isLassoTransforming) {
          return false;
        }

        // 드로잉 도구인지 확인
        final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
        const drawingModes = {
          InkModes.pen,
          InkModes.pencil,
          InkModes.marker,
          InkModes.erase,
          InkModes.shape,
          InkModes.lasso,
          InkModes.text,
        };
        return drawingModes.contains(currentMode);
      } // penOnly 모드에서는 터치는 스크롤용
      return false;
    }

    // 4. 스타일러스/unknown 포인터 + 그리기 도구인 경우만 → true (펜 그리기)
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
    const drawingModes = {
      InkModes.pen,
      InkModes.pencil,
      InkModes.marker,
      InkModes.erase,
      InkModes.shape,
      InkModes.lasso,
      InkModes.text,
    };

    final isDrawingMode = drawingModes.contains(currentMode);
    final isStylusDrawing =
        (currentPointerKind == ui.PointerDeviceKind.stylus ||
            currentPointerKind == ui.PointerDeviceKind.unknown) &&
        isDrawingMode;

    return isStylusDrawing;
  }

  /// 🎯 InteractiveViewer 제스처 허용 여부 확인 (디버깅 포함)
  bool _shouldEnableInteractiveGestures() {
    // 🎯 하이라이트 모드 체크
    final drawingState = DrawingState();
    final currentTool = drawingState.selectedTool.value;
    if (currentTool == .highlighter) {
      // 🔧 멀티터치(핀치 줌) 시에는 InteractiveViewer 활성화
      if (pointerHandler.isMultiTouch()) {
        return true; // ✅ 핀치 줌 허용
      }
      return false; // 싱글터치 시에는 비활성화 (텍스트 선택 투과)
    }

    final isTransforming = widgetState.isTransforming;
    final isPenDrawing = _isPenDrawing();
    final isTextInteracting = textManager.isAnyTextInteracting;

    // 🖊️ 필기 모드에서는 펜으로 그리는 동안에만 InteractiveViewer 비활성화
    // 펜을 들고 있거나 변형 중이거나 텍스트 편집 중일 때만 제스처 차단
    final shouldEnable = !isTransforming && !isPenDrawing && !isTextInteracting;

    return shouldEnable;
  }

  /// 🎯 InteractiveViewer pan 제스처 허용 여부 (panDirection에 따라 제어)
  bool _shouldEnablePan() {
    // 🖊️ 멀티터치(두 손가락) 시에는 항상 pan 허용 (핀치 줌/드래그용)
    if (pointerHandler.isMultiTouch()) {
      return true; // ✅ 두 손가락 터치 시 pan 허용
    }

    // 🖊️ 손모드 + 드로잉 도구일 때는 단일 터치 pan을 즉시 차단.
    //   _processPointerDown 이전(30ms 지연 + Future.delayed 동안)에는
    //   _isHandModeDrawingActive가 아직 false인 race window가 존재하여
    //   InteractiveViewer ScaleGestureRecognizer가 단일 터치 드래그를
    //   pan으로 win → onInteractionUpdate가 페이지 미리보기/이동을
    //   트리거하던 회귀를 사전에 차단한다.
    if (_isInHandModeWithDrawingTool()) {
      return false;
    }

    // 🖊️ 손모드에서 그리기 중일 때는 스크롤 차단 (단, 싱글 터치일 때만)
    if (_isHandModeDrawingActive) {
      return false; // 손모드 그리기 중에는 pan 제스처 완전 차단
    }

    // 🎯 하이라이트 모드 체크 (텍스트 선택을 위해 제스처 투과)
    final drawingState = DrawingState();
    final currentTool = drawingState.selectedTool.value;
    if (currentTool == .highlighter) {
      // 🚨 하이라이트 모드에서는 확대/축소 중일 때만 pan 허용
      // 그 외에는 pan을 차단하여 PageView 스와이프가 작동하도록 함
      final currentScale =
          transformationController?.value.getMaxScaleOnAxis() ?? 1.0;
      return currentScale > 1.01;
    }

    // 🎯 panDirection에 따른 pan 제스처 제어
    switch (widget.panDirection) {
      case .none:
        return false; // pan 제스처 완전 비활성화
      case .horizontal:
        // 🚫 필기 모드에서는 수평 pan 비활성화하여 PageView 스와이프 허용
        if (widget.isScribbleEnable) {
          return false; // 수평 pan 비활성화 (PageView가 처리)
        }
        final result = _shouldEnableInteractiveGestures();
        return result;
      case .vertical:
        // ✅ 세로 pan만 허용 (스크롤용)
        final result = _shouldEnableInteractiveGestures();
        return result;
      case .both:
        // ✅ 모든 방향 pan 허용
        final result = _shouldEnableInteractiveGestures();
        return result;
    }
  }

  /// 🎯 InteractiveViewer scale 제스처 허용 여부 (확대/축소 허용)
  ///
  /// 🚨 멀티터치 판단을 기다리면 안 된다.
  /// 첫 PointerDown 시점에 scaleEnabled=true여야 InteractiveViewer가
  /// ScaleGestureRecognizer를 GestureArena에 등록하고, 그 후에 두 번째
  /// 손가락이 들어와야 핀치가 시작된다. isMultiTouch()를 트리거로 두면
  /// race로 첫 down 이벤트를 놓쳐 핀치가 영영 시작되지 않음.
  ///
  /// 정책: 펜으로 실제로 그리는 중일 때만 비활성화. 그 외에는 항상 활성화.
  bool _shouldEnableScale() {
    return !_isPenDrawing();
  }

  /// 🖊️ 손모드에서 그리기 시작 시 스크롤 차단
  void _startHandModeDrawing() {
    if (!_isHandModeDrawingActive) {
      _isHandModeDrawingActive = true;

      // 상위 위젯에 손모드 그리기 상태 변경 알림
      widget.onHandModeDrawingChanged?.call(true);
    }
  }

  /// 🖊️ 손모드에서 그리기 종료 시 스크롤 허용
  void _endHandModeDrawing() {
    if (_isHandModeDrawingActive) {
      _isHandModeDrawingActive = false;

      // 상위 위젯에 손모드 그리기 상태 변경 알림
      widget.onHandModeDrawingChanged?.call(false);
    }
  }

  /// 🚫 현재 필기 중인지 종합 확인 (페이지 넘김 제스처 차단용)
  /// 🚫 현재 필기 중인지 종합 확인 (페이지 넘김 제스처 차단용)
  bool _isCurrentlyDrawing() {
    // 1. 손모드에서 drawing이 활성화된 상태
    if (_isHandModeDrawingActive) {
      return true;
    }

    // 🎯 하이라이트 모드는 필기 중이 아님 (페이지 넘김 허용)
    final drawingState = DrawingState();
    final currentTool = drawingState.selectedTool.value;
    if (currentTool == .highlighter) {
      return false; // ✅ 하이라이트 모드에서는 페이지 넘김 허용
    }

    // 🆕 손모드 + 드로잉 도구 + 단일 터치 시점부터 페이지 넘김 차단.
    //   _processPointerDown(30ms 지연)이 실행되기 전 race window에
    //   InteractiveViewer ScaleGestureRecognizer가 단일 터치 드래그를
    //   scale=1.0 제스처로 인식 → onInteractionUpdate가 발화하여
    //   `_handleScribbleInteractionUpdate` 가 페이지 미리보기/이동을
    //   트리거하던 회귀를 첫 update 호출 시점부터 차단한다.
    //   멀티터치(pinch zoom)는 isMultiTouch()로 분기하여 그대로 허용.
    if (_isInHandModeWithDrawingTool() && !pointerHandler.isMultiTouch()) {
      return true;
    }

    // 2. InteractiveViewer 제스처가 비활성화되어야 하는 상태 (펜 drawing 등)
    if (!_shouldEnableInteractiveGestures()) {
      return true;
    }

    return false;
  }

  /// 🖊️ 손모드에서 필기 도구가 선택되었는지 확인
  bool _isInHandModeWithDrawingTool() {
    // 1. 포인터 모드 확인 (손모드인지)
    final drawingState = DrawingState();
    final pointerMode = drawingState.pointerMode.value;

    // 손모드(mouseOnly)가 아니면 false
    if (pointerMode != .mouseOnly) {
      return false;
    }

    // 2. 선택된 도구가 필기 도구인지 확인
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
    const drawingModes = {
      InkModes.pen,
      InkModes.pencil,
      InkModes.marker,
      InkModes.erase, // 지우개도 포함
      InkModes.shape, // 도형 그리기도 포함
      InkModes.lasso, // 올가미도 포함
    };

    return drawingModes.contains(currentMode);
  }

  /// 🎯 그리기 시작 가능 여부 확인
  bool _canStartDrawing(PointerDownEvent event) {
    // 1. 필기 모드가 비활성화되어 있으면 → false
    if (!widget.isScribbleEnable) {
      return false;
    }

    // 2. DrawingState의 포인터 모드 설정에 따라 결정
    final drawingState = DrawingState();
    final pointerMode = drawingState.pointerMode.value;

    switch (pointerMode) {
      case .penOnly:
        // 스타일러스/unknown만 허용
        return event.kind == ui.PointerDeviceKind.stylus ||
            event.kind == ui.PointerDeviceKind.unknown;
      case .mouseOnly:
        // 🔧 손가락 모드에서 터치 그리기 조건 개선
        if (event.kind == ui.PointerDeviceKind.touch) {
          // 텍스트/올가미 변형 중이면 그리기 차단
          if (textManager.isDraggingText ||
              textManager.isTransformingText ||
              lassoManager.isLassoTransforming) {
            return false;
          }

          // 멀티터치 시 그리기 차단 (스크롤 우선)
          if (pointerHandler.isMultiTouch()) {
            return false;
          }

          return true;
        }

        // 마우스와 스타일러스도 허용
        return event.kind == ui.PointerDeviceKind.mouse ||
            event.kind == ui.PointerDeviceKind.stylus ||
            event.kind == ui.PointerDeviceKind.unknown;
    }
  }

  // 포인터 이벤트 핸들러들
  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.isScribbleEnable) return;

    if (event.kind == ui.PointerDeviceKind.touch) {
      // ⚠️ incrementTouch()는 외부 Listener(`_buildScribbleLayer`의 onPointerDown,
      //   line ~1001)가 모드 무관하게 항상 호출하므로 여기서는 호출하지 않는다.
      //   이전엔 이중 카운팅으로 단일 손가락에서도 _activeTouchCount=2 가 되어
      //   isMultiTouch()=true 가 되었고, 그 결과 _processPointerDown 이 schedule
      //   되지 않아 손모드 손가락 필기가 시작되지 않던 핵심 회귀였다.

      // 🖊️ 멀티터치 감지 시 InteractiveViewer 상태 갱신 (핀치 줌/드래그 허용)
      if (pointerHandler.isMultiTouch()) {
        // 손모드 그리기 중이면 그리기 상태 해제
        if (_isHandModeDrawingActive) {
          _endHandModeDrawing();
        }
        setState(
          () {},
        ); // InteractiveViewer 상태 갱신 (panEnabled/scaleEnabled 업데이트)
        return; // 두 번째 터치는 드로잉에 사용하지 않음 (줌/드래그용)
      }

      Future<void>.delayed(PointerEventHandler.kTouchDelay, () {
        if (mounted &&
            widget.notifier.currentState.activePointerIds.isEmpty &&
            !pointerHandler.isMultiTouch()) {
          _processPointerDown(event);
        }
      });
    } else if (event.kind == ui.PointerDeviceKind.stylus ||
        event.kind == ui.PointerDeviceKind.unknown) {
      _processPointerDown(event);
    } else if (event.kind == ui.PointerDeviceKind.mouse) {
      // 마우스: _canStartDrawing 체크 후 처리 (웹 지원)
      if (_canStartDrawing(event)) {
        _processPointerDown(event);
      }
    }
  }

  void _processPointerDown(PointerDownEvent event) {
    // 텍스트 편집 중이면 무시
    if (widgetState.isEditingText) {
      return;
    }

    // 선택 영역 우선 처리 (모드에 관계없이)
    if (_handleSelectionAreaFirst(event, context)) {
      return; // 선택 영역에서 처리되었으면 종료
    }

    // 다른 곳을 클릭했을 때 오버레이 숨기기 처리
    _handleOverlayHiding(event);

    // 현재 모드에 따른 처리
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;

    if (currentMode == InkModes.text) {
      // 텍스트 모드 처리
      _handleTextModePointerDown(event);
    } else if (currentMode == InkModes.lasso) {
      // 올가미 모드 처리
      _handleLassoModePointerDown(event, context);
    } else {
      // 다른 모드(펜, 지우개 등)에서는 포인터 종류에 따라 텍스트 상호작용 제한
      bool textHandled = false;

      // 드로잉 모드에서 텍스트 선택 조건:
      // 1. 기존 텍스트 영역 클릭
      // 2. 손터치(touch)인 경우만 허용 (스타일러스는 그리기만)
      final isTouch = event.kind == ui.PointerDeviceKind.touch;
      final isClickingText = _isClickingExistingText(event);

      if (isClickingText && isTouch) {
        textHandled = textManager.handlePointerDown(event);
      } else if (isClickingText && !isTouch) {
        textHandled = false;
      }

      if (!textHandled) {
        // 텍스트가 처리하지 않았거나 텍스트 영역이 아니면 그리기 조건 확인

        // 🎯 필기 조건 확인: 필기모드 + 스타일러스/unknown 포인터
        final canDraw = _canStartDrawing(event);

        if (canDraw) {
          // 그리기 가능: 모든 오버레이 숨기고 그리기 시작

          // 🖊️ 손모드에서 터치/마우스 그리기 시작 시 스크롤 차단
          if ((event.kind == ui.PointerDeviceKind.touch ||
                  event.kind == ui.PointerDeviceKind.mouse) &&
              _isInHandModeWithDrawingTool()) {
            _startHandModeDrawing();
          }

          _hideAllOverlays();
          _updateToolsState();
          pointerHandler.handleNormalDrawingMode(event);
          (strokeCountNotifier).toggle();
          setState(() {});
        } else {
          // 그리기 불가: 터치는 스크롤용으로 사용

          // 터치인 경우 아무것도 하지 않음 (InteractiveViewer가 스크롤 처리)
        }
      } else {
        setState(() {});
      }
    }
  }

  /// 텍스트 모드 포인터 다운 처리
  void _handleTextModePointerDown(PointerDownEvent event) {
    final handled = textManager.handlePointerDown(event);
    if (handled) {
      setState(() {});
    }
  }

  /// 올가미 모드 포인터 다운 처리
  void _handleLassoModePointerDown(
    PointerDownEvent event,
    BuildContext context,
  ) {
    // 도구 상태 업데이트
    _updateToolsState();

    // 올가미 매니저에 포인터 다운 이벤트 위임
    final lassoHandled = lassoManager.handleLassoModePointerDown(
      event,
      context,
    );

    // 올가미 매니저 상태를 위젯 상태와 동기화
    _syncLassoManagerState();

    if (lassoHandled) {
      // 🖊️ 손모드에서 올가미 그리기 시작 시 스크롤 차단
      if ((event.kind == ui.PointerDeviceKind.touch ||
              event.kind == ui.PointerDeviceKind.mouse) &&
          _isInHandModeWithDrawingTool()) {
        _startHandModeDrawing();
      }
    } else {
      // 올가미 매니저가 처리하지 않았다면 기존 텍스트 영역에서 텍스트 상호작용 시도
      // 올가미 모드에서는 포인터 종류에 관계없이 텍스트 선택 허용
      bool textHandled = false;

      // 기존 텍스트 영역 클릭인지 확인
      if (_isClickingExistingText(event)) {
        textHandled = textManager.handlePointerDown(event);
      }

      if (!textHandled) {
        // 텍스트가 처리하지 않았거나 텍스트 영역이 아니면 그리기 조건 확인

        // 🎯 올가미 모드에서도 필기 조건 확인
        final canDraw = _canStartDrawing(event);

        if (canDraw) {
          // 그리기 가능: 모든 오버레이 숨기고 그리기 시작

          // 🖊️ 손모드에서 터치/마우스 그리기 시작 시 스크롤 차단
          if ((event.kind == ui.PointerDeviceKind.touch ||
                  event.kind == ui.PointerDeviceKind.mouse) &&
              _isInHandModeWithDrawingTool()) {
            _startHandModeDrawing();
          }

          _hideAllOverlays();
          pointerHandler.handleNormalDrawingMode(event);
          (strokeCountNotifier).toggle();
          setState(() {});
        } else {
          // 그리기 불가: 터치는 스크롤용으로 사용
        }
      } else {
        setState(() {});
      }
    }
  }

  /// 도구 상태 업데이트 (모드 전환 및 색상 설정)
  void _updateToolsState() {
    // ignore: invalid_use_of_protected_member
    final state = widget.notifier.currentState.scribble;
    isInteractiveNotifier.value = state is Drawing
        ? false
        : true; // 🔥 전역 상태에서 현재 도구 확인 (modeState 대신 전역 상태 사용)
    final globalTool = DrawingState().selectedTool.value;

    // DrawingTool을 InkModes로 변환
    String currentInk;
    switch (globalTool) {
      case .pen:
        currentInk = InkModes.pen;
        break;
      case .pencil:
        currentInk = InkModes.pencil;
        break;
      case .marker:
        currentInk = InkModes.marker;
        break;
      case .fixedPen:
        currentInk = InkModes.fixedPen;
        break;
      case .highlighter:
        currentInk = InkModes.marker; // 하이라이터는 마커로 처리
        break;
      case .erase:
        currentInk = InkModes.erase;
        break;
      case .text:
        currentInk = InkModes.text;
        break;
      case .shape:
        currentInk = InkModes.shape;
        break;
      case .lasso:
        currentInk = InkModes.lasso;
        break;
    }

    // 🔥 중복 호출 방지: ModeNotifier와 전역 상태 비교
    final modeNotifierCurrentInk =
        widget.modeNotifier.state.inkGroupInfo.selectedInk;

    // 🔥 도구 상태가 이미 동기화되어 있다면 추가 설정 스킵
    bool needsUpdate = modeNotifierCurrentInk != currentInk;

    if (!needsUpdate) {
      return;
    }

    // 🎯 지우개에서 다른 도구로 전환하는 경우 특별 처리
    final isEraserToOther =
        modeNotifierCurrentInk == InkModes.erase &&
        currentInk != InkModes.erase;

    switch (currentInk) {
      case InkModes.pen:
      case InkModes.pencil:
      case InkModes.marker:
      case InkModes.shape:
        // 먼저 그리기 모드로 전환
        widget.notifier.setStrokeInk();
        break;
      case InkModes.erase:
        widget.notifier.setEraser();
        break;
      case InkModes.lasso:
        // 올가미 모드는 별도 처리 (그리기 도구가 아님)
        if (isEraserToOther) {}
        widget.notifier.setLassoSelection();
        break;
      case InkModes.text:
        // 텍스트 모드는 별도 처리 (그리기 도구가 아님)
        if (isEraserToOther) {}
        widget.notifier.setStrokeInk(); // 텍스트 모드도 기본적으로 그리기 상태
        break;
      default:
        widget.notifier.setStrokeInk();
        break;
    }

    // 지우개가 아닌 경우에만 색상 설정
    if (currentInk != InkModes.erase) {
      widget.notifier.setColor();
    }

    // 🎯 상태 업데이트 후 Undo/Redo 상태 동기화
    final drawingState = DrawingState();
    drawingState.updateUndoRedoState();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.isScribbleEnable) return;
    if (pointerHandler.isMultiTouch()) return;

    // 선택 영역 우선 처리 (모드에 관계없이)
    bool handled = false;

    // 올가미 변형 중이면 우선 처리
    if (lassoManager.isLassoTransforming) {
      handled = lassoManager.handlePointerMove(event);
      if (handled) {
        _syncLassoManagerState();
        setState(() {});
        return;
      }
    }

    // 텍스트 드래그/변형 중이면 우선 처리 (모든 모드에서)
    if (textManager.isDraggingText || textManager.isTransformingText) {
      handled = textManager.handlePointerMove(event);
      if (handled) {
        setState(() {});
        return;
      }
    }

    // 모드별 처리
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;

    if (currentMode == InkModes.text) {
      // 텍스트 모드에서는 텍스트 매니저 우선 처리
      handled = textManager.handlePointerMove(event);
    } else if (currentMode == InkModes.lasso) {
      // 올가미 모드에서는 올가미 매니저 우선 처리
      handled = lassoManager.handlePointerMove(event);
      if (handled) {
        _syncLassoManagerState();
      }

      // 올가미에서 처리되지 않았다면 텍스트 상호작용 시도
      if (!handled) {
        handled = textManager.handlePointerMove(event);
      }
    } else {
      handled =
          widgetState.selectedTextDrawable != null ||
              textManager.isDraggingText ||
              textManager.isTransformingText
          ? textManager.handlePointerMove(event)
          : false;
    }

    if (!handled) {
      // 다른 도구로 실제 그리기가 시작될 때 텍스트 오버레이 숨기기
      // 단, 텍스트 드래그 준비 상태에서는 숨기지 않음
      if (currentMode != InkModes.text && currentMode != InkModes.lasso) {
        if ((textManager.showTextOverlay ||
                widgetState.selectedTextDrawable != null) &&
            !textManager.isDraggingText &&
            !textManager.isTextDragPreparing) {
          textManager.hideTextOverlayAndDeselect();
        }
      }

      final result = pointerHandler.handlePointerMove(event);
      if (result) {
        (strokeCountNotifier).toggle();
      }
    } else {
      setState(() {});
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMultiTouch = pointerHandler.isMultiTouch();

    // ⚠️ decrementTouch()는 외부 Listener(`_buildScribbleLayer`의 onPointerUp,
    //   line ~1018)가 모드 무관하게 항상 호출하므로 여기서는 호출하지 않는다.
    //   incrementTouch()와 짝을 맞춰 단일 진실 소스(SSOT)로 외부 Listener만 사용.

    // 🖐️ 멀티터치에서 싱글터치로 전환 시 InteractiveViewer 상태 갱신
    if (wasMultiTouch && !pointerHandler.isMultiTouch()) {
      setState(() {});
    }

    if (!widget.isScribbleEnable) return;
    if (pointerHandler.isMultiTouch()) return;

    // 선택 영역 우선 처리 (모드에 관계없이)
    bool handled = false;

    // 올가미 변형 중이면 우선 처리
    if (lassoManager.isLassoTransforming ||
        widgetState.selectedStrokeIds.isNotEmpty) {
      handled = lassoManager.handlePointerUp(event);
      _syncLassoManagerState();
      if (handled) {
        (strokeCountNotifier).toggle();
        setState(() {});
        return;
      }
    }

    // 텍스트 드래그/변형 중이면 우선 처리 (모든 모드에서)
    if (textManager.isDraggingText || textManager.isTransformingText) {
      handled = textManager.handlePointerUp(event);
      if (handled) {
        (strokeCountNotifier).toggle();
        setState(() {});
        return;
      }
    }

    // 모드별 처리
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;

    if (currentMode == InkModes.text) {
      // 텍스트 모드에서는 텍스트 매니저 우선 처리
      handled = textManager.handlePointerUp(event);
    } else if (currentMode == InkModes.lasso) {
      // 올가미 모드에서는 올가미 매니저 우선 처리
      handled = lassoManager.handlePointerUp(event);
      // 올가미 관련 이벤트는 항상 동기화 (오버레이 표시를 위해)
      _syncLassoManagerState();

      // 올가미에서 처리되지 않았다면 텍스트 상호작용 시도
      if (!handled) {
        handled = textManager.handlePointerUp(event);
      }
    } else {
      handled =
          widgetState.selectedTextDrawable != null ||
              textManager.isDraggingText ||
              textManager.isTransformingText
          ? textManager.handlePointerUp(event)
          : false;
    }

    if (!handled) {
      pointerHandler.handlePointerUp(event);
    }

    // 🖊️ 손모드에서 터치/마우스 그리기 종료 시 스크롤 허용
    if ((event.kind == ui.PointerDeviceKind.touch ||
            event.kind == ui.PointerDeviceKind.mouse) &&
        _isHandModeDrawingActive) {
      _endHandModeDrawing();
    }

    (strokeCountNotifier).toggle();

    if (handled) {
      setState(() {});
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final wasMultiTouch = pointerHandler.isMultiTouch();

    // ⚠️ decrementTouch()는 외부 Listener(`_buildScribbleLayer`의 onPointerCancel,
    //   line ~1027)가 모드 무관하게 항상 호출하므로 여기서는 호출하지 않는다.

    // 🖐️ 멀티터치에서 싱글터치로 전환 시 InteractiveViewer 상태 갱신
    if (wasMultiTouch && !pointerHandler.isMultiTouch()) {
      setState(() {});
    }

    // 🖊️ 손모드에서 터치/마우스 취소 시 스크롤 허용 (안전장치)
    if ((event.kind == ui.PointerDeviceKind.touch ||
            event.kind == ui.PointerDeviceKind.mouse) &&
        _isHandModeDrawingActive) {
      _endHandModeDrawing();
    }
  }

  // 스트로크 삭제
  void _removeSelectedStrokes(List<int> strokeIds) {
    if (strokeIds.isEmpty) return;

    final sortedIds = List<int>.of(strokeIds)..sort((a, b) => b.compareTo(a));
    final currentScribble = widget.notifier.currentState.scribble;
    final strokes = List<Stroke>.of(currentScribble.strokes);

    for (final id in sortedIds) {
      if (id >= 0 && id < strokes.length) {
        strokes.removeAt(id);
      }
    }

    final updatedScribble = Scribble(
      strokes: strokes,
      width: currentScribble.width,
      height: currentScribble.height,
      x: currentScribble.x,
      y: currentScribble.y,
      textDrawables: currentScribble.textDrawables,
      createdAt: currentScribble.createdAt,
      version: currentScribble.version,
    );

    widget.notifier.setScribble(
      scribble: updatedScribble,
      addToUndoHistory: true,
    );

    setState(() {
      widgetState.resetLassoState();
    });
  }

  /// 올가미 매니저 상태를 위젯 상태와 동기화
  void _syncLassoManagerState() {
    widgetState.selectedStrokeIds = lassoManager.selectedStrokeIds;
    widgetState.showLassoOverlay = lassoManager.showLassoOverlay;
    widgetState.isLassoTransforming = lassoManager.isLassoTransforming;
    widgetState.lassoSelectionState = lassoManager.lassoSelectionState;
  }

  // 크기조절/회전 핸들러들
  void _onResizeRotateStart(DragStartDetails details) {
    // 🎯 Listener context 전달 (이동과 동일한 좌표계)
    if (_listenerContext != null) {
      lassoManager.onResizeRotateStart(details, _listenerContext!);
    }
    _syncLassoManagerState();
  }

  void _onResizeRotateUpdate(DragUpdateDetails details) {
    // 🎯 Listener context 전달 (이동과 동일한 좌표계)
    if (_listenerContext != null) {
      lassoManager.onResizeRotateUpdate(details, _listenerContext!);
    }
    _syncLassoManagerState();
  }

  void _onResizeRotateEnd(DragEndDetails details) {
    lassoManager.onResizeRotateEnd(details);
    _syncLassoManagerState();
  }

  // 이동 핸들러들 (올가미 선택된 스트로크)
  void _onMoveStart(DragStartDetails details) {
    // Listener context를 전달 (박스 없을 때와 동일한 좌표계)
    if (_listenerContext != null) {
      lassoManager.onMoveStart(details, _listenerContext!);
    }
    _syncLassoManagerState();
  }

  void _onMoveUpdate(DragUpdateDetails details) {
    // Listener context를 전달 (박스 없을 때와 동일한 좌표계)
    if (_listenerContext != null) {
      lassoManager.onMoveUpdate(details, _listenerContext!);
    }
    _syncLassoManagerState();
  }

  void _onMoveEnd(DragEndDetails details) {
    lassoManager.onMoveEnd(details);
    _syncLassoManagerState();
    setState(() {});
  }

  // 텍스트 관련 핸들러들
  void _onTextDelete() {
    textManager.deleteSelectedText();
    setState(() {});
  }

  // 텍스트 변형 핸들러들 (올가미와 동일한 방식)
  void _onTextTransformStart(DragStartDetails details) {
    textManager.onTextTransformStart(details, context);
  }

  void _onTextTransformUpdate(DragUpdateDetails details) {
    textManager.onTextTransformUpdate(details, context);
  }

  void _onTextTransformEnd(DragEndDetails details) {
    textManager.onTextTransformEnd(details);
  }

  // 텍스트 이동 핸들러들
  void _onTextMoveStart(DragStartDetails details) {
    textManager.onTextMoveStart(details);
  }

  void _onTextMoveUpdate(DragUpdateDetails details) {
    textManager.onTextMoveUpdate(details);
  }

  void _onTextMoveEnd(DragEndDetails details) {
    textManager.onTextMoveEnd(details);
  }

  /// 선택 영역 우선 처리 (모드에 관계없이)
  bool _handleSelectionAreaFirst(
    PointerDownEvent event,
    BuildContext context,
  ) {
    final position = event.localPosition;

    // 1. 올가미 오버레이 버튼 클릭 처리
    if (widgetState.showLassoOverlay &&
        widgetState.selectedStrokeIds.isNotEmpty) {
      if (_handleLassoOverlayButtons(position)) {
        return true;
      }
    }

    // 2. 텍스트 오버레이 버튼 클릭 처리
    if (textManager.showTextOverlay &&
        widgetState.selectedTextDrawable != null) {
      if (_handleTextOverlayButtons(position)) {
        return true;
      }
    }

    // 3. 올가미 선택 영역 내부 클릭 처리
    if (widgetState.selectedStrokeIds.isNotEmpty) {
      if (_handleLassoSelectionArea(event, context)) {
        return true;
      }
    }

    // 4. 텍스트 선택 영역 내부 클릭 처리
    if (widgetState.selectedTextDrawable != null) {
      if (_handleTextSelectionArea(event)) {
        return true;
      }
    }

    // 5. 기존 텍스트 영역 클릭 처리 (선택되지 않은 텍스트)
    if (_handleExistingTextArea(event)) {
      return true;
    }

    return false; // 선택 영역에서 처리되지 않음
  }

  /// 올가미 오버레이 버튼 처리
  bool _handleLassoOverlayButtons(Offset position) {
    // 🔥 개선된 버튼 크기 계산
    const baseButtonSize = 50.0; // 더 크게 설정
    // scribble-tools 패턴에서는 Transform.scale(1.0)이므로 currentScale을 그대로 사용
    final effectiveScale = currentScale;
    final scaledButtonSize = baseButtonSize / effectiveScale;
    final buttonRadius = scaledButtonSize / 2;

    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = position; // 변환 없이 원본 좌표 사용

    final boundingBox = _calculateBoundingBox(widgetState.selectedStrokeIds);

    // 삭제 버튼 위치 (우상단)
    final deleteButtonCenter = Offset(boundingBox.right, boundingBox.top);
    final deleteDistance = (adjustedPosition - deleteButtonCenter).distance;

    if (deleteDistance <= buttonRadius) {
      lassoManager.removeSelectedStrokes(widgetState.selectedStrokeIds);
      _syncLassoManagerState();
      setState(() {});
      return true;
    }

    // 변형 버튼 위치 (좌하단)
    final transformButtonCenter = Offset(
      boundingBox.left,
      boundingBox.bottom,
    );
    final transformDistance =
        (adjustedPosition - transformButtonCenter).distance;

    if (transformDistance <= buttonRadius) {
      // 변형 버튼은 드래그로 처리되므로 여기서는 클릭만 감지
      return true;
    }

    return false;
  }

  /// 텍스트 오버레이 버튼 처리
  bool _handleTextOverlayButtons(Offset position) {
    final selectedText = widgetState.selectedTextDrawable;
    if (selectedText == null) return false;

    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = position; // 변환 없이 원본 좌표 사용

    final buttonType = TextDrawablePainter.getButtonType(
      selectedText,
      adjustedPosition, // 원본 좌표 직접 사용
    );

    if (buttonType == 'delete') {
      textManager.deleteSelectedText();
      setState(() {});
      return true;
    } else if (buttonType == 'transform') {
      // 변형 버튼 클릭 시 변형 모드 시작 (드래그 준비 상태 설정)
      textManager.startTextResizeMode(adjustedPosition); // 원본 좌표 직접 사용
      return true;
    }

    return false;
  }

  /// 올가미 선택 영역 내부 클릭 처리
  bool _handleLassoSelectionArea(
    PointerDownEvent event,
    BuildContext context,
  ) {
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = event.localPosition; // 변환 없이 원본 좌표 사용

    final boundingBox = _calculateBoundingBox(widgetState.selectedStrokeIds);

    final contains = boundingBox.contains(adjustedPosition);

    if (contains) {
      final handled = lassoManager.handleLassoModePointerDown(event, context);

      _syncLassoManagerState();
      if (handled) {
        setState(() {});
      }
      return true;
    }
    return false;
  }

  /// 텍스트 선택 영역 내부 클릭 처리
  bool _handleTextSelectionArea(PointerDownEvent event) {
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = event.localPosition; // 변환 없이 원본 좌표 사용

    final isInTextArea = TextDrawablePainter.isPointInTextArea(
      widgetState.selectedTextDrawable!,
      adjustedPosition, // 원본 좌표 직접 사용
    );

    if (isInTextArea) {
      // 🔥 텍스트 모드일 때는 항상 텍스트 매니저로 이벤트 전달 (더블탭 감지용)
      final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
      if (currentMode == InkModes.text) {
        final handled = textManager.handlePointerDown(event);

        if (handled) {
          setState(() {});
        }
        // 🔥 항상 true 반환 (텍스트 매니저가 처리했든 안했든 이벤트는 소비됨)
        return true;
      } // 다른 모드에서는 기존 로직 유지 (선택 상태만 유지)

      return true;
    }
    return false;
  }

  /// 기존 텍스트 영역 클릭 처리
  bool _handleExistingTextArea(PointerDownEvent event) {
    // 현재 선택된 텍스트가 아닌 다른 텍스트 영역을 클릭했는지 확인
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = event.localPosition; // 변환 없이 원본 좌표 사용

    final textDrawables = textManager.textDrawables;
    for (int i = 0; i < textDrawables.length; i++) {
      final textDrawable = textDrawables[i];

      // 현재 선택된 텍스트는 제외
      if (widgetState.selectedTextDrawable?.id == textDrawable.id) {
        continue;
      }

      if (_isPointInTextBounds(adjustedPosition, textDrawable)) {
        final handled = textManager.handlePointerDown(event);
        if (handled) {
          setState(() {});
        }
        return true;
      }
    }
    return false;
  }

  /// 기존 텍스트를 클릭했는지 확인 (다른 모드에서 텍스트 상호작용 허용 여부 판단)
  bool _isClickingExistingText(PointerDownEvent event) {
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = event.localPosition; // 변환 없이 원본 좌표 사용

    final textDrawables = textManager.textDrawables;
    for (final textDrawable in textDrawables) {
      if (_isPointInTextBounds(adjustedPosition, textDrawable)) {
        return true;
      }
    }
    return false;
  }

  /// 포인트가 텍스트 영역 내에 있는지 확인
  bool _isPointInTextBounds(Offset point, TextDrawable textDrawable) {
    final textSpan = TextSpan(
      text: textDrawable.text,
      style: TextStyle(
        fontSize: textDrawable.fontSize,
        color: Color(textDrawable.color),
        fontFamily: textDrawable.fontFamily,
        fontWeight: textDrawable.isBold ? .bold : .normal,
        fontStyle: textDrawable.isItalic ? .italic : .normal,
        decoration: textDrawable.isUnderlined ? .underline : null,
      ),
    );

    final textAlign = _parseTextAlign(textDrawable.textAlign);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: .ltr,
    );
    textPainter.layout();

    // 텍스트 위치 (x, y)
    final position = Offset(textDrawable.x, textDrawable.y);

    // 텍스트 렌더링 위치 계산 (정렬에 따라)
    Offset renderPosition = position;
    switch (textAlign) {
      case .center:
        renderPosition = Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        );
        break;
      case .right:
        renderPosition = Offset(
          position.dx - textPainter.width,
          position.dy - textPainter.height / 2,
        );
        break;
      case .left:
        renderPosition = Offset(
          position.dx,
          position.dy - textPainter.height / 2,
        );
        break;
      default:
        renderPosition = Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        );
        break;
    }

    // 여유 공간을 추가하여 터치 영역 확대 (8px 패딩)
    final textRect = Rect.fromLTWH(
      renderPosition.dx - 8,
      renderPosition.dy - 8,
      textPainter.width + 16,
      textPainter.height + 16,
    );

    return textRect.contains(point);
  }

  /// 오버레이 숨기기 처리
  void _handleOverlayHiding(PointerDownEvent event) {
    // 텍스트나 올가미 변형 중이면 오버레이 숨기지 않음
    if (textManager.isTransformingText ||
        textManager.isDraggingText ||
        lassoManager.isLassoTransforming) {
      return;
    }

    // 현재 올가미 오버레이가 표시되어 있는지 확인
    final hasLassoOverlay =
        widgetState.showLassoOverlay &&
        widgetState.selectedStrokeIds.isNotEmpty;

    // 현재 텍스트 오버레이가 표시되어 있는지 확인
    final hasTextOverlay = textManager.showTextOverlay;

    if (!hasLassoOverlay && !hasTextOverlay) {
      return;
    }

    // 오버레이 버튼 영역 체크 (버튼을 클릭한 경우 숨기지 않음)
    if (_isClickingOverlayButton(event.localPosition)) {
      return;
    }

    // 선택된 영역 내부 클릭 체크 (내부 클릭 시 숨기지 않음)
    if (_isClickingInsideSelection(event.localPosition)) {
      return;
    }

    // 다른 곳을 클릭했으므로 오버레이 숨기기

    _hideAllOverlays();
  }

  /// 오버레이 버튼 클릭 여부 확인
  bool _isClickingOverlayButton(Offset position) {
    // 🔥 개선된 버튼 크기 계산
    const baseButtonSize = 50.0; // 더 크게 설정
    // scribble-tools 패턴에서는 Transform.scale(1.0)이므로 currentScale을 그대로 사용
    final effectiveScale = currentScale;
    final scaledButtonSize = baseButtonSize / effectiveScale;
    final buttonRadius = scaledButtonSize / 2;

    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = position; // 변환 없이 원본 좌표 사용

    // 올가미 오버레이 버튼 체크
    if (widgetState.showLassoOverlay &&
        widgetState.selectedStrokeIds.isNotEmpty) {
      final boundingBox = _calculateBoundingBox(
        widgetState.selectedStrokeIds,
      );

      // 삭제 버튼 위치 (우상단)
      final deleteButtonCenter = Offset(boundingBox.right, boundingBox.top);
      if ((adjustedPosition - deleteButtonCenter).distance <= buttonRadius) {
        return true;
      }

      // 변형 버튼 위치 (좌하단)
      final transformButtonCenter = Offset(
        boundingBox.left,
        boundingBox.bottom,
      );
      if ((adjustedPosition - transformButtonCenter).distance <= buttonRadius) {
        return true;
      }
    }

    // 텍스트 오버레이 버튼 체크
    if (textManager.showTextOverlay &&
        widgetState.selectedTextDrawable != null) {
      final buttonType = TextDrawablePainter.getButtonType(
        widgetState.selectedTextDrawable!,
        adjustedPosition, // 원본 좌표 직접 사용
      );

      if (buttonType != null) {
        return true;
      }
    }

    return false;
  }

  /// 선택 영역 내부 클릭 여부 확인
  bool _isClickingInsideSelection(Offset position) {
    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용
    final adjustedPosition = position; // 변환 없이 원본 좌표 사용

    // 올가미 선택 영역 체크
    if (widgetState.showLassoOverlay &&
        widgetState.selectedStrokeIds.isNotEmpty) {
      final boundingBox = _calculateBoundingBox(
        widgetState.selectedStrokeIds,
      );
      if (boundingBox.contains(adjustedPosition)) {
        return true;
      }
    }

    // 텍스트 선택 영역 체크
    if (textManager.showTextOverlay &&
        widgetState.selectedTextDrawable != null) {
      final isInTextArea = TextDrawablePainter.isPointInTextArea(
        widgetState.selectedTextDrawable!,
        adjustedPosition, // 원본 좌표 직접 사용
      );
      if (isInTextArea) {
        return true;
      }
    }

    return false;
  }

  /// 모든 오버레이 숨기기
  void _hideAllOverlays() {
    // 올가미 오버레이 숨기기
    if (widgetState.showLassoOverlay) {
      lassoManager.resetLassoState();
      _syncLassoManagerState();
    }

    // 🚨 올가미 스트로크 완전 제거 (오버레이 여부와 관계없이)
    widget.notifier.removeLassoStrokes();

    // 텍스트 오버레이 숨기기
    if (widgetState.selectedTextDrawable != null ||
        textManager.showTextOverlay) {
      textManager.hideTextOverlayAndDeselect();
    }

    setState(() {});
  }

  /// 바운딩 박스 계산 (올가미용) - 성능 최적화됨
  Rect _calculateBoundingBox(List<int> strokeIds) {
    if (strokeIds.isEmpty) return .zero;

    final strokes = widget.notifier.currentState.scribble.strokes;
    // 🚀 성능 최적화: 초기값을 더 효율적으로 설정
    double minX = .maxFinite;
    double minY = .maxFinite;
    double maxX = -double.maxFinite;
    double maxY = -double.maxFinite;

    for (final id in strokeIds) {
      if (id >= 0 && id < strokes.length) {
        final stroke = strokes[id];
        for (final point in stroke.points) {
          minX = math.min(minX, point.x);
          minY = math.min(minY, point.y);
          maxX = math.max(maxX, point.x);
          maxY = math.max(maxY, point.y);
        }
      }
    }

    if (minX == .infinity) return .zero;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// textAlign 문자열을 TextAlign enum으로 변환
  TextAlign _parseTextAlign(String textAlign) {
    switch (textAlign.toLowerCase()) {
      case 'left':
        return .left;
      case 'right':
        return .right;
      case 'center':
        return .center;
      case 'justify':
        return .justify;
      default:
        return .center;
    }
  }

  /// 이전 초기 스케일 값 반환
  double _getPreviousInitScale() {
    return _previousInitScale > 0 ? _previousInitScale : 1.0;
  }

  /// 포인터 호버 처리
  void _onPointerHover(PointerHoverEvent event) {
    // 🎯 필기 모드가 비활성화되어 있으면 포인터 표시하지 않음
    if (!widget.isScribbleEnable) {
      return;
    }

    // 🎯 지우개 모드이거나 그리기 도구인 경우에만 포인터 표시
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
    final shouldShowPointer =
        currentMode == InkModes.erase ||
        currentMode == InkModes.pen ||
        currentMode == InkModes.pencil ||
        currentMode == InkModes.marker;

    if (shouldShowPointer) {
      widget.notifier.onPointerHover(event, widget.modeNotifier.state);
      // 🚀 성능 최적화: hover 이벤트의 빈번한 setState 제거 (필요한 경우에만 호출)
      // 포인터 hover는 notifier가 내부적으로 처리하므로 setState 불필요
    }
  }

  // 이전 모드 추적을 위한 변수
  String? _previousMode;

  // 🚀 성능 최적화: 크기 변화 감지를 위한 캐시
  String? _lastLoggedSizeKey;

  // 🚀 성능 최적화: 스케일 계산 캐싱
  String? _lastScaleCalculationKey;

  double? _cachedScaleToFit;

  double? _cachedAdjustedScaleToFit;

  Size? _cachedDisplaySize;

  @override
  void didUpdateWidget(ScribbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 모드 변경 감지
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
    if (_previousMode != null && _previousMode != currentMode) {
      _onModeChanged(currentMode);
    }
    _previousMode = currentMode;
  }

  @override
  void dispose() {
    // 🌍 DrawingState 등록 해제는 ScribbleController에서 자동으로 처리됨 ✅
    // (중복 해제 코드 제거됨)

    // 🎯 Undo/Redo 후 화면 업데이트 콜백 해제
    final drawingState = DrawingState();
    drawingState.unregisterUndoRedoUpdateCallback(_forceRepaint);

    // 🔄 DrawingState 도구 변경 리스너 해제
    drawingState.selectedTool.removeListener(_onDrawingToolChanged);

    // 🆕 스케일 변화 리스너 제거
    transformationController?.removeListener(_onTransformationChanged);

    // 🖊️ 글로벌 PointerRouter 리스너 해제
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalStylusPointer,
    );
    _stylusInactiveTimer?.cancel();

    widgetState.dispose();
    pointerHandler.dispose();
    strokeCountNotifier.dispose();
    isInteractiveNotifier.dispose();
    _currentPointerKindForHighlighter.dispose();
    _isMultiTouchNotifier.dispose();
    _isStylusActiveNotifier.dispose();
    super.dispose();
  }

  /// 🖊️ 글로벌 PointerRouter에서 호출 — stylus 이벤트를 영역 필터링 후
  /// scribble layer의 hit-test 활성화 여부를 결정한다.
  ///
  /// 동작:
  /// - stylus hover/down: 위젯 영역 안이면 _isStylusActive=true (scribble 활성)
  /// - stylus up/cancel: 짧은 딜레이 후 false (다음 down 사이 깜빡임 방지)
  /// - stylus가 아닌 입력: 무시 → 마우스/터치는 PDF로 통과
  void _handleGlobalStylusPointer(PointerEvent event) {
    if (event.kind != ui.PointerDeviceKind.stylus) return;
    if (!mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    if (!renderObject.attached) return;

    try {
      final localPosition = renderObject.globalToLocal(event.position);
      final isInside = (Offset.zero & renderObject.size).contains(
        localPosition,
      );

      if (event is PointerHoverEvent || event is PointerDownEvent) {
        if (isInside && !_isStylusActiveNotifier.value) {
          _stylusInactiveTimer?.cancel();
          _isStylusActiveNotifier.value = true;
        }
      } else if (event is PointerUpEvent || event is PointerCancelEvent) {
        if (_isStylusActiveNotifier.value) {
          // 펜이 화면을 떠난 직후 PDF 인터랙션이 가능해지도록 짧은 딜레이 후 false
          _stylusInactiveTimer?.cancel();
          _stylusInactiveTimer = Timer(
            const Duration(milliseconds: 300),
            () {
              if (mounted) {
                _isStylusActiveNotifier.value = false;
              }
            },
          );
        }
      }
    } on Exception {
      // globalToLocal 실패 시 무시 (위젯이 정상 mount 상태가 아닐 수 있음)
    }
  }

  // 현재 스케일 계산 (내부 transformationController 사용)
  double get currentScale =>
      transformationController?.value.getMaxScaleOnAxis() ?? 1.0;

  // 미디어 쿼리 데이터
  MediaQueryData get mediaData => MediaQuery.of(context);

  double get width {
    // ✨ 1순위: child가 있고 크기가 측정된 경우
    if (_childSize != null) {
      return _childSize!.width;
    }

    // 2순위: 화면 크기 (기본값)
    final screenWidth =
        mediaData.size.width - mediaData.padding.left - mediaData.padding.right;

    return screenWidth;
  }

  double get height {
    // ✨ 1순위: child가 있고 크기가 측정된 경우
    if (_childSize != null) {
      return _childSize!.height;
    }

    // 2순위: 화면 크기 (기본값)
    final screenHeight = mediaData.size.height;

    return screenHeight;
  }

  // ✨ child 크기가 측정되었는지 확인하는 헬퍼 메서드
  bool get _isChildReady => _isChildSizeMeasured && _childSize != null;

  @override
  Widget build(BuildContext context) {
    // transformationController는 이미 initState에서 초기화됨

    // 모드 변경 감지
    final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
    if (_previousMode != null && _previousMode != currentMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onModeChanged(currentMode);
      });
    }
    _previousMode = currentMode;

    // ✅ contentLogicalSize가 제공되면 오프스크린 측정 건너뛰기
    if (!_isChildReady && widget.contentLogicalSize != null) {
      _childSize = widget.contentLogicalSize;
      _isChildSizeMeasured = true;
      return _buildChildOverlay();
    }

    // ✅ 사전 측정: child가 있지만 아직 크기가 준비되지 않았다면 먼저 정확한 크기를 측정
    if (!_isChildReady) {
      // 1) 오프-트리 동기 측정 시도 (항상 유한한 제약 사용)
      final mediaSize = MediaQuery.of(context).size;
      final measured = MeasureWidgetUtil.measureWidget(
        // 오프-트리에서는 굳이 OverflowBox가 필요하지 않음
        RepaintBoundary(child: widget.child),
        constraints: BoxConstraints(
          minWidth: 0,
          minHeight: 0,
          maxWidth: mediaSize.width.isFinite ? mediaSize.width : 4096.0,
          maxHeight: mediaSize.height.isFinite ? mediaSize.height : 4096.0,
        ),
        textDirection: Directionality.of(context),
      );

      if (measured.width > 0 && measured.height > 0) {
        _childSize = measured;
        _isChildSizeMeasured = true;
        return _buildChildOverlay();
      }

      // 2) 실패 시 안전한 위젯 기반 측정으로 폴백 (항상 유한한 제약 보장)
      return LayoutBuilder(
        builder: (context, constraints) {
          final Size bound = Size(
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : mediaSize.width,
            constraints.hasBoundedHeight
                ? constraints.maxHeight
                : mediaSize.height,
          );

          final double w = bound.width.isFinite && bound.width > 0
              ? bound.width
              : mediaSize.width;
          final double h = bound.height.isFinite && bound.height > 0
              ? bound.height
              : mediaSize.height;

          return SizedBox(
            width: w,
            height: h,
            child: RenderMeasureSize(
              onChange: (size) {
                _onChildSizeChanged(size);
              },
              // 부모로부터 유한 제약을 받은 상태에서 상단 좌측 정렬로 배치
              child: Align(alignment: Alignment.topLeft, child: widget.child),
            ),
          );
        },
      );
    }

    // ✨ child가 있는 경우: 크기 측정 후 오버레이 구조로 빌드
    {
      return _buildChildOverlay();
    }
  }
}
