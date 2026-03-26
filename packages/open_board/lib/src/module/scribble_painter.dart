// 🎯 Dart imports:
// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:ui' as ui;

// 🐦 Flutter imports:

import 'package:flutter/material.dart';
// 🌎 Project imports:
import 'package:open_board/src/core/const.dart';
import 'package:open_board/src/core/utils/stroke_calculator.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;
// import 'package:open_board/src/core/utils/extensions/paint_extension/ex_paint.dart';

/// 핸들 위치 열거형
enum HandlePosition {
  none,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  rotation,
}

/// 변환 작업 종류
enum TransformOperation { none, move, rotate, resize }

/// 올가미 선택 상태를 관리하는 클래스
class LassoSelectionState {
  /// 올가미 경로 포인트
  final List<Offset> lassoPoints;

  /// 선택된 스트로크 ID 목록
  final List<int> selectedStrokeIds;

  /// 변환 매트릭스 (확대, 축소, 회전)
  final Matrix4 transformMatrix;

  /// 선택 영역의 경계 상자
  final Rect? boundingBox;

  /// 회전된 바운딩 박스
  final OrientedBoundingBox? orientedBoundingBox;

  /// 선택 모드 여부
  final bool isSelecting;

  /// 변환 모드 여부 (확대, 축소, 회전)
  final bool isTransforming;

  /// 현재 변환 작업 (이동, 회전, 크기 조절)
  final TransformOperation operation;

  LassoSelectionState({
    this.lassoPoints = const [],
    this.selectedStrokeIds = const [],
    Matrix4? transformMatrix,
    this.boundingBox,
    this.orientedBoundingBox,
    this.isSelecting = false,
    this.isTransforming = false,
    this.operation = TransformOperation.none,
  }) : transformMatrix = transformMatrix ?? Matrix4.identity();

  /// 새로운 상태를 생성하는 복사 메서드
  LassoSelectionState copyWith({
    List<Offset>? lassoPoints,
    List<int>? selectedStrokeIds,
    Matrix4? transformMatrix,
    Rect? boundingBox,
    OrientedBoundingBox? orientedBoundingBox,
    bool? isSelecting,
    bool? isTransforming,
    TransformOperation? operation,
  }) {
    return LassoSelectionState(
      lassoPoints: lassoPoints ?? this.lassoPoints,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      transformMatrix: transformMatrix ?? this.transformMatrix,
      boundingBox: boundingBox ?? this.boundingBox,
      orientedBoundingBox: orientedBoundingBox ?? this.orientedBoundingBox,
      isSelecting: isSelecting ?? this.isSelecting,
      isTransforming: isTransforming ?? this.isTransforming,
      operation: operation ?? this.operation,
    );
  }
}

class ScribblePainter extends CustomPainter with SketchLinePainter {
  ScribblePainter({
    required this.state,
    required this.modeState,
    required this.drawPointer,
    required this.drawEraser,
    required this.pressureFactor,
    required this.speedFactor,
    required this.minWidthFactor,
    this.repaint,
    this.background,
    this.isActiveLine = false,
    this.activeHandle = HandlePosition.none,
    this.selectedStrokeIds = const [],
    this.showLassoOverlay = false,
    this.lassoSelectionState,
    this.onLassoDelete,
    this.onLassoTransformStart,
    this.onLassoTransformUpdate,
    this.onLassoTransformEnd,
    this.onLassoMoveStart,
    this.onLassoMoveUpdate,
    this.onLassoMoveEnd,
  }) : super(repaint: repaint);
  final Listenable? repaint;
  final ui.Image? background;

  final double pressureFactor;
  final double speedFactor;
  final double minWidthFactor;

  final ScribbleState state;
  final ScribbleModeState modeState;
  final bool drawPointer;
  final bool drawEraser;
  final bool isActiveLine;
  final List<int> selectedStrokeIds;
  final bool showLassoOverlay;
  final LassoSelectionState? lassoSelectionState;

  // 올가미 오버레이 콜백 함수들
  final VoidCallback? onLassoDelete;
  final void Function(DragStartDetails)? onLassoTransformStart;
  final void Function(DragUpdateDetails)? onLassoTransformUpdate;
  final void Function(DragEndDetails)? onLassoTransformEnd;
  final void Function(DragStartDetails)? onLassoMoveStart;
  final void Function(DragUpdateDetails)? onLassoMoveUpdate;
  final void Function(DragEndDetails)? onLassoMoveEnd;

  final HandlePosition activeHandle;

  var vertices = <Offset>[];
  List<Stroke> get lines => state.lines;

  // 폐곡선 인식 임계값 (시작점과 끝점 사이 거리가 둘레의 15% 미만이면 폐곡선)
  final double _closedThreshold = 0.15;

  @override
  bool shouldRepaint(ScribblePainter oldDelegate) {
    // 🚀 성능 최적화: 실제 변경사항이 있을 때만 repaint
    return state != oldDelegate.state ||
        modeState != oldDelegate.modeState ||
        drawPointer != oldDelegate.drawPointer ||
        drawEraser != oldDelegate.drawEraser ||
        isActiveLine != oldDelegate.isActiveLine ||
        activeHandle != oldDelegate.activeHandle ||
        selectedStrokeIds != oldDelegate.selectedStrokeIds ||
        showLassoOverlay != oldDelegate.showLassoOverlay ||
        lassoSelectionState != oldDelegate.lassoSelectionState ||
        background != oldDelegate.background;
  }

