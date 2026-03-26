import 'package:flutter/material.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DrawingPointerMode { mouseOnly, penOnly }

enum DrawingTool { pen, pencil, marker, erase, highlighter, text, shape, lasso }

/// 🌍 전역 필기 도구 상태 관리 (싱글톤)
///
/// 모든 ScribbleWidget에서 공유되는 전역 상태를 관리합니다.
/// 양면보기 등에서 여러 필기 위젯이 있어도 일관된 상태를 유지합니다.
class DrawingState {
  static DrawingState? _instance;

  factory DrawingState() {
    if (_instance == null || _instance!._isDisposed) {
      // 🔄 인스턴스가 없거나 dispose된 경우 새로 생성
      _instance = DrawingState._internal();
    }
    return _instance!;
  }

  DrawingState._internal() {
    _initializeNotifiers();
    _setupAutoSave();
  }

  // 🎨 전역 상태 변수들 (재초기화 가능)
  late ValueNotifier<DrawingPointerMode> pointerMode;
  late ValueNotifier<DrawingTool> selectedTool;
  late ValueNotifier<Color> selectedColor;
  late ValueNotifier<double> selectedThickness;
  late ValueNotifier<bool> showColorPicker;

  // 🎨 4개의 색상 슬롯 (즐겨찾기) - ValueNotifier로 감싸서 UI 반응형으로
  late ValueNotifier<List<Color>> colorSlots;

  // 🎯 모든 활성 modeNotifier들을 추적
  final Set<ScribbleModeNotifier> _activeNotifiers = <ScribbleModeNotifier>{};

  // 🎯 모든 활성 scribbleNotifier들을 추적 (undo/redo용)
  final Set<ScribbleNotifier> _activeScribbleNotifiers = <ScribbleNotifier>{};

  // 🎯 마지막으로 필기한 ScribbleNotifier (undo/redo 대상)
  ScribbleNotifier? _lastActiveScribbleNotifier;

  // 🎯 활성 ScribbleNotifier 변경 알림용 ValueNotifier (재초기화 가능)
  late ValueNotifier<ScribbleNotifier?> _activeScribbleNotifierNotifier;

  // 🎯 Undo/Redo 가능 여부 실시간 추적용 ValueNotifier (재초기화 가능)
  late ValueNotifier<bool> _canUndoNotifier;
  late ValueNotifier<bool> _canRedoNotifier;

  // 🔗 외부 설정 저장/복원 콜백들
  Future<void> Function()? onSave;
  Future<void> Function()? onLoad;

  // 🔗 SharedPreferences 키 상수들
  static const String _keyPointerMode = 'drawing_pointer_mode';
  static const String _keySelectedTool = 'drawing_selected_tool';
  static const String _keySelectedColor = 'drawing_selected_color';
  static const String _keySelectedThickness = 'drawing_selected_thickness';
  static const String _keyColorSlots = 'drawing_color_slots'; // 🎨 색상 슬롯 저장 키

  // 🔗 설정 저장/복원 활성화 플래그
  bool _persistenceEnabled = false;

  // ✨ dispose 상태 추적 (위젯 생명주기 오류 방지)
  bool _isDisposed = false;

  /// 등록된 notifier 수 확인
  int get activeNotifierCount => _activeNotifiers.length;

  /// 등록된 scribbleNotifier 수 확인
  int get activeScribbleNotifierCount => _activeScribbleNotifiers.length;

  /// 현재 활성 ScribbleNotifier (undo/redo 대상)
  ScribbleNotifier? get lastActiveScribbleNotifier =>
      _lastActiveScribbleNotifier;

  /// 🛡️ dispose 여부 확인
  bool get isDisposed => _isDisposed;

  /// 활성 ScribbleNotifier 변경 알림 ValueNotifier
  ValueNotifier<ScribbleNotifier?> get activeScribbleNotifierNotifier =>
      _activeScribbleNotifierNotifier;

  /// Undo/Redo 가능 여부 실시간 추적 ValueNotifier
  ValueNotifier<bool> get canUndoNotifier => _canUndoNotifier;
  ValueNotifier<bool> get canRedoNotifier => _canRedoNotifier;

