// 🎯 Dart imports:
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:fixnum/fixnum.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';
import 'package:value_notifier_tools/value_notifier_tools.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/state/drawing_state.dart';

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
  ScribbleNotifier({
    /// If you pass a scribble here, the notifier will use that scribble as a
    /// starting point.
    Scribble? scribble,

    /// How many states you want stored in the undo history, 30 by default.
    int maxHistoryLength = 30,

    /// 필기 영역 가로 사이즈
    /// 백그라운드 이미지 사이즈와 동일 합니다
    double? width,

    /// 필기 영역 세로 사이즈
    /// 백그라운드 이미지 사이즈와 동일 합니다
    double? height,

    /// [origin]의 x 좌표 값
    double? x,

    /// [origin]의 y 좌표 값
    double? y,

    /// 현재 필기 데이터의 앱 버전
    String? version,

    /// The curve that's used to map pen pressure to the pressure value when
    /// recording, by default it's linear.
    this.pressureCurve = Curves.linear,
  }) : super(
         Drawing(
           scribble:
               scribble ??
               Scribble(
                 strokes: [],
                 width: width,
                 height: height,
                 x: x,
                 y: y,
                 createdAt: DateTime.now().toIso8601String(),
                 version: version,
               ),
         ),
       ) {
    state = Drawing(
      scribble:
          scribble ??
          Scribble(
            strokes: [],
            width: width,
            height: height,
            x: x,
            y: y,
            createdAt: DateTime.now().toIso8601String(),
            version: version,
          ),
    );
    this.maxHistoryLength = maxHistoryLength;

    // 초기화 시 모든 올가미 스트로크 제거
    removeLassoStrokes();
  }

  BuildContext? currContext;

  /// The curve that's used to map pen pressure to the pressure value when
  /// recording.
  final Curve pressureCurve;

  /// The state of the scribble at this moment.
  ///
  /// If you want to store it somewhere you can call ``.toJson()`` on it to
  /// receive a map.
  Scribble get currentScribble => state.scribble;

  /// 선의 1번째 점이 되는 이전 좌표를 저장하는 변수
  Offset preLocalPosition = const Offset(0, 0);

  /// Only apply the scribble from the undo history, otherwise keep current state
  @override
  @protected
  ScribbleState transformHistoryValue(
    ScribbleState historyState,
    ScribbleState currentState,
  ) {
    // 올가미 스트로크가 있는지 확인
    final hasLassoStrokes = historyState.scribble.strokes.any(
      (stroke) => stroke.ink == InkModes.lasso,
    );

    // 올가미 스트로크가 있다면 올가미 도구 선택
    if (hasLassoStrokes) {
      setLassoSelection();
    }

    return switch (currentState) {
      final Drawing s => s.copyWith(scribble: historyState.scribble),
      final Erasing s => s.copyWith(scribble: historyState.scribble),
    };
  }

  /// Can be used to update the state of the Scribble externally (e.g. when
  /// fetching from a server) to what is passed in as [scribble];
  ///
  /// Per default, this state of the scribble gets added to the undo history. If
  /// this is not desired, set [addToUndoHistory] to ``false``.
  void setScribble({required Scribble scribble, bool addToUndoHistory = true}) {
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

  /// Clear the entire drawing.
  void clear() {
    if (state.scribble.strokes.isEmpty) return;
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

  /// 도형 인식 기능 활성화 상태
  bool _shapeRecognitionEnabled = false;

  /// 도형 인식 기능을 활성화 또는 비활성화합니다.
  /// [enabled]가 true이면 도형 인식 기능이 활성화되고, false이면 비활성화됩니다.
  void setShapeRecognition(bool enabled) {
    _shapeRecognitionEnabled = enabled;
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
    if (event.kind == PointerDeviceKind.touch &&
        state.activePointerIds.isNotEmpty) {
      return;
    }
    // 터치하는 순간 이전 좌표와 현재 좌표를 같게 만든다.
    preLocalPosition = event.localPosition;
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
            thinning: modeState.inkGroupInfo.selectedInk == "pen" ? 0.7 : 0.0,
            smoothing: 0.5,
            streamline: 0.5,
            taperStart: 0.0,
            taperEnd: 0.0,
            capStart: true,
            capEnd: true,
            simulatePressure:
                modeState.allowedPointersMode != ScribblePointerMode.penOnly,
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
  }

  /// preLoacation과 location 사이에 직선을 긋는다.
  /// 직선과 선의 point들을 비교하여 직선과 점 사이의 거리가 stroke width 정도 되는걸 찾는다.
  /// 만약 [preLocalPosition]과 [event.localPosition] 차이가 50px이 되면
  /// [preLocalPosition]을 [event.localPosition]으로 설정한다.
  @override
  bool onPointerUpdate(PointerMoveEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return false;
    if (!state.active) {
      temporaryValue = switch (state) {
        final Drawing s => s.copyWith(pointerPosition: null),
        final Erasing s => s.copyWith(pointerPosition: null),
      };
      return false;
    }

    if (state is Drawing) {
      // 도구 타입에 관계없이 포인트 추가 - 도형 도구도 드래그 중에 라인이 보이도록 함
      final addedState = addPoint(event, state, modeState) as Drawing;
      final newState = addedState.copyWith(
        pointerPosition: getPointFromEvent(event),
      );

      // Shape 도구인 경우 activeLine.shapeType은 'pending'으로 유지
      // 도형 변환은 onPointerUp에서만 수행됨
      if (newState is Drawing &&
          newState.activeLine != null &&
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

      // 지우개는 실시간으로 상태를 업데이트해야 함
      final strokeCountChanged =
          newState.scribble.strokes.length != state.scribble.strokes.length;

      if (strokeCountChanged) {
        // 실제 상태도 즉시 업데이트
        state = newState;
      } else {
        // 스트로크 변경이 없어도 포인터 위치는 업데이트
        temporaryValue = newState;
      }

      /// 만약 [preLocalPosition]과 [event.localPosition] 차이가 50px이 되면
      /// [preLocalPosition]을 [event.localPosition]으로 설정한다.
      if ((event.localPosition - preLocalPosition).distance > 50) {
        preLocalPosition = event.localPosition;
      }

      // 지우개 모드에서는 포인터 위치가 업데이트되었으므로 true 반환
      return true;
    }
    return false;
  }

  /// Used by the Listener callback to finish a line
  @override
  void onPointerUp(PointerUpEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
    final pos = event.kind == PointerDeviceKind.mouse
        ? state.pointerPosition
        : null;

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

        // 상태 업데이트
        state = switch (newState) {
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
        state = newState;
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
      state = erased.copyWith(
        pointerPosition: pos,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
    }

    // 도형 도구를 사용하거나 도형 인식 기능이 활성화되어 있는 경우 도형 변환 처리
    if (modeState.inkGroupInfo.selectedInk == InkModes.shape ||
        _shapeRecognitionEnabled) {
      switch (state) {
        case Drawing(scribble: final scribble):
          // 마지막으로 그린 스트로크 가져오기
          if (scribble.strokes.isNotEmpty) {
            final lastStrokeIndex = scribble.strokes.length - 1;
            final stroke = scribble.strokes[lastStrokeIndex];

            // shape 타입인 경우에만 도형 변환 수행
            if (stroke.ink == InkModes.shape ||
                (stroke.ink != InkModes.lasso && _shapeRecognitionEnabled)) {
              // ShapeDetector를 사용하여 도형 인식 및 변환
              final result = ShapeDetector.instance.detectAndTransform(stroke);

              if (result.shapeType != ShapeType.none) {
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
  void onPointerCancel(PointerCancelEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
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
      state = erased.copyWith(
        pointerPosition: null,
        activePointerIds: state.activePointerIds
            .where((id) => id != event.pointer)
            .toList(),
      );
    }
  }

  @override
  void onPointerExit(PointerExitEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
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

  ScribbleState addPoint(
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
        points: [...currentLine.points, getPointFromEvent(event)],
        color: currentLine.color,
        ink: currentLine.ink,
        width: currentLine.width,
        createdAt: currentLine.createdAt,
        options: currentLine.options,
        shapeType: currentLine.shapeType,
      ),
    );
  }

  ScribbleState erasePoint(PointerEvent event, ScribbleModeState modeState) {
    // 최소 값을 구하기 위해 임시로 설정한 변수
    double minData = double.infinity;
    final newScribble = Scribble(
      x: state.scribble.x,
      y: state.scribble.y,
      width: state.scribble.width,
      height: state.scribble.height,
      strokes: state.scribble.strokes
          .where(
            (stroke) => stroke.points.every((pt) {
              final intersect = getInterSectionPoint(event, pt);
              // 그려져 있는 선들의 점 굵기를 계산한다.
              final lineTarget =
                  modeState.inkGroupInfo.seletedStrokeWidth /
                      modeState.scaleFactor +
                  getStrokeRadius(
                    stroke.options.size,
                    stroke.options.thinning,
                    stroke.ink == "pen" ? stroke.points.first.p : pt.p,
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
                  ? getDistance(pt, intersect)
                  : math.min(
                      getDistance(pt, preLocalPosition),
                      getDistance(pt, event.localPosition),
                    ));

              minData = math.min(minData, minDistance);
              // 구한 교점이 선분 위에 있으면 p 와 a 와의 거리가 최소 거리
              return minDistance >= lineTarget;
            }),
          )
          .toList(),
      textDrawables: state.scribble.textDrawables, // 텍스트 필드 유지
      version: state.scribble.version,
    );
    return switch (state) {
      final Drawing s => s.copyWith(scribble: newScribble),
      final Erasing s => s.copyWith(scribble: newScribble),
    };
  }

  /// 점과 선 사이의 교점을 구하는 함수
  Offset getInterSectionPoint(PointerEvent event, Point p) {
    final Offset a;
    final double m1;
    final double k1;
    final double m2;
    final double k2;

    if (preLocalPosition.dx == event.localPosition.dx) {
      a = Offset(preLocalPosition.dx, p.y);
    }
    // 선분이 수평일 경우
    else if (preLocalPosition.dy == event.localPosition.dy) {
      a = Offset(p.x, preLocalPosition.dy);
    }
    // 그 외의 경우
    else {
      m1 =
          (preLocalPosition.dy - event.localPosition.dy) /
          (preLocalPosition.dx - event.localPosition.dx);

      k1 = -m1 * preLocalPosition.dx + preLocalPosition.dy;

      m2 = -1.0 / m1;
      k2 = p.y - m2 * p.x;
      a = Offset((k2 - k1) / (m1 - m2), (m1 * (k2 - k1) / (m1 - m2) + k1));
    }
    return a;
  }

  /// 점 a와 점 b 사이의 거리를 구하는 함수
  double getDistance(Point a, Offset b) =>
      math.sqrt(math.pow(b.dx - a.x, 2) + math.pow(b.dy - a.y, 2));

  /// Converts a pointer event to the [Point] on the canvas.
  Point getPointFromEvent(PointerEvent event) {
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

  ScribbleState finishLineForState(ScribbleState s) {
    if (s is! Drawing || s.activeLine == null) {
      return s;
    }
    return s.copyWith(
      activeLine: null,
      scribble: Scribble(
        x: state.scribble.x,
        y: state.scribble.y,
        width: state.scribble.width,
        height: state.scribble.height,
        strokes: [...s.scribble.strokes, s.activeLine!],
        textDrawables: state.scribble.textDrawables,
        updatedAt: DateTime.now().toIso8601String(),
        version: s.scribble.version,
      ),
    );
  }

  /// Get the stroke's radius, given its size, thinning and p.
  double getStrokeRadius(double size, double thinning, double p) {
    return size * (0.5 - thinning * (0.5 - p));
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

  /// 올가미 선택을 초기화하고 새로운 올가미를 그릴 수 있도록 하는 메서드
  void resetLassoSelection() {
    // 올가미 스트로크 제거
    removeLassoStrokes();

    // 상태 초기화
    temporaryValue = switch (state) {
      final Drawing s => s.copyWith(pointerPosition: null),
      final Erasing s => s.copyWith(pointerPosition: null),
    };
  }

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

  /// 올가미 스트로크와 교차하는 스트로크를 찾는 메서드
  List<int> findStrokesInLasso(List<Offset> lassoPoints) {
    final result = <int>[];

    if (lassoPoints.length < 3) {
      return result;
    }

    // 올가미를 닫힌 경로로 만들기
    if (lassoPoints.first != lassoPoints.last) {
      lassoPoints.add(lassoPoints.first);
    }

    final numStrokes = state.scribble.strokes.length;

    for (int i = 0; i < numStrokes; i++) {
      final stroke = state.scribble.strokes[i];

      // 올가미 스트로크는 제외
      if (stroke.ink == InkModes.lasso || stroke.points.isEmpty) {
        continue;
      }

      // 스트로크의 모든 포인트가 올가미 내부에 있는지 확인
      bool isStrokeInside = true;
      bool hasInsidePoint = false;

      // 스트로크의 포인트들을 검사
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
      for (int j = 0; j < stroke.points.length - 1; j++) {
        final start = Offset(stroke.points[j].x, stroke.points[j].y);
        final end = Offset(stroke.points[j + 1].x, stroke.points[j + 1].y);

        for (int k = 0; k < lassoPoints.length - 1; k++) {
          if (_doLinesIntersect(
            start,
            end,
            lassoPoints[k],
            lassoPoints[k + 1],
          )) {
            isStrokeIntersecting = true;
            break;
          }
        }
        if (isStrokeIntersecting) break;
      }

      // 스트로크가 올가미 내부에 있거나 교차하는 경우 선택
      if (isStrokeInside || hasInsidePoint || isStrokeIntersecting) {
        result.add(i);
      }
    }

    return result;
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

  /// 현재 ScribbleState 전체 반환 (외부 접근용)
  ScribbleState get currentState => state;

  // ==================== 텍스트 관리 기능 ====================

  /// 텍스트 추가
  void addTextDrawable(TextDrawable textDrawable) {
    final currentTextDrawables = getCurrentTextDrawables();
    final updatedTextDrawables = [...currentTextDrawables, textDrawable];

    _updateScribbleWithTextDrawables(updatedTextDrawables);
  }

  /// 텍스트 수정
  void updateTextDrawable(String id, TextDrawable updatedTextDrawable) {
    final currentTextDrawables = getCurrentTextDrawables();
    final updatedTextDrawables = currentTextDrawables.map((textDrawable) {
      return textDrawable.id == id ? updatedTextDrawable : textDrawable;
    }).toList();

    _updateScribbleWithTextDrawables(updatedTextDrawables);
  }

  /// 텍스트 삭제
  void removeTextDrawable(String id) {
    final currentTextDrawables = getCurrentTextDrawables();
    final updatedTextDrawables = currentTextDrawables
        .where((textDrawable) => textDrawable.id != id)
        .toList();

    _updateScribbleWithTextDrawables(updatedTextDrawables);
  }

  /// 모든 텍스트 삭제
  void clearAllTextDrawables() {
    _updateScribbleWithTextDrawables([]);
  }

  /// 현재 텍스트 목록 가져오기
  List<TextDrawable> getCurrentTextDrawables() {
    // 프로토버퍼 스크리블에서 텍스트 목록 반환
    return state.scribble.textDrawables;
  }

  /// 텍스트로 스크리블 업데이트 (내부 메서드)
  void _updateScribbleWithTextDrawables(List<TextDrawable> textDrawables) {
    // 현재 상태를 유지하면서 텍스트만 업데이트
    final updatedScribble = Scribble(
      x: state.scribble.x,
      y: state.scribble.y,
      width: state.scribble.width,
      height: state.scribble.height,
      strokes: state.scribble.strokes,
      textDrawables: textDrawables, // 텍스트 필드 추가
      createdAt: state.scribble.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      version: state.scribble.version,
    );

    state = switch (state) {
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
  }

  /// 텍스트 ID로 찾기
  TextDrawable? findTextDrawableById(String id) {
    final textDrawables = getCurrentTextDrawables();
    try {
      return textDrawables.firstWhere((textDrawable) => textDrawable.id == id);
    } on Exception catch (error, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint(error.toString());
      return null;
    }
  }

  /// 위치로 텍스트 찾기
  TextDrawable? findTextDrawableAtPosition(
    Offset position, {
    double tolerance = 10.0,
  }) {
    final textDrawables = getCurrentTextDrawables();

    for (final textDrawable in textDrawables) {
      final textPosition = textDrawable.position;
      final distance = (textPosition - position).distance;

      if (distance <= tolerance) {
        return textDrawable;
      }
    }

    return null;
  }

  /// 텍스트 숨김/표시 토글
  void toggleTextDrawableVisibility(String id) {
    final textDrawable = findTextDrawableById(id);
    if (textDrawable != null) {
      final updatedTextDrawable = textDrawable.copyWithHidden(
        !textDrawable.hidden,
      );
      updateTextDrawable(id, updatedTextDrawable);
    }
  }

  /// 텍스트 위치 이동
  void moveTextDrawable(String id, Offset newPosition) {
    final textDrawable = findTextDrawableById(id);
    if (textDrawable != null) {
      final updatedTextDrawable = textDrawable.copyWithPosition(newPosition);
      updateTextDrawable(id, updatedTextDrawable);
    }
  }

  /// 선택된 텍스트들 삭제 (올가미 선택과 연동)
  void deleteSelectedTextDrawables(List<String> selectedTextIds) {
    final currentTextDrawables = getCurrentTextDrawables();
    final updatedTextDrawables = currentTextDrawables
        .where((textDrawable) => !selectedTextIds.contains(textDrawable.id))
        .toList();

    _updateScribbleWithTextDrawables(updatedTextDrawables);
  }

  /// 텍스트 스타일 일괄 변경
  void updateTextDrawableStyle(
    String id, {
    String? fontFamily,
    double? fontSize,
    Color? color,
    bool? isBold,
    bool? isItalic,
    bool? isUnderlined,
    TextAlignment? textAlignment,
  }) {
    final textDrawable = findTextDrawableById(id);
    if (textDrawable != null) {
      final currentStyle = textDrawable.style;
      final updatedStyle = TextStyle(
        fontFamily: fontFamily ?? currentStyle.fontFamily,
        fontSize: fontSize ?? currentStyle.fontSize,
        color: color ?? currentStyle.color,
        fontWeight: isBold != null
            ? (isBold ? FontWeight.bold : FontWeight.normal)
            : currentStyle.fontWeight,
        fontStyle: isItalic != null
            ? (isItalic ? FontStyle.italic : FontStyle.normal)
            : currentStyle.fontStyle,
        decoration: isUnderlined != null
            ? (isUnderlined ? TextDecoration.underline : null)
            : currentStyle.decoration,
      );

      final updatedTextDrawable = textDrawable
          .copyWithStyle(updatedStyle)
          .copyWithAlignment(textAlignment ?? textDrawable.alignment);
      updateTextDrawable(id, updatedTextDrawable);
    }
  }
}