  /// 세 점 사이의 각도를 계산 (degrees)
  /// [prev] 이전 점, [mid] 중간 점, [next] 다음 점
  double _cornerAngle(Point prev, Point mid, Point next) {
    // 벡터 계산
    final v1x = prev.x - mid.x;
    final v1y = prev.y - mid.y;
    final v2x = next.x - mid.x;
    final v2y = next.y - mid.y;

    // 내적 계산
    final dot = v1x * v2x + v1y * v2y;

    // 벡터 크기
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    // 영벡터 처리
    if (mag1 * mag2 == 0) return 180.0;

    // 코사인 값 계산 및 범위 제한
    double cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    // 라디안 -> 각도 변환
    final angleRad = math.acos(cosAngle);
    return angleRad * 180 / math.pi;
  }

  /// 모서리(코너) 감지 - 급격한 방향 변화가 있는 점 찾기
  List<int> _detectCorners(List<Point> points, {double minAngle = 60.0}) {
    if (points.length < 3) return [];

    final List<int> cornerIndices = [];
    final int n = points.length;

    // 각 점에서 각도 계산
    for (int i = 1; i < n - 1; i++) {
      double angle = _cornerAngle(points[i - 1], points[i], points[i + 1]);
      if (angle < minAngle) {
        cornerIndices.add(i);
        // 인접한 점이 모서리로 중복 감지되는 것 방지
        i += 1;
      }
    }

    // 시작점과 끝점이 연결된 경우, 그 지점의 각도도 체크
    if (n > 3) {
      double angleStart = _cornerAngle(points[n - 2], points[n - 1], points[0]);
      double angleEnd = _cornerAngle(points[n - 1], points[0], points[1]);

      if (angleStart < minAngle) cornerIndices.add(n - 1);
      if (angleEnd < minAngle) cornerIndices.add(0);
    }

    // 중복 제거 및 정렬
    return cornerIndices.toSet().toList()..sort();
  }

  /// 내각 계산 (라디안)
  double _calculateInteriorAngle(Point a, Point b, Point c) {
    // 벡터 계산
    final v1x = a.x - b.x;
    final v1y = a.y - b.y;
    final v2x = c.x - b.x;
    final v2y = c.y - b.y;

    // 내적 계산
    final dot = v1x * v2x + v1y * v2y;

    // 벡터 크기
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    // 영벡터 처리
    if (mag1 * mag2 == 0) return 0.0;

    // 코사인 값 계산 및 범위 제한
    double cosAngle = dot / (mag1 * mag2);
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    // 라디안 값 반환
    return math.acos(cosAngle);
  }

