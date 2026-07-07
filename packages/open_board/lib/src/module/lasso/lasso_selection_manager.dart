import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_painter.dart' as painter;
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/coordinate_transformer.dart';
import 'package:open_board/src/module/image/image_drawable_extensions.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/transform_handler.dart';

/// 올가미 변형 시 원본 상태를 보관하기 위한 텍스트 상태 스냅샷
class _OriginalTextState {
  final Offset position;
  final double fontSize;
  final double rotation;
  const _OriginalTextState({
    required this.position,
    required this.fontSize,
    required this.rotation,
  });
}

/// 올가미 선택 기능을 관리하는 클래스
/// ScribbleWidget의 올가미 관련 기능들을 분리하여 관리
class LassoSelectionManager {
  // 의존성
  final ScribbleNotifier scribbleNotifier;
  final VoidCallback onStateChanged;

  // 터치 위치와 버튼 위치의 오프셋

  // TransformationController 참조
  TransformationController? transformationController;

  final void Function(bool isSelecting, bool isTransforming)? onModeChanged;

  // 올가미 선택 관련 상태
  painter.LassoSelectionState _lassoSelectionState =
      painter.LassoSelectionState();

  // 선택된 스트로크 ID 목록
  List<int> _selectedStrokeIds = [];

  // 선택된 텍스트 인덱스 목록 (현재 scribble.textDrawables 기준)
  List<int> _selectedTextIds = [];

  // 변형 시작 시점의 텍스트 원본 상태 (위치/크기/회전)
  List<_OriginalTextState>? _originalTextStates;

  // 클래스 멤버에 추가
  bool _showLassoOverlay = false; // 클래스 멤버 추가 (터치업인사이드 체크 복원)
  bool _isLassoTransforming = false; // 터치업인사이드 체크용 변수들 (필수!)
  DateTime? _lastLassoTapDownTime;

  bool _lassoTapMoved = false;
  Offset? _lastTransformPosition; // 크기조절/회전 관련 변수들
  List<List<Offset>>? _originalStrokePoints;
  painter.OrientedBoundingBox? _originalOrientedBoundingBox;

  Offset? _startTouchPoint; // 터치 시작점 저장

  Offset? _touchToButtonOffset;

  // 공통 변형 핸들러
  late TransformHandler _transformHandler;

  LassoSelectionManager({
    required this.scribbleNotifier,
    required this.onStateChanged,
    required this.transformationController,
    required this.onModeChanged,
  }) {
    _transformHandler = TransformHandler();
  }

  // Getters
  painter.LassoSelectionState get lassoSelectionState => _lassoSelectionState;
  List<int> get selectedStrokeIds => _selectedStrokeIds;
  List<int> get selectedTextIds => _selectedTextIds;
  bool get showLassoOverlay => _showLassoOverlay;
  bool get isLassoTransforming => _isLassoTransforming;

  double get currentScale => _transformer.scale;

  CoordinateTransformer get _transformer =>
      CoordinateTransformer(transformationController);

