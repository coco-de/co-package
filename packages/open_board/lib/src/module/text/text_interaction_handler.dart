import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/text/text_painter.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/coordinate_transformer.dart';

/// 텍스트 상호작용을 처리하는 핸들러 클래스
class TextInteractionHandler {
  final ScribbleNotifier scribbleNotifier;
  final ScribbleModeNotifier modeNotifier;
  final BuildContext context;
  final VoidCallback onStateChanged;
  final TransformationController? transformationController;

  // 텍스트 관련 상태
  final List<TextDrawable> _textDrawables = [];
  TextDrawable? _selectedTextDrawable;
  late TextSettings _textSettings;

  // 더블 탭 감지용 변수
  DateTime? _lastTextTapTime;
  TextDrawable? _lastTappedText;
  Offset? _textTapStartPosition;
  static const double _dragThreshold = 10.0;

  // 텍스트 드래그 및 변형 관련 변수
  bool _isTextTransforming = false;
  Offset? _textDragStartPosition;
  Offset? _textOriginalPosition;
  bool _isTextResizing = false;
  String? _activeTextHandle;
  double? _originalFontSize;

  // 인라인 텍스트 에디터 관련 변수
  OverlayEntry? _textEditorOverlay;
  bool _isEditingText = false;
  String? _editingTextId;

  TextInteractionHandler({
    required this.scribbleNotifier,
    required this.modeNotifier,
    required this.context,
    required this.onStateChanged,
    this.transformationController,
  }) {
    _updateTextSettings();
    _loadTextDrawablesFromNotifier();
  }

  // Getters
  List<TextDrawable> get textDrawables => List.unmodifiable(_textDrawables);
  TextDrawable? get selectedTextDrawable => _selectedTextDrawable;
  bool get isEditingText => _isEditingText;
  String? get editingTextId => _editingTextId;
  bool get isTextTransforming => _isTextTransforming;
  bool get isTextResizing => _isTextResizing;

  CoordinateTransformer get _transformer =>
      CoordinateTransformer(transformationController);

  double get currentScale => _transformer.scale;

  /// 텍스트 설정 업데이트 (현재 선택된 색상과 크기 반영)
  void _updateTextSettings() {
    final currentColor = modeNotifier.state.inkGroupInfo.selectedColor;
    final currentStrokeWidth =
        modeNotifier.state.inkGroupInfo.seletedStrokeWidth;

    // 🔧 펜 굵기 기반 텍스트 크기 계산 (TextInteractionManager와 동일한 공식)
    final textSize = (currentStrokeWidth * 4.0 + 12.0).clamp(12.0, 60.0);

    _textSettings = TextSettings(
      textStyle: TextStyle(
        fontSize: textSize,
        color: currentColor,
        fontWeight: FontWeight.normal,
      ),
      textAlignment: TextAlignment.center,
    );
  }

  /// 텍스트 모드 처리
  void handleTextMode(Offset position) {
    // 스케일 조정된 위치 계산 (다른 모드와 일관성 유지)
    final adjustedPosition = _transformer.screenToCanvas(position);

    // 기존 텍스트 클릭 체크
    for (final textDrawable in _textDrawables) {
      if (TextDrawablePainter.isPointInText(textDrawable, adjustedPosition)) {
        _textTapStartPosition = adjustedPosition;
        selectText(textDrawable);
        return;
      }
    }

    // 기존 텍스트를 클릭하지 않은 경우 선택 해제
    if (_selectedTextDrawable != null) {
      _selectedTextDrawable = null;
      _lastTextTapTime = null;
      _lastTappedText = null;
      _textTapStartPosition = null; // 상태 정리
      onStateChanged();
      return;
    }

    // 새 텍스트 추가
    _addNewText(adjustedPosition);
  }

  /// 텍스트 선택 (더블 탭 감지 포함)
  void selectText(TextDrawable textDrawable) {
    final now = DateTime.now();

    // 더블 탭 감지 (500ms 이내에 같은 텍스트를 다시 탭한 경우)
    if (_lastTextTapTime != null &&
        _lastTappedText?.id == textDrawable.id &&
        now.difference(_lastTextTapTime!).inMilliseconds < 500) {
      // 더블 탭 - 편집 모드로 전환
      _editText(textDrawable);
      _lastTextTapTime = null;
      _lastTappedText = null;
      return;
    }

    // 첫 번째 탭 - 선택 상태로 설정
    _selectedTextDrawable = textDrawable;

    // 더블 탭 감지를 위한 시간 기록
    _lastTextTapTime = now;
    _lastTappedText = textDrawable;

    onStateChanged();
  }