  /// 🔄 ValueNotifier들 초기화 (재사용 시 필요)
  void _initializeNotifiers() {
    _isDisposed = false;

    // 🎨 기본 상태 ValueNotifier들 초기화
    pointerMode = ValueNotifier(DrawingPointerMode.penOnly);
    selectedTool = ValueNotifier(DrawingTool.pencil);
    selectedColor = ValueNotifier(Colors.black);
    selectedThickness = ValueNotifier(2.0);
    showColorPicker = ValueNotifier(false);

    // 🎨 색상 슬롯 기본값 초기화
    colorSlots = ValueNotifier([
      Colors.black,
      const Color(0xFFFE4429), // 빨강
      const Color(0xFF218BFF), // 파랑
      const Color(0xFFFCE14B), // 노랑
    ]);

    // 🎯 활성 ScribbleNotifier 관리 ValueNotifier들 초기화
    _activeScribbleNotifierNotifier = ValueNotifier<ScribbleNotifier?>(null);
    _canUndoNotifier = ValueNotifier<bool>(false);
    _canRedoNotifier = ValueNotifier<bool>(false);

    // 🧹 컨렉션들 초기화
    _activeNotifiers.clear();
    _activeScribbleNotifiers.clear();
    _undoRedoUpdateCallbacks.clear();
    _lastActiveScribbleNotifier = null;
  }

  /// 🔄 상태 초기화 (필요한 경우)
  void reset() {
    pointerMode.value = DrawingPointerMode.penOnly;
    selectedTool.value = DrawingTool.pencil;
    selectedColor.value = Colors.black;
    selectedThickness.value = 2.0;
    showColorPicker.value = false;

    // 모든 활성 notifier에 적용
    _syncToAllNotifiers();
  }

  /// 📝 ScribbleModeNotifier 등록 (ScribbleWidget에서 자동 호출)
  void registerNotifier(ScribbleModeNotifier modeNotifier) {
    _activeNotifiers.add(modeNotifier);
    // 등록 즉시 현재 전역 상태 적용
    applyToModeNotifier(modeNotifier);
  }

  /// 📝 ScribbleModeNotifier 해제 (ScribbleWidget dispose 시 자동 호출)
  void unregisterNotifier(ScribbleModeNotifier modeNotifier) {
    _activeNotifiers.remove(modeNotifier);
  }

  /// 📝 ScribbleNotifier 등록 (ScribbleWidget에서 자동 호출)
  void registerScribbleNotifier(ScribbleNotifier scribbleNotifier) {
    _activeScribbleNotifiers.add(scribbleNotifier);
  }

  /// 📝 ScribbleNotifier 해제 (ScribbleWidget dispose 시 자동 호출)
  void unregisterScribbleNotifier(ScribbleNotifier scribbleNotifier) {
    _activeScribbleNotifiers.remove(scribbleNotifier);

    // 만약 해제되는 notifier가 현재 활성이면 null로 설정
    if (_lastActiveScribbleNotifier == scribbleNotifier) {
      _lastActiveScribbleNotifier = null;

      // ✨ dispose 상태 체크 후 안전하게 UI 업데이트
      if (!_isDisposed) {
        _activeScribbleNotifierNotifier.value = null; // UI 업데이트 알림
        _updateUndoRedoState(); // Undo/Redo 상태 업데이트 (모두 비활성화)
      }
    }
  }