  /// 올가미 모드에서 포인터 다운 처리
  bool handleLassoModePointerDown(
    PointerDownEvent event,
    BuildContext context,
  ) {
    // 🖼️ 기존 이미지를 직접 터치하면 올가미 로직은 관여하지 않고 이벤트만
    // 소비한다(true 반환) — 상태를 건드리지 않아야 ImageDrawableLayer 자체
    // GestureDetector(선택/이동/크기조절/회전/삭제)가 정상 동작하고, 동시에
    // 올가미 자유선 그리기(handleNormalDrawingMode)가 겹쳐 시작되는 것을
    // 막는다 (kobic #7888: 올가미 도구에서 이미지 선택 불가 버그).
    if (_isPointerOverExistingImage(event.localPosition)) {
      return true;
    }

    // 오버레이 컨트롤 영역 체크를 가장 먼저 수행
    if (_showLassoOverlay && _selectedStrokeIds.isNotEmpty) {
      final boundingBox = _calculateBoundingBox(_selectedStrokeIds);

      final controlAreaResult = _handleControlAreaTouch(
        event.localPosition,
        boundingBox,
        context,
      );
      if (controlAreaResult != null) {
        // 컨트롤 영역 터치 처리됨 - 올가미 그리기 방지
        return controlAreaResult;
      }

      // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용 (드로잉과 동일)
      final adjustedPosition = event.localPosition; // 변환 없이 원본 좌표 사용

      if (boundingBox.contains(adjustedPosition)) {
        _isLassoTransforming = true;
        _lastTransformPosition = event.localPosition; // 드래그 시작점 설정 (화면 좌표)

        // 원본 스트로크 위치 캐싱 (텍스트 방식과 동일)
        _cacheOriginalStrokePoints();

        _lassoSelectionState = _lassoSelectionState.copyWith(
          isTransforming: true,
          operation: painter.TransformOperation.move,
        );

        onStateChanged(); // 상태 변경 알림 추가
        return true;
      }

      // 바운딩 박스 밖을 터치하면 선택 해제

      _selectedStrokeIds = [];
      _selectedTextIds = [];
      _originalTextStates = null;
      _lassoSelectionState = painter.LassoSelectionState();
      _showLassoOverlay = false;
      onStateChanged();
      return false; // 일반 드로잉 모드로 넘김
    }

    _isLassoTransforming = false;
    final currentScribble = scribbleNotifier.currentState.scribble;
    final (latestLassoStroke, lassoStrokeIndex) =
        _findLatestLassoStrokeWithIndex(currentScribble);

    if (latestLassoStroke == null || latestLassoStroke.points.length <= 2) {
      // 올가미 영역 밖에서 새로 그리기 시작하면 선택 해제
      _selectedStrokeIds = [];
      _selectedTextIds = [];
      _originalTextStates = null;
      _lassoSelectionState = painter.LassoSelectionState();
      _showLassoOverlay = false;
      onStateChanged();
      return false; // 일반 드로잉 모드로 넘김
    }

    // 🔥 scribble-tools 방식: 원본 화면 좌표 직접 사용 (드로잉과 동일)
    final pointer = event.localPosition; // 변환 없이 원본 좌표 사용

    // 🔥 올가미 포인트들도 원본 좌표계에서 처리 (드로잉과 동일)
    final lassoPoints = latestLassoStroke.points
        .map((pt) => Offset(pt.x, pt.y))
        .toList();
    if (lassoPoints.first != lassoPoints.last) {
      lassoPoints.add(lassoPoints.first);
    }

    if (!_isPointInPolygon(pointer, lassoPoints)) {
      // 🔧 올가미 영역 밖 터치 - 이때만 올가미 정리

      _cleanupExistingLassoStrokes();

      _selectedStrokeIds = [];
      _lassoSelectionState = painter.LassoSelectionState();
      _showLassoOverlay = false;
      _resetLassoState();
      onStateChanged();
      return false; // 일반 드로잉 모드로 넘김
    }

    if (_selectedStrokeIds.isNotEmpty) {
      // 바운딩 박스 터치 체크
      final boundingBox = _calculateBoundingBox(_selectedStrokeIds);
      if (boundingBox.contains(pointer)) {
        // 터치 정보 기록 (드래그 vs 탭 구분용)
        _lastTransformPosition = event.localPosition;
        _lastLassoTapDownTime = DateTime.now();
        _lassoTapMoved = false;
        _isLassoTransforming = false; // 아직 변형 모드 아님

        return true;
      } else {
        resetLassoState();
        return false; // 일반 드로잉 모드로 넘김
      }
    } else {
      final (strokesInLasso, textsInLasso) = _findElementsInLasso(lassoPoints);

      if (strokesInLasso.isNotEmpty || textsInLasso.isNotEmpty) {
        // 선택된 스트로크 + 텍스트 저장
        _selectedStrokeIds = strokesInLasso;
        _selectedTextIds = textsInLasso;

        // 올가미 스트로크 제거 및 오버레이 즉시 표시
        if (lassoStrokeIndex >= 0) {
          final strokes = List<Stroke>.from(currentScribble.strokes)
            ..removeWhere((stroke) => stroke.ink == InkModes.lasso);

          final updatedScribble = Scribble(
            strokes: strokes,
            width: currentScribble.width,
            height: currentScribble.height,
            x: currentScribble.x,
            y: currentScribble.y,
            textDrawables: currentScribble.textDrawables,
            createdAt: currentScribble.createdAt,
            updatedAt: currentScribble.updatedAt,
            version: currentScribble.version,
          );
          scribbleNotifier.setScribble(
            scribble: updatedScribble,
            addToUndoHistory: false,
          );
        }

        // 올가미 선택 상태 설정 (오버레이는 터치업인사이드에서 표시)
        final calculatedBoundingBox = _calculateBoundingBox(_selectedStrokeIds);

        _lassoSelectionState = painter.LassoSelectionState(
          boundingBox: calculatedBoundingBox,
        );
        _showLassoOverlay = false; // 터치업인사이드에서 표시하도록 숨김
        _isLassoTransforming = false;

        // 터치업인사이드 체크를 위한 변수 설정
        _lastLassoTapDownTime = DateTime.now();
        _lassoTapMoved = false;

        onStateChanged(); // 상태 변경 알림
        onModeChanged?.call(false, false); // 선택 완료 상태
        return true; // 이벤트 처리 완료
      } else {
        // 올가미 스트로크만 제거하고 일반 그리기 모드로 복귀
        if (lassoStrokeIndex >= 0) {
          final strokes = List<Stroke>.from(currentScribble.strokes)
            ..removeWhere((stroke) => stroke.ink == InkModes.lasso);

          final updatedScribble = Scribble(
            strokes: strokes,
            width: currentScribble.width,
            height: currentScribble.height,
            x: currentScribble.x,
            y: currentScribble.y,
            textDrawables: currentScribble.textDrawables,
            createdAt: currentScribble.createdAt,
            updatedAt: currentScribble.updatedAt,
            version: currentScribble.version,
          );
          scribbleNotifier.setScribble(
            scribble: updatedScribble,
            addToUndoHistory: false,
          );
        }

        _resetLassoState();
        onStateChanged();
        return false; // 일반 드로잉 모드로 넘김
      }
    }

    // 이벤트 처리 완료 (올가미 그리기 모드에서는 항상 true 반환)
  }

  /// 포인터 이동 처리 (드래그 임계값 체크 복원)
  bool handlePointerMove(PointerMoveEvent event) {
    // 올가미 변형 중인 경우 (드래그 이동 처리)
    if (_isLassoTransforming && _lastTransformPosition != null) {
      // ✅ 수정: 원본 기준 delta 계산 (시작점 대비)
      final delta = event.localPosition - _lastTransformPosition!;

      // ✅ 수정: 원본 기준 이동 메서드 사용 (누적 방지)
      _moveSelectedStrokesFromOriginal(delta);

      // ⚠️ 중요: _lastTransformPosition 업데이트하지 않음 (원본 기준 유지)

      onStateChanged();
      return true;
    }

    // 드래그 임계값 체크 (8픽셀) - 시작점 기준으로 체크
    if (_selectedStrokeIds.isNotEmpty &&
        _lastLassoTapDownTime != null &&
        _lastTransformPosition != null &&
        !_lassoTapMoved) {
      final moveDelta =
          (event.localPosition - _lastTransformPosition!).distance;
      if (moveDelta > 8.0) {
        _lassoTapMoved = true;
        _isLassoTransforming = true; // 드래그 모드 활성화

        // ✅ 추가: 원본 포인트 캐싱 (변형 방지)
        _cacheOriginalStrokePoints();
      }
    }

    return false;
  }

