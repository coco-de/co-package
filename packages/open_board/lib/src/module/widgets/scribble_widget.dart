  import 'dart:async';
  import 'dart:developer';
  import 'dart:math' as math;
  import 'dart:ui' as ui;

  import 'package:flutter/gestures.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
  import 'package:open_board/src/core/utils/measure_size.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/lasso/lasso_selection_manager.dart';
  import 'package:open_board/src/module/scribble.notifier.dart';
  import 'package:open_board/src/module/scribble_mode.notifier.dart';
  import 'package:open_board/src/module/state/drawing_state.dart';
  import 'package:open_board/src/module/state/scribble.state.dart';
  import 'package:open_board/src/module/state/viewer_gesture_bus.dart';
  import 'package:open_board/src/module/text/text_interaction_manager.dart';
  import 'package:open_board/src/module/text/text_painter.dart';
  // 새로 생성한 클래스들 import
  import 'package:open_board/src/module/widgets/pointer_event_handler.dart';
  import 'package:open_board/src/module/widgets/scribble_render_layers.dart';
  import 'package:open_board/src/module/widgets/scribble_widget_state.dart';

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
      this.maxScale = 3.0,
      this.panDirection = PanDirection.horizontal, // 🎯 기본값: 가로 pan 허용
      this.onInteractionUpdate,
      this.onHandModeDrawingChanged,
      this.onSelectionComplete,
      this.onModeChanged,
      this.onChildSizeChanged, // ✨ 자식 크기 변경 콜백
      this.onScaleChanged,
      this.onTransformChanged,
      this.repaintBoundaryKey, // ✨ 외부에서 제공 가능한 GlobalKey
      this.contentLogicalSize,
      this.transformationController, // 🆕 외부 주입 가능한 변환 컨트롤러 (PR #99)
    });

    /// ✨ 이미지 캡처를 위한 GlobalKey - 외부에서 접근 가능
    final GlobalKey? repaintBoundaryKey;

    /// 🆕 논리 컨텐츠 크기(PDF 논리 사이즈 등). 지정 시 필기 좌표계의 기준 크기로 사용
    /// child의 실제 렌더 크기나 뷰포트 크기와 무관하게 고정 좌표계를 유지합니다.
    final Size? contentLogicalSize;

    /// ✨ 크기 결정 방식:
    /// 1. child가 있으면 → child 크기 자동 측정하여 사용
    /// 2. child가 없으면 → 화면 크기 사용

    final ScribbleNotifier notifier;
    final ScribbleModeNotifier modeNotifier;
    final bool isScribbleEnable;
    final bool drawPen;
    final bool drawEraser;
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

    /// 🆕 외부에서 주입 가능한 변환 컨트롤러 (PR #99)
    final TransformationController? transformationController;

    @override
    State<ScribbleWidget> createState() => _ScribbleWidgetState();
  }

  /// ScribbleWidget의 State 클래스 - 리팩토링된 버전
  final class _ScribbleWidgetState extends State<ScribbleWidget> {
    // 기본 컨트롤러들
    TransformationController? transformationController;
    late StrokeCountNotifier strokeCountNotifier;
    late ValueNotifier<bool> isInteractiveNotifier;

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

    // 🖐️ 아직 떼지 않은 터치 포인터 추적 (kTouchDelay 지연 처리용)
    // 30ms 지연 콜백이 발화하기 전에 up/cancel된 포인터의 down을 무시하여
    // 고아 pointer id가 activePointerIds에 영구 잔류하는 것을 방지한다.
    final Set<int> _pendingTouchDowns = <int>{};

    @override
    void initState() {
      super.initState();

      // 🌍 DrawingState 등록은 ScribbleController에서 자동으로 처리됨 ✅
      // (중복 등록 코드 제거됨)

      // 🔄 DrawingState의 도구 변경 감지 리스너 추가
      final drawingState = DrawingState();
      drawingState.selectedTool.addListener(_onDrawingToolChanged);

      // 🚧 G1(kobic #7026): 도구바 핸들 드래그 신호 구독 — true 전환 시
      // resetTouch 로 누출된 stroke 정리 (캔버스 IgnorePointer 게이트는 build 에서).
      ViewerGestureBus().isPanelDragging.addListener(_onPanelDraggingChanged);

      // 등록 후 즉시 강제 동기화 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        drawingState.forceSyncAll();
      });

      // 기본 notifier 초기화
      strokeCountNotifier = StrokeCountNotifier();
      isInteractiveNotifier = ValueNotifier<bool>(true);
      _currentPointerKindForHighlighter = ValueNotifier<ui.PointerDeviceKind?>(
        null,
      );
      // transformationController 먼저 초기화 (매니저들이 의존하므로)
      transformationController =
          widget.transformationController ?? TransformationController();

      // 🆕 스케일 변화 감지 리스너 추가
      _setupScaleChangeListeners();

      // 상태 관리 객체 초기화
      widgetState = ScribbleWidgetState();

      // 포인터 이벤트 핸들러 초기화
      pointerHandler = _createPointerHandler();

      // 렌더링 레이어 초기화
      renderLayers = _createRenderLayers();

      // 매니저들 초기화
      _initializeManagers();

      // 기존 텍스트 불러오기 (매니저 초기화 후)
      _loadTextDrawablesFromNotifier();
    }

    PointerEventHandler _createPointerHandler() {
      return PointerEventHandler(
        scribbleNotifier: widget.notifier,
        modeNotifier: widget.modeNotifier,
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
    }

    ScribbleRenderLayers _createRenderLayers() {
      return ScribbleRenderLayers(
        scribbleNotifier: widget.notifier,
        modeNotifier: widget.modeNotifier,
        widgetState: widgetState,
        strokeCountNotifier: strokeCountNotifier,
        background: widget.background,
        backgroundChild: widget.backgroundChild,
        size: null, // child가 있으면 자동으로 크기 측정됨
        drawPen: widget.drawPen,
        drawEraser: widget.drawEraser,
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
        onTextUpdated: (textDrawable) {},
        onTextDeselected: () {},
      );

      // 올가미 매니저 초기화
      lassoManager = LassoSelectionManager(
        scribbleNotifier: widget.notifier,
        onStateChanged: () {
          if (mounted) {
            setState(() {});
          }
        },
        transformationController: transformationController,
        onModeChanged: widget.onModeChanged,
      );

      // 🚨 undo/redo로 스트로크 목록이 바뀌면 인덱스 기반 올가미 선택이
      // 엉뚱한 스트로크를 가리키게 되므로 선택을 리셋한다.
      widget.notifier.onHistoryApplied = () {
        if (!mounted) return;
        if (widgetState.showLassoOverlay ||
            widgetState.selectedStrokeIds.isNotEmpty) {
          lassoManager.resetLassoState();
          _syncLassoManagerState();
          setState(() {});
        }
      };
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

      // 🎯 fixedPen 등 화면상 물리 두께 보정을 위한 scaleFactor 동기화
      //   InteractiveViewer의 줌이 변할 때마다 modeNotifier.scaleFactor를 갱신
      widget.modeNotifier.setScaleFactor(currentScale);

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

    /// 🚧 G1(kobic #7026): 도구바 핸들 드래그 시작 신호 처리.
    ///
    /// 핸들 pen-down 이 캔버스 `Listener`(arena 미참여)에도 도달해 누출한 stroke 를
    /// `resetTouch()` 로 즉시 정리한다. 입력 차단(IgnorePointer)은 build 에서
    /// `ViewerGestureBus.isPanelDragging` 를 구독해 반응형으로 처리한다.
    void _onPanelDraggingChanged() {
      if (!mounted) return;
      if (ViewerGestureBus().isPanelDragging.value) {
        pointerHandler.resetTouch();
      }
    }

    /// 🔄 DrawingTool을 InkModes로 변환
    String _convertDrawingToolToMode(DrawingTool tool) {
      return switch (tool) {
        DrawingTool.pen => InkModes.pen,
        DrawingTool.pencil => InkModes.pencil,
        DrawingTool.marker => InkModes.marker,
        DrawingTool.fixedPen => InkModes.fixedPen,
        DrawingTool.uniformPen => InkModes.uniformPen,
        DrawingTool.highlighter => InkModes.marker, // 하이라이터는 마커로 처리
        DrawingTool.text => InkModes.text,
        DrawingTool.lasso => InkModes.lasso,
        DrawingTool.erase => InkModes.erase,
        DrawingTool.shape => InkModes.shape,
        DrawingTool.image => InkModes.image,
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
              if (!_isChildReady && widget.contentLogicalSize == null) {
                // 안전장치: contentLogicalSize 미제공 + 사전 측정 미완료 시 최소 위젯 반환
                return const SizedBox.shrink();
              }

              // 스케일 기준 크기: 논리 컨텐츠 크기 우선, 없으면 측정된 child 크기, 최종 폴백은 뷰포트 크기
              Size baseContentSize = widget.contentLogicalSize ?? _childSize ?? scribbleWidgetSize;
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
                boundaryMargin: EdgeInsets.zero,
                minScale:
                    safeMinScale, // 🔥 BoxFit.contain으로 전체 컨텐츠가 보이는 최소 스케일
                maxScale: safeMaxScale, // 🔥 기본 스케일의 3.0배 최대 스케일
                constrained: false,
                // 🎯 정교한 제스처 제어: pan 비활성화로 PageView 스와이프 허용, scale은 허용
                panEnabled: _shouldEnablePan(), // 🚫 필기 모드에서 수평 pan 비활성화
                scaleEnabled: _shouldEnableScale(), // ✅ 확대/축소는 허용
                // 🚨 MouseTracker 버그 방지: 중복 콜백 제거 및 안전한 콜백 처리
                onInteractionStart: (ScaleStartDetails detail) {
                        try {
                          // 사용자가 제스처를 시작했음을 기록하여 자동 스냅 중단
                          _hasUserInteracted = true;
                          widget.onInteractionUpdate?.call(
                            true,
                            isReachedTopBoundary,
                            isReachedBottomBoundary,
                            isReachedLeftBoundary,
                            isReachedRightBoundary,
                            null,
                          );
                        } on Exception {
                          // MouseTracker 버그 방지: 콜백 오류 무시
                        }
                      },
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
                    (widget.onInteractionUpdate != null &&
                        !_isCurrentlyDrawing())
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
                            fit: BoxFit.contain, // BoxFit.contain 명시적 적용
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
                      Positioned(
                        left: fixedContentOffsetX,
                        top: fixedContentOffsetY,
                        child: SizedBox.fromSize(
                          size: displaySize,
                          child: FittedBox(
                            fit: BoxFit.contain,
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

                      // 3. 🚫 스타일러스 pan 차단 오버레이 — 필기 도구 활성 시 stylus
                      //   가 InteractiveViewer pan/scale 을 선점하지 못하게 한다
                      //   (kobic #7364). translucent 라 필기 입력은 그대로 통과.
                      _buildStylusPanBlocker(),
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
          final isHighlighterMode = selectedTool == DrawingTool.highlighter;

          // ⚡ 포인터 종류를 ValueListenableBuilder로 감시하여 즉시 반영
          return ValueListenableBuilder<ui.PointerDeviceKind?>(
            valueListenable: _currentPointerKindForHighlighter,
            builder: (context, currentPointerKind, child) {
              // 🎨 하이라이터 모드에서는 펜/손 입력을 투과시켜 PDF 텍스트 선택 허용
              // 핸드드로잉 모드(mouseOnly)에서는 마우스도 텍스트 선택을 위해 투과
              // 필기 모드에서는 펜 입력을 캡처하여 필기에 사용
              final isMouseOnlyMode =
                  drawingState.pointerMode.value ==
                  DrawingPointerMode.mouseOnly;

              // 🖍️ 하이라이터 모드에서 이 입력이 "텍스트 선택 담당" 장치인지 판정.
              //   포인터모드(펜/손)와 입력 장치를 매칭한다:
              //   - 손모드(mouseOnly): 손가락(touch)/마우스만 선택.
              //   - 펜모드(penOnly): 스타일러스만 선택 (일부 플랫폼은 stylus를
              //     unknown/invertedStylus로 보고하므로 함께 포함).
              //   비매칭 장치(예: 펜모드의 손가락)는 선택도 필기도 하지 않고,
              //   외곽 Listener swipe + InteractiveViewer 핀치로 화면 탐색만 한다.
              bool isTextSelectionDevice(ui.PointerDeviceKind? kind) {
                if (isMouseOnlyMode) {
                  return kind == ui.PointerDeviceKind.touch ||
                      kind == ui.PointerDeviceKind.mouse;
                }
                return kind == ui.PointerDeviceKind.stylus ||
                    kind == ui.PointerDeviceKind.invertedStylus ||
                    kind == ui.PointerDeviceKind.unknown;
              }

              // 🎯 포인터 종류 감지를 위한 최상위 Listener
              // ⚡ onPointerDown에서 펜/마우스/손 모두 감지
              // ⚠️ 중요: IgnorePointer의 ignoring 값이 빌드 시점에 결정되므로 첫 이벤트는 이전 상태로 처리될 수 있음
              // 해결: Builder로 감싸서 최신 ValueNotifier 값을 직접 참조
              // 🖱️ 드로잉 모드(하이라이트 제외)에서는 opaque로 PDF 드래그 차단
              return Listener(
                behavior: widget.isScribbleEnable && !isHighlighterMode
                    ? HitTestBehavior
                          .opaque // 드로잉 모드: PDF 드래그 차단
                    : HitTestBehavior.translucent, // 하이라이트 또는 비활성: 투과
                onPointerDown: isHighlighterMode
                    ? (event) {
                        // 펜/마우스/손 모두 감지
                        if (event.kind == ui.PointerDeviceKind.stylus ||
                            event.kind == ui.PointerDeviceKind.mouse ||
                            event.kind == ui.PointerDeviceKind.touch) {
                          // ⚡ 즉시 포인터 종류 설정
                          _currentPointerKindForHighlighter.value = event.kind;
                        }
                        // 🔧 터치 카운트 균형 유지 — 내부 Listener 는 하이라이트
                        //   모드에서 pdfrx 투과로 단락되므로, pointerHandler 카운트를
                        //   외부 Listener 에서 증감해 모드 전환 시 정합을 보장한다.
                        if (event.kind == ui.PointerDeviceKind.touch) {
                          pointerHandler.incrementTouch();
                        }
                      }
                    : null,
                onPointerUp: isHighlighterMode
                    ? (event) {
                        if (event.kind == ui.PointerDeviceKind.touch) {
                          pointerHandler.decrementTouch();
                        }
                      }
                    : null,
                onPointerCancel: isHighlighterMode
                    ? (event) {
                        if (event.kind == ui.PointerDeviceKind.touch) {
                          pointerHandler.decrementTouch();
                        }
                      }
                    : null,
                // 🚧 G1(kobic #7026): 도구바 핸들 드래그 중에는 캔버스 입력을
                // 차단해 stroke 오발을 막는다 (ViewerGestureBus 반응형 구독).
                child: ValueListenableBuilder<bool>(
                  valueListenable: ViewerGestureBus().isPanelDragging,
                  builder: (context, isPanelDragging, innerChild) {
                    // 🐛 #7092: 하이라이트 모드에서 손가락 핀치 줌이 전혀 안 되던 버그
                    //   수정. 이전엔 `&& !isMultiTouch` 로 두 번째 손가락에서
                    //   ignoring=false 로 뒤집어 InteractiveViewer 로 넘기려 했으나,
                    //   하이라이트 모드의 내부 IV 는 비활성(_shouldEnableScale/Pan=
                    //   false)이고 실제 줌은 pdfrx onInteractionUpdate →
                    //   externalTransformController forward(kobic 측)로 처리된다.
                    //   ignoring 뒤집힘이 진행 중인 핀치의 hit-test 경로를 바꿔(첫
                    //   손가락은 이미 pdfrx 로 라우팅됨) 두 손가락이 한 recognizer 에
                    //   모이지 못해 scale 미형성 → 줌 전혀 안 됨.
                    //   선택 장치(손가락/스타일러스)는 항상 투명 스크리블 오버레이를
                    //   투과(ignoring=true)시켜 pdfrx 가 모든 포인터를 받게 한다 →
                    //   단일=텍스트 선택/화면 탐색, 두 손가락=핀치 줌 정상 동작.
                    // 🐛 #7092: highlighter 면 포인터 종류와 무관하게 항상 투과한다.
                    //   shouldIgnoreForTextSelection(= isTextSelectionDevice 기반)
                    //   에 의존하면, 손가락 입력 직후 currentPointerKind 가 touch 로
                    //   남아 첫 펜(stylus) 입력이 직전 상태로 hit-test 되어 오버레이가
                    //   가로채 "손가락 후 첫 펜 드래그 실패" 버그가 났다(포인터 종류는
                    //   한 이벤트 늦게 갱신). 항상 투과시키면 단일 입력은 pdfrx 가
                    //   장치별로 처리(손=탐색/선택, 펜=선택), 두 손가락 줌은 inner
                    //   IV(부모)가 처리하므로 lag 가 사라진다.
                    final shouldIgnore = isHighlighterMode || isPanelDragging;
                    return IgnorePointer(
                      ignoring: shouldIgnore,
                      child: innerChild,
                    );
                  },
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
                                    behavior: widget.isScribbleEnable
                                        ? (isHighlighterMode &&
                                                  isTextSelectionDevice(
                                                    currentPointerKind,
                                                  ))
                                              ? HitTestBehavior
                                                    .translucent // 선택 장치: 투과
                                              : HitTestBehavior
                                                    .opaque // 필기/비선택: 차단
                                        : HitTestBehavior.translucent,
                                    // 🎨 하이라이트 모드에서 각 이벤트에서 포인터 종류를 직접 확인하여 즉시 처리
                                    // ⚡ 최상위 Listener에서 이미 포인터 종류를 감지했으므로, 여기서는 차단만 처리
                                    onPointerDown: widget.isScribbleEnable
                                        ? (event) {
                                            // 🖍️ 하이라이터 모드는 텍스트 선택 전용 —
                                            //   필기하지 않는다. 선택 장치는
                                            //   IgnorePointer 투과로 pdfrx 도달,
                                            //   비선택 장치는 외곽 Listener/
                                            //   InteractiveViewer 로 화면 탐색만 한다.
                                            //   (터치 카운트는 최상위 Listener 관리)
                                            if (isHighlighterMode) {
                                              return;
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
                                            // 🖍️ 하이라이터 모드는 텍스트 선택 전용 — 필기 차단
                                            if (isHighlighterMode) {
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
                                            // 🖍️ 하이라이터 모드는 텍스트 선택 전용 — 필기 차단
                                            if (isHighlighterMode) {
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
                                            // 🖍️ 하이라이터 모드는 텍스트 선택 전용 — 필기 차단
                                            if (isHighlighterMode) {
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
                                            // 🖍️ 하이라이터 모드는 텍스트 선택 전용 —
                                            //   hover 필기 미리보기 차단
                                            if (isHighlighterMode) {
                                              return;
                                            }
                                            try {
                                              _onPointerHover(event);
                                            } on Exception {
                                              // 예외 처리
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      width: targetSize.width,
                                      height: targetSize.height,
                                      color: Colors.transparent, // ✨ 투명 배경
                                      child: Stack(
                                        children: renderLayers.buildAllLayers(
                                          onDelete: () =>
                                              _removeSelectedStrokes(
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
                                          onTextTransformEnd:
                                              _onTextTransformEnd,
                                          onTextMoveStart: _onTextMoveStart,
                                          onTextMoveUpdate: _onTextMoveUpdate,
                                          onTextMoveEnd: _onTextMoveEnd,
                                          showTextOverlay:
                                              textManager.showTextOverlay ||
                                              widgetState
                                                      .selectedTextDrawable !=
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
        if (pointerMode == DrawingPointerMode.mouseOnly) {
          // 🔧 텍스트/올가미 변형 중이면 그리기 차단하여 충돌 방지
          if (textManager.isDraggingText ||
              textManager.isTransformingText ||
              lassoManager.isLassoTransforming) {
            return false;
          }

          // 드로잉 도구인지 확인
          final currentMode =
              widget.modeNotifier.state.inkGroupInfo.selectedInk;
          const drawingModes = {
            InkModes.pen,
            InkModes.pencil,
            InkModes.marker,
            InkModes.fixedPen,
            InkModes.erase,
            InkModes.shape,
            InkModes.lasso,
            InkModes.text,
          };
          return drawingModes.contains(currentMode);
        } else {
          // penOnly 모드에서는 터치는 스크롤용
          return false;
        }
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
      // 🎯 하이라이트 모드 체크 (텍스트 선택을 위해 제스처 완전 투과)
      final drawingState = DrawingState();
      final currentTool = drawingState.selectedTool.value;
      if (currentTool == DrawingTool.highlighter) {
        return false; // ✅ 하이라이트 모드에서는 InteractiveViewer 완전 비활성화
      }

      final isTransforming = widgetState.isTransforming;
      final isPenDrawing = _isPenDrawing();
      final isTextInteracting = textManager.isAnyTextInteracting;

      // 🖊️ 필기 모드에서는 펜으로 그리는 동안에만 InteractiveViewer 비활성화
      // 펜을 들고 있거나 변형 중이거나 텍스트 편집 중일 때만 제스처 차단
      final shouldEnable =
          !isTransforming && !isPenDrawing && !isTextInteracting;

      return shouldEnable;
    }

    /// 🎯 InteractiveViewer pan 제스처 허용 여부 (panDirection에 따라 제어)
    bool _shouldEnablePan() {
      // 🖊️ 멀티터치(두 손가락) 시에는 항상 pan 허용 (핀치 줌/드래그용).
      //   🐛 #7092: highlighter 체크보다 먼저 둔다. 기존엔 highlighter 를 먼저
      //   false 처리해 "외곽 IV 가 핀치를 처리"하도록 의도했으나, 내부 IV 의
      //   ScaleGestureRecognizer 는 scale/pan 비활성이어도 제스처를 캡처(소비)
      //   하므로 외곽 IV·pdfrx 가 핀치를 받지 못해 하이라이트 줌이 전혀 동작하지
      //   않았다. 두 손가락이면 내부 IV 가 직접 pan 을 처리한다(펜 도구와 동일).
      //   🖐️ 팜 제외 "유효" 멀티터치로 판정한다 (kobic UB-219) — 손모드 필기
      //   중 팜이 닿아도 여기서 true 가 되어 스크롤이 열리는 것을 막는다.
      if (pointerHandler.isEffectiveMultiTouch) {
        return true; // ✅ 두 손가락 터치 시 pan 허용
      }

      // 🎯 단일 손가락 highlighter: pan 비활성 → drag 가 pdfrx 텍스트 선택으로
      //    통과한다.
      final drawingState = DrawingState();
      final currentTool = drawingState.selectedTool.value;
      if (currentTool == DrawingTool.highlighter) {
        return false;
      }

      // 🖊️ 손모드에서 그리기 중일 때는 스크롤 차단 (단, 싱글 터치일 때만)
      if (_isHandModeDrawingActive) {
        return false; // 손모드 그리기 중에는 pan 제스처 완전 차단
      }

      // 🎯 panDirection에 따른 pan 제스처 제어
      switch (widget.panDirection) {
        case PanDirection.none:
          return false; // pan 제스처 완전 비활성화
        case PanDirection.horizontal:
          // 🚫 필기 모드에서는 수평 pan 비활성화하여 PageView 스와이프 허용
          if (widget.isScribbleEnable) {
            return false; // 수평 pan 비활성화 (PageView가 처리)
          }
          final result = _shouldEnableInteractiveGestures();
          return result;
        case PanDirection.vertical:
          // ✅ 세로 pan만 허용 (스크롤용)
          final result = _shouldEnableInteractiveGestures();
          return result;
        case PanDirection.both:
          // ✅ 모든 방향 pan 허용
          final result = _shouldEnableInteractiveGestures();
          return result;
      }
    }

    /// 🎯 InteractiveViewer scale 제스처 허용 여부 (확대/축소 허용)
    bool _shouldEnableScale() {
      // 🎯 하이라이트 모드: 외곽 InteractiveViewer 에 scale 양보 (GestureArena
      //    경합 방지). 외곽 IV 가 멀티터치 핀치를 일관되게 캡처하도록 한다.
      //    내부 IV 와 외곽 IV 가 동시에 ScaleGestureRecognizer 를 등록하면
      //    첫 핀치에서 어느 쪽이 win 할지 불안정해 모드 전환 직후 확대/축소
      //    동작이 일관되지 않는다 (kobic Issue: #5877 후속 보강).
      // 🖊️ 멀티터치(두 손가락) 시에는 항상 scale 허용 (핀치 줌용).
      //   🐛 #7092: highlighter 체크보다 먼저. 내부 IV 의 ScaleGestureRecognizer
      //   는 scale 비활성이어도 핀치 제스처를 캡처(소비)하므로, highlighter 를
      //   먼저 false 처리하면 제스처만 소비되고 줌이 적용되지 않아 "하이라이트
      //   줌 안 됨" 버그가 됐다. 두 손가락이면 내부 IV 가 직접 scale 을 적용한다.
      //   🖐️ 팜 제외 "유효" 멀티터치로 판정한다 (kobic UB-219) — 손모드 필기
      //   중 팜이 닿아도 여기서 true 가 되어 확대/축소가 열리는 것을 막는다.
      if (pointerHandler.isEffectiveMultiTouch) {
        return true; // ✅ 두 손가락 터치 시 핀치 줌 허용
      }

      // 🎯 highlighter: scale 항상 활성. ScaleGestureRecognizer 는 2-pointer 가
      //    있어야 scale 로 인정하므로, 단일 손가락은 IV 가 캡처하지 않고 pdfrx
      //    텍스트 선택으로 양보된다(외곽 _ExternalPinchZoomViewer 와 동일 패턴).
      //    반대로 scale=false 로 두면 IV 가 단일 손가락 제스처를 greedy 하게
      //    소비해 텍스트 선택이 막혔다 (#7092 회귀). 두 손가락은 위 multi 분기.
      final drawingState = DrawingState();
      final currentTool = drawingState.selectedTool.value;
      if (currentTool == DrawingTool.highlighter) {
        return true;
      }

      // ✅ 확대/축소는 필기 모드에서도 허용 (펜 그리기 중에만 비활성화)
      return _shouldEnableInteractiveGestures();
    }

    /// 🚫 스타일러스(펜) 포인터가 InteractiveViewer 의 pan/scale 제스처를 선점해
    ///    "필기 중 본문이 함께 이동(pan)" 되던 race 를 원천 차단한다 (kobic #7364).
    ///
    ///    기존 [_shouldEnablePan]/[_shouldEnableScale] 토글은 `_isPenDrawing()`
    ///    (→ `pointerHandler.isDragging`)에 의존하는데, stylus pen-down 시점엔
    ///    아직 dragging 전이라 pan 이 활성 상태로 남아 InteractiveViewer 의 pan
    ///    recognizer 가 gesture arena 에서 stylus 드래그를 선점한다. 토글은
    ///    rebuild 의존이라 이미 시작된 제스처를 멈추지 못한다(timing race).
    ///
    ///    필기 도구가 활성일 때 캔버스 위에 [HitTestBehavior.translucent] 오버레이
    ///    하나를 얹어, stylus 전용 [EagerGestureRecognizer] 가 pen-down 즉시
    ///    gesture arena 를 승리(다른 멤버 거부)시킨다. translucent 라 같은 포인터가
    ///    아래의 필기 `Listener` 에도 그대로 전달되어 필기는 정상 동작하고, pan/
    ///    scale 만 stylus 에 대해 차단된다. supportedDevices 를 스타일러스로
    ///    한정해 손가락 스크롤·두 손가락 핀치(touch)·마우스는 종전대로 동작한다.
    Widget _buildStylusPanBlocker() {
      return Positioned.fill(
        child: ValueListenableBuilder<DrawingTool>(
          valueListenable: DrawingState().selectedTool,
          builder: (context, tool, child) {
            // 하이라이터는 stylus 가 pdfrx 텍스트 선택을 해야 하므로 제외한다.
            // 🖼️ 이미지 모드(kobic #8101)도 제외: 이미지 선택/이동/변형/삭제는
            // 스트로크를 그리지 않는 위젯 레이어 제스처(ImageDrawableLayer의
            // Tap/Pan GestureDetector)이므로 "필기 중 pan 선점 방지"용 Eager
            // recognizer 가 필요 없다. 오히려 이 오버레이가 활성 상태였다면
            // EagerGestureRecognizer 가 gesture arena 를 즉시 선점해 이미지
            // 레이어의 Tap/Pan recognizer 가 항상 거부되어, 스타일러스로는
            // 이미지를 선택할 수 없었다(터치/마우스는 supportedDevices 밖이라
            // 영향받지 않아 정상 동작했음).
            final enabled =
                widget.isScribbleEnable &&
                tool != DrawingTool.highlighter &&
                tool != DrawingTool.image;
            if (!enabled) {
              return const SizedBox.shrink();
            }
            return RawGestureDetector(
              behavior: .translucent,
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(
                      // recognizer lifecycle 은 RawGestureDetector 가 소유·dispose
                      // 한다 (GestureRecognizerFactory 표준 패턴).
                      // ignore: avoid-undisposed-instances
                      () => EagerGestureRecognizer(
                        supportedDevices: const {
                          ui.PointerDeviceKind.stylus,
                          ui.PointerDeviceKind.invertedStylus,
                          // 🌐 kobic UB-173: 웹 펜은 PointerDeviceKind.unknown 으로
                          //   전달된다. 드로잉 경로(_canStartDrawing/
                          //   _handlePointerDown)는 이미 stylus||unknown 을 펜으로
                          //   취급하므로, pan 차단도 동일하게 unknown 을 포함해
                          //   웹 펜모드 필기 중 본문이 함께 이동(pan)하던 버그를
                          //   막는다. touch/mouse 는 종전대로 미포함(스크롤·핀치·
                          //   마우스 네비게이션 영향 없음).
                          ui.PointerDeviceKind.unknown,
                        },
                      ),
                      (instance) {}, // ignore: no-empty-block
                    ),
              },
            );
          },
        ),
      );
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
      if (currentTool == DrawingTool.highlighter) {
        return false; // ✅ 하이라이트 모드에서는 페이지 넘김 허용
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
      if (pointerMode != DrawingPointerMode.mouseOnly) {
        return false;
      }

      // 2. 선택된 도구가 필기 도구인지 확인
      final currentMode = widget.modeNotifier.state.inkGroupInfo.selectedInk;
      const drawingModes = {
        InkModes.pen,
        InkModes.pencil,
        InkModes.marker,
        InkModes.fixedPen,
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
        case DrawingPointerMode.penOnly:
          // 스타일러스/unknown만 허용
          return event.kind == ui.PointerDeviceKind.stylus ||
              event.kind == ui.PointerDeviceKind.unknown;
        case DrawingPointerMode.mouseOnly:
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
        pointerHandler.incrementTouch();
        _pendingTouchDowns.add(event.pointer);

        // 🖐️ 팜 리젝션 (kobic UB-219): 손모드 필기가 이미 진행 중일 때
        // 도착하는 추가 터치는 의도적 두 손가락 핀치줌이 아니라 필기 중
        // 팜/보조손가락의 우연한 접촉으로 간주해 무시한다. 진행 중인
        // 스트로크의 move 처리·스크롤 차단(_isHandModeDrawingActive)을 그대로
        // 유지한다. 필기가 시작되기 전(스트로크 미시작) 상태에서 동시에 닿은
        // 두 번째 터치만 아래 분기에서 기존처럼 핀치줌/팬으로 인정된다.
        if (_isHandModeDrawingActive) {
          pointerHandler.markPalmIgnored(event.pointer);
          return;
        }

        // 🖊️ 멀티터치 감지 시 InteractiveViewer 상태 갱신 (핀치 줌/드래그 허용)
        if (pointerHandler.isMultiTouch()) {
          setState(
            () {},
          ); // InteractiveViewer 상태 갱신 (panEnabled/scaleEnabled 업데이트)
          return; // 두 번째 터치는 드로잉에 사용하지 않음 (줌/드래그용)
        }

        Future<void>.delayed(PointerEventHandler.kTouchDelay, () {
          // 지연 중에 up/cancel된 포인터는 처리하지 않는다.
          // (up이 먼저 소비되면 여기서 추가된 pointer id를 제거할 기회가 없어
          //  activePointerIds에 영구 잔류하고 터치 필기가 차단된다)
          if (mounted &&
              _pendingTouchDowns.contains(event.pointer) &&
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
      } else if (currentMode == InkModes.image) {
        // 🖼️ 이미지 모드: 그리기 파이프라인 진입을 완전히 차단한다.
        // 선택/이동/크기조절/회전은 ImageDrawableLayer 자체 GestureDetector가
        // 담당하므로 여기서는 아무 것도 하지 않고 포인터 이벤트를 그대로
        // 통과시킨다. `_canStartDrawing()`은 현재 선택된 도구가 아니라
        // DrawingPointerMode(펜전용/손전용) 정책만 판단하므로, 이 분기가
        // 없으면 이미지 모드에서도(특히 penOnly 정책의 스타일러스 탭이)
        // 스트로크로 오인식되어 `_hideAllOverlays()` + `handleNormalDrawingMode()`
        // 가 호출되고, 이미지 탭이 이미지 선택 대신 빈 스트로크 그리기로
        // 소비되어 이미지 선택이 동작하지 않는다.
        return;
      } else {
        // 다른 모드(펜, 지우개 등)에서는 포인터 종류에 따라 텍스트 상호작용 제한
        bool textHandled = false;

        // 드로잉 모드에서 텍스트 선택 조건:
        // 1. 기존 텍스트 영역 클릭
        // 2. 손터치(touch) 또는 마우스(웹/데스크톱) 허용
        //    스타일러스는 그리기 의도로 간주해 텍스트 상호작용 차단
        final isTouchOrMouse =
            event.kind == ui.PointerDeviceKind.touch ||
            event.kind == ui.PointerDeviceKind.mouse;
        final isClickingText = _isClickingExistingText(event);

        if (isClickingText && isTouchOrMouse) {
          textHandled = textManager.handlePointerDown(event);
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
        case DrawingTool.pen:
          currentInk = InkModes.pen;
          break;
        case DrawingTool.pencil:
          currentInk = InkModes.pencil;
          break;
        case DrawingTool.marker:
          currentInk = InkModes.marker;
          break;
        case DrawingTool.fixedPen:
          currentInk = InkModes.fixedPen;
          break;
        case DrawingTool.uniformPen:
          currentInk = InkModes.uniformPen;
          break;
        case DrawingTool.highlighter:
          currentInk = InkModes.marker; // 하이라이터는 마커로 처리
          break;
        case DrawingTool.erase:
          currentInk = InkModes.erase;
          break;
        case DrawingTool.text:
          currentInk = InkModes.text;
          break;
        case DrawingTool.shape:
          currentInk = InkModes.shape;
          break;
        case DrawingTool.lasso:
          currentInk = InkModes.lasso;
          break;
        case DrawingTool.image:
          currentInk = InkModes.image;
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
      // 🖐️ 팜으로 무시된 포인터 자신의 move는 처리하지 않는다 (kobic UB-219).
      if (pointerHandler.isPalmIgnored(event.pointer)) return;
      // 팜을 제외한 "유효" 멀티터치 기준으로 판정해, 손모드 필기 중 팜이
      // 함께 눌려 있어도 실제 그리기 포인터의 move는 계속 처리한다.
      if (pointerHandler.isEffectiveMultiTouch) return;

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

      if (event.kind == ui.PointerDeviceKind.touch) {
        pointerHandler.decrementTouch();
        _pendingTouchDowns.remove(event.pointer);
      }

      // 🖐️ 팜으로 무시된 포인터의 up (kobic UB-219): 실제 필기에 관여하지
      // 않았으므로(_processPointerDown 을 거친 적 없음) 스트로크/손모드
      // 상태에 영향을 주지 않고 카운트 정리 후 종료한다. onScribbleFinished
      // 등 그리기 종료 콜백을 유발하지 않아 진행 중이던 다른 손가락의
      // 스트로크가 이 up 으로 조기 종료되지 않는다.
      if (event.kind == ui.PointerDeviceKind.touch &&
          pointerHandler.isPalmIgnored(event.pointer)) {
        pointerHandler.clearPalmIgnored(event.pointer);
        if (wasMultiTouch && !pointerHandler.isMultiTouch()) {
          setState(() {});
        }
        return;
      }

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

      if (event.kind == ui.PointerDeviceKind.touch) {
        pointerHandler.decrementTouch();
        _pendingTouchDowns.remove(event.pointer);
      }

      // 🖐️ 팜으로 무시된 포인터의 cancel (kobic UB-219): 실제 필기에 관여하지
      // 않았으므로 스트로크/손모드 상태에 영향을 주지 않고 카운트 정리 후
      // 종료한다 (up 처리와 동일한 근거).
      if (event.kind == ui.PointerDeviceKind.touch &&
          pointerHandler.isPalmIgnored(event.pointer)) {
        pointerHandler.clearPalmIgnored(event.pointer);
        if (wasMultiTouch && !pointerHandler.isMultiTouch()) {
          setState(() {});
        }
        return;
      }

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

      // 🚨 notifier에 cancel을 전달해 activePointerIds에서 해당 id를 제거하고
      // 그리던 라인을 정리한다. 전달하지 않으면 시스템 제스처/팜 리젝션으로
      // 취소된 포인터가 영구 잔류하여 해당 페이지 필기가 차단된다.
      pointerHandler.handlePointerCancel(event);

      // 텍스트 드래그/크기조절 상태도 정리 — 고착되면 isAnyTextInteracting이
      // true로 남아 손을 뗀 뒤에도 핀치줌과 필기가 계속 차단된다.
      if (textManager.handlePointerCancel(event)) {
        setState(() {});
      }
    }

    // 스트로크 삭제
    void _removeSelectedStrokes(List<int> strokeIds) {
      if (strokeIds.isEmpty) return;

      final sortedIds = List<int>.from(strokeIds)
        ..sort((a, b) => b.compareTo(a));
      final currentScribble = widget.notifier.currentState.scribble;
      final strokes = List<Stroke>.from(currentScribble.strokes);

      for (final id in sortedIds) {
        if (id >= 0 && id < strokes.length) {
          strokes.removeAt(id);
        }
      }

      final updatedScribble = currentScribble.copyWithContents(
        strokes: strokes,
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
      } else {
        return false;
      }
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
        } else {
          // 다른 모드에서는 기존 로직 유지 (선택 상태만 유지)

          return true;
        }
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
          fontWeight: textDrawable.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: textDrawable.isItalic
              ? FontStyle.italic
              : FontStyle.normal,
          decoration: textDrawable.isUnderlined
              ? TextDecoration.underline
              : null,
        ),
      );

      final textAlign = _parseTextAlign(textDrawable.textAlign);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 텍스트 위치 (x, y)
      final position = Offset(textDrawable.x, textDrawable.y);

      // 텍스트 렌더링 위치 계산 (정렬에 따라)
      Offset renderPosition = position;
      switch (textAlign) {
        case TextAlign.center:
          renderPosition = Offset(
            position.dx - textPainter.width / 2,
            position.dy - textPainter.height / 2,
          );
          break;
        case TextAlign.right:
          renderPosition = Offset(
            position.dx - textPainter.width,
            position.dy - textPainter.height / 2,
          );
          break;
        case TextAlign.left:
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
        if ((adjustedPosition - transformButtonCenter).distance <=
            buttonRadius) {
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
      if (strokeIds.isEmpty) return Rect.zero;

      final strokes = widget.notifier.currentState.scribble.strokes;
      // 🚀 성능 최적화: 초기값을 더 효율적으로 설정
      double minX = double.maxFinite;
      double minY = double.maxFinite;
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

      // 유효한 포인트가 하나도 없으면 초기값(maxFinite)이 그대로 남는다.
      if (minX == double.maxFinite) return Rect.zero;
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    /// textAlign 문자열을 TextAlign enum으로 변환
    TextAlign _parseTextAlign(String textAlign) {
      switch (textAlign.toLowerCase()) {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        case 'center':
          return TextAlign.center;
        case 'justify':
          return TextAlign.justify;
        default:
          return TextAlign.center;
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

      // 🚨 notifier/modeNotifier 교체 시 매니저들을 새 notifier로 재연결한다.
      // 재연결하지 않으면 매니저들이 옛(또는 dispose된) notifier에 계속
      // 필기를 기록해 크래시하거나 입력이 유실된다.
      if (widget.notifier != oldWidget.notifier ||
          widget.modeNotifier != oldWidget.modeNotifier) {
        oldWidget.notifier.onHistoryApplied = null;
        textManager.dispose();
        pointerHandler.dispose();
        pointerHandler = _createPointerHandler();
        renderLayers = _createRenderLayers();
        _initializeManagers();
        _loadTextDrawablesFromNotifier();
        _pendingTouchDowns.clear();
      }

      // 🖐️ 필기 활성화 상태가 토글되면 진행 중이던 터치 추적을 초기화한다.
      // 비활성화 동안 Listener의 up/cancel 핸들러가 끊겨 터치 카운트가
      // 고착되면 이후 모든 싱글터치가 멀티터치로 오인된다.
      if (widget.isScribbleEnable != oldWidget.isScribbleEnable) {
        pointerHandler.resetTouch();
        _pendingTouchDowns.clear();
      }

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

      // 🔄 DrawingState 도구 변경 리스너 해제
      final drawingState = DrawingState();
      drawingState.selectedTool.removeListener(_onDrawingToolChanged);

      // 🚧 G1(kobic #7026): 도구바 핸들 드래그 신호 구독 해제.
      ViewerGestureBus().isPanelDragging.removeListener(
        _onPanelDraggingChanged,
      );

      // 🆕 스케일 변화 리스너 제거
      transformationController?.removeListener(_onTransformationChanged);

      // 히스토리 적용 콜백 해제 (dispose된 State 참조 방지)
      widget.notifier.onHistoryApplied = null;

      // 편집 중이던 인라인 에디터 오버레이 제거 (좀비 UI/스테일 커밋 방지)
      textManager.dispose();

      widgetState.dispose();
      pointerHandler.dispose();
      strokeCountNotifier.dispose();
      isInteractiveNotifier.dispose();
      _currentPointerKindForHighlighter.dispose();
      super.dispose();
    }

    // 현재 스케일 계산 (내부 transformationController 사용)
    double get currentScale =>
        transformationController?.value.getMaxScaleOnAxis() ?? 1.0;

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

      // ✅ contentLogicalSize가 외부에서 제공된 경우 사전 측정을 건너뛰고 바로 오버레이 빌드
      if (!_isChildReady && widget.contentLogicalSize != null) {
        final cls = widget.contentLogicalSize!;
        if (cls.width > 0 && cls.height > 0) {
          _childSize = cls;
          _isChildSizeMeasured = true;
          return _buildChildOverlay();
        }
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
