// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:fixnum/fixnum.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

/// 스트로크 생성/계산 관련 유틸리티 클래스
///
/// ScribbleNotifier에서 추출된 상태 없는(stateless) 유틸리티로,
/// 포인트 추가, 이벤트에서 포인트 생성, 스트로크 완료, 반지름 계산을 담당합니다.
class StrokeProcessor {
  const StrokeProcessor({this.pressureCurve = Curves.linear});

  /// 펜 압력 매핑에 사용되는 커브
  final Curve pressureCurve;

  /// 현재 활성 라인에 새 포인트를 추가합니다.
  ///
  /// [event]에서 좌표를 추출하여 [Drawing] 상태의 activeLine에 포인트를 추가합니다.
  /// [Erasing] 상태이거나 활성 라인이 없으면 상태를 그대로 반환합니다.
  ScribbleState addPointToStroke(
    PointerEvent event,
    ScribbleState s,
    ScribbleModeState modeState,
  ) {
    if (s is Erasing || !s.active) return s;
    if (s is! Drawing || s.activeLine == null) return s;

    final drawing = s;
    final currentLine = drawing.activeLine!;
    final distanceToLast = currentLine.points.isEmpty
        ? double.infinity
        : (Offset(currentLine.points.last.x, currentLine.points.last.y) -
                  event.localPosition)
              .distance;
    if (distanceToLast <=
        kPrecisePointerPanSlop / modeState.scaleFactor * 0.01) {
      return s;
    }
    return drawing.copyWith(
      activeLine: Stroke(
        points: [...currentLine.points, createPointFromEvent(event)],
        color: currentLine.color,
        ink: currentLine.ink,
        width: currentLine.width,
        createdAt: currentLine.createdAt,
        options: currentLine.options,
        shapeType: currentLine.shapeType,
      ),
    );
  }

  /// 포인터 이벤트에서 [Point] 객체를 생성합니다.
  ///
  /// 이벤트의 좌표와 압력 정보를 사용하여 Point를 생성합니다.
  /// 웹 환경의 hover 이벤트나 압력 범위가 동일한 경우 기본 압력(0.5)을 사용합니다.
  Point createPointFromEvent(PointerEvent event) {
    final overridePressureOnWeb = event is PointerHoverEvent && kIsWeb;
    final p = overridePressureOnWeb || event.pressureMin == event.pressureMax
        ? 0.5
        : (event.pressure - event.pressureMin) /
              (event.pressureMax - event.pressureMin);
    return Point(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      p: pressureCurve.transform(p),
      timestamp: Int64(DateTime.now().microsecondsSinceEpoch),
    );
  }

  /// 현재 활성 라인을 완료하여 스트로크 목록에 추가합니다.
  ///
  /// [Drawing] 상태의 activeLine을 scribble.strokes에 추가하고
  /// activeLine을 null로 설정합니다.
  ScribbleState finishStroke(ScribbleState s) {
    if (s is! Drawing || s.activeLine == null) {
      return s;
    }
    // Drawing.copyWith(activeLine: null)은 null 합류 연산자 때문에
    // activeLine을 null로 설정하지 못하므로 직접 Drawing을 생성합니다.
    return Drawing(
      scribble: Scribble(
        x: s.scribble.x,
        y: s.scribble.y,
        width: s.scribble.width,
        height: s.scribble.height,
        strokes: [...s.scribble.strokes, s.activeLine!],
        textDrawables: s.scribble.textDrawables,
        updatedAt: DateTime.now().toIso8601String(),
        version: s.scribble.version,
      ),
      activeLine: null,
      activePointerIds: s.activePointerIds,
      selectedStrokeIds: s.selectedStrokeIds,
      pointerPosition: s.pointerPosition,
    );
  }

  /// 스트로크의 반지름을 계산합니다.
  ///
  /// [size], [thinning], [p] (압력)을 기반으로 스트로크의 반지름을 계산합니다.
  double calculateRadius(double size, double thinning, double p) {
    return size * (0.5 - thinning * (0.5 - p));
  }
}
