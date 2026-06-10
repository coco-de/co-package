// 🎯 Dart imports:
import 'dart:async';

// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:value_notifier_tools/value_notifier_tools.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';
import 'package:open_board/src/module/stroke/eraser_processor.dart';
import 'package:open_board/src/module/text/text_drawable_manager.dart';

abstract class ScribbleNotifierBase extends ValueNotifier<ScribbleState> {
  ScribbleNotifierBase(super.value);

  /// Compatibility getter/setter for state (maps to value)
  ScribbleState get state => value;
  set state(ScribbleState newState) => value = newState;

  void onPointerHover(PointerHoverEvent event, ScribbleModeState modeState);

  void onPointerDown(PointerDownEvent event, ScribbleModeState modeState);

  bool onPointerUpdate(PointerMoveEvent event, ScribbleModeState modeState);

  void onPointerUp(PointerUpEvent event, ScribbleModeState modeState);

  void onPointerCancel(PointerCancelEvent event, ScribbleModeState modeState);

  void onPointerExit(PointerExitEvent event, ScribbleModeState modeState);
}

/// This class controls the state and behavior for a [Strokes] widget.
class ScribbleNotifier extends ScribbleNotifierBase
    with HistoryValueNotifierMixin<ScribbleState> {
  BuildContext? currContext;

  /// The curve that's used to map pen pressure to the pressure value when
  /// recording.
  final Curve pressureCurve = Curves.linear;

  /// ♻️ 스트로크 생성/계산 프로세서
  late final StrokeProcessor strokeProcessor;

  /// ♻️ 지우개 프로세서
  final EraserProcessor eraserProcessor = const EraserProcessor();

  /// ♻️ 텍스트 관리자
  final TextDrawableManager textDrawableManager = const TextDrawableManager();

  /// 선의 1번째 점이 되는 이전 좌표를 저장하는 변수
  Offset preLocalPosition = const Offset(0, 0);

  /// 도형 인식 기능 활성화 상태
  bool _shapeRecognitionEnabled = false;

  /// 마커 펜 정지 시 직선 변환까지의 대기 시간
  static const Duration kMarkerStraightenDelay = Duration(milliseconds: 1500);

  /// 마커 펜 정지 판정 이동 임계값(픽셀, 제곱값으로 비교)
  static const double kMarkerStraightenMoveThresholdSquared = 9.0;

  /// 마커 펜 정지 감지 타이머
  Timer? _markerStraightenTimer;

  /// 마커 펜 정지 기준 위치(가장 마지막으로 의미 있는 이동이 발생한 좌표)
  Offset _markerHoldAnchor = Offset.zero;

  /// 마커 펜이 직선으로 변환되었는지 여부 (변환 후에는 끝점만 추종)
  bool _markerStraightened = false;

  /// 지우개 제스처 시작 시점의 스트로크 수
  ///
  /// 한 번의 지우개 제스처(down→move…→up)를 undo 1단위로 만들기 위해
  /// 제스처 시작 시 스냅샷을 기록하고, up/cancel에서 실제로 스트로크가
  /// 지워졌을 때만 히스토리에 커밋한다.
  int? _eraseGestureStartStrokeCount;

  ScribbleNotifier({
    /// If you pass a scribble here, the notifier will use that scribble as a
    /// starting point.
    Scribble? scribble,
  }) : super(
         Drawing(
           scribble:
               scribble ??
               Scribble(
                 strokes: [],
                 createdAt: DateTime.now().toIso8601String(),
               ),
         ),
       ) {
    state = Drawing(
      scribble:
          scribble ??
          Scribble(strokes: [], createdAt: DateTime.now().toIso8601String()),
    );
    this.maxHistoryLength = 30;

    // ♻️ StrokeProcessor 초기화
    strokeProcessor = StrokeProcessor(pressureCurve: pressureCurve);

    // 초기화 시 모든 올가미 스트로크 제거
    removeLassoStrokes();

    // super() 초기값과 본문 재할당이 각각 히스토리에 들어가 생성 직후
    // canUndo == true가 되는 것을 방지한다. (컨트롤러를 거치지 않고
    // 직접 생성해 ScribbleWidget에 주입하는 공개 API 경로 보정)
    resetHistoryToBaseline();
  }

  /// The state of the scribble at this moment.
  ///
  /// If you want to store it somewhere you can call ``.toJson()`` on it to
  /// receive a map.
  Scribble get currentScribble => state.scribble;

  /// 현재 ScribbleState 전체 반환 (외부 접근용)
  ScribbleState get currentState => state;

  /// Only apply the scribble from the undo history, otherwise keep current state
  @override
  @protected
  ScribbleState transformHistoryValue(
    ScribbleState historyState,
    ScribbleState currentState,
  ) {
    // 선택용 올가미 스트로크는 콘텐츠가 아니므로 히스토리 복원 시 정화한다.
    // (정화하지 않으면 undo 시 올가미 윤곽선이 그려진 콘텐츠처럼 복원된다)
    final strokes = historyState.scribble.strokes
        .where((stroke) => stroke.ink != InkModes.lasso)
        .toList();
    final cleanedScribble =
        strokes.length == historyState.scribble.strokes.length
        ? historyState.scribble
        : (historyState.scribble.deepCopy()
            ..strokes.clear()
            ..strokes.addAll(strokes));

    return switch (currentState) {
      final Drawing s => s.copyWith(scribble: cleanedScribble),
      final Erasing s => s.copyWith(scribble: cleanedScribble),
    };
  }

  /// Can be used to update the state of the Scribble externally (e.g. when
  /// fetching from a server) to what is passed in as [scribble];
  ///
  /// Per default, this state of the scribble gets added to the undo history. If
  /// this is not desired, set [addToUndoHistory] to ``false``.
  void setScribble({
    required Scribble scribble,
    bool addToUndoHistory = true,
  }) {
    final newState = switch (state) {
      final Drawing s => s.copyWith(scribble: scribble),
      final Erasing s => s.copyWith(scribble: scribble),
    };
    if (addToUndoHistory) {
      state = newState;
    } else {
      temporaryValue = newState;
    }
  }

  /// Undo 히스토리를 현재 상태 1개로 초기화하여 baseline 을 설정한다.
  ///
  /// `clearQueue()` 는 history 를 완전히 비우므로 첫 변경 후 `length == 1`
  /// 이 되어 `canUndo` 가 `false` 가 된다 (첫 stroke 는 undo 불가능 상태).
  ///
  /// 이 메서드는 clearQueue 직후 현재 상태를 baseline 으로 history 에 명시 추가하여
  /// 첫 변경이 즉시 undo 가능하도록 보정한다.
  ///
  /// `Drawing` / `Erasing` 은 identity 비교이므로 `copyWith()` 로 새 인스턴스를
  /// 만들면 `shouldInsertValueIntoQueue` 가 `true` 를 반환하여 history 에 들어간다.
  void resetHistoryToBaseline() {
    clearQueue();
    state = switch (state) {
      final Drawing s => s.copyWith(),
      final Erasing s => s.copyWith(),
    };
  }

  /// Clear the entire drawing.
  void clear() {
    // 텍스트/이미지 객체만 있는 페이지에서도 전체 지우기가 동작해야 한다.
    if (state.scribble.strokes.isEmpty &&
        state.scribble.textDrawables.isEmpty &&
        state.scribble.imageDrawables.isEmpty) {
      return;
    }
    state = Drawing(
      scribble: Scribble(
        x: state.scribble.x,
        y: state.scribble.y,
        width: state.scribble.width,
        height: state.scribble.height,
        strokes: [],
        textDrawables: [],
        version: state.scribble.version,
      ),
      activePointerIds: state.activePointerIds,
    );
  }

  /// Sets the ink type of the next line
  void setStrokeInk() {
    temporaryValue = switch (state) {
      Drawing(:final scribble) => Drawing(scribble: scribble),
      Erasing(:final scribble) => Drawing(
        scribble: scribble,
        activePointerIds: state.activePointerIds,
      ),
    };

    // 🎯 그리기 모드 설정 후 DrawingState의 Undo/Redo 상태 업데이트
    final drawingState = DrawingState();
    if (drawingState.lastActiveScribbleNotifier == this) {
      drawingState.updateUndoRedoState();
    }
  }

  /// Switches to eraser mode
  void setEraser() {
    temporaryValue = Erasing(
      scribble: state.scribble,
      activePointerIds: state.activePointerIds,
    );

    // 🎯 지우개 모드 설정 후 DrawingState의 Undo/Redo 상태 업데이트
    final drawingState = DrawingState();
    if (drawingState.lastActiveScribbleNotifier == this) {
      drawingState.updateUndoRedoState();
    }
  }

  /// Switches to lasso selection mode
  void setLassoSelection() {
    // 모든 올가미 스트로크 제거
    removeLassoStrokes();
  }

  /// Sets the color of the pen to the given color.
  void setColor() {
    temporaryValue = switch (state) {
      Drawing(:final scribble) => Drawing(scribble: scribble),
      Erasing(:final scribble) => Drawing(
        scribble: scribble,
        activePointerIds: state.activePointerIds,
      ),
    };
  }

  /// Sets the current mode of allowed pointers to the given [ScribblePointerMode]
  // void setAllowedPointersMode(ScribblePointerMode allowedPointersMode) {
  //   temporaryValue = state.copyWith(
  //     allowedPointersMode: allowedPointersMode,
  //   );
  // }

  /// Used by the Listener callback to display the pen if desired
  @override
  void onPointerHover(PointerHoverEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;

    // 🎯 지우개 모드에서도 포인터 위치 업데이트
    final newPointerPosition = event.distance > 10000
        ? null
        : getPointFromEvent(event);

    // 🚀 성능 최적화: 포인터 위치가 실제로 변경된 경우에만 상태 업데이트
    final currentPosition = state.pointerPosition;
    if (currentPosition != null && newPointerPosition != null) {
      final dx = currentPosition.x - newPointerPosition.x;
      final dy = currentPosition.y - newPointerPosition.y;
      final distance = (dx * dx + dy * dy); // 제곱근 계산 생략하여 성능 향상
      if (distance < 1.0) return; // 1픽셀 미만 이동은 무시
    }

    temporaryValue = switch (state) {
      final Drawing s => s.copyWith(pointerPosition: newPointerPosition),
      final Erasing s => s.copyWith(pointerPosition: newPointerPosition),
    };
  }

  /// Used by the Listener callback to start drawing
  @override
  void onPointerDown(PointerDownEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;

    // 손가락 입력일 때 멀티터치 방지
    if (event.kind == .touch && state.activePointerIds.isNotEmpty) {
      return;
    }
    // 터치하는 순간 이전 좌표와 현재 좌표를 같게 만든다.
    preLocalPosition = event.localPosition;

    // 지우개 제스처 시작 스냅샷 (첫 포인터 down에서만)
    if (state is Erasing && state.activePointerIds.isEmpty) {
      _eraseGestureStartStrokeCount = state.scribble.strokes.length;
    }
    ScribbleState s = state;

    // 올가미 스트로크가 있는지 확인
    final hasLassoStrokes = state.scribble.strokes.any(
      (stroke) => stroke.ink == InkModes.lasso,
    );

    // 올가미 스트로크가 있고, 올가미 도구가 선택되어 있지 않다면 올가미 스트로크 제거
    if (hasLassoStrokes &&
        modeState.inkGroupInfo.selectedInk != InkModes.lasso) {
      removeLassoStrokes();
      s = state; // 상태 업데이트 후 s 변수 갱신
    }
    // 올가미 도구가 선택된 경우에도 이전 올가미 스트로크 제거
    else if (modeState.inkGroupInfo.selectedInk == InkModes.lasso) {
      removeLassoStrokes();
      s = state; // 상태 업데이트 후 s 변수 갱신
    }

    // Are there already pointers on the screen?
    if (state.activePointerIds.isNotEmpty) {
      s = switch (state) {
        Drawing(:final activeLine) =>
          // If the current line already contains something
          (activeLine != null && activeLine.points.length > 2)
              ? finishLineForState(s)
              : s,
        Erasing() => s,
      };
    } else if (state is Drawing) {
      s = (state as Drawing).copyWith(
        pointerPosition: getPointFromEvent(event),
        activeLine: Stroke(
          points: [getPointFromEvent(event)],
          color: colorToInt(modeState.inkGroupInfo.selectedColor),
          ink: modeState.inkGroupInfo.selectedInk,
          width: modeState.inkGroupInfo.seletedStrokeWidth,
          createdAt: DateTime.now().toIso8601String(),
          shapeType: modeState.inkGroupInfo.selectedInk == InkModes.shape
              ? "pending"
              : "",
          options: StrokeOptions(
            size:
                modeState.inkGroupInfo.seletedStrokeWidth /
                modeState.scaleFactor,
            // fixedPen은 압력/두께 변화 없이 균일한 고정 두께를 유지한다.
            //   - thinning 0: 속도/압력에 따른 두께 변화 비활성화
            //   - simulatePressure false: 시뮬레이션 압력 무시
            thinning:
                modeState.inkGroupInfo.selectedInk == "pen" ? 0.7 : 0.0,
            smoothing: 0.5,
            streamline: 0.5,
            taperStart: 0.0,
            taperEnd: 0.0,
            capStart: true,
            capEnd: true,
            simulatePressure:
                modeState.inkGroupInfo.selectedInk != "fixedPen" &&
                modeState.allowedPointersMode != .penOnly,
          ),
        ),
      );
    }
    temporaryValue = switch (s) {
      Drawing() => s.copyWith(
        activePointerIds: [...state.activePointerIds, event.pointer],
      ),
      Erasing() => s.copyWith(
        activePointerIds: [...state.activePointerIds, event.pointer],
      ),
    };

    // 마커 펜 정지 감지: 그리기 시작 시점부터 타이머 가동
    if (modeState.inkGroupInfo.selectedInk == InkModes.marker &&
        state.activePointerIds.length == 1) {
      _startMarkerStraightenTimer(event.localPosition);
    } else {
      _cancelMarkerStraighten();
    }
  }

  /// preLocalPosition과 localPosition 사이에 직선을 긋는다.
  /// 직선과 선의 point들을 비교하여 직선과 점 사이의 거리가 stroke width 정도 되는걸 찾는다.
  /// 지우기 판정 후에는 [preLocalPosition]을 [event.localPosition]으로 갱신하여
  /// 판정 선분이 항상 '직전 move 위치 → 현재 위치'가 되도록 한다.
  @override
  bool onPointerUpdate(PointerMoveEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return false;
    // 스트로크를 소유하지 않은 포인터(그리는 중 닿은 두 번째 손가락 등)의
    // move는 활성 라인에 점을 추가하지 못하도록 무시한다.
    if (state.activePointerIds.isNotEmpty &&
        !state.activePointerIds.contains(event.pointer)) {
      return false;
    }
    if (!state.active) {
      temporaryValue = switch (state) {
        final Drawing s => s.copyWith(pointerPosition: null),
        final Erasing s => s.copyWith(pointerPosition: null),
      };
      return false;
    }

    if (state is Drawing) {
      // 마커 펜 직선화 이후: 새 포인트를 추가하지 않고 끝점만 갱신
      if (_markerStraightened &&
          modeState.inkGroupInfo.selectedInk == InkModes.marker) {
        final drawing = state as Drawing;
        final activeLine = drawing.activeLine;
        if (activeLine != null &&
            activeLine.ink == InkModes.marker &&
            activeLine.points.length >= 2) {
          final newEndPoint = getPointFromEvent(event);
          final updatedStroke = Stroke(
            points: [activeLine.points.first, newEndPoint],
            color: activeLine.color,
            ink: activeLine.ink,
            width: activeLine.width,
            createdAt: activeLine.createdAt,
            options: activeLine.options,
            shapeType: activeLine.shapeType,
          );
          temporaryValue = drawing.copyWith(
            activeLine: updatedStroke,
            pointerPosition: newEndPoint,
          );
          return true;
        }
      }

      // 마커 펜 정지 감지: 임계값 이상 이동 시 타이머 재시작
      if (modeState.inkGroupInfo.selectedInk == InkModes.marker &&
          _markerStraightenTimer != null) {
        final dx = event.localPosition.dx - _markerHoldAnchor.dx;
        final dy = event.localPosition.dy - _markerHoldAnchor.dy;
        if (dx * dx + dy * dy > kMarkerStraightenMoveThresholdSquared) {
          _startMarkerStraightenTimer(event.localPosition);
        }
      }

      // 도구 타입에 관계없이 포인트 추가 - 도형 도구도 드래그 중에 라인이 보이도록 함
      final addedState = addPoint(event, state, modeState) as Drawing;
      final newState = addedState.copyWith(
        pointerPosition: getPointFromEvent(event),
      );

      // Shape 도구인 경우 activeLine.shapeType은 'pending'으로 유지
      // 도형 변환은 onPointerUp에서만 수행됨
      if (newState.activeLine != null &&
          modeState.inkGroupInfo.selectedInk == InkModes.shape &&
          newState.activeLine!.shapeType.isEmpty) {
        // 드래그 중에도 쉐이프 타입을 'pending'으로 설정 (변환 예정을 표시)
        final activeLine = newState.activeLine!;
        // 새 Stroke 객체 생성하여 속성 복사
        final updatedActiveLine = Stroke(
          points: activeLine.points,
          color: activeLine.color,
          ink: activeLine.ink,
          width: activeLine.width,
          createdAt: activeLine.createdAt,
          options: activeLine.options,
          shapeType: "pending", // 도형 변환 예정 표시
        );

        temporaryValue = newState.copyWith(activeLine: updatedActiveLine);
      } else {
        temporaryValue = newState;
      }

      final result =
          newState.scribble.strokes.length != state.scribble.strokes.length;
      return result;
    } else if (state is Erasing) {
      final erasedState = erasePoint(event, modeState) as Erasing;
      final newState = erasedState.copyWith(
        pointerPosition: getPointFromEvent(event),
      );

      // 지우개는 실시간으로 화면을 갱신하되 히스토리에는 push하지 않는다.
      // (move마다 state=로 커밋하면 한 제스처가 수십 개의 undo 항목을 만들고
      //  maxHistoryLength 한도를 잠식해 지우기 이전 상태가 evict된다)
      // 제스처 단위 커밋은 onPointerUp/onPointerCancel이 담당한다.
      temporaryValue = newState;

      // 판정 선분이 '직전 move 위치 → 현재 위치'가 되도록 매번 갱신한다.
      // anchor를 50px 지연시키면 곡선 지우기 시 현(chord)이 실제 궤적 안쪽을
      // 지나가 닿지 않은 스트로크까지 삭제된다. 이벤트 간 갭 보간(선분 판정)은
      // 매번 갱신해도 그대로 유지된다.
      preLocalPosition = event.localPosition;

      // 지우개 모드에서는 포인터 위치가 업데이트되었으므로 true 반환
      return true;
    }
    return false;
  }

  /// Used by the Listener callback to finish a line
  @override
  void onPointerUp(PointerUpEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
    // 스트로크를 소유하지 않은 포인터의 up이 활성 라인에 점프 라인을 추가하고
    // 스트로크를 조기 종료시키는 것을 방지한다. (팜/두 번째 손가락의 up)
    if (state.activePointerIds.isNotEmpty &&
        !state.activePointerIds.contains(event.pointer)) {
      return;
    }
    _cancelMarkerStraighten();
    final pos = event.kind == .mouse ? state.pointerPosition : null;

    // 올가미 선택 도구를 사용하는 경우
    if (modeState.inkGroupInfo.selectedInk == InkModes.lasso) {
      // 현재 그리고 있는 올가미 스트로크를 완료
      final finishedState =
          finishLineForState(addPoint(event, state, modeState)) as Drawing;
      ScribbleState newState = finishedState.copyWith(
        pointerPosition: pos,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );

      // 완료된 상태에서 올가미 스트로크가 2개 이상인지 확인
      final lassoStrokes = newState.scribble.strokes
          .where((stroke) => stroke.ink == InkModes.lasso)
          .toList();

      // 올가미 스트로크가 2개 이상이면 가장 최근 것만 남기고 제거
      if (lassoStrokes.length > 1) {
        // 가장 최근 올가미 스트로크 찾기
        final latestLassoStroke = lassoStrokes.reduce(
          (a, b) =>
              DateTime.parse(a.createdAt).isAfter(DateTime.parse(b.createdAt))
              ? a
              : b,
        );

        // 최신 올가미를 제외한 모든 스트로크 필터링
        final updatedStrokes = newState.scribble.strokes
            .where(
              (stroke) =>
                  stroke.ink != InkModes.lasso || stroke == latestLassoStroke,
            )
            .toList();

        // 상태 업데이트 — 선택용 올가미 스트로크는 콘텐츠가 아니므로
        // undo 히스토리에 push하지 않는다 (temporaryValue).
        temporaryValue = switch (newState) {
          Drawing() => newState.copyWith(
            scribble: Scribble(
              x: newState.scribble.x,
              y: newState.scribble.y,
              width: newState.scribble.width,
              height: newState.scribble.height,
              strokes: updatedStrokes,
              textDrawables: newState.scribble.textDrawables, // 텍스트 필드 유지
              updatedAt: DateTime.now().toIso8601String(),
              version: newState.scribble.version,
            ),
          ),
          Erasing() => newState.copyWith(
            scribble: Scribble(
              x: newState.scribble.x,
              y: newState.scribble.y,
              width: newState.scribble.width,
              height: newState.scribble.height,
              strokes: updatedStrokes,
              textDrawables: newState.scribble.textDrawables, // 텍스트 필드 유지
              updatedAt: DateTime.now().toIso8601String(),
              version: newState.scribble.version,
            ),
          ),
        };
      } else {
        temporaryValue = newState;
      }

      // 올가미 스트로크가 있는지 확인
      final hasLassoStrokes = state.scribble.strokes.any(
        (stroke) => stroke.ink == InkModes.lasso,
      );
      if (hasLassoStrokes) {
        // 올가미 스트로크와 교차하는 다른 스트로크가 있는지 확인
        final lassoStroke = state.scribble.strokes.firstWhere(
          (stroke) => stroke.ink == InkModes.lasso,
        );

        // 올가미 포인트들을 Offset 리스트로 변환
        final lassoPoints = lassoStroke.points
            .map((point) => Offset(point.x, point.y))
            .toList();

        // 유효한 스트로크가 없다면 올가미 스트로크 제거
        if (!hasIntersectingStrokes(lassoPoints)) {
          removeLassoStrokes();
        }
      }
    } else if (state is Drawing) {
      final finished =
          finishLineForState(addPoint(event, state, modeState)) as Drawing;
      state = finished.copyWith(
        pointerPosition: pos,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
    } else if (state is Erasing) {
      final erased = erasePoint(event, modeState) as Erasing;
      final newState = erased.copyWith(
        pointerPosition: pos,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
      _commitEraseGesture(newState);
    }

    // 도형 도구를 사용하거나 도형 인식 기능이 활성화되어 있는 경우 도형 변환 처리
    if (modeState.inkGroupInfo.selectedInk == InkModes.shape ||
        _shapeRecognitionEnabled) {
      switch (state) {
        case Drawing(:final scribble):
          // 마지막으로 그린 스트로크 가져오기
          if (scribble.strokes.isNotEmpty) {
            final lastStrokeIndex = scribble.strokes.length - 1;
            final stroke = scribble.strokes[lastStrokeIndex];

            // shape 타입인 경우에만 도형 변환 수행
            if (stroke.ink == InkModes.shape ||
                (stroke.ink != InkModes.lasso && _shapeRecognitionEnabled)) {
              // ShapeDetector를 사용하여 도형 인식 및 변환
              final result = ShapeDetector.instance.detectAndTransform(
                stroke,
              );

              if (result.shapeType != .none) {
                // 변환된 스트로크를 적용
                final newStroke = result.transformedStroke;
                newStroke.shapeType = result.shapeTypeString;

                // 도형 변환 후 스크리블 업데이트
                final strokes = [...scribble.strokes];

                // 마지막 스트로크를 새로운 도형으로 교체
                strokes.removeLast();
                strokes.add(newStroke);

                // 상태 업데이트
                state = Drawing(
                  scribble: Scribble(
                    strokes: strokes,
                    x: scribble.x,
                    y: scribble.y,
                    width: scribble.width,
                    height: scribble.height,
                    textDrawables: scribble.textDrawables, // 텍스트 필드 유지
                    createdAt: scribble.createdAt,
                    updatedAt: DateTime.now().toIso8601String(),
                    version: scribble.version,
                  ),
                  activeLine: null,
                  activePointerIds: [],
                  pointerPosition: null,
                );
              }
            }
          }
        case Erasing():
          break;
      }
    }
  }

  /// Used by the Listener callback to stop displaying the cursor
  @override
  void onPointerCancel(
    PointerCancelEvent event,
    ScribbleModeState modeState,
  ) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
    // 소유하지 않은 포인터의 cancel은 활성 스트로크에 영향을 주지 않는다.
    if (state.activePointerIds.isNotEmpty &&
        !state.activePointerIds.contains(event.pointer)) {
      return;
    }
    _cancelMarkerStraighten();
    if (state is Drawing) {
      final finished =
          finishLineForState(addPoint(event, state, modeState)) as Drawing;
      state = finished.copyWith(
        pointerPosition: null,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
    } else if (state is Erasing) {
      final erased = erasePoint(event, modeState) as Erasing;
      final newState = erased.copyWith(
        pointerPosition: null,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
      _commitEraseGesture(newState);
    }
  }

  /// 지우개 제스처 종료 시 결과를 커밋한다.
  ///
  /// 제스처 동안 실제로 스트로크가 지워졌을 때만 히스토리에 push하여
  /// 한 제스처 = undo 1단위를 보장한다. 빈 탭(아무것도 안 지움)은
  /// temporaryValue로만 반영해 no-op 히스토리 항목과 redo 스택 파괴를 막는다.
  void _commitEraseGesture(ScribbleState newState) {
    final startCount =
        _eraseGestureStartStrokeCount ?? newState.scribble.strokes.length;
    _eraseGestureStartStrokeCount = null;
    if (newState.scribble.strokes.length != startCount) {
      state = newState;
    } else {
      temporaryValue = newState;
    }
  }

  @override
  void onPointerExit(PointerExitEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
    _cancelMarkerStraighten();
    final finished = finishLineForState(state);
    temporaryValue = switch (finished) {
      Drawing() => finished.copyWith(
        pointerPosition: null,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      ),
      Erasing() => finished.copyWith(
        pointerPosition: null,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      ),
    };
  }

  /// ♻️ StrokeProcessor로 위임
  ScribbleState addPoint(
    PointerEvent event,
    ScribbleState s,
    ScribbleModeState modeState,
  ) => strokeProcessor.addPointToStroke(event, s, modeState);

  /// ♻️ EraserProcessor로 위임
  ScribbleState erasePoint(PointerEvent event, ScribbleModeState modeState) =>
      eraserProcessor.eraseAtPoint(event, modeState, state, preLocalPosition);

  /// ♻️ StrokeProcessor로 위임
  Point getPointFromEvent(PointerEvent event) =>
      strokeProcessor.createPointFromEvent(event);

  /// ♻️ StrokeProcessor로 위임
  ScribbleState finishLineForState(ScribbleState s) =>
      strokeProcessor.finishStroke(s);

  /// 마커 정지 감지 타이머 시작
  void _startMarkerStraightenTimer(Offset anchor) {
    _markerStraightenTimer?.cancel();
    _markerHoldAnchor = anchor;
    _markerStraightened = false;
    _markerStraightenTimer = Timer(kMarkerStraightenDelay, _straightenMarkerStroke);
  }

  /// 마커 정지 상태 초기화
  void _cancelMarkerStraighten() {
    _markerStraightenTimer?.cancel();
    _markerStraightenTimer = null;
    _markerStraightened = false;
  }

  /// 마커 펜 stroke을 첫 점 → 마지막 점 직선으로 변환
  void _straightenMarkerStroke() {
    final s = state;
    if (s is! Drawing) return;
    final activeLine = s.activeLine;
    if (activeLine == null) return;
    if (activeLine.ink != InkModes.marker) return;
    if (activeLine.points.length < 2) return;

    final firstPoint = activeLine.points.first;
    final lastPoint = activeLine.points.last;

    final straightStroke = Stroke(
      points: [firstPoint, lastPoint],
      color: activeLine.color,
      ink: activeLine.ink,
      width: activeLine.width,
      createdAt: activeLine.createdAt,
      options: activeLine.options,
      shapeType: activeLine.shapeType,
    );

    _markerStraightened = true;
    temporaryValue = s.copyWith(activeLine: straightStroke);
  }

  /// 모든 올가미 스트로크를 제거하는 메서드
  void removeLassoStrokes() {
    final updatedScribble = Scribble(
      x: state.scribble.x,
      y: state.scribble.y,
      width: state.scribble.width,
      height: state.scribble.height,
      strokes: state.scribble.strokes
          .where((stroke) => stroke.ink != InkModes.lasso)
          .toList(),
      textDrawables: state.scribble.textDrawables, // 텍스트 필드 유지
      updatedAt: DateTime.now().toIso8601String(),
      version: state.scribble.version,
    );

    // 선택된 포인트 초기화를 위한 콜백 호출
    if (currContext != null) {
      final scribbleWidget = currContext!
          .findAncestorWidgetOfExactType<ScribbleWidget>();
      if (scribbleWidget != null) {
        scribbleWidget.onSelectionComplete?.call([], Matrix4.identity());
      }
    }

    temporaryValue = switch (state) {
      Drawing(:final activeLine) => Drawing(
        scribble: updatedScribble,
        activePointerIds: state.activePointerIds,
        activeLine: activeLine,
        pointerPosition: state.pointerPosition,
      ),
      Erasing(:final pointerPosition) => Erasing(
        scribble: updatedScribble,
        activePointerIds: state.activePointerIds,
        pointerPosition: pointerPosition,
      ),
    };
  }

  /// 올가미 스트로크와 교차하는 스트로크가 있는지 확인하는 메서드
  bool hasIntersectingStrokes(List<Offset> lassoPoints) {
    if (lassoPoints.length < 3) return false;

    // 올가미를 닫힌 경로로 만들기
    if (lassoPoints.first != lassoPoints.last) {
      lassoPoints.add(lassoPoints.first);
    }

    // 모든 스트로크 검사
    for (final stroke in state.scribble.strokes) {
      if (stroke.ink == "lasso" || stroke.points.isEmpty) continue;

      bool isStrokeInside = true;
      bool hasInsidePoint = false;

      // 스트로크의 모든 포인트가 올가미 내부에 있는지 확인
      for (final point in stroke.points) {
        final offsetPoint = Offset(point.x, point.y);
        if (_isPointInPolygon(offsetPoint, lassoPoints)) {
          hasInsidePoint = true;
        } else {
          isStrokeInside = false;
        }
      }

      // 스트로크가 올가미와 교차하는지 확인
      bool isStrokeIntersecting = false;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final start = Offset(stroke.points[i].x, stroke.points[i].y);
        final end = Offset(stroke.points[i + 1].x, stroke.points[i + 1].y);

        for (int j = 0; j < lassoPoints.length - 1; j++) {
          if (_doLinesIntersect(
            start,
            end,
            lassoPoints[j],
            lassoPoints[j + 1],
          )) {
            isStrokeIntersecting = true;
            break;
          }
        }
        if (isStrokeIntersecting) break;
      }

      // 스트로크가 올가미 내부에 있거나 교차하는 경우
      if (isStrokeInside || hasInsidePoint || isStrokeIntersecting) {
        return true;
      }
    }

    return false;
  }

  /// 텍스트 추가
  void addTextDrawable(TextDrawable textDrawable) {
    _updateScribbleWithTextDrawables(
      textDrawableManager.add(state.scribble, textDrawable),
    );
  }

  /// 텍스트 수정
  ///
  /// 드래그/변형 중간 프레임처럼 히스토리에 남기지 않을 업데이트는
  /// [addToUndoHistory]를 `false`로 전달한다. (최종 확정은 호출 측이
  /// `setScribble(addToUndoHistory: true)`로 1회 커밋)
  void updateTextDrawable(
    String id,
    TextDrawable updatedTextDrawable, {
    bool addToUndoHistory = true,
  }) {
    _updateScribbleWithTextDrawables(
      textDrawableManager.update(state.scribble, id, updatedTextDrawable),
      addToUndoHistory: addToUndoHistory,
    );
  }

  /// 텍스트 삭제
  void removeTextDrawable(String id) {
    _updateScribbleWithTextDrawables(
      textDrawableManager.remove(state.scribble, id),
    );
  }

  /// 현재 텍스트 목록 가져오기
  List<TextDrawable> getCurrentTextDrawables() =>
      textDrawableManager.getAll(state.scribble);

  /// 점이 다각형 내부에 있는지 확인하는 함수
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          (point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  /// 두 선분이 교차하는지 확인하는 함수
  bool _doLinesIntersect(Offset p1, Offset p2, Offset l1, Offset l2) {
    // 선분의 방향 벡터 계산
    final dx1 = p2.dx - p1.dx;
    final dy1 = p2.dy - p1.dy;
    final dx2 = l2.dx - l1.dx;
    final dy2 = l2.dy - l1.dy;

    // 선분의 방향성 확인
    final cross = dx1 * dy2 - dy1 * dx2;
    if (cross == 0) return false; // 평행한 경우

    // 교차점의 파라미터 계산
    final t = ((p1.dx - l1.dx) * dy2 - (p1.dy - l1.dy) * dx2) / cross;
    final u = ((p1.dx - l1.dx) * dy1 - (p1.dy - l1.dy) * dx1) / cross;

    // 교차점이 선분 위에 있는지 확인
    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  // ==================== 텍스트 관리 기능 (♻️ TextDrawableManager로 위임) ====================

  /// 텍스트로 스크리블 업데이트 (내부 메서드)
  void _updateScribbleWithTextDrawables(
    Scribble updatedScribble, {
    bool addToUndoHistory = true,
  }) {
    final newState = switch (state) {
      Drawing(
        :final activeLine,
        :final activePointerIds,
        :final pointerPosition,
      ) =>
        Drawing(
          scribble: updatedScribble,
          activeLine: activeLine,
          activePointerIds: activePointerIds,
          pointerPosition: pointerPosition,
        ),
      Erasing(:final activePointerIds, :final pointerPosition) => Erasing(
        scribble: updatedScribble,
        activePointerIds: activePointerIds,
        pointerPosition: pointerPosition,
      ),
    };
    if (addToUndoHistory) {
      state = newState;
    } else {
      temporaryValue = newState;
    }
  }

  @override
  void dispose() {
    _markerStraightenTimer?.cancel();
    _markerStraightenTimer = null;
    super.dispose();
  }
}