  /// 포인터 업 처리 (터치업인사이드 체크 복원)
  bool handlePointerUp(PointerUpEvent event) {
    // 터치업인사이드 체크 - 가장 중요한 로직
    if (_selectedStrokeIds.isNotEmpty && _lastLassoTapDownTime != null) {
      final elapsed = DateTime.now().difference(_lastLassoTapDownTime!);

      if (!_lassoTapMoved && elapsed.inMilliseconds < 200) {
        // ✅ 터치업인사이드 - 바운딩 박스 표시
        final overlayBoundingBox = _calculateBoundingBox(_selectedStrokeIds);

        _showLassoOverlay = true;
        _lassoSelectionState = painter.LassoSelectionState(
          boundingBox: overlayBoundingBox,
        );
        onStateChanged();

        final currentScribble = scribbleNotifier.currentState.scribble;
        final strokes = List<Stroke>.from(currentScribble.strokes);
        strokes.removeWhere((stroke) => stroke.ink == InkModes.lasso);

        final updatedScribble = Scribble(
          strokes: strokes,
          width: currentScribble.width,
          height: currentScribble.height,
          x: currentScribble.x,
          y: currentScribble.y,
          textDrawables: currentScribble.textDrawables,
          createdAt: currentScribble.createdAt,
          updatedAt: currentScribble.updatedAt,
          version: currentScribble.version,
        );
        scribbleNotifier.setScribble(
          scribble: updatedScribble,
          addToUndoHistory: false,
        );

        _cleanupTouchState();
        return true;
      } else if (_isLassoTransforming) {
        // ✅ 드래그 완료 - 이동 처리 완료

        final currentScribble = scribbleNotifier.currentState.scribble;
        scribbleNotifier.setScribble(
          scribble: currentScribble,
          addToUndoHistory: true,
        );
        _isLassoTransforming = false;
        _lastTransformPosition = null;
        onStateChanged();
        _cleanupTouchState();
        return true;
      } else {
        // ❌ 조건 불만족 - 선택 해제

        resetLassoState();
        return true;
      }
    }

    return false;
  }

  /// 올가미 스트로크가 추가된 직후(드로잉 PointerUp) 자동 선택 및 바운딩 박스 표시
  void selectElementsInLassoIfNeeded() {
    final currentScribble = scribbleNotifier.currentState.scribble;
    if (currentScribble.strokes.isNotEmpty &&
        currentScribble.strokes.last.ink == InkModes.lasso &&
        currentScribble.strokes.last.points.length > 2 &&
        _selectedStrokeIds.isEmpty) {
      final lassoStroke = currentScribble.strokes.last;
      final lassoPoints = lassoStroke.points
          .map((pt) => Offset(pt.x, pt.y))
          .toList();
      if (lassoPoints.first != lassoPoints.last) {
        lassoPoints.add(lassoPoints.first);
      }
      final (strokesInLasso, textsInLasso) = _findElementsInLasso(lassoPoints);

      if (strokesInLasso.isNotEmpty || textsInLasso.isNotEmpty) {
        // ① 올가미 스트로크의 id를 찾아서 추가
        final lassoStrokeIndex = currentScribble.strokes.lastIndexWhere(
          (stroke) => stroke.ink == InkModes.lasso,
        );

        // ② 기존 선택된 스트로크 id 목록 복사
        final allSelected = List<int>.from(strokesInLasso);

        // ③ 올가미 스트로크가 있으면 id 추가
        if (lassoStrokeIndex != -1) {
          allSelected.add(lassoStrokeIndex);
        }

        // ④ 선택 id 목록에 올가미 곡선도 포함
        _selectedStrokeIds = allSelected;
        _selectedTextIds = textsInLasso;

        // ⑤ 선택 상태 및 바운딩 박스 등은 기존대로
        _lassoSelectionState = painter.LassoSelectionState(
          boundingBox: _calculateBoundingBox(_selectedStrokeIds),
        );
        _showLassoOverlay = false;
        _isLassoTransforming = false;
        _lastLassoTapDownTime = DateTime.now();
        _lassoTapMoved = false;

        onStateChanged();
        onModeChanged?.call(false, false);
      } else {
        _resetLassoState();
        onStateChanged();
      }
    }
  }

  /// 올가미 상태 초기화
  void resetLassoState() {
    // 텍스트 선택 상태(_selectedTextIds/_originalTextStates)도 함께
    // 초기화한다 — 잔존하면 선택 해제 후에도 매니저가 텍스트를
    // 선택 중으로 간주한다.
    _resetLassoState();
    _showLassoOverlay = false;
    onStateChanged();
  }

  /// 선택된 스트로크 + 텍스트를 삭제하는 메서드
  void removeSelectedStrokes(List<int> strokeIds) {
    if (strokeIds.isEmpty && _selectedTextIds.isEmpty) return;

    final currentScribble = scribbleNotifier.currentState.scribble;
    final List<Stroke> strokes = List<Stroke>.from(currentScribble.strokes);
    final List<TextDrawable> textDrawables = List<TextDrawable>.from(
      currentScribble.textDrawables,
    );

    // 스트로크 삭제 (인덱스 변동을 피하기 위해 내림차순)
    final sortedStrokeIds = List<int>.from(strokeIds)
      ..sort((a, b) => b.compareTo(a));
    for (final id in sortedStrokeIds) {
      if (id >= 0 && id < strokes.length) {
        strokes.removeAt(id);
      }
    }

    // 텍스트 삭제 (인덱스 변동을 피하기 위해 내림차순)
    final sortedTextIds = List<int>.from(_selectedTextIds)
      ..sort((a, b) => b.compareTo(a));
    for (final id in sortedTextIds) {
      if (id >= 0 && id < textDrawables.length) {
        textDrawables.removeAt(id);
      }
    }

    final updatedScribble = Scribble(
      strokes: strokes,
      width: currentScribble.width,
      height: currentScribble.height,
      x: currentScribble.x,
      y: currentScribble.y,
      textDrawables: textDrawables,
      createdAt: currentScribble.createdAt,
      updatedAt: currentScribble.updatedAt,
      version: currentScribble.version,
    );

    scribbleNotifier.setScribble(
      scribble: updatedScribble,
      addToUndoHistory: true,
    );

    // 선택 상태 초기화
    _selectedStrokeIds = [];
    _selectedTextIds = [];
    _originalTextStates = null;
    _lassoSelectionState = painter.LassoSelectionState();
    _showLassoOverlay = false;
    _isLassoTransforming = false;
    onStateChanged();
  }

