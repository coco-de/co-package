  import 'package:open_board/open_board.dart';
  import 'dart:math' as math;
  import 'package:flutter/material.dart' show Rect;
  import 'package:fixnum/fixnum.dart' as fixnum; // 🔧 Int64 타입 처리용 import
  import 'package:flutter/foundation.dart' show debugPrint; // 🔧 디버그 출력용 import

  extension MergeScribble on Scribble {
    // 다른 필기데이터와 병합 처리
    // 가장 첫번째 좌표를 빼줘서 첫번째 좌표에 대한 상대 좌표들로 만들기
    /// 🔄 **Phase 5: 스트로크 분할/머지 시스템**
    ///
    /// 양면 모드에서 그린 필기를 단면 모드로 변환할 때 사용
    /// 페이지 경계를 넘나드는 스트로크를 각 페이지별로 분할
    ScribbleSplitResult splitStrokesForDoubleToSingleMode({
      required double pageWidth,
      required double pageHeight,
      required bool isFirstPageSingle,
    }) {
      final leftPageStrokes = <Stroke>[];
      final rightPageStrokes = <Stroke>[];
      final crossPageStrokes = <CrossPageStroke>[];

      // 페이지 경계 X 좌표 (화면 가로의 중앙)
      final pageBoundaryX = pageWidth / 2;

      for (int strokeIndex = 0; strokeIndex < strokes.length; strokeIndex++) {
        final stroke = strokes[strokeIndex];

        if (stroke.points.isEmpty) continue;

        // 스트로크의 경계 박스 계산
        final strokeBounds = _calculateStrokeBounds(stroke);

        // 페이지 경계를 넘나드는지 확인
        if (strokeBounds.left < pageBoundaryX &&
            strokeBounds.right > pageBoundaryX) {
          // 🔄 경계 넘나드는 스트로크: 분할 처리
          final splitResult = _splitStrokeAtBoundary(
            stroke,
            pageBoundaryX,
            strokeIndex,
          );

          if (splitResult.leftStroke != null) {
            leftPageStrokes.add(splitResult.leftStroke!);
          }
          if (splitResult.rightStroke != null) {
            rightPageStrokes.add(splitResult.rightStroke!);
          }

          crossPageStrokes.add(
            CrossPageStroke(
              leftStroke: splitResult.leftStroke,
              rightStroke: splitResult.rightStroke,
              boundaryX: pageBoundaryX,
            ),
          );
        } else if (strokeBounds.right <= pageBoundaryX) {
          // 🔄 왼쪽 페이지에만 속하는 스트로크
          leftPageStrokes.add(stroke);
        } else {
          // 🔄 오른쪽 페이지에만 속하는 스트로크
          // 오른쪽 페이지 좌표를 왼쪽 기준으로 변환
          final adjustedStroke = _adjustStrokeForRightPage(
            stroke,
            pageBoundaryX,
          );
          rightPageStrokes.add(adjustedStroke);
        }
      }

      return ScribbleSplitResult(
        leftPageScribble: _createScribbleFromStrokes(
          leftPageStrokes,
          pageWidth / 2,
          pageHeight,
        ),
        rightPageScribble: _createScribbleFromStrokes(
          rightPageStrokes,
          pageWidth / 2,
          pageHeight,
        ),
        crossPageStrokes: crossPageStrokes,
        originalPageBoundary: pageBoundaryX,
      );
    }

    /// 🔄 단면 모드에서 양면 모드로 변환할 때 분할된 스트로크를 다시 병합
    Scribble mergeFromSplitResult({
      required ScribbleSplitResult splitResult,
      required double targetPageWidth,
      required double targetPageHeight,
    }) {
      final mergedStrokes = <Stroke>[];

      // 왼쪽 페이지 스트로크 추가
      mergedStrokes.addAll(splitResult.leftPageScribble.strokes);

      // 오른쪽 페이지 스트로크를 원래 위치로 복원하여 추가
      for (final rightStroke in splitResult.rightPageScribble.strokes) {
        final restoredStroke = _restoreStrokeFromRightPage(
          rightStroke,
          splitResult.originalPageBoundary,
        );
        mergedStrokes.add(restoredStroke);
      }

      // 경계를 넘나들었던 스트로크들을 다시 병합
      for (final crossStroke in splitResult.crossPageStrokes) {
        if (crossStroke.leftStroke != null && crossStroke.rightStroke != null) {
          final mergedStroke = _mergeCrossPageStroke(
            crossStroke.leftStroke!,
            crossStroke.rightStroke!,
            crossStroke.boundaryX,
          );

          // 기존 분할된 스트로크들을 제거하고 병합된 스트로크 추가
          mergedStrokes.removeWhere(
            (stroke) =>
                _isSameStroke(stroke, crossStroke.leftStroke!) ||
                _isSameStroke(stroke, crossStroke.rightStroke!),
          );
          mergedStrokes.add(mergedStroke);
        }
      }

      // 중복 스트로크 제거
      final deduplicatedStrokes = _removeDuplicateStrokes(mergedStrokes);

      return _createScribbleFromStrokes(
        deduplicatedStrokes,
        targetPageWidth,
        targetPageHeight,
      );
    }

    /// 🔄 스트로크의 경계 박스 계산
    Rect _calculateStrokeBounds(Stroke stroke) {
      if (stroke.points.isEmpty) {
        return .zero;
      }

      double minX = stroke.points.first.x;
      double maxX = stroke.points.first.x;
      double minY = stroke.points.first.y;
      double maxY = stroke.points.first.y;

      for (final point in stroke.points) {
        minX = math.min(minX, point.x);
        maxX = math.max(maxX, point.x);
        minY = math.min(minY, point.y);
        maxY = math.max(maxY, point.y);
      }

      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    /// 🔄 페이지 경계에서 스트로크 분할 (개선된 버전)
    StrokeSplitResult _splitStrokeAtBoundary(
      Stroke originalStroke,
      double boundaryX,
      int originalIndex,
    ) {
      const double epsilon = 1e-6; // 🎯 경계 판정을 위한 허용 오차
      final leftPoints = <Point>[];
      final rightPoints = <Point>[];
      final addedIntersections = <int>{}; // 🚨 중복 교차점 방지

      for (int i = 0; i < originalStroke.points.length; i++) {
        final point = originalStroke.points[i];

        // 🎯 엡실론을 고려한 경계 판정
        if (point.x < boundaryX - epsilon) {
          leftPoints.add(point);
        } else if (point.x > boundaryX + epsilon) {
          rightPoints.add(point);
        } else {
          // 경계 근처의 점은 양쪽에 추가
          leftPoints.add(point);
          rightPoints.add(point);
        }

        // 경계를 가로지르는 선분이 있는지 확인
        if (i > 0 && !addedIntersections.contains(i)) {
          final prevPoint = originalStroke.points[i - 1];

          final prevOnLeft = prevPoint.x < boundaryX - epsilon;
          final prevOnRight = prevPoint.x > boundaryX + epsilon;
          final currOnLeft = point.x < boundaryX - epsilon;
          final currOnRight = point.x > boundaryX + epsilon;

          // 🔄 실제로 경계를 넘나드는 경우만 교차점 계산
          if ((prevOnLeft && currOnRight) || (prevOnRight && currOnLeft)) {
            // 경계와 교차하는 지점 계산
            final intersectionPoint = _calculateIntersectionPoint(
              prevPoint,
              point,
              boundaryX,
            );

            // 양쪽 페이지에 교차점 추가
            leftPoints.add(intersectionPoint);
            rightPoints.add(intersectionPoint);
            addedIntersections.add(i);
          }
        }
      }

      Stroke? leftStroke;
      Stroke? rightStroke;

      // 🎯 유효한 스트로크만 생성 (최소 2개 점 필요)
      if (leftPoints.length >= 2) {
        leftStroke = Stroke()
          ..points.addAll(leftPoints)
          ..ink = originalStroke.ink
          ..width = originalStroke.width
          ..color = originalStroke.color;
      }

      if (rightPoints.length >= 2) {
        rightStroke = Stroke()
          ..points.addAll(rightPoints)
          ..ink = originalStroke.ink
          ..width = originalStroke.width
          ..color = originalStroke.color;
      }

      return StrokeSplitResult(
        leftStroke: leftStroke,
        rightStroke: rightStroke,
      );
    }

    /// 🔄 두 점 사이에서 경계와의 교차점 계산 (안전한 버전)
    Point _calculateIntersectionPoint(Point p1, Point p2, double boundaryX) {
      const double epsilon = 1e-10;

      // 🚨 수직선 처리: 분모가 0에 가까운 경우
      if ((p2.x - p1.x).abs() < epsilon) {
        // 수직선인 경우, 중점의 Y 좌표 사용
        return Point()
          ..x = boundaryX
          ..y = (p1.y + p2.y) / 2
          ..p = (p1.p + p2.p) / 2
          ..altitude = (p1.altitude + p2.altitude) / 2
          ..azimuth = (p1.azimuth + p2.azimuth) / 2
          ..opacity = (p1.opacity + p2.opacity) / 2
          ..timestamp = _calculateTimestamp(p1, p2, 0.5); // 🔧 안전한 timestamp 계산
      }

      // 선형 보간을 사용하여 교차점 계산
      final t = (boundaryX - p1.x) / (p2.x - p1.x);
      final clampedT = t.clamp(0.0, 1.0); // 🎯 t를 [0,1] 범위로 제한

      return Point()
        ..x = boundaryX
        ..y = p1.y + clampedT * (p2.y - p1.y)
        ..p = p1.p + clampedT * (p2.p - p1.p)
        ..altitude = p1.altitude + clampedT * (p2.altitude - p1.altitude)
        ..azimuth = p1.azimuth + clampedT * (p2.azimuth - p1.azimuth)
        ..opacity = p1.opacity + clampedT * (p2.opacity - p1.opacity)
        ..timestamp = _calculateTimestamp(
          p1,
          p2,
          clampedT,
        ); // 🔧 안전한 timestamp 계산
    }

    /// 🔧 두 Point 사이의 timestamp를 안전하게 계산
    ///
    /// Int64 타입의 timestamp를 올바르게 처리합니다.
    /// [p1]: 첫 번째 포인트
    /// [p2]: 두 번째 포인트
    /// [t]: 보간 비율 (0.0~1.0)
    fixnum.Int64 _calculateTimestamp(Point p1, Point p2, double t) {
      // 🎯 timestamp가 없는 경우 현재 시간 사용
      if (!p1.hasTimestamp() || !p2.hasTimestamp()) {
        return fixnum.Int64(DateTime.now().millisecondsSinceEpoch);
      }

      // 🔧 Int64를 int로 변환해서 계산 후 다시 Int64로 변환
      try {
        final t1 = p1.timestamp.toInt();
        final t2 = p2.timestamp.toInt();

        // 선형 보간으로 중간 timestamp 계산
        final interpolatedTime = (t1 + t * (t2 - t1)).round();

        return fixnum.Int64(interpolatedTime);
      } on Exception catch (error) {
        // 🚨 계산 실패 시 현재 시간 사용
        debugPrint('⚠️ timestamp 계산 오류: $error, 현재 시간 사용');
        return fixnum.Int64(DateTime.now().millisecondsSinceEpoch);
      }
    }

    /// 🔄 오른쪽 페이지 스트로크를 왼쪽 기준 좌표로 조정
    Stroke _adjustStrokeForRightPage(Stroke stroke, double pageBoundaryX) {
      final adjustedStroke = Stroke()
        ..ink = stroke.ink
        ..width = stroke.width
        ..color = stroke.color;

      for (final point in stroke.points) {
        adjustedStroke.points.add(
          Point()
            ..x =
                point.x -
                pageBoundaryX // X 좌표를 왼쪽 기준으로 조정
            ..y = point.y
            ..p = point.p
            ..altitude = point.altitude
            ..azimuth = point.azimuth
            ..opacity = point.opacity
            ..size.addAll(point.size)
            ..timestamp = point.timestamp,
        );
      }

      return adjustedStroke;
    }

    /// 🔄 오른쪽 페이지 스트로크를 원래 위치로 복원
    Stroke _restoreStrokeFromRightPage(Stroke stroke, double pageBoundaryX) {
      final restoredStroke = Stroke()
        ..ink = stroke.ink
        ..width = stroke.width
        ..color = stroke.color;

      for (final point in stroke.points) {
        restoredStroke.points.add(
          Point()
            ..x =
                point.x +
                pageBoundaryX // X 좌표를 원래 위치로 복원
            ..y = point.y
            ..p = point.p
            ..altitude = point.altitude
            ..azimuth = point.azimuth
            ..opacity = point.opacity
            ..size.addAll(point.size)
            ..timestamp = point.timestamp,
        );
      }

      return restoredStroke;
    }

    /// 🔄 분할된 양쪽 스트로크를 다시 병합
    Stroke _mergeCrossPageStroke(
      Stroke leftStroke,
      Stroke rightStroke,
      double boundaryX,
    ) {
      final mergedStroke = Stroke()
        ..ink = leftStroke.ink
        ..width = leftStroke.width
        ..color = leftStroke.color;

      // 시간순으로 정렬하여 병합
      final allPoints = <Point>[];
      allPoints.addAll(leftStroke.points);

      // 오른쪽 스트로크의 좌표를 원래 위치로 복원하여 추가
      for (final point in rightStroke.points) {
        allPoints.add(
          Point()
            ..x = point.x + boundaryX
            ..y = point.y
            ..p = point.p
            ..altitude = point.altitude
            ..azimuth = point.azimuth
            ..opacity = point.opacity
            ..size.addAll(point.size)
            ..timestamp = point.timestamp,
        );
      }

      // 타임스탬프 기준으로 정렬
      allPoints.sort(
        (a, b) => a.timestamp.toInt().compareTo(b.timestamp.toInt()),
      );

      mergedStroke.points.addAll(allPoints);
      return mergedStroke;
    }

    /// 🔄 중복 스트로크 제거 (성능 최적화된 버전)
    List<Stroke> _removeDuplicateStrokes(List<Stroke> strokes) {
      const threshold = 5.0; // 유사성 임계값
      final strokeHashes = <String, List<Stroke>>{};
      final deduplicatedStrokes = <Stroke>[];

      // 🚀 1단계: 해시 기반 그룹핑 (O(n))
      for (final stroke in strokes) {
        if (stroke.points.length < 2) continue; // 유효하지 않은 스트로크 제외

        final hash = _calculateStrokeHash(stroke);
        strokeHashes.putIfAbsent(hash, () => <Stroke>[]).add(stroke);
      }

      // 🚀 2단계: 해시 그룹 내에서만 유사성 검사 (평균 O(n))
      for (final hashGroup in strokeHashes.values) {
        if (hashGroup.length == 1) {
          deduplicatedStrokes.add(hashGroup.first);
        } else {
          // 같은 해시 그룹 내에서만 상세 비교
          final groupDedup = <Stroke>[];
          for (final stroke in hashGroup) {
            bool isDuplicate = false;
            for (final existing in groupDedup) {
              if (_areSimilarStrokes(stroke, existing, threshold)) {
                isDuplicate = true;
                break;
              }
            }
            if (!isDuplicate) {
              groupDedup.add(stroke);
            }
          }
          deduplicatedStrokes.addAll(groupDedup);
        }
      }

      return deduplicatedStrokes;
    }

    /// 🔄 스트로크의 해시값 계산 (공간 분할 기반)
    String _calculateStrokeHash(Stroke stroke) {
      if (stroke.points.length < 2) return '';

      final start = stroke.points.first;
      final end = stroke.points.last;
      const gridSize = 10.0; // 해시 그리드 크기

      final startGridX = (start.x / gridSize).round();
      final startGridY = (start.y / gridSize).round();
      final endGridX = (end.x / gridSize).round();
      final endGridY = (end.y / gridSize).round();

      return '${startGridX}_${startGridY}_${endGridX}_$endGridY';
    }

    /// 🔄 두 스트로크가 유사한지 확인
    bool _areSimilarStrokes(Stroke stroke1, Stroke stroke2, double threshold) {
      if (stroke1.points.length != stroke2.points.length) {
        return false;
      }

      if (stroke1.points.length < 2) {
        return false;
      }

      // 시작점과 끝점의 거리로 유사성 판단
      final startDistance = math.sqrt(
        math.pow(stroke1.points.first.x - stroke2.points.first.x, 2) +
            math.pow(stroke1.points.first.y - stroke2.points.first.y, 2),
      );

      final endDistance = math.sqrt(
        math.pow(stroke1.points.last.x - stroke2.points.last.x, 2) +
            math.pow(stroke1.points.last.y - stroke2.points.last.y, 2),
      );

      return startDistance < threshold && endDistance < threshold;
    }

    /// 🔄 두 스트로크가 동일한지 확인
    bool _isSameStroke(Stroke stroke1, Stroke stroke2) {
      if (stroke1.points.length != stroke2.points.length) {
        return false;
      }

      if (stroke1.points.isEmpty) {
        return true;
      }

      // 첫 번째와 마지막 점이 정확히 일치하는지 확인
      return stroke1.points.first.x == stroke2.points.first.x &&
          stroke1.points.first.y == stroke2.points.first.y &&
          stroke1.points.last.x == stroke2.points.last.x &&
          stroke1.points.last.y == stroke2.points.last.y;
    }

    /// 🔄 스트로크 리스트로부터 Scribble 생성
    Scribble _createScribbleFromStrokes(
      List<Stroke> strokes,
      double width,
      double height,
    ) {
      return Scribble()
        ..strokes.addAll(strokes)
        ..width = width
        ..height = height;
    }
  }

  /// 🔄 스트로크 분할 결과
  class ScribbleSplitResult {
    final Scribble leftPageScribble;
    final Scribble rightPageScribble;
    final List<CrossPageStroke> crossPageStrokes;
    final double originalPageBoundary;

    const ScribbleSplitResult({
      required this.leftPageScribble,
      required this.rightPageScribble,
      required this.crossPageStrokes,
      required this.originalPageBoundary,
    });
  }

  /// 🔄 페이지 경계를 넘나드는 스트로크 정보
  class CrossPageStroke {
    final Stroke? leftStroke;
    final Stroke? rightStroke;
    final double boundaryX;

    const CrossPageStroke({
      required this.leftStroke,
      required this.rightStroke,
      required this.boundaryX,
    });
  }

  /// 🔄 개별 스트로크 분할 결과
  class StrokeSplitResult {
    final Stroke? leftStroke;
    final Stroke? rightStroke;

    const StrokeSplitResult({
      required this.leftStroke,
      required this.rightStroke,
    });
  }
