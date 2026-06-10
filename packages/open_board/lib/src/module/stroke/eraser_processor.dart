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
  /// 스트로크의 포인트들이 해당 직선에 충분히 가까운 경우 해당 스트로크를 제거합니다.
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
            (stroke) => stroke.points.every((pt) {
              final intersect = findIntersection(
                event,
                pt,
                preLocalPosition,
              );
              // 그려져 있는 선들의 점 굵기를 계산한다.
              final lineTarget =
                  modeState.inkGroupInfo.seletedStrokeWidth /
                      modeState.scaleFactor +
                  _calculateStrokeRadius(
                    stroke.options.size,
                    stroke.options.thinning,
                    (stroke.ink == "pen" || stroke.ink == "fixedPen")
                        ? stroke.points.first.p
                        : pt.p,
                  );
              final minDistance =
                  (intersect.dx >=
                          math.min(
                            preLocalPosition.dx,
                            event.localPosition.dx,
                          ) &&
                      intersect.dx <=
                          math.max(
                            preLocalPosition.dx,
                            event.localPosition.dx,
                          ) &&
                      intersect.dy >=
                          math.min(
                            preLocalPosition.dy,
                            event.localPosition.dy,
                          ) &&
                      intersect.dy <=
                          math.max(
                            preLocalPosition.dy,
                            event.localPosition.dy,
                          )
                  ? _getDistance(pt, intersect)
                  : math.min(
                      _getDistance(pt, preLocalPosition),
                      _getDistance(pt, event.localPosition),
                    ));

              // 구한 교점이 선분 위에 있으면 p 와 a 와의 거리가 최소 거리
              return minDistance >= lineTarget;
            }),
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

  /// 점 a와 점 b 사이의 거리를 구합니다.
  double _getDistance(Point a, Offset b) =>
      math.sqrt(math.pow(b.dx - a.x, 2) + math.pow(b.dy - a.y, 2));

  /// 스트로크의 반지름을 계산합니다.
  double _calculateStrokeRadius(double size, double thinning, double p) {
    return size * (0.5 - thinning * (0.5 - p));
  }
}