  /// 새 텍스트 추가
  void _addNewText(Offset adjustedPosition) {
    final newText = TextDrawableFactory.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      position: adjustedPosition,
      style: _textSettings.textStyle,
      alignment: _textSettings.textAlignment,
      hidden: true, // 편집 중에는 숨김
    );

    // scene 좌표를 화면 좌표로 변환하여 에디터 표시
    _showTextEditorAtScenePosition(newText, adjustedPosition);
  }

  /// 텍스트 편집
  void _editText(TextDrawable textDrawable) {
    _selectedTextDrawable = textDrawable;
    _showTextEditor(textDrawable);
  }

  /// scene 좌표에서 인라인 텍스트 에디터 표시 (새 텍스트용)
  void _showTextEditorAtScenePosition(
    TextDrawable textDrawable,
    Offset scenePosition,
  ) {
    if (_isEditingText || _textEditorOverlay != null) {
      return; // 이미 편집 중이면 무시
    }

    // scene 좌표를 local 좌표로 변환
    final localPosition = _transformer.canvasToLocal(scenePosition);

    // local 좌표를 화면 좌표로 변환
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final screenPosition =
        renderBox?.localToGlobal(localPosition) ?? localPosition;

    _isEditingText = true;
    _selectedTextDrawable = textDrawable;
    _editingTextId = textDrawable.id;

    _textEditorOverlay = OverlayEntry(
      builder: (context) => InlineTextEditor(
        drawable: textDrawable,
        position: screenPosition,
        textSettings: _textSettings,
        isNew: true,
        scale: currentScale,
        selectedColor: modeNotifier.state.inkGroupInfo.selectedColor,
        onComplete: (updatedDrawable) {
          _hideTextEditor();

          if (updatedDrawable != null) {
            // 새 텍스트 추가
            final finalDrawable = updatedDrawable.copyWithHidden(false);
            _textDrawables.add(finalDrawable);
            // ScribbleNotifier에 텍스트 추가
            scribbleNotifier.addTextDrawable(finalDrawable);
            // 편집 완료 후 해당 텍스트를 선택 상태로 유지
            _selectedTextDrawable = finalDrawable;
          } else {
            // 취소된 경우 선택 해제
            _selectedTextDrawable = null;
          }

          onStateChanged();
          _editingTextId = null;
        },
      ),
    );

    // 오버레이에 추가
    Overlay.of(context).insert(_textEditorOverlay!);
    onStateChanged();
  }

  /// 인라인 텍스트 에디터 표시
  void _showTextEditor(TextDrawable textDrawable) {
    if (_isEditingText || _textEditorOverlay != null) {
      return; // 이미 편집 중이면 무시
    }

    // scene 좌표를 local 좌표로 변환 후 화면 좌표로 변환
    final scenePosition = textDrawable.position;
    final localPosition = _transformer.canvasToLocal(scenePosition);

    // local 좌표를 화면 좌표로 변환
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final editorPosition =
        renderBox?.localToGlobal(localPosition) ?? localPosition;

    _isEditingText = true;
    _editingTextId = textDrawable.id;

    _textEditorOverlay = OverlayEntry(
      builder: (context) => InlineTextEditor(
        drawable: textDrawable,
        position: editorPosition,
        textSettings: _textSettings,
        isNew: !_textDrawables.contains(textDrawable),
        scale: currentScale,
        selectedColor: modeNotifier.state.inkGroupInfo.selectedColor,
        onComplete: (updatedDrawable) {
          _hideTextEditor();

          if (updatedDrawable != null) {
            // 텍스트가 업데이트되었을 때
            final index = _textDrawables.indexWhere(
              (drawable) => drawable.id == updatedDrawable.id,
            );
            final finalDrawable = updatedDrawable.copyWithHidden(false);

            if (index >= 0) {
              // 기존 텍스트 업데이트
              _textDrawables[index] = finalDrawable;
              // ScribbleNotifier에 텍스트 업데이트
              scribbleNotifier.updateTextDrawable(
                updatedDrawable.id,
                finalDrawable,
              );
            } else {
              // 새 텍스트 추가
              _textDrawables.add(finalDrawable);
              // ScribbleNotifier에 텍스트 추가
              scribbleNotifier.addTextDrawable(finalDrawable);
            }
            // 편집 완료 후 해당 텍스트를 선택 상태로 유지
            _selectedTextDrawable = finalDrawable;
          } else {
            // 텍스트가 취소되거나 삭제되었을 때
            _textDrawables.removeWhere(
              (drawable) => drawable.id == textDrawable.id,
            );
            // ScribbleNotifier에서 텍스트 삭제
            scribbleNotifier.removeTextDrawable(textDrawable.id);
            _selectedTextDrawable = null;
          }

          onStateChanged();
          _editingTextId = null;
        },
      ),
    );

    // 오버레이에 추가
    Overlay.of(context).insert(_textEditorOverlay!);
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

    onStateChanged();
  }

  /// 포인터 다운 이벤트 처리 (텍스트 관련)
  bool handlePointerDown(PointerDownEvent event) {
    // 텍스트 편집 중이면 이벤트 무시
    if (_isEditingText) {
      return true; // 이벤트 처리됨
    }

    // 텍스트 모드 처리
    if (modeNotifier.state.inkGroupInfo.selectedInk == InkModes.text) {
      handleTextMode(event.localPosition);
      return true; // 이벤트 처리됨
    }

    // 다른 모드에서도 텍스트 터치 감지
    return _handleTextTouchInOtherModes(event);
  }

  /// 다른 모드에서 텍스트 터치 처리
  bool _handleTextTouchInOtherModes(PointerDownEvent event) {
    // 스케일 조정된 위치 계산
    final adjustedPosition = _transformer.screenToCanvas(event.localPosition);

    // 선택된 텍스트가 있는 경우 변형 처리
    if (_selectedTextDrawable != null) {
      // 핸들 영역을 먼저 확인
      final handleType = TextDrawablePainter.getHandleType(
        _selectedTextDrawable!,
        adjustedPosition,
      );
      if (handleType != null) {
        // 핸들 드래그 시작 (크기 조절)
        _isTextResizing = true;
        _activeTextHandle = handleType;
        _textDragStartPosition = adjustedPosition;
        _originalFontSize = _selectedTextDrawable!.style.fontSize ?? 14.0;
        onStateChanged();
        return true;
      }
      // 선택된 텍스트 영역 내에서 터치했는지 확인
      else if (TextDrawablePainter.isPointInText(
        _selectedTextDrawable!,
        adjustedPosition,
      )) {
        // 터치 시작 위치 기록 (드래그 vs 더블탭 감지용)
        _textTapStartPosition = adjustedPosition;
        return true;
      } else {
        // 다른 텍스트를 터치했는지 확인
        for (final textDrawable in _textDrawables) {
          if (textDrawable.hidden) continue;
          if (TextDrawablePainter.isPointInText(
            textDrawable,
            adjustedPosition,
          )) {
            // 다른 텍스트 선택
            selectText(textDrawable);
            return true;
          }
        }

        // 텍스트 영역 밖을 터치하면 선택 해제 (그리기 모드에서만)
        final currentMode = modeNotifier.state.inkGroupInfo.selectedInk;
        if (currentMode == InkModes.pen ||
            currentMode == InkModes.pencil ||
            currentMode == InkModes.marker ||
            currentMode == InkModes.shape ||
            currentMode == InkModes.erase ||
            currentMode == InkModes.lasso) {
          _selectedTextDrawable = null;
          _lastTextTapTime = null;
          _lastTappedText = null;
          onStateChanged();
        }
      }
    } else {
      // 선택된 텍스트가 없는 경우 텍스트 터치 감지
      for (final textDrawable in _textDrawables) {
        if (textDrawable.hidden) continue;
        if (TextDrawablePainter.isPointInText(textDrawable, adjustedPosition)) {
          // 텍스트 선택
          selectText(textDrawable);
          return true;
        }
      }
    }

    return false; // 텍스트 관련 이벤트가 아님
  }

  /// 포인터 무브 이벤트 처리 (텍스트 관련)
  bool handlePointerMove(PointerMoveEvent event) {
    // 텍스트 터치 시작 위치가 있고 아직 드래그 모드가 아닌 경우 드래그 감지
    if (_textTapStartPosition != null &&
        !_isTextTransforming &&
        !_isTextResizing &&
        _selectedTextDrawable != null) {
      // 스케일 조정된 위치 계산
      final adjustedPosition = _transformer.screenToCanvas(event.localPosition);

      // 드래그 거리 확인
      final dragDistance = (adjustedPosition - _textTapStartPosition!).distance;

      if (dragDistance > _dragThreshold) {
        // 드래그 임계값을 넘으면 더블탭 취소하고 드래그 모드 시작
        _lastTextTapTime = null;
        _lastTappedText = null;

        _isTextTransforming = true;
        _textDragStartPosition = _textTapStartPosition;
        _textOriginalPosition = _selectedTextDrawable!.position;

        _textTapStartPosition = null;
        onStateChanged();
      }
    }

    // 텍스트 크기 조절 처리
    if (_isTextResizing &&
        _textDragStartPosition != null &&
        _selectedTextDrawable != null &&
        _originalFontSize != null) {
      _handleTextResize(event);
      return true;
    }
    // 텍스트 드래그 처리
    else if (_isTextTransforming &&
        _textDragStartPosition != null &&
        _selectedTextDrawable != null) {
      _handleTextDrag(event);
      return true;
    }

    return false; // 텍스트 관련 이벤트가 아님
  }

  /// 텍스트 크기 조절 처리
  void _handleTextResize(PointerMoveEvent event) {
    // 스케일 조정된 위치 계산
    final adjustedPosition = _transformer.screenToCanvas(event.localPosition);

    // 드래그 거리를 기반으로 폰트 크기 계산
    final delta = adjustedPosition - _textDragStartPosition!;
    final distance = delta.distance;
    final direction =
        _activeTextHandle == 'bottomRight' || _activeTextHandle == 'topRight'
        ? 1
        : -1;

    // 크기 변화 계산 (거리에 따라 폰트 크기 조절)
    final sizeChange = (distance * direction * 0.1).clamp(
      -_originalFontSize! * 0.8,
      _originalFontSize! * 3,
    );
    final newFontSize = (_originalFontSize! + sizeChange).clamp(8.0, 72.0);

    // 텍스트 스타일 업데이트
    final updatedStyle = _selectedTextDrawable!.style.copyWith(
      fontSize: newFontSize,
    );
    final updatedText = _selectedTextDrawable!.copyWithStyle(updatedStyle);

    // 텍스트 목록에서 해당 텍스트 업데이트
    final index = _textDrawables.indexWhere(
      (drawable) => drawable.id == _selectedTextDrawable!.id,
    );
    if (index >= 0) {
      _textDrawables[index] = updatedText;
      _selectedTextDrawable = updatedText;
      onStateChanged();
    }
  }

  /// 텍스트 드래그 처리
  void _handleTextDrag(PointerMoveEvent event) {
    // 스케일 조정된 위치 계산
    final adjustedPosition = _transformer.screenToCanvas(event.localPosition);

    // 드래그 거리 계산
    final delta = adjustedPosition - _textDragStartPosition!;
    final newPosition = _textOriginalPosition! + delta;

    // 텍스트 위치 업데이트
    final updatedText = _selectedTextDrawable!.copyWithPosition(newPosition);

    // 텍스트 목록에서 해당 텍스트 업데이트
    final index = _textDrawables.indexWhere(
      (drawable) => drawable.id == _selectedTextDrawable!.id,
    );
    if (index >= 0) {
      _textDrawables[index] = updatedText;
      _selectedTextDrawable = updatedText;
      onStateChanged();
    }
  }

  /// 포인터 업 이벤트 처리 (텍스트 관련)
  bool handlePointerUp(PointerUpEvent event) {
    if (_textTapStartPosition != null &&
        !_isTextTransforming &&
        !_isTextResizing) {
      // 드래그 없는 단순 탭
      if (_selectedTextDrawable != null) {
        // 이미 선택된 텍스트를 다시 클릭한 경우는 이미 _handleTextPointerDown에서 처리됨
      } else {
        // 빈 영역 탭 - 새 텍스트 생성
        _addNewText(_textTapStartPosition!);
      }
    }

    if (_isTextResizing) {
      _isTextResizing = false;
      _activeTextHandle = null;
      _textDragStartPosition = null;
      _originalFontSize = null;
      onStateChanged();
    }

    if (_isTextTransforming) {
      _isTextTransforming = false;
      _textDragStartPosition = null;
      _textOriginalPosition = null;
      onStateChanged();
    }

    _textTapStartPosition = null;
    return false; // 텍스트 관련 이벤트가 아님
  }

  /// ScribbleNotifier에서 기존 텍스트 불러오기
  void _loadTextDrawablesFromNotifier() {
    final existingTextDrawables = scribbleNotifier.getCurrentTextDrawables();
    _textDrawables.clear();
    _textDrawables.addAll(existingTextDrawables);
  }

  /// 리소스 정리
  void dispose() {
    // 인라인 텍스트 에디터 정리
    if (_textEditorOverlay != null) {
      _textEditorOverlay!.remove();
      _textEditorOverlay = null;
    }
    _isEditingText = false;
    _editingTextId = null;
  }
}
