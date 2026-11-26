// 🐦 Flutter imports:
import 'package:flutter/widgets.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';

// 🌎 Project imports:
import 'package:open_note/src/module/state/scribble.state.dart';
import 'package:open_note/src/module/state/scribble_input_options.dart';
import 'package:open_note/src/module/state/scribble_mode.state.dart';

abstract class ScribbleModeNotifierBase
    extends ValueNotifier<ScribbleModeState> {
  ScribbleModeNotifierBase(super.value);
}

class ScribbleModeNotifier extends ScribbleModeNotifierBase {
  ScribbleModeNotifier()
    : super(
        ScribbleModeState(
          allowedPointersMode: .all,
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
        ),
      );

  bool _isDisposed = false;

  ScribbleModeState get state => value;

  /// dispose 이후의 setter 호출은 조용히 무시한다.
  /// (PageView 전환·hot reload 시 stale notifier가 build에서 접근하면
  ///  ValueNotifier의 `Once you have called dispose() ...` 예외가 발생해
  ///  필기 stroke가 비결정적으로 누락되는 원인이 됨)
  set state(ScribbleModeState newState) {
    if (_isDisposed) return;
    value = newState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Sets the width of the next line
  void setStrokeWidth(double strokeWidth) {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(strokeWidth: strokeWidth),
    );
    // temporaryState = state.copyWith(
    //   selectedWidth: strokeWidth,
    // );
  }

  /// 현재 캔버스 줌 배율을 갱신한다.
  /// fixedPen 등 화면상 물리 두께를 일정하게 유지해야 하는 도구가
  /// 이 값을 사용해 stroke size를 보정한다.
  void setScaleFactor(double scaleFactor) {
    if (state.scaleFactor == scaleFactor) return;
    state = state.copyWith(scaleFactor: scaleFactor);
  }

  /// 펜 모드로 설정
  void setPen() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.pen),
    );
  }

  /// 연필 모드로 설정
  void setPencil() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.pencil),
    );
  }

  /// 마커 모드로 설정
  void setMarker() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.marker),
    );
  }

  /// 고정 두께 펜 모드로 설정 (화면상 물리적 두께가 줌과 무관하게 고정)
  void setFixedPen() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.fixedPen),
    );
  }

  /// 균일 두께 펜 모드로 설정 (필압 무시 + 콘텐츠 좌표 고정 두께, 줌 보정 없음)
  void setUniformPen() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(
        selectedInk: InkModes.uniformPen,
      ),
    );
  }

  /// 도형 모드로 설정
  void setShape() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.shape),
    );
  }

  /// 지우개 모드로 설정
  void setEraser() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.erase),
    );
  }

  /// 올가미 선택 모드로 설정
  void setLassoSelection() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.lasso),
    );
  }

  /// 텍스트 모드로 설정
  void setText() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.text),
    );
  }

  /// 이미지 임베드 선택/변형 모드로 설정
  void setImage() {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.image),
    );
  }

  /// Sets the color of the pen to the given color.
  void setColor(Color color) {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(inkColor: color),
    );
  }

  /// allowedPointersMode만 변경하는 함수
  void setAllowedPointersMode(ScribblePointerMode mode) {
    state = state.copyWith(allowedPointersMode: mode);
  }

  /// 현재 선택된 도구(selectedInk)만 복원하는 메서드
  void setSelectedInk(String inkType) {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: inkType),
    );
  }

  /// open_note: 획 안정화 · 선 스타일 · 지우개 방식 · 도형 스냅 · 올가미 모양.
  void setInputOptions(ScribbleInputOptions inputOptions) {
    if (state.inputOptions == inputOptions) return;
    state = state.copyWith(inputOptions: inputOptions);
  }

  /// shape 도구의 타겟 도형([ShapeTargets])을 설정한다.
  ///
  /// '' 이면 자유 도형(자동 인식), 'line'/'ellipse'/'rectangle' 이면
  /// 드래그 bounding-box 결정적 드로잉. shape 잉크가 선택된 경우에만 참조된다.
  void setShapeType(String shapeType) {
    state = state.copyWith(
      inkGroupInfo: state.inkGroupInfo.copyWith(shapeType: shapeType),
    );
  }
}
