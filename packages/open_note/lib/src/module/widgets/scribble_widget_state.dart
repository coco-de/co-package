import 'dart:async';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/scribble_painter.dart' as painter;
import 'package:open_note/src/module/state/text_settings.dart';

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

  // 🖼️ 이미지 관련 상태
  String? _selectedImageId;
  String? get selectedImageId => _selectedImageId;
  set selectedImageId(String? id) {
    if (id == _selectedImageId) return;
    _selectedImageId = id;
    onSelectedImageChanged?.call(id);
  }

  /// open_note: 선택한 이미지가 바뀔 때 (이미지 스타일 패널 등 위젯 밖 도구용).
  ValueChanged<String?>? onSelectedImageChanged;
  bool isImageTransforming = false;
  bool isImageResizing = false;

  // 타이머
  Timer? lassoSelectionTimer;

  /// 변형 중인지 확인
  bool get isTransforming =>
      isLassoTransforming ||
      isTextTransforming ||
      isTextResizing ||
      isImageTransforming ||
      isImageResizing;

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

  /// 이미지 상태 초기화
  void resetImageState() {
    selectedImageId = null;
    isImageTransforming = false;
    isImageResizing = false;
  }

  /// 변형 상태 초기화
  void resetTransformState() {
    // Transform state is managed by LassoSelectionManager and TextInteractionManager
  }

  /// 모든 상태 초기화
  void resetAll() {
    resetLassoState();
    resetTextState();
    resetImageState();
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
