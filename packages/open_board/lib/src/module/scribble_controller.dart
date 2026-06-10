import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

/// ✨ ScribbleWidget을 편리하게 사용하기 위한 컨트롤러
///
/// 내부적으로 ScribbleNotifier와 ScribbleModeNotifier를 관리하며,
/// 외부에서는 간단한 API로 필기 기능을 제어할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// final controller = ScribbleController();
///
/// ScribbleWidget(
///   controller: controller,
///   child: YourWidget(),
///   onScribbleChanged: (data) => print('필기 변경됨'),
/// )
///
/// // 컨트롤러로 조작
/// controller.clear();
/// controller.undo();
/// controller.setTool(ScribbleTool.pen);
/// ```
class ScribbleController extends ChangeNotifier {
  /// ✨ 이미지 캡처를 위한 GlobalKey
  final GlobalKey repaintBoundaryKey = GlobalKey();

  /// 필기 데이터 변경 콜백
  void Function(Scribble scribble)? onScribbleChanged;

  /// 필기 완료 콜백
  void Function(Scribble scribble)? onScribbleFinished;

  /// 도구 변경 콜백
  void Function(String tool)? onToolChanged;

  /// 내부적으로 관리되는 notifier들
  late final ScribbleNotifier _scribbleNotifier;

  late final ScribbleModeNotifier _modeNotifier;

  /// ✨ Listener callbacks (dispose 시 정리용)
  VoidCallback? _scribbleListener;

  VoidCallback? _modeListener;

  /// 🚀 초기 로딩 최적화: 지연 초기화 플래그
  bool _isInitialized = false;
  Scribble? _pendingInitialScribble;
  String _pendingInitialTool = InkModes.pen;
  Color _pendingInitialColor = Colors.black;
  double _pendingInitialStrokeWidth = 2.0;

  ScribbleController({
    this.onScribbleChanged,
    this.onScribbleFinished,
    this.onToolChanged,
    Scribble? initialScribble,
    String initialTool = InkModes.pen,
    Color initialColor = Colors.black,
    double initialStrokeWidth = 2.0,
  }) {
    // 🚀 초기 로딩 최적화: 실제 사용 시까지 초기화 지연
    _pendingInitialScribble = initialScribble;
    _pendingInitialTool = initialTool;
    _pendingInitialColor = initialColor;
    _pendingInitialStrokeWidth = initialStrokeWidth;

    // 즉시 초기화 대신 필요 시점에 초기화
    // _initializeNotifiers(...);
    // _setupListeners();
    // _registerToDrawingState();
  }

  /// 내부 notifier들에 대한 읽기 전용 접근
  ScribbleNotifier get scribbleNotifier {
    _ensureInitialized();
    return _scribbleNotifier;
  }

  ScribbleModeNotifier get modeNotifier {
    _ensureInitialized();
    return _modeNotifier;
  }

  /// === 편의 메서드들 ===

  /// 현재 필기 데이터 가져오기
  Scribble get currentScribble {
    _ensureInitialized();
    return _scribbleNotifier.currentScribble;
  }

  /// 되돌리기 가능 여부
  bool get canUndo {
    _ensureInitialized();
    return _scribbleNotifier.canUndo;
  }

  /// 다시 실행 가능 여부
  bool get canRedo {
    _ensureInitialized();
    return _scribbleNotifier.canRedo;
  }

  /// 필기 데이터가 비어있는지 확인
  bool get isEmpty =>
      currentScribble.strokes.isEmpty && currentScribble.textDrawables.isEmpty;

  /// 통계 정보
  ScribbleStats get stats => .from(currentScribble);

  /// === 도구 제어 메서드들 ===

  /// 도구 변경
  void setTool(String tool) {
    _ensureInitialized();
    _modeNotifier.setSelectedInk(tool);
  }

  /// === 필기 데이터 제어 메서드들 ===

