// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:fixnum/fixnum.dart';

// 🌎 Project imports:
import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/module/stroke/pen_pressure_response.dart';

/// 스트로크 생성/계산 관련 유틸리티 클래스
///
/// ScribbleNotifier에서 추출된 상태 없는(stateless) 유틸리티로,
/// 포인트 추가, 이벤트에서 포인트 생성, 스트로크 완료, 반지름 계산을 담당합니다.
class StrokeProcessor {
  /// 스타일러스 하드웨어 필압을 기록 압력으로 옮기는 응답 커브.
  ///
  /// 하드웨어 필압([PenPressureResponse.providesHardwarePressure])에만
  /// 적용된다 — 손가락 터치의 필압은 속도 시뮬레이션의 시작값으로만 쓰이므로
  /// 곡선을 태우지 않는다.
  final Curve pressureCurve;

  const StrokeProcessor({required this.pressureCurve});

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
    // ⚠️ 필드를 손으로 나열해 복사하지 말 것 — 그 방식이 `segments`(8)·
    // `confidence`(9) 를 포인터 이동마다 조용히 떨어뜨리고 있었다. `deepCopy`
    // 는 미지정 필드까지 승계하므로 proto 에 필드가 늘어도 자동으로 따라온다.
    //
    // 비용 실측(포인트 3000개 기준): 열거 복사 29µs → deepCopy 138µs.
    // 120Hz 프레임 예산 8333µs 의 1.3% 로, 유실을 감수할 만한 차이가 아니다.
    return drawing.copyWith(
      activeLine: currentLine.deepCopy()
        ..points.add(createPointFromEvent(event)),
    );
  }

  /// 포인터 이벤트에서 [Point] 객체를 생성합니다.
  ///
  /// 이벤트의 좌표와 압력 정보를 사용하여 Point를 생성합니다.
  /// 웹 환경의 hover 이벤트나 압력 범위가 동일한 경우 기본 압력(0.5)을 사용합니다.
  /// 이 중립값에는 [pressureCurve] 를 적용하지 않는다 — 곡선을 태우면 필압
  /// 없는 입력이 선택한 굵기보다 두껍게 기록된다.
  Point createPointFromEvent(PointerEvent event) {
    final overridePressureOnWeb = event is PointerHoverEvent && kIsWeb;
    final double p;
    if (overridePressureOnWeb || event.pressureMin == event.pressureMax) {
      p = 0.5;
    } else {
      // 보정이 어긋난 기기는 pressureMax를 초과한 압력을 보고할 수 있으므로
      // Curve.transform의 [0,1] 정의역에 맞게 클램프한다.
      final normalized = clampDouble(
        (event.pressure - event.pressureMin) /
            (event.pressureMax - event.pressureMin),
        0.0,
        1.0,
      );
      p = PenPressureResponse.providesHardwarePressure(event)
          ? pressureCurve.transform(normalized)
          : normalized;
    }

    return Point(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      p: p,
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
      scribble: s.scribble.copyWithContents(
        strokes: [...s.scribble.strokes, s.activeLine!],
      ),
      activeLine: null,
      activePointerIds: s.activePointerIds,
      selectedStrokeIds: s.selectedStrokeIds,
      pointerPosition: s.pointerPosition,
    );
  }
}