  /// 🎯 마지막 활성 ScribbleNotifier 설정 (필기 시작 시 호출)
  void setLastActiveScribbleNotifier(ScribbleNotifier scribbleNotifier) {
    // 🛡️ dispose 상태 체크
    if (_isDisposed) {
      debugPrint(
        '⚠️ DrawingState가 dispose된 상태로 setLastActiveScribbleNotifier 호출 무시',
      );
      return;
    }

    // 이미 같은 notifier가 설정되어 있다면 중복 처리 방지
    if (_lastActiveScribbleNotifier == scribbleNotifier) {
      // 상태만 업데이트
      _updateUndoRedoState();
      return;
    }

    _lastActiveScribbleNotifier = scribbleNotifier;

    // 🛡️ dispose 상태 재확인 후 ValueNotifier 접근
    if (!_isDisposed) {
      _activeScribbleNotifierNotifier.value = scribbleNotifier; // UI 업데이트 알림
    }

    // 🔄 즉시 undo/redo 상태 업데이트
    _updateUndoRedoState();

    // 🎯 약간의 지연 후 한 번 더 업데이트 (비동기 상태 변경 반영)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_lastActiveScribbleNotifier == scribbleNotifier) {
        _updateUndoRedoState();
      }
    });
  }

  /// 🎯 Undo/Redo 가능 여부 상태 업데이트 (public)
  void updateUndoRedoState() {
    _updateUndoRedoState();
  }

  /// 🎯 Undo/Redo 가능 여부 상태 업데이트 (private)
  void _updateUndoRedoState() {
    // ✨ dispose 체크: 이미 dispose된 상태면 상태 업데이트 안함
    if (_isDisposed) {
      return;
    }

    // ✨ 안전한 상태 업데이트: 다음 프레임에서 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 다시 한번 dispose 체크 (다음 프레임에서 dispose될 수 있음)
      if (_isDisposed) {
        return;
      }

      try {
        final activeNotifier = _lastActiveScribbleNotifier;

        if (activeNotifier == null) {
          // 활성 notifier가 없으면 모두 비활성화
          if (_canUndoNotifier.value != false) {
            _canUndoNotifier.value = false;
          }
          if (_canRedoNotifier.value != false) {
            _canRedoNotifier.value = false;
          }
          return;
        }

        // 현재 상태 확인
        final newCanUndo = activeNotifier.canUndo;
        final newCanRedo = activeNotifier.canRedo;

        // 값이 실제로 변경된 경우에만 업데이트 (불필요한 리빌드 방지)
        if (_canUndoNotifier.value != newCanUndo) {
          _canUndoNotifier.value = newCanUndo;
        }

        if (_canRedoNotifier.value != newCanRedo) {
          _canRedoNotifier.value = newCanRedo;
        }
      } on Exception {
        // 에러 발생 시 안전하게 비활성화 (dispose 체크 후)
        if (!_isDisposed) {
          if (_canUndoNotifier.value != false) {
            _canUndoNotifier.value = false;
          }
          if (_canRedoNotifier.value != false) {
            _canRedoNotifier.value = false;
          }
        }
      }
    });
  }

  /// 🎯 현재 상태를 특정 modeNotifier에 적용
  void applyToModeNotifier(ScribbleModeNotifier modeNotifier) {
    try {
      final currentTool = selectedTool.value;
      final currentColor = selectedColor.value;
      final currentThickness = selectedThickness.value;

      // 📋 적용 전 modeNotifier 현재 상태 확인
      final beforeState = modeNotifier.state;

      // 🎯 지우개에서 다른 도구로 전환하는 경우 ScribbleNotifier도 함께 변경
      final isEraserToOtherTool =
          beforeState.inkGroupInfo.selectedInk == 'erase' &&
          currentTool != DrawingTool.erase;
      ScribbleNotifier? correspondingScribbleNotifier;

      if (isEraserToOtherTool) {
        // 🔄 해당 modeNotifier와 연결된 ScribbleNotifier 찾기
        correspondingScribbleNotifier = _findScribbleNotifierForModeNotifier(
          modeNotifier,
        );
        if (correspondingScribbleNotifier != null) {
          correspondingScribbleNotifier.setStrokeInk(); // 그리기 모드로 전환
        }
      }

      // 포인터 모드 설정
      if (pointerMode.value == DrawingPointerMode.mouseOnly) {
        modeNotifier.setAllowedPointersMode(ScribblePointerMode.all);
      } else {
        modeNotifier.setAllowedPointersMode(ScribblePointerMode.penOnly);
      }

      // 🎯 새로운 순서: 먼저 색상과 두께를 설정한 후 도구 설정
      // 이렇게 하면 도구 변경 시 기존 설정이 초기화되는 문제를 방지할 수 있습니다.

      switch (currentTool) {
        case DrawingTool.pen:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          // 먼저 색상과 두께 설정
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);
          // 그 다음 도구 설정
          modeNotifier.setPen();

        case DrawingTool.pencil:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          // 먼저 색상과 두께 설정
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);
          // 그 다음 도구 설정
          modeNotifier.setPencil();

        case DrawingTool.marker:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          // 마커는 투명도 적용
          final markerColor = currentColor.withValues(alpha: 0.5);
          // 먼저 색상과 두께 설정
          modeNotifier.setColor(markerColor);
          modeNotifier.setStrokeWidth(currentThickness);
          // 그 다음 도구 설정
          modeNotifier.setMarker();

        case DrawingTool.highlighter:
          // 🎯 하이라이트는 PDF 텍스트 선택 모드로만 사용
          // 실제 그리기는 텍스트 선택 툴바에서 처리하므로 여기서는 아무 동작 안 함
          break;

        case DrawingTool.erase:

          // 🔧 지우개 모드 설정 시 두께도 함께 적용
          modeNotifier.setStrokeWidth(currentThickness);
          modeNotifier.setEraser();

          // 🎯 다른 도구에서 지우개로 전환하는 경우 ScribbleNotifier도 함께 변경
          if (beforeState.inkGroupInfo.selectedInk != 'erase') {
            correspondingScribbleNotifier =
                _findScribbleNotifierForModeNotifier(modeNotifier);
            if (correspondingScribbleNotifier != null) {
              correspondingScribbleNotifier.setEraser(); // 지우개 모드로 전환
            }
          }

        case DrawingTool.text:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setText();

        case DrawingTool.shape:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          // 먼저 색상과 두께 설정
          modeNotifier.setColor(currentColor);
          modeNotifier.setStrokeWidth(currentThickness);
          // 그 다음 도구 설정
          modeNotifier.setShape();

        case DrawingTool.lasso:
          // 🔄 지우개에서 다른 도구로 전환 시 지우개 모드 해제
          if (beforeState.inkGroupInfo.selectedInk == 'erase') {}
          modeNotifier.setLassoSelection();
      }

      // 📋 적용 후 modeNotifier 상태 확인
      final afterState = modeNotifier.state;

      // 🚨 상태 불일치 감지 (지우개 모드가 아닌 경우에만)
      if (currentTool != DrawingTool.erase &&
          currentTool != DrawingTool.lasso &&
          currentTool != DrawingTool.text) {
        final expectedColor = currentTool == DrawingTool.marker
            ? currentColor.withValues(alpha: 0.5)
            : currentColor;
        final actualColor = afterState.inkGroupInfo.selectedColor;
        final actualThickness = afterState.inkGroupInfo.seletedStrokeWidth;

        if (actualColor != expectedColor) {
          // 🔄 한 번 더 색상 설정 시도
          modeNotifier.setColor(expectedColor);
        }
        if (actualThickness != currentThickness) {
          // 🔄 한 번 더 두께 설정 시도
          modeNotifier.setStrokeWidth(currentThickness);
        }
      }
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
    }
  }

  /// 🌍 모든 활성 notifier에 현재 상태 동기화
  void _syncToAllNotifiers() {
    if (_activeNotifiers.isEmpty) {
      return;
    }

    for (final notifier in _activeNotifiers) {
      applyToModeNotifier(notifier);
    }

    // 🔄 동기화 후 일치성 확인 및 필요시 재설정
    Future.delayed(const Duration(milliseconds: 100), () {
      ensureStateConsistency();
      debugAllNotifierStates();
    });
  }

  /// 🚀 강제 동기화 (외부에서 호출 가능)
  void forceSyncAll() {
    _syncToAllNotifiers();
  }

  /// 🎨 도구 변경 (모든 notifier에 자동 동기화)
  void setTool(DrawingTool tool) {
    selectedTool.value = tool;
    _syncToAllNotifiers();
  }

  /// 🎨 색상 변경 (모든 notifier에 자동 동기화)
  void setColor(Color color) {
    selectedColor.value = color;
    _syncToAllNotifiers();
  }

  /// 🎨 두께 변경 (모든 notifier에 자동 동기화)
  void setThickness(double thickness) {
    selectedThickness.value = thickness;
    _syncToAllNotifiers();
  }

  /// 🎨 포인터 모드 변경 (모든 notifier에 자동 동기화)
  void setPointerMode(DrawingPointerMode mode) {
    pointerMode.value = mode;
    _syncToAllNotifiers();
  }

  /// 설정 콜백 등록 (외부에서 호출)
  void setupCallbacks({
    Future<void> Function()? onSave,
    Future<void> Function()? onLoad,
  }) {
    this.onSave = onSave;
    this.onLoad = onLoad;
  }

  /// 설정 저장 (외부 콜백 사용)
  Future<void> saveSettings() async {
    if (onSave != null) {
      await onSave!();
    }
  }

  /// 설정 복원 (외부 콜백 사용)
  Future<void> loadSettings() async {
    if (onLoad != null) {
      await onLoad!();
      // 복원 후 모든 notifier에 동기화
      _syncToAllNotifiers();
    }
  }

  /// 🔗 SharedPreferences 기반 영구 저장 활성화
  Future<void> enablePersistence() async {
    if (_persistenceEnabled) return;

    try {
      _persistenceEnabled = true;

      // 기존 콜백을 SharedPreferences 구현으로 설정
      onSave = _saveToSharedPreferences;
      onLoad = _loadFromSharedPreferences;

      // 저장된 설정 즉시 복원
      await loadSettings();
    } on Exception {
      _persistenceEnabled = false;
    }
  }

  /// 🔗 SharedPreferences 기반 영구 저장 비활성화
  void disablePersistence() {
    _persistenceEnabled = false;
    onSave = null;
    onLoad = null;
  }

  /// 💾 SharedPreferences에 설정 저장
  Future<void> _saveToSharedPreferences() async {
    if (!_persistenceEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 포인터 모드 저장
      await prefs.setString(_keyPointerMode, pointerMode.value.toString());

      // 선택된 도구 저장
      await prefs.setString(
        _keySelectedTool,
        selectedTool.value.toString(),
      );

      // 선택된 색상 저장 (ARGB 값으로)
      await prefs.setInt(_keySelectedColor, selectedColor.value.toARGB32());

      // 선택된 두께 저장
      await prefs.setDouble(_keySelectedThickness, selectedThickness.value);

      // 색상 슬롯 저장 (4개의 ARGB 값을 문자열 리스트로)
      final slotValues = colorSlots.value
          .map((color) => color.toARGB32().toString())
          .toList();
      await prefs.setStringList(_keyColorSlots, slotValues);
    } on Exception catch (error, stackTrace) {
      debugPrint('❌ SharedPreferences 저장 에러: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// 📂 SharedPreferences에서 설정 복원
  Future<void> _loadFromSharedPreferences() async {
    if (!_persistenceEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 포인터 모드 복원
      final pointerModeStr = prefs.getString(_keyPointerMode);
      if (pointerModeStr != null) {
        if (pointerModeStr.contains('mouseOnly')) {
          pointerMode.value = DrawingPointerMode.mouseOnly;
        } else if (pointerModeStr.contains('penOnly')) {
          pointerMode.value = DrawingPointerMode.penOnly;
        }
      }

      // 선택된 도구 복원
      final toolStr = prefs.getString(_keySelectedTool);
      if (toolStr != null) {
        for (final tool in DrawingTool.values) {
          if (toolStr.contains(tool.toString().split('.').last)) {
            selectedTool.value = tool;
            break;
          }
        }
      }

      // 선택된 색상 복원
      final colorValue = prefs.getInt(_keySelectedColor);
      if (colorValue != null) {
        selectedColor.value = Color(colorValue);
      }

      // 선택된 두께 복원
      final thickness = prefs.getDouble(_keySelectedThickness);
      if (thickness != null) {
        selectedThickness.value = thickness;
      }

      // 색상 슬롯 복원
      final slotStrings = prefs.getStringList(_keyColorSlots);
      if (slotStrings != null && slotStrings.length == 4) {
        colorSlots.value = slotStrings
            .map((str) => Color(int.parse(str)))
            .toList();
      }
    } on Exception catch (_) {
      // 설정 복원 실패 시 기본값 유지
    }
  }

  /// 🔄 설정 초기화 (기본값으로 리셋)
  Future<void> resetToDefaults() async {
    try {
      pointerMode.value = DrawingPointerMode.penOnly;
      selectedTool.value = DrawingTool.pencil;
      selectedColor.value = Colors.black;
      selectedThickness.value = 2.0;
      showColorPicker.value = false;

      // SharedPreferences에서도 제거
      if (_persistenceEnabled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyPointerMode);
        await prefs.remove(_keySelectedTool);
        await prefs.remove(_keySelectedColor);
        await prefs.remove(_keySelectedThickness);
      }

      // 모든 활성 notifier에 적용
      _syncToAllNotifiers();
    } on Exception catch (_) {
      // 설정 초기화 실패 시 무시
    }
  }

  /// 설정이 변경될 때마다 자동 저장 및 동기화 설정
  void _setupAutoSave() {
    pointerMode.addListener(() {
      saveSettings();
      // 🔄 지연된 동기화로 상태 안정화
      Future.delayed(const Duration(milliseconds: 50), () {
        _syncToAllNotifiers();
      });
    });

    selectedTool.addListener(() {
      saveSettings();
      // 🔄 지연된 동기화로 상태 안정화
      Future.delayed(const Duration(milliseconds: 50), () {
        _syncToAllNotifiers();
      });
    });

    selectedColor.addListener(() {
      saveSettings();
      // 🔄 지연된 동기화로 상태 안정화
      Future.delayed(const Duration(milliseconds: 50), () {
        _syncToAllNotifiers();
      });
    });

    selectedThickness.addListener(() {
      saveSettings();
      // 🔄 지연된 동기화로 상태 안정화
      Future.delayed(const Duration(milliseconds: 50), () {
        _syncToAllNotifiers();
      });
    });
  }

  /// 📝 디스포즈 (앱 종료 시)
  void dispose() {
    _isDisposed = true;
    // 모든 listener 제거 (auto save + sync listeners)
    _removeAllListeners();

    pointerMode.dispose();
    selectedTool.dispose();
    selectedColor.dispose();
    selectedThickness.dispose();
    showColorPicker.dispose();

    // 🎯 새로 추가한 ValueNotifier들도 정리
    _activeScribbleNotifierNotifier.dispose();
    _canUndoNotifier.dispose();
    _canRedoNotifier.dispose();

    _activeNotifiers.clear();
    _activeScribbleNotifiers.clear();
    _undoRedoUpdateCallbacks.clear();
  }

  /// 모든 listener 제거
  void _removeAllListeners() {
    // 기존 listener들이 복합 함수이므로 제거할 수 없음
    // 대신 새로운 ValueNotifier 생성으로 완전 초기화
  }

  /// 🔍 현재 상태 디버깅 출력
  void debugCurrentState() {}

  /// 🔍 모든 등록된 modeNotifier의 현재 상태 확인
  void debugAllNotifierStates() {
    // 디버그 모드에서만 사용 - 현재는 비활성화
    for (final _ in _activeNotifiers) {
      // 상태 확인 로직 (현재 비활성화)
    }
  }

  /// 🎯 강제 상태 일치 확인 및 재설정 (불일치 시 한번 더 설정)
  void ensureStateConsistency() {
    if (_activeNotifiers.isEmpty) return;

    final expectedTool = selectedTool.value;
    final expectedColor = selectedColor.value;
    final expectedThickness = selectedThickness.value;

    for (final notifier in _activeNotifiers) {
      final state = notifier.state;
      final actualColor = state.inkGroupInfo.selectedColor;
      final actualThickness = state.inkGroupInfo.seletedStrokeWidth;

      // 지우개나 올가미는 색상 체크 생략
      if (expectedTool != DrawingTool.erase &&
          expectedTool != DrawingTool.lasso) {
        final expectedFinalColor = expectedTool == DrawingTool.marker
            ? expectedColor.withValues(alpha: 0.5)
            : expectedColor;

        if (actualColor != expectedFinalColor) {
          notifier.setColor(expectedFinalColor);
        }

        if (actualThickness != expectedThickness) {
          notifier.setStrokeWidth(expectedThickness);
        }
      }
    }
  }

  // ===== Undo/Redo 관련 메서드들 =====

  /// 🔙 Undo 가능 여부 (활성 ScribbleNotifier 기준)
  bool get canUndo => _lastActiveScribbleNotifier?.canUndo ?? false;

  /// 🔜 Redo 가능 여부 (활성 ScribbleNotifier 기준)
  bool get canRedo => _lastActiveScribbleNotifier?.canRedo ?? false;

  // 🎯 Undo/Redo 후 화면 업데이트 콜백들
  final List<VoidCallback> _undoRedoUpdateCallbacks = [];

  /// 🎯 Undo/Redo 후 화면 업데이트 콜백 등록
  void registerUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoUpdateCallbacks.add(callback);
  }

  /// 🎯 Undo/Redo 후 화면 업데이트 콜백 해제
  void unregisterUndoRedoUpdateCallback(VoidCallback callback) {
    _undoRedoUpdateCallbacks.remove(callback);
  }

  /// 🎯 모든 등록된 콜백으로 화면 업데이트 트리거
  void _triggerUndoRedoUpdate() {
    for (final callback in _undoRedoUpdateCallbacks) {
      try {
        callback();
      } on Exception {
        // 콜백 실행 실패 시 무시
      }
    }
  }

  /// 🔙 Undo 실행 (활성 ScribbleNotifier 기준)
  void undo() {
    if (_lastActiveScribbleNotifier?.canUndo ?? false) {
      _lastActiveScribbleNotifier!.undo();
      // 🎯 Undo/Redo 상태 즉시 업데이트 (버튼 활성화 상태 반영)
      _updateUndoRedoState();

      // 🎯 화면 즉시 업데이트
      _triggerUndoRedoUpdate();
    } else {}
  }

  /// 🔜 Redo 실행 (활성 ScribbleNotifier 기준)
  void redo() {
    if (_lastActiveScribbleNotifier?.canRedo ?? false) {
      _lastActiveScribbleNotifier!.redo();
      // 🎯 Undo/Redo 상태 즉시 업데이트 (버튼 활성화 상태 반영)
      _updateUndoRedoState();

      // 🎯 화면 즉시 업데이트
      _triggerUndoRedoUpdate();
    } else {}
  }

  /// 🔍 ModeNotifier에 해당하는 ScribbleNotifier 찾기
  ScribbleNotifier? _findScribbleNotifierForModeNotifier(
    ScribbleModeNotifier modeNotifier,
  ) {
    // 🎯 현재 활성 ScribbleNotifier가 있다면 우선 사용
    if (_lastActiveScribbleNotifier != null) {
      return _lastActiveScribbleNotifier;
    }

    // 🎯 등록된 ScribbleNotifier 중에서 첫 번째 반환 (임시 방안)
    if (_activeScribbleNotifiers.isNotEmpty) {
      return _activeScribbleNotifiers.first;
    }

    return null;
  }

  /// 🎯 특정 ScribbleNotifier의 상태를 현재 전역 도구에 맞게 동기화
  void syncScribbleNotifierToGlobalTool(ScribbleNotifier scribbleNotifier) {
    try {
      final currentTool = selectedTool.value;

      switch (currentTool) {
        case DrawingTool.pen:
        case DrawingTool.pencil:
        case DrawingTool.marker:
        case DrawingTool.highlighter:
        case DrawingTool.shape:
        case DrawingTool.text:
        case DrawingTool.lasso:
          // 그리기 도구들은 setStrokeInk() 호출
          scribbleNotifier.setStrokeInk();

          break;
        case DrawingTool.erase:
          // 지우개는 setEraser() 호출
          scribbleNotifier.setEraser();

          break;
      }

      // 상태 변경 후 Undo/Redo 상태 업데이트
      updateUndoRedoState();
    } on Exception {
      // ScribbleNotifier 동기화 실패 시 무시
    }
  }
}