  /// 필기 데이터 로드
  ///
  /// 기본값([resetHistory] = true)은 로드된 데이터를 undo baseline으로
  /// 설정한다. 로드를 히스토리에 push하면 undo 한 번으로 페이지 전체가
  /// 빈 baseline으로 되돌아가고, 이어지는 페이지 전환 저장으로 원본이
  /// 영구 유실된다.
  ///
  /// 라이브 세션/리플레이처럼 빈번한 외부 갱신은 [resetHistory] = false로
  /// 호출해 로컬 undo 히스토리를 오염시키지 않는다.
  void loadScribble(Scribble scribble, {bool resetHistory = true}) {
    _ensureInitialized();
    _scribbleNotifier.setScribble(scribble: scribble, addToUndoHistory: false);
    if (resetHistory) {
      _scribbleNotifier.resetHistoryToBaseline();
    }
  }

  /// 전체 지우기
  void clear() {
    _ensureInitialized();
    _scribbleNotifier.clear();
  }

  /// 되돌리기
  void undo() {
    if (canUndo) {
      _scribbleNotifier.undo();

      // 🎯 undo 실행 후 DrawingState 상태 업데이트
      final drawingState = DrawingState();
      if (drawingState.lastActiveScribbleNotifier == _scribbleNotifier) {
        drawingState.updateUndoRedoState();
      }
    }
  }

  /// 다시 실행
  void redo() {
    if (canRedo) {
      _scribbleNotifier.redo();

      // 🎯 redo 실행 후 DrawingState 상태 업데이트
      final drawingState = DrawingState();
      if (drawingState.lastActiveScribbleNotifier == _scribbleNotifier) {
        drawingState.updateUndoRedoState();
      }
    }
  }

  /// === 내보내기 메서드들 ===

  /// 필기 데이터를 바이트 배열로 내보내기
  Uint8List exportAsBytes() {
    return currentScribble.writeToBuffer();
  }

  /// 바이트 배열에서 필기 데이터 가져오기
  void importFromBytes(Uint8List bytes) {
    final scribble = Scribble.fromBuffer(bytes);
    loadScribble(scribble);
  }

  /// ✨ 이미지 캡처 메서드 - UI 이미지 반환
  Future<ui.Image?> captureAsImage({double pixelRatio = 3.0}) async {
    try {
      if (repaintBoundaryKey.currentContext == null) {
        return null;
      }

      final boundary =
          repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      return image;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return null;
    }
  }

  /// ✨ PNG ByteData로 이미지 캡처
  Future<ByteData?> captureAsPng({double pixelRatio = 3.0}) async {
    try {
      final image = await captureAsImage(pixelRatio: pixelRatio);
      if (image == null) return null;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // 메모리 해제

      return byteData;
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return null;
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      // 🌍 DrawingState에서 자동 해제
      _unregisterFromDrawingState();

      // ✨ Listener들 정리
      if (_scribbleListener != null) {
        _scribbleNotifier.removeListener(_scribbleListener!);
      }
      if (_modeListener != null) {
        _modeNotifier.removeListener(_modeListener!);
      }
      _scribbleListener = null;
      _modeListener = null;

      // Notifier들 정리
      _scribbleNotifier.dispose();
      _modeNotifier.dispose();
    }

    super.dispose();
  }

  /// 🚀 초기 로딩 최적화: 지연 초기화 메서드
  void _ensureInitialized() {
    if (_isInitialized) return;

    _initializeNotifiers(
      initialScribble: _pendingInitialScribble,
      initialTool: _pendingInitialTool,
      initialColor: _pendingInitialColor,
      initialStrokeWidth: _pendingInitialStrokeWidth,
    );
    _setupListeners();

    // 🌍 자동으로 DrawingState에 등록 (통일성 확보)
    _registerToDrawingState();

    _isInitialized = true;

    // 메모리 정리
    _pendingInitialScribble = null;
  }

  /// 🌍 DrawingState에 자동 등록
  void _registerToDrawingState() {
    try {
      final drawingState = DrawingState();
      drawingState.registerNotifier(_modeNotifier);
      drawingState.registerScribbleNotifier(_scribbleNotifier);
      // 성능 최적화: 등록 완료 로그 제거
      // debugPrint('✅ ScribbleController: DrawingState에 자동 등록 완료');
    } on Exception catch (error) {
      debugPrint('❌ ScribbleController: DrawingState 등록 오류 - $error');
    }
  }

