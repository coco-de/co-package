import 'dart:math' as math;

import 'package:flutter/material.dart';

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
