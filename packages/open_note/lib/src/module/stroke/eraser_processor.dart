// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:fixnum/fixnum.dart';

// 🌎 Project imports:
import 'package:open_note/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/core/utils/stroke_id.dart';
import 'package:open_note/src/module/state/scribble_input_options.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/painter/stroke_styles.dart';
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';

/// 지우개 관련 유틸리티 클래스
///
/// ScribbleNotifier에서 추출된 상태 없는(stateless) 유틸리티로,
/// 포인트 지우기와 교차점 계산을 담당합니다.
class EraserProcessor {
  const EraserProcessor();

  /// 지우개 현(preLocalPosition → 현재 위치)의 판정 최대 길이(논리 픽셀).
  ///
  /// 프레임 드롭 등으로 move 이벤트 간 간격이 벌어지면 현이 비정상적으로
  /// 길어져, 실제로 지나가지 않은 다른 스트로크까지 관통(tunneling)해 함께
  /// 지워질 수 있다 (#9006). 정상 스와이프의 프레임당 이동 거리보다 넉넉히
  /// 큰 값으로 설정해, 통상적인 빠른 스와이프는 그대로 전체 판정하되
  /// 비정상적으로 큰 점프만 현재 위치 기준으로 잘라낸다.
  static const double _maxEraseChordLength = 96;

  /// 이벤트 위치에서 스트로크를 지웁니다.
  ///
  /// [event]의 현재 위치와 [preLocalPosition] 사이의 직선을 기준으로,
  /// 스트로크의 포인트 또는 점 사이 선분이 해당 직선에 충분히 가까운 경우
  /// 해당 스트로크를 제거합니다. 두 위치 사이 거리가 [_maxEraseChordLength]
  /// 를 넘으면, 현재 위치에서 그만큼 떨어진 지점으로 시작점을 당겨와
  /// 판정합니다 (#9006 — 큰 점프로 인한 무관한 스트로크 관통 방지).
  ///
  /// open_note: [ScribbleInputOptions.eraserMode] 가 pixel 이면 통째로 지우지
  /// 않고 지나간 구간만 지운다([_erasePartially]). 남은 조각의 id 는
  /// [newStrokeId] 로 새로 발급한다.
  ScribbleState eraseAtPoint(
    PointerEvent event,
    ScribbleModeState modeState,
    ScribbleState state,
    Offset preLocalPosition, {
    String Function() newStrokeId = generateStrokeId,
  }) {
    final clampedPreLocalPosition = _clampChordStart(
      preLocalPosition,
      event.localPosition,
    );
    final isPartial =
        modeState.inputOptions.eraserMode == ScribbleEraserMode.pixel;
    final newScribble = state.scribble.copyWithContents(
      touchUpdatedAt: false,
      strokes: isPartial
          ? [
              for (final stroke in state.scribble.strokes)
                ..._erasePartially(
                  stroke,
                  event,
                  modeState,
                  clampedPreLocalPosition,
                  newStrokeId,
                ),
            ]
          : state.scribble.strokes
                .where(
                  (stroke) => !_isStrokeHit(
                    stroke,
                    event,
                    modeState,
                    clampedPreLocalPosition,
                  ),
                )
                .toList(),
    );
    return switch (state) {
      final Drawing s => s.copyWith(scribble: newScribble),
      final Erasing s => s.copyWith(scribble: newScribble),
    };
  }

