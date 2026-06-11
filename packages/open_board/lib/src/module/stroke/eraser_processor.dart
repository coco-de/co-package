// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/widgets.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

/// 지우개 관련 유틸리티 클래스
///
/// ScribbleNotifier에서 추출된 상태 없는(stateless) 유틸리티로,
/// 포인트 지우기와 교차점 계산을 담당합니다.
class EraserProcessor {
  const EraserProcessor();

  /// 이벤트 위치에서 스트로크를 지웁니다.
  ///
  /// [event]의 현재 위치와 [preLocalPosition] 사이의 직선을 기준으로,
  /// 스트로크의 포인트 또는 점 사이 선분이 해당 직선에 충분히 가까운 경우
  /// 해당 스트로크를 제거합니다.
  ScribbleState eraseAtPoint(
    PointerEvent event,
    ScribbleModeState modeState,
    ScribbleState state,
    Offset preLocalPosition,
  ) {
    final newScribble = state.scribble.copyWithContents(
      touchUpdatedAt: false,
      strokes: state.scribble.strokes
          .where(
            (stroke) =>
                !_isStrokeHit(stroke, event, modeState, preLocalPosition),
          )
          .toList(),
    );
    return switch (state) {
      final Drawing s => s.copyWith(scribble: newScribble),
      final Erasing s => s.copyWith(scribble: newScribble),
    };
  }

  /// 점과 선 사이의 교점을 구합니다.
  ///
  /// [event]의 현재 위치와 [preLocalPosition]을 잇는 직선에 대해,
  /// 포인트 [p]에서 수선을 내린 교점을 반환합니다.
  Offset findIntersection(
    PointerEvent event,
    Point p,
    Offset preLocalPosition,
  ) {
    final Offset a;

    if (preLocalPosition.dx == event.localPosition.dx) {
      a = Offset(preLocalPosition.dx, p.y);
    }
    // 선분이 수평일 경우
    else if (preLocalPosition.dy == event.localPosition.dy) {
      a = Offset(p.x, preLocalPosition.dy);
    }
    // 그 외의 경우
    else {
      final m1 =
          (preLocalPosition.dy - event.localPosition.dy) /
          (preLocalPosition.dx - event.localPosition.dx);

      final k1 = -m1 * preLocalPosition.dx + preLocalPosition.dy;

      final m2 = -1.0 / m1;
      final k2 = p.y - m2 * p.x;
      a = Offset((k2 - k1) / (m1 - m2), (m1 * (k2 - k1) / (m1 - m2) + k1));
    }
    return a;
  }

  /// 지우개 현(직전 위치 → 현재 위치)이 스트로크에 닿았는지 판정합니다.
  bool _isStrokeHit(
    Stroke stroke,
    PointerEvent event,
    ScribbleModeState modeState,
    Offset preLocalPosition,
  ) {
    // 1) 점 기반 판정 (조밀한 손그림 스트로크)
    for (final pt in stroke.points) {
      final lineTarget = _lineTarget(stroke, pt, modeState);
      if (_pointToChordDistance(pt, event, preLocalPosition) < lineTarget) {
        return true;
      }
    }

    // 2) 선분 기반 판정: 도형 변환/정지 직선화 스트로크는 점이 희소해
    //    (직선 2점, 다각형은 코너만) 변 중간을 지나는 지우개가 어떤 점에도
    //    닿지 않으므로, 연속 점 쌍 선분과 지우개 현의 거리로 보완한다.
    for (var i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i];
      final b = stroke.points[i + 1];
      final lineTarget = math.max(
        _lineTarget(stroke, a, modeState),
        _lineTarget(stroke, b, modeState),
      );

      // 짧은 선분은 양 끝점 판정으로 충분히 커버되므로 건너뛴다 (성능 가드).
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      if (dx * dx + dy * dy <= 4 * lineTarget * lineTarget) continue;

      final aOffset = Offset(a.x, a.y);
      final bOffset = Offset(b.x, b.y);
      if (_segmentsIntersect(
        aOffset,
        bOffset,
        preLocalPosition,
        event.localPosition,
      )) {
        return true;
      }
      // 지우개 현의 양 끝이 선분에 가까운 경우 (점 판정의 보완:
      // 스트로크 점 → 현 거리는 이미 점 판정이 커버하므로 반대 방향만 확인)
      if (_pointToSegmentDistance(preLocalPosition, aOffset, bOffset) <
              lineTarget ||
          _pointToSegmentDistance(event.localPosition, aOffset, bOffset) <
              lineTarget) {
        return true;
      }
    }
    return false;
  }

  /// 스트로크 점 기준 지우개 판정 두께를 계산합니다.
  double _lineTarget(Stroke stroke, Point pt, ScribbleModeState modeState) =>
      modeState.inkGroupInfo.seletedStrokeWidth / modeState.scaleFactor +
      _calculateStrokeRadius(
        stroke.options.size,
        stroke.options.thinning,
        (stroke.ink == "pen" || stroke.ink == "fixedPen")
            ? stroke.points.first.p
            : pt.p,
      );

  /// 점 [pt]와 지우개 현(선분) 사이의 최소 거리를 계산합니다.
  double _pointToChordDistance(
    Point pt,
    PointerEvent event,
    Offset preLocalPosition,
  ) {
    final intersect = findIntersection(event, pt, preLocalPosition);
    final onSegment =
        intersect.dx >= math.min(preLocalPosition.dx, event.localPosition.dx) &&
        intersect.dx <= math.max(preLocalPosition.dx, event.localPosition.dx) &&
        intersect.dy >= math.min(preLocalPosition.dy, event.localPosition.dy) &&
        intersect.dy <= math.max(preLocalPosition.dy, event.localPosition.dy);

    // 구한 교점이 선분 위에 있으면 pt와 교점의 거리가 최소 거리
    return onSegment
        ? _getDistance(pt, intersect)
        : math.min(
            _getDistance(pt, preLocalPosition),
            _getDistance(pt, event.localPosition),
          );
  }

  /// 점 [p]와 선분 [a]-[b] 사이의 최소 거리를 계산합니다.
  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final abx = b.dx - a.dx;
    final aby = b.dy - a.dy;
    final lengthSquared = abx * abx + aby * aby;
    if (lengthSquared == 0) return (p - a).distance;

    final t = (((p.dx - a.dx) * abx + (p.dy - a.dy) * aby) / lengthSquared)
        .clamp(0.0, 1.0);
    return (p - Offset(a.dx + abx * t, a.dy + aby * t)).distance;
  }

  /// 두 선분 [p1]-[p2], [q1]-[q2]가 교차하는지 판정합니다.
  bool _segmentsIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
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

  /// 점 a와 점 b 사이의 거리를 구합니다.
  double _getDistance(Point a, Offset b) =>
      math.sqrt(math.pow(b.dx - a.x, 2) + math.pow(b.dy - a.y, 2));

  /// 스트로크의 반지름을 계산합니다.
  double _calculateStrokeRadius(double size, double thinning, double p) {
    return size * (0.5 - thinning * (0.5 - p));
  }
}
