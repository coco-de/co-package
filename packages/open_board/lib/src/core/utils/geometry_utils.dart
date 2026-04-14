  // 🎯 Dart imports:
  import 'dart:math' as math;

  // 🐦 Flutter imports:

  // 🌎 Project imports:
  import 'package:flutter/material.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

  /// 기하학적 계산을 담당하는 유틸리티 클래스
  class GeometryUtils {
    const GeometryUtils._();

    /// 두 점 사이의 거리 계산
    static double calculateDistance(Point p1, Point p2) {
      final dx = p1.x - p2.x;
      final dy = p1.y - p2.y;
      return math.sqrt(dx * dx + dy * dy);
    }

    /// 세 점 사이의 각도를 계산 (degrees)
    static double calculateCornerAngle(Point prev, Point mid, Point next) {
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

    /// 점들의 중심점 계산
    static Point calculateCentroid(List<Point> points) {
      if (points.isEmpty) return Point(x: 0, y: 0);

      double sumX = 0, sumY = 0;
      for (final point in points) {
        sumX += point.x;
        sumY += point.y;
      }
      return Point(x: sumX / points.length, y: sumY / points.length);
    }

    /// 점들의 둘레 길이 계산
    static double calculatePolygonPerimeter(List<Point> points) {
      if (points.length < 2) return 0.0;

      double perimeter = 0.0;
      for (int i = 0; i < points.length - 1; i++) {
        perimeter += calculateDistance(points[i], points[i + 1]);
      }

      // 닫힌 경로인 경우 시작점과 끝점 사이 거리도 추가
      perimeter += calculateDistance(points.first, points.last);

      return perimeter;
    }

    /// 바운딩 박스 계산
    static Rect calculateBoundingBox(List<Point> points) {
      if (points.isEmpty) return .zero;

      double minX = points[0].x;
      double minY = points[0].y;
      double maxX = points[0].x;
      double maxY = points[0].y;

      for (final point in points) {
        minX = math.min(minX, point.x);
        minY = math.min(minY, point.y);
        maxX = math.max(maxX, point.x);
        maxY = math.max(maxY, point.y);
      }

      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    /// 지정된 경로 구간의 방향 벡터 계산
    static Point calculatePathDirection(
      List<Point> points,
      int startIdx,
      int endIdx,
    ) {
      if (startIdx >= endIdx || endIdx >= points.length)
        return Point(x: 0, y: 0);

      // 첫번째와 마지막 포인트로 방향 벡터 계산
      final start = points[startIdx];
      final end = points[endIdx];

      return Point(x: end.x - start.x, y: end.y - start.y);
    }

    /// 세 점의 방향성 계산 (0: 일직선, 1: 시계 방향, 2: 반시계 방향)
    static int calculateOrientation(Point p, Point q, Point r) {
      double val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
      if (val == 0) return 0;
      return (val > 0) ? 1 : 2;
    }
  }
