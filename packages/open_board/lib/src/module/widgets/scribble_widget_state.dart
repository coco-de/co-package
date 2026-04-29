import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble_painter.dart' as painter;
import 'package:open_board/src/module/state/text_settings.dart';

/// ScribbleWidget의 상태를 관리하는 클래스
class ScribbleWidgetState {
  // 올가미 선택 관련 상태
  painter.LassoSelectionState lassoSelectionState =
      painter.LassoSelectionState();
  painter.HandlePosition activeHandle = painter.HandlePosition.none;
  List<int> selectedStrokeIds = [];
  bool showLassoOverlay = false;
  bool isLassoTransforming = false;

  // 텍스트 관련 상태
  TextDrawable? selectedTextDrawable;
  bool isEditingText = false;
  String? editingTextId;
  OverlayEntry? textEditorOverlay;

  // 텍스트 설정
  TextSettings? textSettings;

  // 텍스트 변형 관련 상태
  bool isTextTransforming = false;
  bool isTextResizing = false;

  // 타이머
  Timer? lassoSelectionTimer;

  /// 변형 중인지 확인
  bool get isTransforming =>
      isLassoTransforming || isTextTransforming || isTextResizing;

  /// 올가미 상태 초기화
  void resetLassoState() {
    selectedStrokeIds.clear();
    lassoSelectionState = painter.LassoSelectionState();
    activeHandle = painter.HandlePosition.none;
    showLassoOverlay = false;
    isLassoTransforming = false;
  }

  /// 텍스트 상태 초기화
  void resetTextState() {
    selectedTextDrawable = null;
    isEditingText = false;
    editingTextId = null;
    isTextTransforming = false;
    isTextResizing = false;
  }

  /// 변형 상태 초기화
  void resetTransformState() {
    // Transform state is managed by LassoSelectionManager and TextInteractionManager
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
}