  /// 🌍 DrawingState에서 자동 해제
  void _unregisterFromDrawingState() {
    try {
      final drawingState = DrawingState();
      drawingState.unregisterNotifier(_modeNotifier);
      drawingState.unregisterScribbleNotifier(_scribbleNotifier);
      debugPrint('✅ ScribbleController: DrawingState에서 자동 해제 완료');
    } on Exception catch (error) {
      debugPrint('❌ ScribbleController: DrawingState 해제 오류 - $error');
    }
  }

  /// Notifier들 초기화
  void _initializeNotifiers({
    Scribble? initialScribble,
    required String initialTool,
    required Color initialColor,
    required double initialStrokeWidth,
  }) {
    // ScribbleNotifier 초기화
    _scribbleNotifier = ScribbleNotifier(
      scribble: initialScribble ?? Scribble(strokes: [], width: 0, height: 0),
    );
    // ScribbleNotifier 생성자가 state 를 두 번 설정하여 spurious undo 히스토리가 생긴다.
    // `clearQueue()` 만 호출하면 history 가 완전히 비어서 첫 stroke 시 length=1 →
    // `canUndo` 가 false 가 되는 버그가 발생하므로, 현재 상태를 baseline 으로 push 하여
    // 첫 변경이 즉시 undo 가능하도록 보정한다.
    _scribbleNotifier.resetHistoryToBaseline();

    // ScribbleModeNotifier 초기화
    _modeNotifier = ScribbleModeNotifier();

    // 초기 도구 설정
    _modeNotifier.setSelectedInk(initialTool);
    _modeNotifier.setColor(initialColor);
    _modeNotifier.setStrokeWidth(initialStrokeWidth);
  }

  /// 리스너 설정
  void _setupListeners() {
    // ScribbleNotifier 변경 감지 (ValueNotifier listener 사용)
    _scribbleListener = () {
      final currentScribble = _scribbleNotifier.value.scribble;
      onScribbleChanged?.call(currentScribble);
      notifyListeners();
    };
    _scribbleNotifier.addListener(_scribbleListener!);

    // ModeNotifier 변경 감지 (ValueNotifier listener 사용)
    _modeListener = () {
      final currentTool = _modeNotifier.value.inkGroupInfo.selectedInk;
      onToolChanged?.call(currentTool);
      notifyListeners();
    };
    _modeNotifier.addListener(_modeListener!);
  }
}

/// 필기 통계 정보
class ScribbleStats {
  final int strokeCount;
  final int textCount;
  final int totalPointCount;
  final Size canvasSize;
  final String fileSize;

  const ScribbleStats({
    required this.strokeCount,
    required this.textCount,
    required this.totalPointCount,
    required this.canvasSize,
    required this.fileSize,
  });

  factory ScribbleStats.from(Scribble scribble) {
    int totalPoints = 0;
    for (final stroke in scribble.strokes) {
      totalPoints += stroke.points.length;
    }

    final bytes = scribble.writeToBuffer().length;
    String fileSize;
    if (bytes < 1024) {
      fileSize = '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      fileSize = '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      fileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }

    return ScribbleStats(
      strokeCount: scribble.strokes.length,
      textCount: scribble.textDrawables.length,
      totalPointCount: totalPoints,
      canvasSize: Size(scribble.width, scribble.height),
      fileSize: fileSize,
    );
  }

  @override
  String toString() {
    return 'ScribbleStats(strokes: $strokeCount, texts: $textCount, points: $totalPointCount, size: $canvasSize, fileSize: $fileSize)';
  }
}

/// 필기 도구 상수
class ScribbleTool {
  static const String pen = InkModes.pen;
  static const String pencil = InkModes.pencil;
  static const String marker = InkModes.marker;
  static const String fixedPen = InkModes.fixedPen;
  static const String eraser = InkModes.erase;
  static const String lasso = InkModes.lasso;
  static const String text = InkModes.text;
  static const String shape = InkModes.shape;
}
