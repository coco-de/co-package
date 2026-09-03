// 🎯 Dart imports:
import 'dart:async';

// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// 📦 Package imports:
import 'package:value_notifier_tools/value_notifier_tools.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';
import 'package:open_board/src/core/utils/extensions/scribble_extension.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';
import 'package:open_board/src/core/utils/shape_detector.dart';
import 'package:open_board/src/core/utils/stroke_id.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/stroke/stroke_processor.dart';
import 'package:open_board/src/module/stroke/eraser_processor.dart';
import 'package:open_board/src/module/text/text_drawable_manager.dart';
import 'package:open_board/src/module/image/image_drawable_manager.dart';

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
  /// 마커 펜 정지 시 직선 변환까지의 대기 시간
  static const Duration kMarkerStraightenDelay = Duration(milliseconds: 1500);

  /// 일반 펜(pen/pencil/fixedPen) 정지 시 직선 변환까지의 대기 시간
  static const Duration kPenStraightenDelay = Duration(milliseconds: 2000);

  /// 펜 정지 판정 이동 임계값(픽셀, 제곱값으로 비교)
  static const double kStraightenMoveThresholdSquared = 9.0;

  /// 정지 직선 변환이 적용되는 잉크 모드
  ///
  /// shape는 자체 도형 변환이 있고, lasso/erase/text는 드로잉 도구가 아니므로
  /// 제외한다.
  static const Set<String> kStraightenableInks = {
    InkModes.pen,
    InkModes.pencil,
    InkModes.marker,
    InkModes.fixedPen,
  };

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

  /// 🖼️ 이미지 관리자
  final ImageDrawableManager imageDrawableManager =
      const ImageDrawableManager();

  /// 선의 1번째 점이 되는 이전 좌표를 저장하는 변수
  Offset preLocalPosition = const Offset(0, 0);

  /// 펜 정지 감지 타이머
  Timer? _straightenTimer;

  /// 펜 정지 기준 위치(가장 마지막으로 의미 있는 이동이 발생한 좌표)
  Offset _holdAnchor = Offset.zero;

  /// 활성 스트로크가 직선으로 변환되었는지 여부 (변환 후에는 끝점만 추종)
  bool _strokeStraightened = false;

  /// 지우개 제스처 시작 시점의 스트로크 수
  ///
  /// 한 번의 지우개 제스처(down→move…→up)를 undo 1단위로 만들기 위해
  /// 제스처 시작 시 스냅샷을 기록하고, up/cancel에서 실제로 스트로크가
  /// 지워졌을 때만 히스토리에 커밋한다.
  int? _eraseGestureStartStrokeCount;

  /// undo/redo로 히스토리 상태가 적용된 직후 호출되는 콜백
  ///
  /// 인덱스 기반 선택(올가미 등)은 undo/redo로 스트로크 목록이 바뀌면
  /// 무효화되므로, 이 콜백으로 선택 상태를 리셋할 기회를 제공한다.
  VoidCallback? onHistoryApplied;

  /// [setScribble]/[_updateScribbleWithTextDrawables] 가 `addToUndoHistory:
  /// true` 로 히스토리에 실제로 커밋된 직후 호출되는 콜백.
  ///
  /// 펜/지우개 그리기 완료는 `onPointerUp` 이 `state` 를 직접 대입해 이
  /// 경로를 거치지 않는다(`PointerEventHandler.handlePointerUp` 이 별도로
  /// `ScribbleWidget.onScribbleFinished` 를 호출한다). 반면 올가미 이동/
  /// 크기조절/회전, 텍스트 추가/편집/이동/변형/삭제, 이미지 이동/크기조절/
  /// 삭제는 모두 이 두 메서드를 거치므로, 이 콜백 하나로 그 모든 "제스처
  /// 완료" 시점을 커버한다. `value`/`temporaryValue` 변경(값 리스너)은 드래그
  /// 중 매 프레임에도 발화해 진행 중 상태와 완료 시점을 구분할 수 없는
  /// 반면, 이 콜백은 `addToUndoHistory: false`(드래그 중간 프레임)에는
  /// 호출되지 않는다 (kobic#10836).
  VoidCallback? onScribbleFinished;

  /// 새 스트로크에 부여할 [Stroke.id] 를 만드는 함수.
  ///
  /// 기본값은 `Random.secure()` 기반 v4 UUID 다. 호스트가 자체 규칙(예: 서버
  /// 발급 id, 테스트 결정론)을 쓰려면 생성자로 주입한다 — `LinkTargetResolver`
  /// 와 같은 주입 선례를 따른다.
  ///
  /// ⛔ **시각 기반 값을 넣지 말 것.** 오프라인 다중 기기에서 같은 밀리초에
  /// 그린 스트로크가 충돌한다. 그것이 이 필드를 도입한 이유의 절반이다.
  final String Function() strokeIdFactory;

  ScribbleNotifier({
    /// If you pass a scribble here, the notifier will use that scribble as a
    /// starting point.
    Scribble? scribble,
    String Function()? strokeIdFactory,
  }) : strokeIdFactory = strokeIdFactory ?? generateStrokeId,
       super(
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

  /// 펜 정지 감지 타이머 활성 여부 (테스트 전용)
  @visibleForTesting
  bool get debugStraightenTimerActive => _straightenTimer?.isActive ?? false;

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

    // 히스토리 적용 알림은 상태 변환이 끝난 뒤로 미룬다.
    if (onHistoryApplied != null) {
      scheduleMicrotask(() => onHistoryApplied?.call());
    }

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
  void setScribble({required Scribble scribble, bool addToUndoHistory = true}) {
    final newState = switch (state) {
      final Drawing s => s.copyWith(scribble: scribble),
      final Erasing s => s.copyWith(scribble: scribble),
    };
    if (addToUndoHistory) {
      state = newState;
      onScribbleFinished?.call();
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

  /// 포인터 이벤트 없이(손/팬 모드 전환 등) 호출해 커서 잔상을 제거한다.
  ///
  /// `onPointerExit` 와 동일하게 `pointerPosition` 만 null 로 지워 지우개 커서
  /// (회색 원)를 숨긴다. 손(팬)모드 전환처럼 포인터가 캔버스를 떠나지 않아 exit
  /// 이벤트가 발생하지 않는 경우, 마지막 지우개 위치에 커서가 잔상으로 남는 문제를
  /// 방지한다(kobic UB-108). 이미 커서가 없으면 no-op. 커서 표시는 히스토리
  /// 대상이 아니므로 `temporaryValue` 로만 갱신한다.
  void clearCursor() {
    if (state.pointerPosition == null) return;
    temporaryValue = switch (state) {
      final Drawing s => s.copyWith(pointerPosition: null),
      final Erasing s => s.copyWith(pointerPosition: null),
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
      // 핀치 줌 시작: 진행 중인 펜 정지 직선화를 중단해
      // 핀치 도중 스트로크가 직선으로 변환·커밋되는 것을 방지한다.
      _cancelStraighten();
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
      final selectedInk = modeState.inkGroupInfo.selectedInk;
      final strokeWidth = modeState.inkGroupInfo.seletedStrokeWidth;
      // shape 도구의 타겟 도형: '' 이면 자유 도형(자유 필기 후 자동 인식,
      // shapeType 'pending'), 그 외(line/ellipse/rectangle)면 그 자체를
      // shapeType 으로 두어 드래그 bounding-box 결정적 드로잉을 한다.
      final shapeTarget = modeState.inkGroupInfo.shapeType;
      s = (state as Drawing).copyWith(
        pointerPosition: getPointFromEvent(event),
        activeLine: Stroke(
          // 스트로크의 유일한 발급 지점 — 여기서 한 번 부여하면 이후 모든
          // 재구성은 `deepCopy` 로 승계한다. 완료 후 재발급하지 않는다.
          id: strokeIdFactory(),
          points: [getPointFromEvent(event)],
          color: colorToInt(modeState.inkGroupInfo.selectedColor),
          ink: selectedInk,
          width: strokeWidth,
          createdAt: DateTime.now().toIso8601String(),
          shapeType: selectedInk == InkModes.shape
              ? (shapeTarget.isEmpty ? "pending" : shapeTarget)
              : "",
          options: StrokeOptions(
            // size 두께 정책은 modeState.options(단일 진실 공급원)에 위임한다.
            // BrushMode 표준안(kobic #7160): fixedPen(화면비례)만 줌 배율로 보정해
            // 화면상 물리 두께를 일정하게 유지(반응형), 그 외(pen=필압,
            // uniformPen=균일)는 콘텐츠 좌표계 고정 두께라 확대 시 콘텐츠와 함께
            // 굵어진다. 커서 미리보기와 실제 스트로크 두께가 일치한다.
            size: modeState.options.size,
            // 필압(두께 변화)은 pen 만 적용. uniformPen/fixedPen 은 균일 두께.
            thinning: selectedInk == InkModes.pen ? 0.7 : 0.0,
            smoothing: 0.5,
            streamline: 0.5,
            taperStart: 0.0,
            taperEnd: 0.0,
            capStart: true,
            capEnd: true,
            // 균일 계열(uniformPen/fixedPen)은 가짜 압력도 끈다. penOnly
            // (스타일러스)는 실제 압력을 쓰므로 시뮬레이션 비활성화.
            simulatePressure:
                selectedInk != InkModes.fixedPen &&
                selectedInk != InkModes.uniformPen &&
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

    // 펜 정지 감지: 그리기 시작 시점부터 타이머 가동
    if (kStraightenableInks.contains(modeState.inkGroupInfo.selectedInk) &&
        state.activePointerIds.length == 1) {
      _startStraightenTimer(
        modeState.inkGroupInfo.selectedInk,
        event.localPosition,
      );
    } else {
      _cancelStraighten();
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

    final selectedInk = modeState.inkGroupInfo.selectedInk;
    final isStraightenableInk = kStraightenableInks.contains(selectedInk);
    if (state is Drawing) {
      // 결정적 도형(타원/사각형/선분): 포인트를 누적하지 않고 시작점→현재점
      // 2점 rubber-band 로 activeLine 을 재구성한다. (자유 도형은 shapeTarget=''
      // 이라 이 분기를 타지 않고 기존 손그림+자동 인식 경로를 유지한다.)
      final shapeTarget = modeState.inkGroupInfo.shapeType;
      if (selectedInk == InkModes.shape && shapeTarget.isNotEmpty) {
        final drawing = state as Drawing;
        final activeLine = drawing.activeLine;
        if (activeLine != null && activeLine.points.isNotEmpty) {
          final startPoint = activeLine.points.first;
          final endPoint = getPointFromEvent(event);
          // 필드 열거 복사 금지 — 미지정 필드가 조용히 유실된다. deepCopy 로
          // 전 필드를 승계하고 바뀌는 것만 덮어쓴다.
          final updatedStroke = activeLine.deepCopy()
            ..points.clear()
            ..points.addAll([startPoint, endPoint])
            ..shapeType = shapeTarget;
          temporaryValue = drawing.copyWith(
            activeLine: updatedStroke,
            pointerPosition: endPoint,
          );
          return true;
        }
      }

      // 펜 직선화 이후: 새 포인트를 추가하지 않고 끝점만 갱신
      if (_strokeStraightened && isStraightenableInk) {
        final drawing = state as Drawing;
        final activeLine = drawing.activeLine;
        if (activeLine != null &&
            kStraightenableInks.contains(activeLine.ink) &&
            activeLine.points.length >= 2) {
          final newEndPoint = getPointFromEvent(event);
          final updatedStroke = activeLine.deepCopy()
            ..points.clear()
            ..points.addAll([activeLine.points.first, newEndPoint]);
          temporaryValue = drawing.copyWith(
            activeLine: updatedStroke,
            pointerPosition: newEndPoint,
          );
          return true;
        }
      }

      // 펜 정지 감지: 임계값 이상 이동 시 타이머 재시작
      if (isStraightenableInk && _straightenTimer != null) {
        final dx = event.localPosition.dx - _holdAnchor.dx;
        final dy = event.localPosition.dy - _holdAnchor.dy;
        if (dx * dx + dy * dy > kStraightenMoveThresholdSquared) {
          _startStraightenTimer(selectedInk, event.localPosition);
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
          selectedInk == InkModes.shape &&
          newState.activeLine!.shapeType.isEmpty) {
        // 드래그 중에도 쉐이프 타입을 'pending'으로 설정 (변환 예정을 표시)
        final activeLine = newState.activeLine!;
        // 전 필드를 승계한 사본에 도형 변환 예정만 표시한다(열거 복사 금지).
        final updatedActiveLine = activeLine.deepCopy()..shapeType = "pending";

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
    final wasStraightened = _strokeStraightened;
    _cancelStraighten();
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
            scribble: newState.scribble.copyWithContents(
              strokes: updatedStrokes,
            ),
          ),
          Erasing() => newState.copyWith(
            scribble: newState.scribble.copyWithContents(
              strokes: updatedStrokes,
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
      final shapeTarget = modeState.inkGroupInfo.selectedInk == InkModes.shape
          ? modeState.inkGroupInfo.shapeType
          : "";
      final remainingPointerIds = state.activePointerIds
          .where((id) => id != event.pointer)
          .toList();

      if (shapeTarget.isNotEmpty) {
        // 결정적 도형: 시작점→up 점 2점으로 확정하고 자동 인식은 건너뛴다.
        final drawing = state as Drawing;
        final activeLine = drawing.activeLine;
        final startPoint = (activeLine != null && activeLine.points.isNotEmpty)
            ? activeLine.points.first
            : null;
        final endPoint = getPointFromEvent(event);
        if (activeLine != null &&
            startPoint != null &&
            (startPoint.x != endPoint.x || startPoint.y != endPoint.y)) {
          final finalStroke = activeLine.deepCopy()
            ..points.clear()
            ..points.addAll([startPoint, endPoint])
            ..shapeType = shapeTarget;
          final finished =
              finishLineForState(drawing.copyWith(activeLine: finalStroke))
                  as Drawing;
          state = finished.copyWith(
            pointerPosition: pos,
            activePointerIds: remainingPointerIds,
          );
        } else {
          // 드래그가 없으면(시작==끝) 도형을 만들지 않고 활성 라인만 폐기한다.
          // copyWith(activeLine: null)은 null 병합으로 지워지지 않으므로 직접 생성.
          state = Drawing(
            scribble: drawing.scribble,
            activeLine: null,
            activePointerIds: remainingPointerIds,
            selectedStrokeIds: drawing.selectedStrokeIds,
            pointerPosition: pos,
          );
        }
      } else {
        // 자유 도형/일반 필기: 기존 손그림 커밋 + 자동 인식 경로.
        // 직선화된 스트로크는 끝점이 이미 마지막 move를 추종하고 있으므로,
        // up 지점을 추가하면 직선 끝이 꺾인다. 점 추가를 건너뛴다.
        final finished =
            finishLineForState(
                  wasStraightened ? state : addPoint(event, state, modeState),
                )
                as Drawing;
        final newState = finished.copyWith(
          pointerPosition: pos,
          activePointerIds: remainingPointerIds,
        );

        // 도형 도구 사용 시 마지막 스트로크를 변환해 한 번에 커밋한다.
        // (손그림 커밋 + 변환 커밋을 각각 push하면 도형 1개에 undo 2회가 필요)
        state = _transformLastStrokeToShape(newState, modeState) ?? newState;
      }
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
  }

  /// 도형 도구가 선택된 경우 마지막 스트로크를 도형으로 변환한
  /// 상태를 반환한다. 변환 대상이 아니면 null을 반환한다.
  ///
  /// 반환된 상태는 호출 측에서 한 번만 히스토리에 커밋해
  /// '도형 1개 그리기 = undo 1단위'를 보장한다.
  Drawing? _transformLastStrokeToShape(
    Drawing drawing,
    ScribbleModeState modeState,
  ) {
    if (modeState.inkGroupInfo.selectedInk != InkModes.shape) return null;

    final scribble = drawing.scribble;
    if (scribble.strokes.isEmpty) return null;

    // shape 타입인 경우에만 도형 변환 수행
    final stroke = scribble.strokes.last;
    if (stroke.ink != InkModes.shape) return null;

    // ShapeDetector를 사용하여 도형 인식 및 변환
    final result = ShapeDetector.instance.detectAndTransform(stroke);
    if (result.shapeType == .none) return null;

    final newStroke = result.transformedStroke;
    newStroke.shapeType = result.shapeTypeString;

    // 마지막 스트로크를 새로운 도형으로 교체
    final strokes = [...scribble.strokes]
      ..removeLast()
      ..add(newStroke);

    return drawing.copyWith(
      scribble: scribble.copyWithContents(strokes: strokes),
    );
  }

  /// Used by the Listener callback to stop displaying the cursor
  @override
  void onPointerCancel(PointerCancelEvent event, ScribbleModeState modeState) {
    if (!modeState.supportedPointerKinds.contains(event.kind)) return;
    // 소유하지 않은 포인터의 cancel은 활성 스트로크에 영향을 주지 않는다.
    if (state.activePointerIds.isNotEmpty &&
        !state.activePointerIds.contains(event.pointer)) {
      return;
    }
    final wasStraightened = _strokeStraightened;
    _cancelStraighten();
    if (state is Drawing) {
      // 직선화된 스트로크는 cancel 지점 추가로 직선이 꺾이지 않도록 한다.
      final finished =
          finishLineForState(
                wasStraightened ? state : addPoint(event, state, modeState),
              )
              as Drawing;
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

  /// 진행 중인 활성 라인을 커밋 없이 폐기하고 [pointerId]의 소유권을 해제한다
  /// (kobic UB-219 2차, 팜-먼저 리젝션).
  ///
  /// 손모드에서 팜이 필기 손가락보다 먼저 닿으면 팜이 잠정 스트로크를
  /// 시작해버린다. 실제 필기 포인터로 교체(스왑)할 때 팜이 만든 라인이
  /// 콘텐츠/히스토리에 남지 않도록 temporaryValue 로만 정리한다.
  /// [onPointerCancel] 은 라인을 완성(커밋)하므로 이 용도에 쓸 수 없다.
  void discardActiveLine(int pointerId) {
    final s = state;
    if (s is! Drawing) return;
    _cancelStraighten();
    // copyWith 는 activeLine: null 전달을 기존 값 유지로 병합하므로
    // 생성자를 직접 사용해 activeLine 을 폐기한다.
    temporaryValue = Drawing(
      scribble: s.scribble,
      activePointerIds: s.activePointerIds
          .where((id) => id != pointerId)
          .toList(),
      selectedStrokeIds: s.selectedStrokeIds,
    );
  }

  /// up/cancel 유실로 잔존한 포인터 소유권을 전부 정리한다
  /// (kobic UB-219 2차, 고착 자가치유).
  ///
  /// 멀티터치 중 up 스킵·isScribbleEnable 토글 등으로 up/cancel 이 notifier
  /// 까지 전달되지 않으면 activePointerIds 가 영구 잔류하여 이후 터치 필기가
  /// 완전히 차단된다. 진행 중이던 활성 라인이 있으면 폐기하지 않고
  /// 완성(커밋 대신 temporaryValue 보존)하여 이미 그려진 내용을 유지한다.
  void releaseStalePointers() {
    if (state.activePointerIds.isEmpty) return;
    _cancelStraighten();
    final finished = finishLineForState(state);
    temporaryValue = switch (finished) {
      final Drawing s => s.copyWith(
        activePointerIds: const [],
        pointerPosition: null,
      ),
      final Erasing s => s.copyWith(
        activePointerIds: const [],
        pointerPosition: null,
      ),
    };
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
    _cancelStraighten();
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

  /// 잉크 모드별 정지 직선 변환 대기 시간
  Duration _straightenDelayFor(String ink) =>
      ink == InkModes.marker ? kMarkerStraightenDelay : kPenStraightenDelay;

  /// 펜 정지 감지 타이머 시작
  void _startStraightenTimer(String ink, Offset anchor) {
    _straightenTimer?.cancel();
    _holdAnchor = anchor;
    _strokeStraightened = false;
    _straightenTimer = Timer(_straightenDelayFor(ink), _straightenActiveStroke);
  }

  /// 펜 정지 상태 초기화
  void _cancelStraighten() {
    _straightenTimer?.cancel();
    _straightenTimer = null;
    _strokeStraightened = false;
  }

  /// 활성 stroke을 첫 점 → 마지막 점 직선으로 변환
  void _straightenActiveStroke() {
    final s = state;
    if (s is! Drawing) return;
    final activeLine = s.activeLine;
    if (activeLine == null) return;
    if (!kStraightenableInks.contains(activeLine.ink)) return;
    if (activeLine.points.length < 2) return;

    final firstPoint = activeLine.points.first;
    final lastPoint = activeLine.points.last;

    final straightStroke = activeLine.deepCopy()
      ..points.clear()
      ..points.addAll([firstPoint, lastPoint]);

    _strokeStraightened = true;
    temporaryValue = s.copyWith(activeLine: straightStroke);
  }

  /// 모든 올가미 스트로크를 제거하는 메서드
  void removeLassoStrokes() {
    final updatedScribble = state.scribble.copyWithContents(
      strokes: state.scribble.strokes
          .where((stroke) => stroke.ink != InkModes.lasso)
          .toList(),
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

  // ==================== 이미지 관리 기능 (🖼️ ImageDrawableManager로 위임) ====================

  /// 이미지 추가
  void addImageDrawable(ImageDrawable imageDrawable) {
    _updateScribbleWithTextDrawables(
      imageDrawableManager.add(state.scribble, imageDrawable),
    );
  }

  /// 이미지 수정
  ///
  /// 드래그/변형 중간 프레임처럼 히스토리에 남기지 않을 업데이트는
  /// [addToUndoHistory]를 `false`로 전달한다. (최종 확정은 호출 측이 1회 커밋)
  void updateImageDrawable(
    String id,
    ImageDrawable updatedImageDrawable, {
    bool addToUndoHistory = true,
  }) {
    _updateScribbleWithTextDrawables(
      imageDrawableManager.update(state.scribble, id, updatedImageDrawable),
      addToUndoHistory: addToUndoHistory,
    );
  }

  /// 이미지 삭제
  void removeImageDrawable(String id) {
    _updateScribbleWithTextDrawables(
      imageDrawableManager.remove(state.scribble, id),
    );
  }

  /// 현재 이미지 목록 가져오기
  List<ImageDrawable> getCurrentImageDrawables() =>
      imageDrawableManager.getAll(state.scribble);

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
      onScribbleFinished?.call();
    } else {
      temporaryValue = newState;
    }
  }

  @override
  void dispose() {
    _straightenTimer?.cancel();
    _straightenTimer = null;
    super.dispose();
  }
}