  /// 중심점 계산
  Point _calculateCentroid(List<Point> points) {
    if (points.isEmpty) return Point(x: 0, y: 0);

    double sumX = 0, sumY = 0;
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
    }
    return Point(x: sumX / points.length, y: sumY / points.length);
  }

  /// 두 점 사이의 거리 계산
  double _calculateDistance(Point p1, Point p2) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 폐곡선 여부 확인
  bool _isClosedShape(List<Point> points, double perimeter) {
    if (points.length < 3) return false;

    final firstLastDistance = _calculateDistance(points.first, points.last);
    return firstLastDistance < perimeter * _closedThreshold;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);

    if (!isActiveLine && background != null) {
      canvas.drawImageRect(
        background!,
        Rect.fromPoints(
          Offset.zero,
          Offset(background!.width.toDouble(), background!.height.toDouble()),
        ),
        Rect.fromPoints(
          Offset.zero,
          Offset(
            background!.width.toDouble() * maxScale,
            background!.height.toDouble() * maxScale,
          ),
        ),
        Paint(),
      );
    }

    if (isActiveLine) {
      if (state is Drawing && (state as Drawing).activeLine != null) {
        final line = (state as Drawing).activeLine!;
        switch (line.ink) {
          case "marker":
            _marker(canvas, line);
            break;
          case "pencil":
            _pencil(canvas, line);
            break;
          case "pen":
            _pen(canvas, line);
            break;
          case "lasso":
            _drawLassoLine(canvas, line);
            break;
          case "shape":
            // shape 타입일 때 shapeType에 따라 그리기
            if (line.shapeType == "pending") {
              // pending 상태일 때는 일반 스트로크로 그리기
              _pen(canvas, line);
            } else {
              // Paint 객체 생성 후 _drawShape 호출
              final paint = Paint()
                ..color = Color(line.color)
                ..strokeWidth = line.options.size
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke;
              _drawShape(canvas, paint, line);
            }
            break;
          case "erase":
            break;
        }
      }
    } else {
      // 올가미 스트로크 찾기
      Stroke? lassoStroke;
      final nonLassoStrokes = <Stroke>[];
      final Map<int, int> strokeIndexMap = {}; // 원래 인덱스를 저장하는 맵

      // 스트로크 분류
      for (int i = 0; i < state.scribble.strokes.length; i++) {
        final line = state.scribble.strokes[i];
        if (line.ink == "lasso") {
          // 가장 최근의 올가미 스트로크만 저장
          if (lassoStroke == null ||
              DateTime.parse(
                line.createdAt,
              ).isAfter(DateTime.parse(lassoStroke.createdAt))) {
            lassoStroke = line;
          }
        } else {
          nonLassoStrokes.add(line);
          strokeIndexMap[nonLassoStrokes.length - 1] = i; // 원래 인덱스 저장
        }
      }

      // 선택되지 않은 일반 스트로크 먼저 그리기
      for (int i = 0; i < nonLassoStrokes.length; i++) {
        final line = nonLassoStrokes[i];
        final originalIndex = strokeIndexMap[i];

        // 선택된 스트로크는 그리지 않음
        if (selectedStrokeIds.contains(originalIndex)) {
          continue;
        }

        // 도형 타입이 있는 경우 도형 그리기
        if (line.shapeType.isNotEmpty) {
          final paint = Paint()
            ..color = Color(line.color)
            ..strokeWidth = line.options.size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;
          _drawShape(canvas, paint, line);
        } else {
          // 일반 스트로크 그리기
          _drawStroke(canvas, line);
        }
      }

      // 선택된 스트로크 그리기 및 핸들 표시
      if (selectedStrokeIds.isNotEmpty) {
        _drawSelectedStrokes(canvas);
      }

      // 가장 최근의 올가미 스트로크만 그리기
      if (lassoStroke != null) {
        _drawLassoLine(canvas, lassoStroke);
      }

      // 올가미 오버레이 렌더링 (선택된 스트로크가 있고 오버레이 표시 중일 때)
      if (showLassoOverlay &&
          selectedStrokeIds.isNotEmpty &&
          lassoSelectionState != null) {
        _drawLassoOverlay(canvas);
      }
    }

    // 🎯 지우개 포인터 그리기 (지우개 모드일 때 항상 표시)
    if (state.pointerPosition != null && state is Erasing && drawEraser) {
      canvas.save();
      _pointer(canvas);
      canvas.restore();
    }
  }

  // 올가미 선택 라인 그리기
  void _drawLassoLine(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // 변환 중인지 확인 - 실제 올가미 선택 상태 확인
    bool isTransforming = false; // 기본값은 false

    // 현재 스트로크가 선택된 올가미 스트로크이고, 오버레이가 표시 중인 경우에만 변형 중으로 간주
    if (selectedStrokeIds.isNotEmpty && showLassoOverlay) {
      // 현재 올가미 스트로크의 인덱스 찾기
      final currentStrokeIndex = state.scribble.strokes.indexOf(stroke);
      if (currentStrokeIndex >= 0) {
        // 이 스트로크가 올가미 스트로크인지 확인 (ink가 "lasso"이고 가장 최근 스트로크)
        final lassoStrokes = state.scribble.strokes
            .where((stroke) => stroke.ink == "lasso")
            .toList();
        if (lassoStrokes.isNotEmpty && stroke == lassoStrokes.last) {
          isTransforming = true; // 오버레이 표시 중일 때 반투명 배경 표시
        }
      }
    }

    // 경로 생성
    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].x, stroke.points[i].y);
    }

    // 시작점과 연결하여 닫힌 경로 만들기
    if (stroke.points.length > 2 && !isActiveLine) {
      path.close();
    }

    // 내부 채우기용 페인트 - 변환 중(이동 중)일 때만 배경색 표시
    if (isTransforming && stroke.points.length > 2 && !isActiveLine) {
      final fillPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;

      // 내부 채우기
      canvas.drawPath(path, fillPaint);

      // 변환 중일 때도 점선으로 테두리 그리기
      final borderPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth =
            4.0 // 더 굵게 설정
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // 점선 패턴 설정 (굵은 선에 맞게 조정)
      final dashPattern = <double>[10.0, 6.0];
      _drawDashedPath(canvas, path, borderPaint, dashPattern);
    } else {
      // 일반 상태나 선택 중일 때는 점선으로 테두리만 그리기
      final strokePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth =
            4.0 // 더 굵게 설정
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final dashPattern = <double>[10.0, 6.0]; // 굵은 선에 맞게 조정
      _drawDashedPath(canvas, path, strokePaint, dashPattern);
    }
  }

  // 선택된 스트로크 그리기
  void _drawSelectedStrokes(Canvas canvas) {
    if (selectedStrokeIds.isEmpty) return;

    // 선택된 스트로크의 경계 상자 계산
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final selectedStrokes = <Stroke>[];

    // 선택된 스트로크 수집 및 경계 상자 계산
    for (final id in selectedStrokeIds) {
      if (id >= 0 && id < state.scribble.strokes.length) {
        final stroke = state.scribble.strokes[id];
        selectedStrokes.add(stroke);

        for (final point in stroke.points) {
          minX = math.min(minX, point.x);
          minY = math.min(minY, point.y);
          maxX = math.max(maxX, point.x);
          maxY = math.max(maxY, point.y);
        }
      }
    }

    if (selectedStrokes.isEmpty) return;

    // 선택된 스트로크 그리기
    canvas.save();

    // 선택된 스트로크 그리기
    for (final stroke in selectedStrokes) {
      // 도형 타입이 있는 경우 도형 그리기
      if (stroke.shapeType.isNotEmpty) {
        final paint = Paint()
          ..color = Color(stroke.color)
          ..strokeWidth = stroke.options.size
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        _drawShape(canvas, paint, stroke);
      } else {
        // 일반 스트로크 그리기
        _drawStroke(canvas, stroke);
      }
    }

    canvas.restore();
  }

  // 점선 경로 그리기
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dashPattern,
  ) {
    final dashLength = dashPattern[0];
    final dashSpace = dashPattern[1];

    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashLength : dashSpace;
        if (draw) {
          final extractPath = metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  // 올가미 오버레이 렌더링 (선택 버튼들)
  void _drawLassoOverlay(Canvas canvas) {
    if (lassoSelectionState?.boundingBox == null) return;

    final boundingBox = lassoSelectionState!.boundingBox!;
    const handleSize = 50.0; // 더 크게 설정
    const borderColor = Colors.blue;

    // 1. 바운딩 박스 테두리 그리기
    _drawBoundingBox(canvas, boundingBox, lassoSelectionState, borderColor);

    // 2. 버튼 위치 계산
    Offset deleteButtonPosition;
    Offset transformButtonPosition;

    if (lassoSelectionState?.orientedBoundingBox?.corners != null &&
        lassoSelectionState!.orientedBoundingBox!.corners.length >= 4) {
      // 회전된 올가미 박스의 경우: 실제 모서리 위치 사용
      final corners = lassoSelectionState!.orientedBoundingBox!.corners;
      deleteButtonPosition = corners[1]; // 우상단
      transformButtonPosition = corners[3]; // 좌하단
    } else {
      // 일반 박스의 경우: 기존 방식
      deleteButtonPosition = Offset(boundingBox.right, boundingBox.top);
      transformButtonPosition = Offset(boundingBox.left, boundingBox.bottom);
    }

    // 3. 삭제 버튼 (우상단)
    _drawOverlayButton(
      canvas,
      deleteButtonPosition,
      handleSize,
      Colors.red,
      Icons.delete,
    );

    // 4. 크기조절/회전 버튼 (좌하단)
    _drawOverlayButton(
      canvas,
      transformButtonPosition,
      handleSize,
      borderColor,
      Icons.transform,
    );
  }

  // 바운딩 박스 테두리 그리기
  void _drawBoundingBox(
    Canvas canvas,
    Rect boundingBox,
    LassoSelectionState? lassoState,
    Color borderColor,
  ) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 배경 채우기 (반투명)
    final fillPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // OrientedBoundingBox가 있으면 회전된 박스 그리기
    if (lassoState?.orientedBoundingBox?.corners != null &&
        lassoState!.orientedBoundingBox!.corners.length >= 4) {
      final corners = lassoState.orientedBoundingBox!.corners;

      // 회전된 박스의 경로 생성
      final path = Path();
      path.moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();

      // 회전된 박스 그리기
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, paint);
    } else {
      // 일반 사각형 박스 그리기
      canvas.drawRect(boundingBox, fillPaint);
      canvas.drawRect(boundingBox, paint);
    }
  }

  // 오버레이 버튼 그리기 (텍스트 오버레이와 동일한 스타일)
  void _drawOverlayButton(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
    IconData icon,
  ) {
    final center = position;
    final radius = size / 2;

    // 버튼 배경 원
    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 버튼 테두리
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);

    // 아이콘 그리기 (텍스트 오버레이와 동일한 스타일)
    if (icon == Icons.delete) {
      // X 표시 그리기
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      const iconSize = 12.0;
      canvas.drawLine(
        center + const Offset(-iconSize / 2, -iconSize / 2),
        center + const Offset(iconSize / 2, iconSize / 2),
        iconPaint,
      );
      canvas.drawLine(
        center + const Offset(iconSize / 2, -iconSize / 2),
        center + const Offset(-iconSize / 2, iconSize / 2),
        iconPaint,
      );
    } else if (icon == Icons.transform) {
      // 크기조절 화살표 아이콘 (텍스트 오버레이와 동일)
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      const arrowSize = 10.0;
      // 대각선 화살표 (↗)
      canvas.drawLine(
        center + const Offset(-arrowSize / 2, arrowSize / 2),
        center + const Offset(arrowSize / 2, -arrowSize / 2),
        iconPaint,
      );
      // 화살표 머리 (→)
      canvas.drawLine(
        center + const Offset(arrowSize / 2, -arrowSize / 2),
        center + const Offset(arrowSize / 2 - 4, -arrowSize / 2 + 2),
        iconPaint,
      );
      canvas.drawLine(
        center + const Offset(arrowSize / 2, -arrowSize / 2),
        center + const Offset(arrowSize / 2 - 2, -arrowSize / 2 + 4),
        iconPaint,
      );
    }
  }

  void _marker(Canvas canvas, Stroke stroke) {
    stroke.color = applyTransparencyToMarkerColorValue(stroke.color);

    // Default paint color
    Paint paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.options.size * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = getSimplePathForStroke(
      Stroke(
        points: stroke.points,
        color: stroke.color,
        ink: stroke.ink,
        createdAt: stroke.createdAt,
        options: StrokeOptions(
          size: stroke.options.size * 2,
          thinning: stroke.options.thinning,
          smoothing: stroke.options.smoothing,
          streamline: stroke.options.streamline,
          taperStart: stroke.options.taperStart,
          capStart: stroke.options.capStart,
          taperEnd: stroke.options.taperEnd,
          capEnd: stroke.options.capEnd,
          simulatePressure: stroke.options.simulatePressure,
          isComplete: stroke.options.isComplete,
        ),
      ),
    );
    if (path == null) {
      return;
    }
    canvas.drawPath(path, paint);
  }

  void _pencil(Canvas canvas, Stroke stroke) {
    // Shader
    Paint paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.options.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = getSimplePathForStroke(stroke);
    if (path == null) {
      return;
    }
    canvas.drawPath(path, paint);
  }

  void _pen(Canvas canvas, Stroke stroke) {
    // Default paint color
    Paint paint = Paint()
      ..color = Color(stroke.color)
      ..style = PaintingStyle.fill;
    final path = getPathForStrokeOld(stroke);
    if (path == null) {
      return;
    }
    canvas.drawPath(path, paint);
  }

  void _pointer(ui.Canvas canvas) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    // canvas.drawPath(path, paint);
    paint.style = switch (state) {
      Drawing() => PaintingStyle.fill,
      Erasing() => PaintingStyle.fill,
      _ => PaintingStyle.fill,
    };
    paint.color = switch (state) {
      Drawing() => modeState.inkGroupInfo.selectedColor,
      Erasing() => Colors.grey.withValues(alpha: 0.7),
      _ => Colors.grey.withValues(alpha: 0.7),
    };
    paint.strokeWidth = 1;

    // 🎯 지우개 모드일 때 두께에 맞는 크기로 포인터 그리기
    final radius = state is Erasing
        ? modeState
              .inkGroupInfo
              .seletedStrokeWidth // 지우개 두께 그대로 사용
        : modeState.options.size; // 일반 도구는 기존 방식

    canvas.drawCircle(
      Offset(state.pointerPosition!.x, state.pointerPosition!.y),
      radius,
      paint,
    );
  }

  // 스트로크 그리기 메서드
  void _drawStroke(Canvas canvas, Stroke stroke) {
    // shapeType이 있거나 ink가 "shape"인 경우 도형으로 처리
    if (stroke.shapeType.isNotEmpty && stroke.shapeType != "pending") {
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.options.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawShape(canvas, paint, stroke);
      return;
    }

    switch (stroke.ink) {
      case "pen":
        _pen(canvas, stroke);
        break;
      case "pencil":
        _pencil(canvas, stroke);
        break;
      case "marker":
        _marker(canvas, stroke);
        break;
      case "shape":
        // shape 타입인 경우 간단하게 선으로 처리
        _pen(canvas, stroke);
        break;
      case "lasso":
        _drawLassoLine(canvas, stroke);
        break;
      case "erase":
        break;
    }
  }

  // 도형 그리기 메서드
  void _drawShape(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 2) return;

    // 도형 타입에 따라 적절한 그리기 메서드 호출
    switch (stroke.shapeType) {
      case "line":
        // 선분의 경우 segments가 없거나 하나밖에 없어서 special case로 처리
        _drawLine(canvas, paint, stroke);
        break;
      case "circle":
      case "ellipse":
        // 원/타원의 경우도 segments가 아닌 특별한 방식으로 그려야 함
        _drawCircle(canvas, paint, stroke);
        break;
      case "polyline":
        _drawPolyline(canvas, paint, stroke);
      default:
        // 그 외 모든 도형 (삼각형, 사각형, 다각형 등)은 segments 정보로 그리기
        if (stroke.segments.isNotEmpty) {
          _drawPolygon(canvas, paint, stroke);

          // 도형 타입별 추가 정보 출력
          if (stroke.shapeType == "triangle" && stroke.segments.length >= 3) {
          } else if (stroke.shapeType == "rectangle" &&
              stroke.segments.length >= 4) {}
        }
        break;
    }
  }

  // 직선 그리기 메서드
  void _drawLine(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 2) return;

    // 실제 시작점과 끝점 가져오기
    final List<Point> points = stroke.points;
    final Point start = points.first;
    final Point end = points.last;

    // 직선 경로 그리기 - 중간 점들 없이 시작점과 끝점만 연결
    final path = Path();
    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);

    canvas.drawPath(path, paint);
  }

  // 원/타원 그리기 메서드
  void _drawCircle(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.length < 5) {
      // 점이 적은 경우 일반 폴리라인으로 처리
      _drawPolyline(canvas, paint, stroke);
      return;
    }

    // 중심점 계산
    final centroid = _calculateCentroid(stroke.points);

    // PCA를 사용한 타원 주축 분석
    double covXx = 0, covYy = 0, covXy = 0;
    for (final point in stroke.points) {
      final dx = point.x - centroid.x;
      final dy = point.y - centroid.y;
      covXx += dx * dx;
      covYy += dy * dy;
      covXy += dx * dy;
    }

    // 평균값으로 나누기
    covXx /= stroke.points.length;
    covYy /= stroke.points.length;
    covXy /= stroke.points.length;

    // 회전 각도 계산
    double angle = 0.0;
    if (!(covXx == covYy && covXy == 0.0)) {
      angle = 0.5 * math.atan2(2 * covXy, covXx - covYy);
    }

    // 고유값 계산 (2x2 행렬의 특성방정식 해)
    final trace = covXx + covYy;
    final det = covXx * covYy - covXy * covXy;
    final disc = math.sqrt(trace * trace - 4 * det);
    final eigenvalue1 = (trace + disc) / 2;
    final eigenvalue2 = (trace - disc) / 2;

    // 타원 반지름 계산 (고유값의 제곱근에 비례)
    final principalAxisLength = math.sqrt(math.max(eigenvalue1, 0));
    final secondaryAxisLength = math.sqrt(math.max(eigenvalue2, 0));
    final aspectRatio = principalAxisLength > 0
        ? secondaryAxisLength / principalAxisLength
        : 1.0;

    // 원에 가까운지 확인 (종횡비가 0.9 이상이면 거의 원형으로 간주)
    final isNearCircular = aspectRatio > 0.9;

    // Convex Hull에 기반한 실제 타원 크기 계산 (경계점까지의 거리 사용)
    double maxDistX = 0.0;
    double maxDistY = 0.0;

    // 각 점을 역회전하여 주축 방향으로 정렬된 좌표계에서 최대 거리 계산
    for (final point in stroke.points) {
      final dx = point.x - centroid.x;
      final dy = point.y - centroid.y;

      // 역회전으로 주축 정렬
      final cosA = math.cos(-angle);
      final sinA = math.sin(-angle);
      final rx = dx * cosA - dy * sinA;
      final ry = dx * sinA + dy * cosA;

      // 각 축 방향의 최대 거리 갱신
      maxDistX = math.max(maxDistX, rx.abs());
      maxDistY = math.max(maxDistY, ry.abs());
    }

    // 타원 반지름 계산 - 실제 경계점까지의 거리 활용 (PCA 결과와 결합)
    // 기존 계수 2.0을 1.2로 축소하고 실제 경계점 거리 반영
    final radiusX = isNearCircular
        ? math.max(maxDistX, maxDistY) // 원형일 경우 최대 반지름 사용
        : math.max(
            principalAxisLength * 1.2,
            maxDistX * 0.95,
          ); // 주축 길이와 실제 경계 사이 조정

    final radiusY = isNearCircular
        ? radiusX
        : math.max(
            secondaryAxisLength * 1.2,
            maxDistY * 0.95,
          ); // 부축 길이와 실제 경계 사이 조정

    // 원 또는 타원 그리기 - Path 대신 drawOval 사용하여 매끄러운 원 그리기
    canvas.save();
    canvas.translate(centroid.x, centroid.y);
    canvas.rotate(angle);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: radiusX * 2,
      height: radiusY * 2,
    );

    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  // 폴리곤 그리기 메서드
  void _drawPolygon(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = Path();

    // 선분 정보가 있는 경우 선분을 사용하여 그리기
    if (stroke.segments.isNotEmpty) {
      // 첫 번째 선분의 시작점으로 이동
      path.moveTo(stroke.segments[0].start.x, stroke.segments[0].start.y);

      // 각 선분의 시작점을 순서대로 연결
      for (final segment in stroke.segments) {
        path.lineTo(segment.start.x, segment.start.y);
      }

      // 폐곡선 완성
      if (stroke.segments.isNotEmpty) {
        path.lineTo(stroke.segments[0].start.x, stroke.segments[0].start.y);
      }
    } else {
      // 선분 정보가 없는 경우 점들을 직접 연결
      final points = stroke.points;
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
      // 폐곡선 완성
      path.lineTo(points[0].x, points[0].y);
    }

    canvas.drawPath(path, paint);
  }

  // 별 모양 감지 함수
  bool _detectStarShape(List<Point> points, Point centroid) {
    if (points.length < 5) return false; // 별은 최소 5개 이상의 꼭지점 필요

    // 모든 점에 대해 Convex Hull 계산
    List<Point> convexHull = _calculateConvexHull(points);

    // Convex Hull과 원본 도형의 면적 계산
    double originalArea = _calculatePolygonArea(points);
    double convexHullArea = _calculatePolygonArea(convexHull);

    // 면적 비율 계산 (별 모양은 면적 비율이 0.3~0.7 정도)
    if (convexHullArea <= 0) return false;
    double areaRatio = originalArea / convexHullArea;

    // 모서리 감지 - 별 모양은 날카로운 모서리가 많음
    final cornerIndices = _detectCorners(points, minAngle: 45.0);

    // 별 모양 조건:
    // 1. 면적 비율이 0.3~0.7 범위
    // 2. 꼭지점이 5개 이상
    // 3. 모서리가 5개 이상
    return (areaRatio >= 0.3 && areaRatio <= 0.7) &&
        (cornerIndices.length >= 5 && cornerIndices.length <= 10);
  }

  // 다각형 면적 계산 (Shoelace 공식)
  double _calculatePolygonArea(List<Point> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].x + points[i].x) * (points[j].y - points[i].y);
      j = i;
    }

    return area.abs() / 2.0;
  }

  // Convex Hull 계산 (Graham Scan 알고리즘)
  List<Point> _calculateConvexHull(List<Point> points) {
    if (points.length < 3) return List.from(points);

    // 기준점 찾기 (y가 가장 작은 점, 같다면 x가 가장 작은 점)
    Point pivot = points[0];
    for (int i = 1; i < points.length; i++) {
      if (points[i].y < pivot.y ||
          (points[i].y == pivot.y && points[i].x < pivot.x)) {
        pivot = points[i];
      }
    }

    // 기준점 기준으로 각도 정렬
    final sortedPoints = List<Point>.from(points);
    sortedPoints.remove(pivot);
    sortedPoints.sort((a, b) {
      double angleA = math.atan2(a.y - pivot.y, a.x - pivot.x);
      double angleB = math.atan2(b.y - pivot.y, b.x - pivot.x);

      if (angleA == angleB) {
        // 같은 각도면 거리가 가까운 점 먼저
        double distA =
            (a.x - pivot.x) * (a.x - pivot.x) +
            (a.y - pivot.y) * (a.y - pivot.y);
        double distB =
            (b.x - pivot.x) * (b.x - pivot.x) +
            (b.y - pivot.y) * (b.y - pivot.y);
        return distA.compareTo(distB);
      }

      return angleA.compareTo(angleB);
    });

    // Graham Scan 알고리즘
    List<Point> hull = [pivot];
    if (sortedPoints.isNotEmpty) {
      hull.add(sortedPoints[0]);
    }

    for (int i = 1; i < sortedPoints.length; i++) {
      while (hull.length > 1 &&
          !_isCounterClockwise(
            hull[hull.length - 2],
            hull[hull.length - 1],
            sortedPoints[i],
          )) {
        hull.removeLast();
      }
      hull.add(sortedPoints[i]);
    }

    return hull;
  }

  // 세 점이 반시계 방향인지 확인
  bool _isCounterClockwise(Point a, Point b, Point c) {
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0;
  }

  // Douglas-Peucker 알고리즘으로 점 단순화
  List<Point> _simplifyPoints(List<Point> points, double epsilon) {
    if (points.length <= 2) return List.from(points);

    // 시작점과 끝점 연결 직선에서 가장 먼 점 찾기
    final Point start = points.first;
    final Point end = points.last;

    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // 최대 거리가 임계값보다 크면 재귀적으로 단순화
    if (maxDistance > epsilon) {
      // 두 부분으로 나누어 단순화
      final List<Point> firstPart = _simplifyPoints(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final List<Point> secondPart = _simplifyPoints(
        points.sublist(maxIndex),
        epsilon,
      );

      // 결과 합치기 (중복 제거)
      return [...firstPart.sublist(0, firstPart.length - 1), ...secondPart];
    } else {
      // 단순화된 직선 반환
      return [start, end];
    }
  }

  // 점과 직선 사이의 수직 거리 계산
  double _perpendicularDistance(Point point, Point lineStart, Point lineEnd) {
    final double dx = lineEnd.x - lineStart.x;
    final double dy = lineEnd.y - lineStart.y;
    final double lineLengthSquared = dx * dx + dy * dy;

    if (lineLengthSquared == 0) {
      return _calculateDistance(point, lineStart);
    }

    // 점을 직선에 투영한 점의 파라미터 t 계산 (0 <= t <= 1 이면 선분 위)
    final double t =
        ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) /
        lineLengthSquared;

    // 투영점 계산
    double projX, projY;
    if (t < 0) {
      projX = lineStart.x;
      projY = lineStart.y;
    } else if (t > 1) {
      projX = lineEnd.x;
      projY = lineEnd.y;
    } else {
      projX = lineStart.x + t * dx;
      projY = lineStart.y + t * dy;
    }

    // 점과 투영점 사이의 거리 계산
    final double distX = point.x - projX;
    final double distY = point.y - projY;
    return math.sqrt(distX * distX + distY * distY);
  }

  // 점 회전 함수
  Point _rotatePoint(
    double x,
    double y,
    double cosTheta,
    double sinTheta,
    Point center,
  ) {
    final rotatedX = x * cosTheta - y * sinTheta + center.x;
    final rotatedY = x * sinTheta + y * cosTheta + center.y;
    return Point(x: rotatedX, y: rotatedY);
  }

  // 점들의 둘레 길이 계산
  double _calculatePerimeter(List<Point> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      perimeter += _calculateDistance(points[i], points[i + 1]);
    }

    // 닫힌 경로인 경우 시작점과 끝점 사이 거리도 추가
    perimeter += _calculateDistance(points.first, points.last);

    return perimeter;
  }

  // 폴리라인 그리기 메서드
  void _drawPolyline(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.color)
      ..strokeWidth = stroke.options.size
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // 선분 정보가 있는 경우 선분을 사용하여 그리기
    if (stroke.segments.isNotEmpty) {
      // 첫 번째 선분의 시작점으로 이동
      path.moveTo(stroke.segments[0].start.x, stroke.segments[0].start.y);

      // 각 선분의 끝점을 순서대로 연결
      for (final segment in stroke.segments) {
        path.lineTo(segment.end.x, segment.end.y);
      }
    } else {
      // 선분 정보가 없는 경우 점들을 직접 연결
      final points = stroke.points;
      path.moveTo(points[0].x, points[0].y);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].x, points[i].y);
      }
    }

    canvas.drawPath(path, paint);
  }

  // 직진성 평가 함수 개선
  double _evaluateLinearity(List<Point> points) {
    if (points.length < 3) return 1.0; // 점이 2개 이하면 완벽한 직선

    final first = points.first;
    final last = points.last;

    // 시작점과 끝점 사이 직선 벡터
    final dx = last.x - first.x;
    final dy = last.y - first.y;
    final lineLength = math.sqrt(dx * dx + dy * dy);

    if (lineLength < 0.001) return 0.0; // 너무 짧은 선은 직선성이 없다고 판단

    // 직선 벡터의 단위 벡터 계산
    final unitDx = dx / lineLength;
    final unitDy = dy / lineLength;

    // 총 편차와 최대 편차 계산
    double totalDeviation = 0.0;
    double maxDeviation = 0.0;

    // 각 점에서 직선까지의 수직 거리 계산
    for (int i = 1; i < points.length - 1; i++) {
      final p = points[i];

      // 점 p에서 직선에 내린 수직선의 발 계산
      final t =
          ((p.x - first.x) * unitDx + (p.y - first.y) * unitDy) / lineLength;

      // t값이 [0,1] 범위 내에 있으면 선분 위에 수직선의 발이 있음
      // 범위 밖이면 시작점이나 끝점까지의 거리 계산
      double distance;
      if (t < 0) {
        distance = math.sqrt(
          (p.x - first.x) * (p.x - first.x) + (p.y - first.y) * (p.y - first.y),
        );
      } else if (t > 1) {
        distance = math.sqrt(
          (p.x - last.x) * (p.x - last.x) + (p.y - last.y) * (p.y - last.y),
        );
      } else {
        // 직선 위의 점 계산
        final projX = first.x + t * lineLength * unitDx;
        final projY = first.y + t * lineLength * unitDy;

        // 수직 거리 계산
        distance = math.sqrt(
          (p.x - projX) * (p.x - projX) + (p.y - projY) * (p.y - projY),
        );
      }

      totalDeviation += distance;
      maxDeviation = math.max(maxDeviation, distance);
    }

    // 평균 편차 계산
    final avgDeviation = totalDeviation / (points.length - 2);

    // 직선 길이에 대한 상대적 편차로 직진성 점수 계산
    // 편차가 클수록 직진성이 낮음
    final relativeTotalDeviation = avgDeviation / lineLength;
    final relativeMaxDeviation = maxDeviation / lineLength;

    // 직진성 점수 (0~1, 1이 완벽한 직선)
    double linearityScore =
        1.0 -
        math.min(
          1.0,
          math.max(relativeTotalDeviation * 2, relativeMaxDeviation),
        );

    return linearityScore;
  }
}