  /// open_note: 부분 지우개 — 닿은 스트로크에서 지우개 현에 닿은 점만 빼고,
  /// 남은 연속 구간(점 2개 이상)을 새 id 의 스트로크로 남긴다. 닿지 않은
  /// 스트로크는 같은 인스턴스를 돌려준다. 도형 · 올가미 · 점 2개 미만
  /// 스트로크는 점으로 나눌 수 없어 통째로 지운다.
  List<Stroke> _erasePartially(
    Stroke stroke,
    PointerEvent event,
    ScribbleModeState modeState,
    Offset preLocalPosition,
    String Function() newStrokeId,
  ) {
    if (!_isStrokeHit(stroke, event, modeState, preLocalPosition)) {
      return [stroke];
    }
    if (stroke.shapeType.isNotEmpty ||
        stroke.ink == InkModes.lasso ||
        stroke.points.length < 2) {
      return const [];
    }
    final reach = _lineTarget(stroke, stroke.points.first, modeState);
    final dense = _densify(stroke.points, math.max(reach / 2, 1));
    final runs = <List<Point>>[<Point>[]];
    var erasedAny = false;
    for (final point in dense) {
      final distance = _pointToSegmentDistance(
        Offset(point.x, point.y),
        preLocalPosition,
        event.localPosition,
      );
      if (distance < _lineTarget(stroke, point, modeState)) {
        erasedAny = true;
        if (runs.last.isNotEmpty) runs.add(<Point>[]);
      } else {
        runs.last.add(point);
      }
    }
    if (!erasedAny) return [stroke];

    return [
      for (final run in runs)
        if (run.length >= 2)
          stroke.deepCopy()
            ..points.clear()
            ..points.addAll(run)
            ..id = newStrokeId(),
    ];
  }

  /// open_note: 긴 선분을 [maxStep] 이하로 나눠, 점이 성긴 스트로크(빠른
  /// 필기)도 지나간 곳만 정확히 지운다. 좌표 · 필압 · 시각을 보간한다.
  List<Point> _densify(List<Point> points, double maxStep) {
    final result = <Point>[points.first];
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      final length = _getDistance(from, Offset(to.x, to.y));
      final steps = (length / maxStep).ceil();
      for (var step = 1; step < steps; step++) {
        final t = step / steps;
        final elapsed = (to.timestamp - from.timestamp).toInt() * t;
        result.add(
          to.deepCopy()
            ..x = from.x + (to.x - from.x) * t
            ..y = from.y + (to.y - from.y) * t
            ..p = from.p + (to.p - from.p) * t
            ..timestamp = from.timestamp + Int64(elapsed.round()),
        );
      }
      result.add(to);
    }

    return result;
  }

  /// [current] 기준 [_maxEraseChordLength] 를 넘는 [previous] 를, 그 방향으로
  /// 딱 그 거리만큼 떨어진 지점으로 당겨옵니다. 거리가 이미 그 이하면
  /// [previous] 를 그대로 반환합니다.
  Offset _clampChordStart(Offset previous, Offset current) {
    final dx = previous.dx - current.dx;
    final dy = previous.dy - current.dy;
    final distanceSquared = dx * dx + dy * dy;
    const maxLengthSquared = _maxEraseChordLength * _maxEraseChordLength;
    if (distanceSquared <= maxLengthSquared) return previous;

    final scale = _maxEraseChordLength / math.sqrt(distanceSquared);
    return Offset(current.dx + dx * scale, current.dy + dy * scale);
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
    // open_note: 2점 도형(사각형 · 타원 · 별 · 입체 도형 …)은 두 점을 잇는
    // 대각선이 아니라 화면에 보이는 윤곽으로 판정한다.
    final shapeKind = StrokeStyles.twoPointShapeOf(stroke);
    if (shapeKind != null) {
      return _isContourHit(
        stroke,
        StrokeStyles.noteShapeContours(stroke, shapeKind),
        event,
        modeState,
        preLocalPosition,
      );
    }
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

  /// open_note: 폴리라인 윤곽들 중 하나라도 지우개 현에 닿으면 true.
  bool _isContourHit(
    Stroke stroke,
    List<List<Offset>> contours,
    PointerEvent event,
    ScribbleModeState modeState,
    Offset preLocalPosition,
  ) {
    final reach = _lineTarget(stroke, stroke.points.first, modeState);
    final current = event.localPosition;
    for (final contour in contours) {
      for (var i = 0; i < contour.length - 1; i++) {
        final a = contour[i];
        final b = contour[i + 1];
        if (_segmentsIntersect(a, b, preLocalPosition, current) ||
            _pointToSegmentDistance(a, preLocalPosition, current) < reach ||
            _pointToSegmentDistance(preLocalPosition, a, b) < reach ||
            _pointToSegmentDistance(current, a, b) < reach) {
          return true;
        }
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
