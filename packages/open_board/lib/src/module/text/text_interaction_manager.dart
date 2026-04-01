  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
  import 'package:open_board/src/module/scribble.notifier.dart';
  import 'package:open_board/src/module/scribble_mode.notifier.dart';
  import 'package:open_board/src/module/text/text_drawable_extensions.dart';
  import 'package:open_board/src/module/text/inline_text_editor.dart';
  import 'package:open_board/src/module/state/text_settings.dart';
  import 'package:open_board/src/module/widgets/scribble_widget_state.dart';
  import 'package:open_board/src/module/coordinate_transformer.dart';
  import 'package:open_board/src/module/transform_handler.dart';
  import 'dart:math' as math;

  /// 텍스트 상호작용을 관리하는 클래스
  /// ScribbleWidget의 텍스트 관련 기능들을 분리하여 관리
  class TextInteractionManager {
    // 더블탭 감지 상수
    static const double _doubleTapThreshold = 800.0; // 밀리초 (500ms → 800ms로 증가)
    static const double _doubleTapPositionThreshold = 50.0; // 픽셀

    final ScribbleNotifier scribbleNotifier;
    final ScribbleModeNotifier modeNotifier;
    final VoidCallback onStateChanged;
    final BuildContext context;

    final TransformationController? transformationController;
    final GlobalKey? repaintBoundaryKey; // 추가: Overlay 위치 계산용

    // 콜백 함수들
    final void Function(TextDrawable textDrawable) onTextSelected;

    final void Function(TextDrawable textDrawable) onTextUpdated;

    final void Function() onTextDeselected; // ScribbleWidgetState 참조 추가
    final ScribbleWidgetState widgetState;

    // 텍스트 관련 상태 - 로컬 리스트 제거하고 ScribbleNotifier 참조만 사용
    int? _selectedTextIndex;
    late TextSettings _textSettings; // 편집 상태
    bool _isEditingText = false;

    String? _editingTextId;
    OverlayEntry? _textEditorOverlay; // 드래그 상태
    int? _draggingTextIndex;
    Offset? _dragStartPosition;
    Offset? _textDragOffset;

    Offset? _lastTransformPosition; // 올가미 방식 드래그를 위한 마지막 위치

    bool _isDraggingText = false;

    // 변형 상태
    bool _isTransformingText = false;

    // 오버레이 표시 상태
    bool _showTextOverlay = false; // 크기조절 상태
    bool _isTextResizing = false;

    // 더블탭 감지용 변수
    DateTime? _lastTapTime;
    Offset? _lastTapPosition;

    // 텍스트 변형 관련 변수들 (올가미 방식 적용)
    Offset? _originalTextCenter; // 텍스트 중심점
    double? _originalFontSize; // 원본 폰트 크기

    // 공통 변형 핸들러
    late TransformHandler _transformHandler;

    TextInteractionManager({
      required this.scribbleNotifier,
      required this.modeNotifier,
      required this.onStateChanged,
      required this.context,
      required this.transformationController,
      required this.repaintBoundaryKey,
      required this.onTextSelected,
      required this.onTextUpdated,
      required this.onTextDeselected,
      required this.widgetState,
    }) {
      _transformHandler = TransformHandler();
      _initializeFromScribble();
    }

    // Getters - ScribbleNotifier에서 직접 가져오기
    List<TextDrawable> get textDrawables =>
        scribbleNotifier.getCurrentTextDrawables();
    bool get isDraggingText => _isDraggingText;
    bool get isTextDragPreparing =>
        _draggingTextIndex != null && !_isDraggingText;
    bool get isTransformingText => _isTransformingText;
    bool get showTextOverlay => _showTextOverlay;

    bool get isAnyTextInteracting =>
        _isTextResizing ||
        _isDraggingText ||
        _isTransformingText ||
        isTextDragPreparing;

    double get currentScale => _transformer.scale;

    CoordinateTransformer get _transformer =>
        CoordinateTransformer(transformationController);

    /// 포인터 다운 이벤트 처리
    bool handlePointerDown(PointerDownEvent event) {
      // 편집 중이면 무시
      if (_isEditingText) {
        return false;
      }

      // 오버레이 컨트롤 영역 체크를 가장 먼저 수행 (올가미 매니저와 동일한 방식)
      if (_showTextOverlay &&
          _selectedTextIndex != null &&
          _selectedTextIndex! < textDrawables.length) {
        final selectedText = textDrawables[_selectedTextIndex!];

        final controlAreaResult = _handleControlAreaTouch(
          event.localPosition,
          selectedText,
        );
        if (controlAreaResult != null) {
          // 컨트롤 영역 터치 처리됨 - 텍스트 선택/드래그 방지
          return controlAreaResult;
        }

        // 선택된 텍스트 영역 내부 터치 확인 (변형 모드)
        // 🔥 scribble-tools 방식: 원본 좌표 직접 사용
        final adjustedPosition = event.localPosition; // toScene() 제거
        if (_isPointInTextBounds(adjustedPosition, selectedText)) {
          // 🔥 더블탭 감지를 드래그 준비보다 먼저 처리
          return _handleExistingTextTap(_selectedTextIndex!, adjustedPosition);
        }
      }

      // 🔥 scribble-tools 방식: 원본 좌표 직접 사용
      final adjustedPosition = event.localPosition; // toScene() 제거
      final textIndex = _findTextAt(adjustedPosition);

      if (textIndex != null) {
        // 기존 텍스트 탭 처리
        return _handleExistingTextTap(textIndex, adjustedPosition);
      }

      // 텍스트를 찾지 못한 경우 - 새 텍스트 추가

      return _addNewTextAt(adjustedPosition, event.localPosition);
    }

    /// 포인터 이동 이벤트 처리
    bool handlePointerMove(PointerMoveEvent event) {
      // 편집 중이면 무시
      if (_isEditingText) {
        return false;
      }

      // 텍스트 변형 중인 경우 (TransformHandler 사용)
      if (_isTextResizing &&
          _selectedTextIndex != null &&
          _originalTextCenter != null &&
          _transformHandler.isResizeRotating &&
          _originalFontSize != null) {
        final currentTouchPoint = event.localPosition;

        // TransformHandler로 스케일/회전 계산
        final result = _transformHandler.computeResizeRotate(currentTouchPoint);
        final clampedScale = result.scale;

        // 회전 정보를 맵에 저장 (TextDrawablePainter에서 사용)
        final textDrawable = textDrawables[_selectedTextIndex!];
        final newStyle = textDrawable.style.copyWith(
          fontSize: _originalFontSize! * clampedScale,
        );
        final updatedText = textDrawable.copyWithStyle(newStyle);

        // 회전 각도를 TextDrawable에 안전하게 설정
        try {
          updatedText.rotation = result.deltaAngle;
        } on Exception catch (error, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);
          debugPrint(error.toString());
          // rotation 설정이 실패해도 다른 변형은 계속 진행
        }

        // 텍스트 리스트 업데이트
        textDrawables[_selectedTextIndex!] = updatedText;

        // ScribbleNotifier에 즉시 업데이트 (히스토리 추가 없이)
        scribbleNotifier.updateTextDrawable(updatedText.id, updatedText);

        // 오버레이 상태 유지
        _showTextOverlay = true;

        _syncWithWidgetState();
        onStateChanged();

        return true; // 이벤트 처리 완료
      }

      // 텍스트 드래그 준비 상태에서 임계값 확인
      if (!_isDraggingText &&
          _draggingTextIndex != null &&
          _dragStartPosition != null &&
          _textDragOffset != null) {
        final dragDistance =
            (event.localPosition - _dragStartPosition!).distance;

        if (dragDistance > 15.0) {
          _isDraggingText = true;

          // 🔥 InteractiveViewer 제스처 제어를 위한 상태 변경 로그

          _syncWithWidgetState();
        }
      }

      // 텍스트 드래그 중인 경우
      if (_isDraggingText &&
          _draggingTextIndex != null &&
          _textDragOffset != null) {
        // 🔥 scribble-tools 방식: 원본 좌표 직접 사용
        final adjustedPosition = event.localPosition; // toScene() 제거
        final newPosition = Offset(
          adjustedPosition.dx - _textDragOffset!.dx,
          adjustedPosition.dy - _textDragOffset!.dy,
        );

        _updateTextPosition(_draggingTextIndex!, newPosition);

        return true; // 이벤트 처리 완료
      }

      return false;
    }

    /// 포인터 업 이벤트 처리
    bool handlePointerUp(PointerUpEvent event) {
      // 편집 중이면 무시
      if (_isEditingText) {
        return false;
      }

      // 텍스트 변형 완료 처리 (올가미 매니저와 동일한 방식)
      if (_isTextResizing) {
        _isTextResizing = false;

        // TransformHandler 크기조절/회전 상태 종료
        _transformHandler.endResizeRotate();

        // 변형 관련 변수들 초기화
        _originalTextCenter = null;
        _originalFontSize = null;

        _syncWithWidgetState();
        onStateChanged();
        return true;
      }

      // 텍스트 드래그 완료 처리
      if (_isDraggingText) {
        _finishTextDrag();
        return true;
      }

      // 드래그 준비 상태였지만 임계값에 도달하지 못한 경우 정리
      if (_draggingTextIndex != null ||
          _dragStartPosition != null ||
          _textDragOffset != null) {
        _draggingTextIndex = null;
        _dragStartPosition = null;
        _textDragOffset = null;
        _isDraggingText = false;
        _syncWithWidgetState();
        return true;
      }

      return false;
    }

    /// 선택된 텍스트 삭제
    void deleteSelectedText() {
      if (_selectedTextIndex == null ||
          _selectedTextIndex! >= textDrawables.length) {
        return;
      }

      final selectedText = textDrawables[_selectedTextIndex!];

      // ScribbleNotifier에서 텍스트 삭제
      scribbleNotifier.removeTextDrawable(selectedText.id);

      // 선택 상태 및 오버레이 초기화
      _selectedTextIndex = null;
      _showTextOverlay = false;
      _isTextResizing = false;

      // widgetState 동기화
      _syncWithWidgetState();

      onStateChanged();
    }

    /// 텍스트 크기조절 모드 시작 (변형 버튼 드래그 시작)
    void startTextResizeMode(Offset position) {
      if (_selectedTextIndex == null ||
          _selectedTextIndex! >= textDrawables.length) {
        return;
      }

      final textDrawable = textDrawables[_selectedTextIndex!];

      // 텍스트 중심점 계산 (올가미와 동일한 방식)
      final bounds = _getTextBounds(textDrawable);
      _originalTextCenter = bounds.center;

      // 원본 폰트 크기 저장
      _originalFontSize = textDrawable.style.fontSize ?? 16.0;

      // 기존 회전 각도를 현재 회전으로 설정 (안전한 접근)
      double currentRotation = 0.0;
      try {
        currentRotation = textDrawable.rotation;
      } on Exception {
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        currentRotation = 0.0;
      }

      // TransformHandler로 크기조절/회전 시작
      _transformHandler.startResizeRotate(
        position,
        _originalTextCenter!,
        initialRotation: currentRotation,
      );

      _isTextResizing = true;

      // widgetState 동기화
      _syncWithWidgetState();

      onStateChanged();
    }

    /// 텍스트 오버레이 숨기기
    void hideTextOverlay() {
      _showTextOverlay = false;
      onStateChanged();
    }

    /// 텍스트 오버레이 숨기기 및 선택 해제
    void hideTextOverlayAndDeselect() {
      _showTextOverlay = false;
      _selectedTextIndex = null;
      _syncWithWidgetState();
      onStateChanged();
    }

    /// 스크리블 상태 동기화
    void syncWithScribble() {
      _initializeFromScribble();
      _syncWithWidgetState();
      onStateChanged();
    }

    /// 텍스트 변형 시작 (올가미와 동일한 방식)
    void onTextTransformStart(DragStartDetails details, BuildContext context) {
      if (_selectedTextIndex == null ||
          _selectedTextIndex! >= textDrawables.length) {
        return;
      }

      final textDrawable = textDrawables[_selectedTextIndex!];

      // 텍스트 중심점 계산
      final bounds = _getTextBounds(textDrawable);
      _originalTextCenter = bounds.center;

      // 원본 폰트 크기 저장
      _originalFontSize = textDrawable.style.fontSize ?? 16.0;

      // TransformHandler로 크기조절/회전 시작
      final touchPoint = details.localPosition;
      _transformHandler.startResizeRotate(touchPoint, _originalTextCenter!);

      _isTextResizing = true;

      // 오버레이 상태 유지 (변형 중에도 버튼이 보이도록)
      _showTextOverlay = true;

      _syncWithWidgetState();
      onStateChanged();
    }

    /// 텍스트 변형 업데이트 (TransformHandler 사용)
    void onTextTransformUpdate(
      DragUpdateDetails details,
      BuildContext context,
    ) {
      if (_selectedTextIndex == null ||
          _originalTextCenter == null ||
          _originalFontSize == null ||
          !_isTextResizing ||
          !_transformHandler.isResizeRotating) {
        return;
      }

      final textDrawable = textDrawables[_selectedTextIndex!];
      final currentTouchPoint = details.localPosition;

      // TransformHandler로 스케일/회전 계산
      final result = _transformHandler.computeResizeRotate(currentTouchPoint);
      final clampedScale = result.scale;

      // 새 폰트 크기 계산
      final newFontSize = (_originalFontSize! * clampedScale).clamp(8.0, 72.0);

      // 텍스트 스타일 업데이트 (폰트 크기만 - 회전은 별도 처리 필요)
      final newStyle = textDrawable.style.copyWith(fontSize: newFontSize);
      final updatedText = textDrawable.copyWithStyle(newStyle);

      // 회전 각도를 TextDrawable에 직접 설정
      updatedText.rotation = result.deltaAngle;

      // 텍스트 리스트 업데이트
      textDrawables[_selectedTextIndex!] = updatedText;

      // ScribbleNotifier에 즉시 업데이트 (히스토리 추가 없이)
      scribbleNotifier.updateTextDrawable(updatedText.id, updatedText);

      // 오버레이 상태 유지
      _showTextOverlay = true;

      _syncWithWidgetState();
      onStateChanged();
    }

    /// 텍스트 변형 종료 (TransformHandler 사용)
    void onTextTransformEnd(DragEndDetails details) {
      // 최종 변환 완료 - 히스토리에 저장
      if (_selectedTextIndex != null &&
          _selectedTextIndex! < textDrawables.length) {
        final currentScribble = scribbleNotifier.currentState.scribble;
        scribbleNotifier.setScribble(
          scribble: currentScribble,
          addToUndoHistory: true,
        );
      }

      // TransformHandler 크기조절/회전 상태 종료
      _transformHandler.endResizeRotate();

      // 상태 초기화
      _isTextResizing = false;
      _originalTextCenter = null;
      _originalFontSize = null;

      // 오버레이 상태 유지 (변형 완료 후에도 선택 상태 유지)
      _showTextOverlay = true;

      _syncWithWidgetState();
      onStateChanged();
    }

    /// 텍스트 이동 업데이트 (ScribbleWidget에서 호출)
    void onTextMoveUpdate(DragUpdateDetails details) {
      if (_draggingTextIndex == null || _lastTransformPosition == null) return;

      // 드래그 시작 감지 (임계값을 높여서 더블탭과 구분)
      if (!_isDraggingText && _dragStartPosition != null) {
        final dragDistance =
            (details.localPosition - _dragStartPosition!).distance;

        if (dragDistance > 15.0) {
          _isDraggingText = true;
          // widgetState 동기화 (드래그 시작 시)
          _syncWithWidgetState();
        }
      }

      if (_isDraggingText) {
        // 올가미와 동일한 방식: 델타 계산 후 직접 이동
        final delta = details.localPosition - _lastTransformPosition!;
        final adjustedDelta = delta / currentScale;

        // 텍스트 직접 이동
        _moveTextDirectly(adjustedDelta);

        // 다음 계산을 위해 현재 위치 저장
        _lastTransformPosition = details.localPosition;
      }
    }

    /// 텍스트 이동 시작 (ScribbleWidget에서 호출)
    void onTextMoveStart(DragStartDetails details) {
      if (_selectedTextIndex == null) return;

      // 드래그 준비
      _prepareDrag(_selectedTextIndex!, details.localPosition);
    }

    /// 텍스트 이동 종료 (ScribbleWidget에서 호출)
    void onTextMoveEnd(DragEndDetails details) {
      _finishTextDrag();
    }

    /// 스크리블에서 텍스트 데이터 초기화
    void _initializeFromScribble() {
      // 🔧 현재 펜 굵기 기반으로 텍스트 크기 계산
      final currentStrokeWidth =
          modeNotifier.state.inkGroupInfo.seletedStrokeWidth;
      // 더 넓은 범위와 적절한 비율로 조정 (0.5→14, 1.5→18, 2.5→22, 4.0→28, 6.0→36)
      final textSize = (currentStrokeWidth * 4.0 + 12.0).clamp(12.0, 60.0);

      // 성능 최적화: 텍스트 초기화 로그 제거 (매번 호출되어 성능 저하)
      // debugPrint('🔧 텍스트 초기화: 펜 굵기 $currentStrokeWidth → 텍스트 크기 $textSize');

      // 텍스트 설정 초기화
      _textSettings = TextSettings(
        textStyle: TextStyle(
          fontSize: textSize,
          color: modeNotifier.state.inkGroupInfo.selectedColor,
          fontWeight: FontWeight.normal,
        ),
        textAlignment: TextAlignment.center,
      );
      _syncWithWidgetState();
    }

    /// widgetState와 동기화
    void _syncWithWidgetState() {
      widgetState.isEditingText = _isEditingText;
      widgetState.editingTextId = _editingTextId;
      widgetState.isTextTransforming =
          _isDraggingText || _isTransformingText; // 텍스트 변형 상태 동기화

      widgetState.selectedTextDrawable =
          _selectedTextIndex != null &&
              _selectedTextIndex! >= 0 &&
              _selectedTextIndex! < textDrawables.length
          ? textDrawables[_selectedTextIndex!]
          : null;
    }

    /// 새 텍스트 추가 (빈 영역 탭 시)
    bool _addNewTextAt(Offset adjustedPosition, Offset localPosition) {
      // 기존 선택 상태 해제
      if (_selectedTextIndex != null) {
        _selectedTextIndex = null;
        _showTextOverlay = false;
        onTextDeselected();
      }

      // 🔧 새 텍스트 추가 시 현재 펜 굵기로 텍스트 설정 업데이트
      final currentStrokeWidth =
          modeNotifier.state.inkGroupInfo.seletedStrokeWidth;
      // 더 넓은 범위와 적절한 비율로 조정 (0.5→14, 1.5→18, 2.5→22, 4.0→28, 6.0→36)
      final textSize = (currentStrokeWidth * 4.0 + 12.0).clamp(12.0, 60.0);

      debugPrint('🖊️ 텍스트 추가: 펜 굵기 $currentStrokeWidth → 텍스트 크기 $textSize');

      _textSettings = TextSettings(
        textStyle: TextStyle(
          fontSize: textSize,
          color: modeNotifier.state.inkGroupInfo.selectedColor,
          fontWeight: FontWeight.normal,
        ),
        textAlignment: _textSettings.textAlignment,
      );

      // 🔥 scribble-tools 방식: 원본 좌표 직접 사용
      // toScene() 변환 제거하고 로컬 좌표를 그대로 텍스트 위치로 사용
      final textPosition = localPosition;

      // 새 텍스트 생성
      final newTextId = DateTime.now().millisecondsSinceEpoch.toString();
      final newText = TextDrawable(
        id: newTextId,
        text: '',
        x: textPosition.dx,
        y: textPosition.dy,
        fontSize: _textSettings.textStyle.fontSize ?? 20.0,
        color: (_textSettings.textStyle.color ?? Colors.black).toARGB32(),
        fontFamily: _textSettings.textStyle.fontFamily ?? '',
        isBold: _textSettings.textStyle.fontWeight == FontWeight.bold,
        isItalic: _textSettings.textStyle.fontStyle == FontStyle.italic,
        isUnderlined:
            _textSettings.textStyle.decoration == TextDecoration.underline,
        textAlign: _textSettings.textAlignment.name,
        hidden: true, // 편집 중에는 숨김
      );

      // 새 텍스트의 경우 터치한 화면 위치를 직접 사용하여 인라인 에디터 표시
      _showTextEditorAtScreenPosition(newText, localPosition);

      return true; // 이벤트 처리됨
    }

    /// 특정 화면 위치에 인라인 텍스트 에디터 표시 (새 텍스트용)
    void _showTextEditorAtScreenPosition(
      TextDrawable textDrawable,
      Offset localPosition, // 캔버스 좌표계 기준
    ) {
      if (_isEditingText || _textEditorOverlay != null) {
        return; // 이미 편집 중이면 무시
      }

      // 변환 없이 localToGlobal만 적용
      final RenderBox? renderBox =
          repaintBoundaryKey?.currentContext?.findRenderObject() as RenderBox?;
      final editorPosition =
          renderBox?.localToGlobal(localPosition) ?? Offset.zero;

      _isEditingText = true;
      _editingTextId = textDrawable.id;

      // widgetState 동기화
      _syncWithWidgetState();

      _textEditorOverlay = OverlayEntry(
        builder: (context) => InlineTextEditor(
          drawable: textDrawable,
          position: editorPosition,
          textSettings: _textSettings,
          isNew: true,
          scale: 1.0,
          selectedColor: modeNotifier.state.inkGroupInfo.selectedColor,
          onComplete: (updatedDrawable) {
            _hideTextEditor();

            if (updatedDrawable != null && updatedDrawable.text.isNotEmpty) {
              // 새 텍스트 추가
              final finalDrawable = updatedDrawable.copyWithHidden(false);
              scribbleNotifier.addTextDrawable(finalDrawable);

              // 추가된 텍스트를 선택 상태로 설정
              final newIndex = textDrawables.length - 1;
              _selectedTextIndex = newIndex;
              _showTextOverlay = true;

              onTextUpdated(finalDrawable);
            } else {
              // 취소된 경우 또는 빈 텍스트인 경우
            }

            // widgetState 동기화
            _syncWithWidgetState();
            onStateChanged();
          },
        ),
      );

      // 오버레이에 추가
      Overlay.of(context).insert(_textEditorOverlay!);
      onStateChanged();
    }

    /// 인라인 텍스트 에디터 표시 (기존 텍스트용)
    void _showTextEditor(TextDrawable textDrawable) {
      if (_isEditingText || _textEditorOverlay != null) {
        return; // 이미 편집 중이면 무시
      }

      // 변환 없이 localToGlobal만 적용
      final RenderBox? renderBox =
          repaintBoundaryKey?.currentContext?.findRenderObject() as RenderBox?;
      final editorPosition =
          renderBox?.localToGlobal(textDrawable.position) ?? Offset.zero;

      _isEditingText = true;
      _editingTextId = textDrawable.id;

      // widgetState 동기화
      _syncWithWidgetState();

      _textEditorOverlay = OverlayEntry(
        builder: (context) => InlineTextEditor(
          drawable: textDrawable,
          position: editorPosition,
          textSettings: _textSettings,
          isNew: false,
          scale: 1.0, // 이미 화면에 스케일 적용되어 있으므로 확대 X
          selectedColor: modeNotifier.state.inkGroupInfo.selectedColor,
          onComplete: (updatedDrawable) {
            _hideTextEditor();

            if (updatedDrawable != null) {
              // 텍스트가 업데이트되었을 때
              final currentTextDrawables = textDrawables;
              final index = currentTextDrawables.indexWhere(
                (drawable) => drawable.id == updatedDrawable.id,
              );
              final finalDrawable = updatedDrawable.copyWithHidden(false);

              if (index >= 0) {
                // 기존 텍스트 업데이트

                // 편집 완료 후 해당 텍스트를 선택 상태로 유지
                _selectedTextIndex = index;

                // ScribbleNotifier에 텍스트 업데이트
                scribbleNotifier.updateTextDrawable(
                  updatedDrawable.id,
                  finalDrawable,
                );
              } else {
                // 새 텍스트 추가 (인덱스를 찾지 못한 경우)

                // ScribbleNotifier에 텍스트 추가
                scribbleNotifier.addTextDrawable(finalDrawable);

                // 편집 완료 후 해당 텍스트를 선택 상태로 유지
                _selectedTextIndex = textDrawables.length - 1;
              }

              // 바로 변형 모드(오버레이) 활성화
              _showTextOverlay = true;

              // widgetState 동기화
              _syncWithWidgetState();
            } else {
              // 텍스트가 취소되거나 삭제되었을 때

              // ScribbleNotifier에서 텍스트 삭제
              scribbleNotifier.removeTextDrawable(textDrawable.id);
              _selectedTextIndex = null;

              // widgetState 동기화
              _syncWithWidgetState();
            }

            onStateChanged();
          },
        ),
      );

      // 오버레이에 추가
      try {
        Overlay.of(context).insert(_textEditorOverlay!);
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        // 에러 발생 시 상태 초기화
        _isEditingText = false;
        _editingTextId = null;
        if (_textEditorOverlay != null) {
          try {
            _textEditorOverlay!.remove();
          } on Exception catch (removeError, stackTrace) {
            debugPrintStack(stackTrace: stackTrace);
            debugPrint(removeError.toString());
          }
          _textEditorOverlay = null;
        }
      }

      onStateChanged();
    }

    /// 인라인 텍스트 에디터 숨기기
    void _hideTextEditor() {
      if (_textEditorOverlay != null) {
        _textEditorOverlay!.remove();
        _textEditorOverlay = null;
      }

      _isEditingText = false;
      _editingTextId = null;

      // widgetState 동기화
      _syncWithWidgetState();
      onStateChanged();
    }

    /// 지정된 위치에서 텍스트 찾기
    int? _findTextAt(Offset position) {
      for (int i = textDrawables.length - 1; i >= 0; i--) {
        final textDrawable = textDrawables[i];

        if (textDrawable.hidden) {
          continue;
        }

        if (_isPointInTextBounds(position, textDrawable)) {
          return i;
        }
      }

      return null;
    }

    /// 포인트가 텍스트 영역 내에 있는지 확인 (회전 지원)
    bool _isPointInTextBounds(Offset point, TextDrawable textDrawable) {
      // 회전된 텍스트의 경우 점이 회전된 영역 내부에 있는지 확인
      double rotation = 0.0;
      try {
        rotation = textDrawable.rotation;
      } on Exception catch (error, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
        debugPrint(error.toString());
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        rotation = 0.0;
      }

      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (rotation == 0.0) {
        // 회전이 없는 경우 기존 방식
        // TextDrawablePainter와 동일한 방식으로 렌더링 위치 계산
        Offset renderPosition = textDrawable.position;
        switch (textDrawable.alignment) {
          case TextAlignment.center:
            renderPosition = Offset(
              textDrawable.position.dx - textPainter.width / 2,
              textDrawable.position.dy - textPainter.height / 2,
            );
            break;
          case TextAlignment.right:
            renderPosition = Offset(
              textDrawable.position.dx - textPainter.width,
              textDrawable.position.dy - textPainter.height / 2,
            );
            break;
          case TextAlignment.left:
            renderPosition = Offset(
              textDrawable.position.dx,
              textDrawable.position.dy - textPainter.height / 2,
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

        final contains = textRect.contains(point);

        return contains;
      } else {
        // 회전된 텍스트의 경우 역변환을 통해 점이 영역 내부에 있는지 확인
        final center = textDrawable.position;
        final halfWidth = textPainter.width / 2;
        final halfHeight = textPainter.height / 2;

        // 점을 텍스트 중심 기준으로 이동
        final relativePoint = point - center;

        // 역회전 적용 (-rotation)
        final cos = math.cos(-rotation);
        final sin = math.sin(-rotation);
        final rotatedPoint = Offset(
          relativePoint.dx * cos - relativePoint.dy * sin,
          relativePoint.dx * sin + relativePoint.dy * cos,
        );

        // 회전되지 않은 상태에서 영역 내부에 있는지 확인 (8px 패딩 포함)
        final rect = Rect.fromLTWH(
          -halfWidth - 8,
          -halfHeight - 8,
          textPainter.width + 16,
          textPainter.height + 16,
        );

        final contains = rect.contains(rotatedPoint);

        return contains;
      }
    }

    /// 기존 텍스트 탭 처리
    bool _handleExistingTextTap(int textIndex, Offset position) {
      final now = DateTime.now();
      final isDoubleTap = _isDoubleTap(now, position);

      if (isDoubleTap) {
        // 더블탭 - 텍스트 편집 모드

        // 드래그 상태 초기화 (더블탭 시 드래그 방지)
        _isDraggingText = false;
        _draggingTextIndex = null;
        _dragStartPosition = null;
        _textDragOffset = null;

        _editText(textIndex);

        // 더블탭 시에는 탭 히스토리를 초기화하여 연속 탭 방지
        _lastTapTime = null;
        _lastTapPosition = null;
      } else {
        // 단일탭 처리 - 텍스트 선택 및 바로 변형 모드 활성화

        // 새로운 텍스트 선택 또는 이미 선택된 텍스트 재선택
        _selectText(textIndex);

        // 드래그 준비
        _prepareDrag(textIndex, position);

        // 단일탭 시에만 탭 히스토리 업데이트
        _updateTapHistory(now, position);
      }

      return true;
    }

    /// 더블탭 감지
    bool _isDoubleTap(DateTime currentTime, Offset currentPosition) {
      if (_lastTapTime == null || _lastTapPosition == null) {
        return false;
      }

      final timeDiff = currentTime.difference(_lastTapTime!).inMilliseconds;
      final positionDiff = (currentPosition - _lastTapPosition!).distance;

      final isDoubleTap =
          timeDiff < _doubleTapThreshold &&
          positionDiff < _doubleTapPositionThreshold;

      return isDoubleTap;
    }

    /// 탭 히스토리 업데이트
    void _updateTapHistory(DateTime time, Offset position) {
      _lastTapTime = time;
      _lastTapPosition = position;
    }

    /// 텍스트 선택
    void _selectText(int index) {
      if (index < 0 || index >= textDrawables.length) {
        return;
      }

      _selectedTextIndex = index;
      _isEditingText = false;
      _showTextOverlay = true; // 텍스트 선택 시 오버레이 표시

      final selectedText = textDrawables[index];

      // widgetState 동기화
      _syncWithWidgetState();

      onTextSelected(selectedText);
      onStateChanged();
    }

    /// 텍스트 편집
    void _editText(int index) {
      if (index < 0 || index >= textDrawables.length) {
        return;
      }

      final textDrawable = textDrawables[index];

      _showTextEditor(textDrawable);
    }

    /// 드래그 준비
    void _prepareDrag(int textIndex, Offset position) {
      _draggingTextIndex = textIndex;
      _dragStartPosition = position;
      _isDraggingText = false; // 실제 드래그는 임계값 초과 시 시작

      // 🔥 scribble-tools 방식: 원본 좌표 직접 사용
      // toScene() 변환 제거
      final textDrawable = textDrawables[textIndex];
      _textDragOffset = Offset(
        position.dx - textDrawable.position.dx,
        position.dy - textDrawable.position.dy,
      );

      // �� InteractiveViewer 제스처 제어를 위한 상태 변경 로그

      // widgetState 동기화
      _syncWithWidgetState();
      onStateChanged();
    }

    /// 텍스트 위치 업데이트
    void _updateTextPosition(int index, Offset newPosition) {
      if (index < 0 || index >= textDrawables.length) {
        return;
      }

      final updatedText = textDrawables[index].copyWithPosition(newPosition);

      // ScribbleNotifier에 즉시 업데이트 (히스토리 추가 없이)
      scribbleNotifier.updateTextDrawable(updatedText.id, updatedText);

      // widgetState 동기화
      _syncWithWidgetState();

      onTextUpdated(updatedText);
      onStateChanged(); // 실시간 렌더링을 위한 상태 변경 알림
    }

    /// 올가미 방식의 텍스트 직접 이동 (델타 기반)
    void _moveTextDirectly(Offset delta) {
      if (_draggingTextIndex == null) return;

      final currentScribble = scribbleNotifier.currentState.scribble;
      final textDrawables = List<TextDrawable>.from(
        currentScribble.textDrawables,
      );

      if (_draggingTextIndex! >= 0 &&
          _draggingTextIndex! < textDrawables.length) {
        final textDrawable = textDrawables[_draggingTextIndex!];
        final oldPosition = textDrawable.position;
        final newPosition = Offset(
          oldPosition.dx + delta.dx,
          oldPosition.dy + delta.dy,
        );

        // 새 위치로 텍스트 업데이트
        final updatedText = textDrawable.copyWithPosition(newPosition);
        textDrawables[_draggingTextIndex!] = updatedText;

        // 스크리블 즉시 업데이트 (히스토리 추가 없이)
        final updatedScribble = Scribble(
          strokes: currentScribble.strokes,
          width: currentScribble.width,
          height: currentScribble.height,
          x: currentScribble.x,
          y: currentScribble.y,
          textDrawables: textDrawables,
          createdAt: currentScribble.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          version: currentScribble.version,
        );

        scribbleNotifier.setScribble(
          scribble: updatedScribble,
          addToUndoHistory: false, // 드래그 중에는 히스토리 추가 안함
        );

        // widgetState 동기화
        _syncWithWidgetState();
        onStateChanged(); // 실시간 렌더링
      }
    }

    /// 텍스트 드래그 완료 처리
    void _finishTextDrag() {
      if (_isDraggingText && _draggingTextIndex != null) {
        // 최종 변경사항을 히스토리에 저장
        final currentScribble = scribbleNotifier.currentState.scribble;
        scribbleNotifier.setScribble(
          scribble: currentScribble,
          addToUndoHistory: true, // 드래그 완료 시 히스토리 저장
        );
      }

      // 🔥 InteractiveViewer 제스처 제어를 위한 상태 변경 로그

      // 드래그 상태 초기화
      _isDraggingText = false;
      _draggingTextIndex = null;
      _dragStartPosition = null;
      _lastTransformPosition = null;
      _textDragOffset = null;

      // widgetState 동기화
      _syncWithWidgetState();
      onStateChanged();
    }

    /// 컨트롤 영역 터치 처리 메서드 (회전된 텍스트 지원)
    bool? _handleControlAreaTouch(Offset position, TextDrawable textDrawable) {
      const buttonSize = 50.0; // 더 크게 설정 // TextDrawablePainter와 동일한 크기
      const buttonRadius = buttonSize / 2;

      final scale = currentScale;
      final scaledButtonRadius = buttonRadius / scale;
      final adjustedPosition = position;

      // 회전된 텍스트의 정확한 버튼 위치 계산
      final buttonPositions = _getRotatedButtonPositions(textDrawable);

      // 삭제 버튼 터치 (원형 영역)
      final deleteButtonDistance =
          (adjustedPosition - buttonPositions['delete']!).distance;
      if (deleteButtonDistance <= scaledButtonRadius) {
        deleteSelectedText();
        return true; // 이벤트 처리 완료
      }

      // 변형 버튼 터치 (원형 영역) - 크기조정 모드 시작
      final transformButtonDistance =
          (adjustedPosition - buttonPositions['transform']!).distance;
      if (transformButtonDistance <= scaledButtonRadius) {
        _isTextResizing = true;
        onStateChanged();
        return true; // 이벤트 처리 완료 (텍스트 드래그 방지)
      }

      return null; // 컨트롤 영역이 아님
    }

    /// 회전된 텍스트의 정확한 버튼 위치 계산 (TextDrawablePainter와 동일한 로직)
    Map<String, Offset> _getRotatedButtonPositions(TextDrawable textDrawable) {
      // TextPainter로 텍스트 크기 계산
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final center = textDrawable.position;
      final halfWidth = textPainter.width / 2;
      final halfHeight = textPainter.height / 2;

      double rotation = 0.0;
      try {
        rotation = textDrawable.rotation;
      } on Exception {
        // rotation 필드가 없거나 접근할 수 없는 경우 기본값 사용
        rotation = 0.0;
      }

      if (rotation == 0.0) {
        // 회전이 없는 경우 기존 방식
        final rect = Rect.fromLTWH(
          center.dx - halfWidth - 4,
          center.dy - halfHeight - 4,
          textPainter.width + 8,
          textPainter.height + 8,
        );
        return {
          'delete': Offset(rect.right, rect.top),
          'transform': Offset(rect.left, rect.bottom),
        };
      }

      // 회전된 텍스트의 네 모서리 계산 (패딩 포함)
      final corners = [
        Offset(-halfWidth - 4, -halfHeight - 4), // 좌상단
        Offset(halfWidth + 4, -halfHeight - 4), // 우상단
        Offset(halfWidth + 4, halfHeight + 4), // 우하단
        Offset(-halfWidth - 4, halfHeight + 4), // 좌하단
      ];

      // 회전 변환 적용
      final cos = math.cos(rotation);
      final sin = math.sin(rotation);

      final rotatedCorners = corners.map((corner) {
        return Offset(
          center.dx + corner.dx * cos - corner.dy * sin,
          center.dy + corner.dx * sin + corner.dy * cos,
        );
      }).toList();

      return {
        'delete': rotatedCorners[1], // 우상단
        'transform': rotatedCorners[3], // 좌하단
      };
    }

    /// 텍스트 바운딩 박스 계산 (TextDrawablePainter.getTextBounds와 동일)
    Rect _getTextBounds(TextDrawable textDrawable) {
      final textSpan = TextSpan(
        text: textDrawable.text,
        style: textDrawable.style,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: textDrawable.alignment.textAlign,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 텍스트 정렬에 따른 렌더링 위치 계산
      Offset renderPosition = textDrawable.position;
      switch (textDrawable.alignment) {
        case TextAlignment.center:
          renderPosition = Offset(
            textDrawable.position.dx - textPainter.width / 2,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case TextAlignment.right:
          renderPosition = Offset(
            textDrawable.position.dx - textPainter.width,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
        case TextAlignment.left:
          renderPosition = Offset(
            textDrawable.position.dx,
            textDrawable.position.dy - textPainter.height / 2,
          );
          break;
      }

      return Rect.fromLTWH(
        renderPosition.dx,
        renderPosition.dy,
        textPainter.width,
        textPainter.height,
      );
    }
  }