mixin SketchLinePainter {
  Path? getSimplePathForStroke(Stroke stroke) {
    if (stroke.points.isEmpty) {
      return null;
    } else if (stroke.points.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(stroke.points[0].x, stroke.points[0].y),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(stroke.points[0].x, stroke.points[0].y);
      for (int i = 1; i < stroke.points.length - 1; ++i) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        path.quadraticBezierTo(
          p0.x,
          p0.y,
          (p0.x + p1.x) / 2,
          (p0.y + p1.y) / 2,
        );
      }
      return path;
    }
  }

  Path? getPathForStrokeOld(Stroke stroke, {double scaleFactor = 1.0}) {
    final outlinePoints = getStroke(stroke);
    if (outlinePoints.isEmpty) {
      return null;
    } else if (outlinePoints.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(outlinePoints[0].x, outlinePoints[0].y),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
      for (int i = 1; i < outlinePoints.length - 1; ++i) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(
          p0.x,
          p0.y,
          (p0.x + p1.x) / 2,
          (p0.y + p1.y) / 2,
        );
      }
      return path;
    }
  }

  Path? getPathForStroke(Stroke stroke, {double scaleFactor = 1.0}) {
    final points = stroke.points
        .map((point) => pf.Point(point.x, point.y, point.p))
        .toList();
    final outlinePoints = pf.getStroke(
      points,
      options: pf.StrokeOptions(
        size: stroke.options.size,
        thinning: stroke.options.thinning,
        smoothing: stroke.options.smoothing,
        streamline: stroke.options.streamline,
        start: pf.StrokeEndOptions.start(
          customTaper: stroke.options.taperStart,
          cap: stroke.options.capStart,
        ),
        end: pf.StrokeEndOptions.end(
          customTaper: stroke.options.taperEnd,
          cap: stroke.options.capEnd,
        ),
        simulatePressure: stroke.options.simulatePressure,
        isComplete: stroke.options.isComplete,
      ),
    );
    if (outlinePoints.isEmpty) {
      return null;
    } else if (outlinePoints.length < 2) {
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(outlinePoints[0].dx, outlinePoints[0].dy),
          radius: 1,
        ),
      );
    } else {
      final path = Path();
      path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
      for (int i = 1; i < outlinePoints.length - 1; ++i) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      return path;
    }
  }
}