  /// 크기조절/회전 시작
  void onResizeRotateStart(DragStartDetails details, BuildContext context) {
    if (_selectedStrokeIds.isEmpty && _selectedTextIds.isEmpty) {
      return;
    }

    // 🔥 변형 상태 활성화 (터치 입력 처리를 위해 필요)
    _isLassoTransforming = true;

    // 선택된 스트로크들의 원본 포인트 저장 (변환 전 상태)
    final strokes = scribbleNotifier.currentState.scribble.strokes;
    _originalStrokePoints = _selectedStrokeIds
        .map(
          (id) => strokes[id].points.map((pt) => Offset(pt.x, pt.y)).toList(),
        )
        .toList();

    // TransformHandler에도 원본 포인트 캐싱
    _transformHandler.cacheOriginalPoints(_originalStrokePoints!);

    // 원본 스트로크들로부터 직접 바운딩 박스 계산 (현재 변환된 상태)
    final box = _calculateBoundingBox(_selectedStrokeIds);

    // 현재 회전된 바운딩 박스가 있다면 그것을 기준으로, 없다면 새로 생성
    _originalOrientedBoundingBox =
        _lassoSelectionState.orientedBoundingBox ??
        painter.OrientedBoundingBox(
          center: box.center,
          width: box.width,
          height: box.height,
          rotation: 0.0,
        );

    // 🎯 터치와 버튼 간의 오프셋 저장 (버튼이 정확히 따라가도록)
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 터치 시작점 (화면 좌표)
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    _startTouchPoint = localPosition;

    // 변형 버튼 위치 (OrientedBoundingBox의 좌하단 corners[3])
    // localPosition(globalToLocal)은 InteractiveViewer 자식 내부의
    // 캔버스 좌표이므로, 버튼/중심 좌표도 캔버스 좌표 그대로 사용한다.
    // canvasToScreen으로 viewport 좌표를 섞으면 줌 배율 s≠1에서
    // 스케일이 1/s로 둔화되고 회전이 특정 각도에서 발산한다.
    final corners = _originalOrientedBoundingBox!.corners;
    final buttonPosition = corners[3]; // 좌하단 = 변형 버튼 위치 (캔버스 좌표)

    // ⭐ 터치 위치와 버튼 위치의 오프셋 저장 (점프 방지)
    _touchToButtonOffset = buttonPosition - localPosition;

    // TransformHandler로 크기조절/회전 시작 (캔버스 좌표 기준)
    _transformHandler.startResizeRotate(
      buttonPosition,
      _originalOrientedBoundingBox!.center,
      initialRotation: _originalOrientedBoundingBox!.rotation,
    );
  }

  /// 크기조절/회전 업데이트
  void onResizeRotateUpdate(DragUpdateDetails details, BuildContext context) {
    // 🔥 필수 변수들이 null인 경우 자동으로 초기화 (onPanStart 미호출 대응)
    if (_originalOrientedBoundingBox == null ||
        _startTouchPoint == null ||
        !_transformHandler.isResizeRotating) {
      // onResizeRotateStart와 동일한 초기화 로직 실행
      if (_selectedStrokeIds.isEmpty && _selectedTextIds.isEmpty) {
        return;
      }

      // 🔥 변형 상태 활성화
      _isLassoTransforming = true;

      // 🔥 이동 시와 동일한 방식으로 원본 스트로크 포인트 저장
      final strokes = scribbleNotifier.currentState.scribble.strokes;

      // 유효한 인덱스만 필터링
      final validStrokeIds = _selectedStrokeIds
          .where((id) => id >= 0 && id < strokes.length)
          .toList();

      if (validStrokeIds.isEmpty) {
        return;
      }

      // 유효한 인덱스로 업데이트
      _selectedStrokeIds = validStrokeIds;

      // 🎯 이동 시와 정확히 동일한 방식으로 원본 포인트 캐싱
      _cacheOriginalStrokePoints();

      // 원본 스트로크들로부터 직접 바운딩 박스 계산 (업데이트된 인덱스 사용)
      final box = _calculateBoundingBox(_selectedStrokeIds);

      // 현재 회전된 바운딩 박스가 있다면 그것을 기준으로, 없다면 새로 생성
      _originalOrientedBoundingBox =
          _lassoSelectionState.orientedBoundingBox ??
          painter.OrientedBoundingBox(
            center: box.center,
            width: box.width,
            height: box.height,
            rotation: 0.0,
          );

      // 🎯 터치와 버튼 간의 오프셋 저장 (자동 초기화)
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        return;
      }

      // 터치 시작점 (화면 좌표)
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      _startTouchPoint = localPosition;

      // 변형 버튼 위치 — 캔버스 좌표 그대로 사용 (onResizeRotateStart와 동일)
      final corners = _originalOrientedBoundingBox!.corners;
      final buttonPosition = corners[3]; // 좌하단

      // ⭐ 터치 위치와 버튼 위치의 오프셋 저장 (점프 방지)
      _touchToButtonOffset = buttonPosition - localPosition;

      // TransformHandler로 크기조절/회전 시작 (캔버스 좌표 기준)
      _transformHandler.startResizeRotate(
        buttonPosition,
        _originalOrientedBoundingBox!.center,
        initialRotation: _originalOrientedBoundingBox!.rotation,
      );
    }

    final originalBox = _originalOrientedBoundingBox!;
    final center = originalBox.center;

    // 🎯 터치에 오프셋을 적용하여 버튼이 있어야 할 위치 계산
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 현재 터치점 (화면 좌표)
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // ⭐ 터치 위치에 오프셋을 더해서 실제 버튼이 있어야 할 위치 계산
    final currentButtonPosition =
        localPosition + (_touchToButtonOffset ?? Offset.zero);

    // TransformHandler로 스케일/회전 계산
    final result = _transformHandler.computeResizeRotate(currentButtonPosition);
    final scale = result.scale;

    // 🎯 텍스트 방식: 기존회전 + 상대회전
    final originalRotation = originalBox.rotation;
    final finalRotation = originalRotation + result.deltaAngle;

    final newOrientedBox = painter.OrientedBoundingBox(
      center: center, // 중심점 고정
      width: originalBox.width * scale,
      height: originalBox.height * scale,
      rotation: finalRotation, // 기존 + 상대 회전
    );

    // 라쏘 선택 상태 업데이트 (일반 바운딩 박스는 원본 유지)
    _lassoSelectionState = _lassoSelectionState.copyWith(
      orientedBoundingBox: newOrientedBox,
    );

