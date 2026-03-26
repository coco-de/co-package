import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble_painter.dart' as painter;
import 'package:open_board/src/module/state/text_settings.dart';

/// ScribbleWidget의 상태를 관리하는 클래스
class ScribbleWidgetState {
  // InteractiveViewer 관련 상태
  bool isBlockVerticalDrag = false;
  bool isReachedTopBoundary = false;
  bool isReachedBottomBoundary = false;
  bool isZoomedIn = false;

  // 올가미 선택 관련 상태
  painter.LassoSelectionState lassoSelectionState =
      painter.LassoSelectionState();
  painter.HandlePosition activeHandle = painter.HandlePosition.none;
  List<int> selectedStrokeIds = [];
  List<int> cachedSelectedStrokeIds = [];
  bool showLassoOverlay = false;
  bool isLassoTransforming = false;
  DateTime? lastLassoTapDownTime;
  bool lassoTapMoved = false;

  // 드래그 관련 상태
  Offset? dragStartPosition;
  Offset? lastTransformPosition;

  // 크기조절/회전 관련 상태
  List<List<Offset>>? originalStrokePoints;
  painter.OrientedBoundingBox? originalOrientedBoundingBox;
  Offset? startTouchPoint;
  double? originalDistance;
  double? originalAngle;

  // 텍스트 관련 상태
  TextDrawable? selectedTextDrawable;
  bool isEditingText = false;
  String? editingTextId;
  OverlayEntry? textEditorOverlay;
  late TextSettings textSettings;

  // 텍스트 변형 관련 상태
  bool isTextTransforming = false;
  bool isTextResizing = false;
  String? activeTextHandle;
  Offset? textDragStartPosition;
  Offset? textOriginalPosition;
  double? originalFontSize;
  Offset? textTapStartPosition;
  DateTime? lastTextTapTime;
  TextDrawable? lastTappedText;

  // 타이머
  Timer? lassoSelectionTimer;

  // 상수
  static const double dragThreshold = 10.0;

  /// 올가미 상태 초기화
  void resetLassoState() {
    selectedStrokeIds.clear();
    cachedSelectedStrokeIds.clear();
    lassoSelectionState = painter.LassoSelectionState();
    activeHandle = painter.HandlePosition.none;
    showLassoOverlay = false;
    isLassoTransforming = false;
    lastLassoTapDownTime = null;
    lassoTapMoved = false;
  }

  /// 텍스트 상태 초기화
  void resetTextState() {
    selectedTextDrawable = null;
    isEditingText = false;
    editingTextId = null;
    isTextTransforming = false;
    isTextResizing = false;
    activeTextHandle = null;
    textDragStartPosition = null;
    textOriginalPosition = null;
    originalFontSize = null;
    textTapStartPosition = null;
    lastTextTapTime = null;
    lastTappedText = null;
  }

  /// 변형 상태 초기화
  void resetTransformState() {
    originalStrokePoints = null;
    originalOrientedBoundingBox = null;
    startTouchPoint = null;
    originalDistance = null;
    originalAngle = null;
    dragStartPosition = null;
    lastTransformPosition = null;
  }

  /// 모든 상태 초기화
  void resetAll() {
    resetLassoState();
    resetTextState();
    resetTransformState();
  }

  /// 리소스 정리
  void dispose() {
    lassoSelectionTimer?.cancel();
    textEditorOverlay?.remove();
    textEditorOverlay = null;
    resetAll();
  }

  /// 현재 선택된 요소가 있는지 확인
  bool get hasSelection =>
      selectedStrokeIds.isNotEmpty || selectedTextDrawable != null;

  /// 변형 중인지 확인
  bool get isTransforming =>
      isLassoTransforming || isTextTransforming || isTextResizing;

  /// 편집 중인지 확인
  bool get isEditing => isEditingText;
}