// 회전된 바운딩 박스를 나타내는 클래스
class OrientedBoundingBox {
  final Offset center;
  final double width;
  final double height;
  final double rotation; // 라디안

  const OrientedBoundingBox({
    required this.center,
    required this.width,
    required this.height,
    required this.rotation,
  });

  // 4개의 모서리 점 계산
  List<Offset> get corners {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);

    return [
      // 좌상단
      Offset(
        center.dx + (-halfWidth * cos - (-halfHeight) * sin),
        center.dy + (-halfWidth * sin + (-halfHeight) * cos),
      ),
      // 우상단
      Offset(
        center.dx + (halfWidth * cos - (-halfHeight) * sin),
        center.dy + (halfWidth * sin + (-halfHeight) * cos),
      ),
      // 우하단
      Offset(
        center.dx + (halfWidth * cos - halfHeight * sin),
        center.dy + (halfWidth * sin + halfHeight * cos),
      ),
      // 좌하단
      Offset(
        center.dx + (-halfWidth * cos - halfHeight * sin),
        center.dy + (-halfWidth * sin + halfHeight * cos),
      ),
    ];
  }

  // 축에 정렬된 바운딩 박스로 변환 (UI 표시용)
  Rect get alignedBoundingBox {
    final cornerPoints = corners;
    double minX = cornerPoints.first.dx;
    double maxX = cornerPoints.first.dx;
    double minY = cornerPoints.first.dy;
    double maxY = cornerPoints.first.dy;

    for (final point in cornerPoints) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  OrientedBoundingBox copyWith({
    Offset? center,
    double? width,
    double? height,
    double? rotation,
  }) {
    return OrientedBoundingBox(
      center: center ?? this.center,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }
}