    // 스트로크 + 텍스트 변환 적용
    final hasStrokes =
        _originalStrokePoints != null && _selectedStrokeIds.isNotEmpty;
    final hasTexts = _originalTextStates != null && _selectedTextIds.isNotEmpty;
    if (hasStrokes || hasTexts) {
      final currentScribble = scribbleNotifier.currentState.scribble;
      final strokes = List<Stroke>.from(currentScribble.strokes);
      final textDrawables = List<TextDrawable>.from(
        currentScribble.textDrawables,
      );

      // 스트로크 변환 — 캐시(_originalStrokePoints)는 이미 기존 회전이
      // 반영된 현재 상태이므로, 텍스트 경로와 동일하게 이번 제스처의 순수
      // 변화량(deltaAngle)만 적용한다. finalRotation을 적용하면 두 번째
      // 제스처부터 기존 회전이 이중으로 적용된다(2Δ1+Δ2).
      if (hasStrokes) {
        final transformedGroups = _transformHandler.applyResizeRotate(
          _originalStrokePoints!,
          center: center,
          scale: scale,
          rotation: result.deltaAngle,
        );

        for (int i = 0; i < _selectedStrokeIds.length; i++) {
          final strokeId = _selectedStrokeIds[i];
          if (strokeId >= 0 &&
              strokeId < strokes.length &&
              i < transformedGroups.length) {
            final stroke = strokes[strokeId];
            final transformedPoints = transformedGroups[i];

            for (
              int j = 0;
              j < stroke.points.length && j < transformedPoints.length;
              j++
            ) {
              final transformedPoint = transformedPoints[j];
              stroke.points[j].x = transformedPoint.dx;
              stroke.points[j].y = transformedPoint.dy;
            }
          }
        }
      }

      // 텍스트 변환:
      //  - 위치: 원본 - center → scale → rotate(deltaAngle) → + center
      //  - fontSize: 원본 * scale (8~72 클램프, 단일 텍스트 변형과 동일)
      //  - rotation: 원본 + deltaAngle
      if (hasTexts) {
        final dCos = math.cos(result.deltaAngle);
        final dSin = math.sin(result.deltaAngle);

        for (int i = 0; i < _selectedTextIds.length; i++) {
          final textId = _selectedTextIds[i];
          if (textId < 0 ||
              textId >= textDrawables.length ||
              i >= _originalTextStates!.length) {
            continue;
          }
          final orig = _originalTextStates![i];

          final relX = orig.position.dx - center.dx;
          final relY = orig.position.dy - center.dy;
          final scaledX = relX * scale;
          final scaledY = relY * scale;
          final rotX = scaledX * dCos - scaledY * dSin;
          final rotY = scaledX * dSin + scaledY * dCos;
          final newPosition = Offset(center.dx + rotX, center.dy + rotY);
          final newFontSize = (orig.fontSize * scale).clamp(8.0, 72.0);
          final newRotation = orig.rotation + result.deltaAngle;

          // 적용
          final t = textDrawables[textId];
          final newStyle = t.style.copyWith(fontSize: newFontSize);
          var updated = t.copyWithStyle(newStyle).copyWithPosition(newPosition);
          try {
            updated.rotation = newRotation;
          } on Exception {
            // rotation 필드 미지원 시 무시
          }
          textDrawables[textId] = updated;
        }
      }

      // 스크리블 업데이트
      final newScribble = currentScribble.copyWithContents(
        strokes: strokes,
        textDrawables: textDrawables,
      );

      scribbleNotifier.setScribble(
        scribble: newScribble,
        addToUndoHistory: false,
      );
    }

    // UI 업데이트
    onStateChanged();
  }

  /// 크기조절/회전 종료
  void onResizeRotateEnd(DragEndDetails details) {
    // 🔥 변형 상태 해제
    _isLassoTransforming = false;

    // 터치 오프셋 초기화
    _touchToButtonOffset = null;

    // 최종 변환 완료 - 히스토리에 저장
    if (_selectedStrokeIds.isNotEmpty) {
      final currentScribble = scribbleNotifier.currentState.scribble;
      scribbleNotifier.setScribble(
        scribble: currentScribble,
        addToUndoHistory: true,
      );

      // 🔥 변형 완료 후 바운딩 박스 업데이트 (오버레이가 올바른 위치에서 움직이도록)
      final updatedBoundingBox = _calculateBoundingBox(_selectedStrokeIds);

      _lassoSelectionState = _lassoSelectionState.copyWith(
        boundingBox: updatedBoundingBox,
      );
    }

    // TransformHandler 크기조절/회전 상태 종료
    _transformHandler.endResizeRotate();

    // 상태 초기화 (텍스트 방식: 변형 완료 후에는 현재 회전 유지)
    _originalOrientedBoundingBox = null;
    _startTouchPoint = null;

    // 🔥 변형된 스트로크들의 현재 포인트를 다시 캐싱 (이동 시 정확한 기준점 확보)
    // 주의: _originalStrokePoints는 초기화하지 않고 새로운 값으로 업데이트
    if (_selectedStrokeIds.isNotEmpty) {
      _cacheOriginalStrokePoints();
    }
  }

  /// 이동 시작 (박스 드래그 시작)
  void onMoveStart(DragStartDetails details, BuildContext context) {
    // 🎯 Listener 로컬 좌표 사용
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 로컬 좌표
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // 🔄 박스 없을 때와 동일한 변수 사용 (완전 통합)
    _lastTransformPosition = localPosition;
    _isLassoTransforming = true;

    // TransformHandler로 이동 시작
    _transformHandler.startMove(localPosition);

    // 현재 선택된 스트로크들의 원본 좌표 저장
    _cacheOriginalStrokePoints();
    onStateChanged();
  }

  /// 이동 업데이트 (박스 드래그 중)
  void onMoveUpdate(DragUpdateDetails details, BuildContext context) {
    // 🔄 박스 없을 때와 동일한 체크 (통합)
    // 스트로크 또는 텍스트 중 하나라도 선택돼 있으면 진행
    final hasStrokesCached =
        _selectedStrokeIds.isNotEmpty && _originalStrokePoints != null;
    final hasTextsCached =
        _selectedTextIds.isNotEmpty && _originalTextStates != null;
    if (_lastTransformPosition == null ||
        (!hasStrokesCached && !hasTextsCached)) {
      return;
    }

    // 🎯 박스 없을 때와 동일: Listener 로컬 좌표 사용
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Listener와 동일한 로컬 좌표 획득
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // TransformHandler로 delta 계산
    final delta = _transformHandler.getMoveDeleta(localPosition);
    if (delta == null) return;

    // 원본 위치에서 델타만큼 이동
    _moveSelectedStrokesFromOriginal(delta);
  }

  /// 이동 종료
  void onMoveEnd(DragEndDetails details) {
    _isLassoTransforming = false;

    // TransformHandler 이동 상태 종료
    _transformHandler.endMove();

    // 최종 변경사항을 히스토리에 저장
    if (_selectedStrokeIds.isNotEmpty) {
      final currentScribble = scribbleNotifier.currentState.scribble;
      scribbleNotifier.setScribble(
        scribble: currentScribble,
        addToUndoHistory: true,
      );
    }

    // 바운딩 박스 업데이트
    _updateBoundingBox();
    onStateChanged();
  }

  /// 터치 상태 정리 헬퍼 메서드
  void _cleanupTouchState() {
    _lastLassoTapDownTime = null;
    _lassoTapMoved = false;
    _lastTransformPosition = null;
  }

  /// 바운딩 박스 계산 메서드 (선택된 스트로크 + 텍스트 영역 모두 포함)
  Rect _calculateBoundingBox(List<int> strokeIds) {
    final scribble = scribbleNotifier.currentState.scribble;
    final strokes = scribble.strokes;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    // 선택된 스트로크들의 모든 포인트를 검사하여 바운딩 박스 계산
    for (final id in strokeIds) {
      if (id >= 0 && id < strokes.length) {
        final stroke = strokes[id];

        // 🔥 올가미 스트로크는 바운딩 박스 계산에서 제외
        if (stroke.ink == InkModes.lasso) {
          continue;
        }

        for (final point in stroke.points) {
          minX = math.min(minX, point.x);
          minY = math.min(minY, point.y);
          maxX = math.max(maxX, point.x);
          maxY = math.max(maxY, point.y);
        }
      }
    }

    // 선택된 텍스트의 bounds도 포함
    final textDrawables = scribble.textDrawables;
    for (final id in _selectedTextIds) {
      if (id < 0 || id >= textDrawables.length) continue;
      final bounds = _calculateTextBounds(textDrawables[id]);
      if (bounds == Rect.zero) continue;
      minX = math.min(minX, bounds.left);
      minY = math.min(minY, bounds.top);
      maxX = math.max(maxX, bounds.right);
      maxY = math.max(maxY, bounds.bottom);
    }

    // 유효한 요소가 하나도 없으면 빈 영역
    if (minX == double.infinity) return Rect.zero;

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 텍스트의 axis-aligned bounds 계산 (회전 고려해 외접 사각형)
  Rect _calculateTextBounds(TextDrawable textDrawable) {
    final textSpan = TextSpan(
      text: textDrawable.text,
      style: textDrawable.style,
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: textDrawable.alignment.textAlign,
      textDirection: TextDirection.ltr,
    )..layout();

    final center = textDrawable.position;
    final halfW = tp.width / 2;
    final halfH = tp.height / 2;
    double rotation = 0.0;
    try {
      rotation = textDrawable.rotation;
    } on Exception {
      rotation = 0.0;
    }

    if (rotation == 0.0) {
      return Rect.fromLTWH(
        center.dx - halfW,
        center.dy - halfH,
        tp.width,
        tp.height,
      );
    }

    // 회전된 텍스트의 4개 모서리를 회전시켜 외접 axis-aligned bounds 계산
    final corners = [
      Offset(-halfW, -halfH),
      Offset(halfW, -halfH),
      Offset(halfW, halfH),
      Offset(-halfW, halfH),
    ];
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final c in corners) {
      final x = center.dx + c.dx * cos - c.dy * sin;
      final y = center.dy + c.dx * sin + c.dy * cos;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 컨트롤 영역 터치 처리 메서드
  bool? _handleControlAreaTouch(
    Offset position,
    Rect boundingBox,
    BuildContext context,
  ) {
    const buttonSize = 28.0; // 70% 축소 (기존 40)
    const extraPadding = 4.0;

    // 🎯 다른 메서드들과 동일한 좌표 변환 방식 사용
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    Offset localPosition = position;

    // transformationController가 있고 스케일이 1.0이 아닌 경우 추가 변환
    if (currentScale != 1.0) {
      localPosition = _transformer.canvasToLocal(localPosition);
    }

    final scale = currentScale;
    final scaledButtonSize = (buttonSize + extraPadding * 2) / scale;
    final adjustedPosition = localPosition;

    // 버튼 위치 계산
    Offset deleteButtonCenter;
    Offset resizeButtonCenter;

    final orientedBox = _lassoSelectionState.orientedBoundingBox;
    if (orientedBox != null && orientedBox.corners.length >= 4) {
      deleteButtonCenter = orientedBox.corners[1]; // 우상단
      resizeButtonCenter = orientedBox.corners[3]; // 좌하단
    } else {
      deleteButtonCenter = Offset(
        boundingBox.right - buttonSize / (2 * scale),
        boundingBox.top - buttonSize / (2 * scale),
      );
      resizeButtonCenter = Offset(
        boundingBox.left - buttonSize / (2 * scale),
        boundingBox.bottom - buttonSize / (2 * scale),
      );
    }

    // 버튼 영역 생성
    final deleteButtonRect = Rect.fromCenter(
      center: deleteButtonCenter,
      width: scaledButtonSize,
      height: scaledButtonSize,
    );
    final resizeButtonRect = Rect.fromCenter(
      center: resizeButtonCenter,
      width: scaledButtonSize,
      height: scaledButtonSize,
    );

    // 삭제 버튼 터치
    if (deleteButtonRect.contains(adjustedPosition)) {
      removeSelectedStrokes(_selectedStrokeIds);
      return true; // 이벤트 처리 완료
    }

    // 크기조정 버튼 터치 - 현재는 터치만 감지하고 실제 크기조정은 드래그에서 처리
    if (resizeButtonRect.contains(adjustedPosition)) {
      return true; // 이벤트 처리 완료 (올가미 그리기 방지)
    }

    return null; // 컨트롤 영역이 아님
  }

  /// [position]이 기존 이미지 드로어블(회전 포함) 위에 있는지 확인
  bool _isPointerOverExistingImage(Offset position) {
    final images = scribbleNotifier.getCurrentImageDrawables();
    if (images.isEmpty) return false;
    for (final image in images) {
      if (!image.hidden && image.containsPoint(position)) {
        return true;
      }
    }
    return false;
  }

  /// 포인트가 폴리곤 내에 있는지 확인하는 메서드 (Ray Casting 알고리즘)
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    bool isInside = false;
    final x = point.dx;
    final y = point.dy;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      final intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) isInside = !isInside;
    }

    return isInside;
  }

  /// 스트로크의 연속 점 쌍 선분이 올가미 폴리곤의 변과 교차하는지 판정
  bool _strokeEdgesIntersectPolygon(List<Point> points, List<Offset> polygon) {
    if (points.length < 2 || polygon.length < 2) return false;

    for (int i = 0; i < points.length - 1; i++) {
      final start = Offset(points[i].x, points[i].y);
      final end = Offset(points[i + 1].x, points[i + 1].y);

      for (int j = 0; j < polygon.length - 1; j++) {
        if (_doSegmentsIntersect(start, end, polygon[j], polygon[j + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  /// 두 선분 [p1]-[p2], [q1]-[q2]가 교차하는지 판정
  bool _doSegmentsIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    final d1x = p2.dx - p1.dx;
    final d1y = p2.dy - p1.dy;
    final d2x = q2.dx - q1.dx;
    final d2y = q2.dy - q1.dy;

    final cross = d1x * d2y - d1y * d2x;
    if (cross == 0) return false; // 평행

    final t = ((q1.dx - p1.dx) * d2y - (q1.dy - p1.dy) * d2x) / cross;
    final u = ((q1.dx - p1.dx) * d1y - (q1.dy - p1.dy) * d1x) / cross;

    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  /// 올가미 영역 내의 스트로크 ID와 텍스트 ID 찾기 (좌표계 통일)
  (List<int> strokeIds, List<int> textIds) _findElementsInLasso(
    List<Offset> lassoPoints,
  ) {
    if (lassoPoints.length < 3) {
      return ([], []);
    }

    // 🔥 scribble-tools 방식: 올가미 포인트도 원본 좌표 직접 사용 (드로잉과 동일)
    final polygon = List<Offset>.from(lassoPoints);

    // 폴리곤 닫기
    if (polygon.isNotEmpty && polygon.first != polygon.last) {
      polygon.add(polygon.first);
    }

    if (polygon.isNotEmpty) {}

    final List<int> strokeIds = [];
    final List<int> textIds = [];
    final currentScribble = scribbleNotifier.currentState.scribble;

    // 스트로크 검색 (좌표계 통일)
    final strokes = currentScribble.strokes;

    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];

      // 올가미 스트로크는 무시
      if (stroke.ink == InkModes.lasso) {
        continue;
      }

      // 각 스트로크의 포인트 중 일부가 올가미 내에 있는지 확인
      bool hasPointsInside = false;
      int checkedPoints = 0;

      for (final point in stroke.points) {
        // ✅ 스트로크 포인트는 원본 좌표 - 원본 올가미 polygon과 직접 비교 (드로잉과 동일)
        final strokeOffset = Offset(point.x, point.y);

        checkedPoints++;

        if (_isPointInPolygon(strokeOffset, polygon)) {
          hasPointsInside = true;
        } else {
          if (checkedPoints <= 3) {
            // 처음 몇 개만 로그
          }
        }

        // 성능을 위해 처음 몇 개 포인트만 체크
        if (hasPointsInside && checkedPoints >= 5) {
          break;
        }
      }

      // 도형 변환/정지 직선화 스트로크는 점이 희소해(직선 2점, 다각형은
      // 코너만) 변 중간만 올가미로 감싸면 내부 점이 없다. 점 쌍 선분과
      // 올가미 변의 교차 검사로 보완한다.
      if (!hasPointsInside) {
        hasPointsInside = _strokeEdgesIntersectPolygon(stroke.points, polygon);
      }

      if (hasPointsInside) {
        strokeIds.add(i);
      }
    }

    // 텍스트 검색
    final textDrawables = currentScribble.textDrawables;
    for (int i = 0; i < textDrawables.length; i++) {
      final textDrawable = textDrawables[i];

      // 텍스트의 중심점이 올가미 내에 있는지 확인
      final textCenter = Offset(textDrawable.x, textDrawable.y);
      if (_isPointInPolygon(textCenter, polygon)) {
        textIds.add(i);
      }
    }
    return (strokeIds, textIds);
  }

  /// 올가미 스트로크 찾기
  (Stroke? stroke, int index) _findLatestLassoStrokeWithIndex(
    Scribble scribble,
  ) {
    for (int i = scribble.strokes.length - 1; i >= 0; i--) {
      final stroke = scribble.strokes[i];
      if (stroke.ink == InkModes.lasso) {
        return (stroke, i);
      }
    }
    return (null, -1);
  }

  /// 원본 위치에서 델타만큼 이동 (누적 이동 방지 - 텍스트 방식과 동일)
  void _moveSelectedStrokesFromOriginal(Offset delta) {
    final hasStrokes =
        _originalStrokePoints != null && _selectedStrokeIds.isNotEmpty;
    final hasTexts = _originalTextStates != null && _selectedTextIds.isNotEmpty;
    if (!hasStrokes && !hasTexts) return;

    final currentScribble = scribbleNotifier.currentState.scribble;
    final strokes = List<Stroke>.from(currentScribble.strokes);

    // 원본 스트로크 위치에서 델타만큼 이동
    if (hasStrokes) {
      for (int i = 0; i < _selectedStrokeIds.length; i++) {
        final strokeId = _selectedStrokeIds[i];
        if (strokeId >= 0 &&
            strokeId < strokes.length &&
            i < _originalStrokePoints!.length) {
          final stroke = strokes[strokeId];
          final originalPoints = _originalStrokePoints![i];

          for (
            int j = 0;
            j < stroke.points.length && j < originalPoints.length;
            j++
          ) {
            final originalPoint = originalPoints[j];
            stroke.points[j].x = originalPoint.dx + delta.dx;
            stroke.points[j].y = originalPoint.dy + delta.dy;
          }
        }
      }
    }

    // 텍스트도 원본 위치에서 델타만큼 이동
    final textDrawables = List<TextDrawable>.from(
      currentScribble.textDrawables,
    );
    if (hasTexts) {
      for (int i = 0; i < _selectedTextIds.length; i++) {
        final textId = _selectedTextIds[i];
        if (textId < 0 ||
            textId >= textDrawables.length ||
            i >= _originalTextStates!.length) {
          continue;
        }
        final orig = _originalTextStates![i];
        final newPos = Offset(
          orig.position.dx + delta.dx,
          orig.position.dy + delta.dy,
        );
        textDrawables[textId] = textDrawables[textId].copyWithPosition(newPos);
      }
    }

    // 스크리블 업데이트 (히스토리에 저장하지 않음 - 드래그 중)
    final updatedScribble = currentScribble.copyWithContents(
      touchUpdatedAt: false,
      strokes: strokes,
      textDrawables: textDrawables,
    );
    scribbleNotifier.setScribble(
      scribble: updatedScribble,
      addToUndoHistory: false,
    );

    // 바운딩 박스 업데이트
    final newBoundingBox = _calculateBoundingBox(_selectedStrokeIds);

    // 🔥 orientedBoundingBox도 함께 업데이트 (변형 버튼 위치 정확성 보장)
    final currentOrientedBox = _lassoSelectionState.orientedBoundingBox;
    painter.OrientedBoundingBox? newOrientedBox;

    if (currentOrientedBox != null &&
        _lassoSelectionState.boundingBox != null) {
      // 기존 orientedBoundingBox가 있으면 이동된 위치로 업데이트
      final deltaX =
          newBoundingBox.center.dx -
          _lassoSelectionState.boundingBox!.center.dx;
      final deltaY =
          newBoundingBox.center.dy -
          _lassoSelectionState.boundingBox!.center.dy;

      newOrientedBox = painter.OrientedBoundingBox(
        center: Offset(
          currentOrientedBox.center.dx + deltaX,
          currentOrientedBox.center.dy + deltaY,
        ),
        width: currentOrientedBox.width,
        height: currentOrientedBox.height,
        rotation: currentOrientedBox.rotation,
      );
    }

    _lassoSelectionState = _lassoSelectionState.copyWith(
      isTransforming: true,
      operation: painter.TransformOperation.move,
      boundingBox: newBoundingBox,
      orientedBoundingBox: newOrientedBox,
    );
    onStateChanged();
  }

  void _resetLassoState() {
    _selectedStrokeIds = [];
    _selectedTextIds = [];
    _originalTextStates = null;
    _lassoSelectionState = painter.LassoSelectionState();
    _isLassoTransforming = false; // 올가미 변형 상태도 초기화
  }

  /// 원본 스트로크 포인트 + 텍스트 상태 캐싱 (변형 시 누적 방지)
  void _cacheOriginalStrokePoints() {
    // 🛡️ 히스토리 스냅샷 보호 (copy-on-write):
    // undo 히스토리는 상태를 참조로 보관하므로, 변형 중 protobuf Point를
    // 제자리(in-place) 수정하면 과거 모든 스냅샷의 좌표가 함께 바뀌어
    // undo가 원위치를 복원하지 못한다. 제스처 시작 시 깊은 복사본으로
    // 교체해 이후 in-place 수정이 히스토리와 분리되도록 한다.
    final current = scribbleNotifier.currentState.scribble;
    scribbleNotifier.setScribble(
      scribble: current.deepCopy(),
      addToUndoHistory: false,
    );

    final scribble = scribbleNotifier.currentState.scribble;

    // 스트로크 캐싱
    final strokes = scribble.strokes;
    _originalStrokePoints = [];
    for (final id in _selectedStrokeIds) {
      if (id >= 0 && id < strokes.length) {
        final stroke = strokes[id];
        final points = stroke.points.map((pt) => Offset(pt.x, pt.y)).toList();
        _originalStrokePoints!.add(points);
      }
    }

    // 텍스트 캐싱
    final textDrawables = scribble.textDrawables;
    _originalTextStates = [];
    for (final id in _selectedTextIds) {
      if (id < 0 || id >= textDrawables.length) continue;
      final t = textDrawables[id];
      double rot = 0.0;
      try {
        rot = t.rotation;
      } on Exception {
        rot = 0.0;
      }
      _originalTextStates!.add(
        _OriginalTextState(
          position: t.position,
          fontSize: t.style.fontSize ?? 16.0,
          rotation: rot,
        ),
      );
    }

    // TransformHandler에도 원본 포인트 캐싱
    _transformHandler.cacheOriginalPoints(_originalStrokePoints!);
  }

  /// 바운딩 박스 업데이트
  void _updateBoundingBox() {
    if (_selectedStrokeIds.isEmpty) return;

    final newBoundingBox = _calculateBoundingBox(_selectedStrokeIds);
    _lassoSelectionState = _lassoSelectionState.copyWith(
      boundingBox: newBoundingBox,
    );
  }

  /// 🔧 새 터치 시작 시 기존 올가미 스트로크 정리 (매번 자동 정리)
  void _cleanupExistingLassoStrokes() {
    final currentScribble = scribbleNotifier.currentState.scribble;
    final strokes = List<Stroke>.from(currentScribble.strokes);
    strokes.removeWhere((stroke) => stroke.ink == InkModes.lasso);

    final updatedScribble = currentScribble.copyWithContents(
      touchUpdatedAt: false,
      strokes: strokes,
    );

    scribbleNotifier.setScribble(
      scribble: updatedScribble,
      addToUndoHistory: false,
    );

    _selectedStrokeIds = [];
    _selectedTextIds = [];
    _originalTextStates = null;
    _lassoSelectionState = painter.LassoSelectionState();
    _showLassoOverlay = false;
    _isLassoTransforming = false;
    onStateChanged();
  }
}
