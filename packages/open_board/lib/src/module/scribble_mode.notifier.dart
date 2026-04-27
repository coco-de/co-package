// 🐦 Flutter imports:
import 'package:flutter/widgets.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

// 🌎 Project imports:
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

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
    state = ScribbleModeState(
      inkGroupInfo: state.inkGroupInfo.copyWith(strokeWidth: strokeWidth),
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
    );
    // temporaryState = state.copyWith(
    //   selectedWidth: strokeWidth,
    // );
  }

  /// 펜 모드로 설정
  void setPen() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.pen),
    );
  }

  /// 연필 모드로 설정
  void setPencil() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.pencil),
    );
  }

  /// 마커 모드로 설정
  void setMarker() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.marker),
    );
  }

  /// 고정 두께 펜 모드로 설정 (화면상 물리적 두께가 줌과 무관하게 고정)
  void setFixedPen() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(
        selectedInk: InkModes.fixedPen,
      ),
    );
  }

  /// 도형 모드로 설정
  void setShape() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.shape),
    );
  }

  /// 지우개 모드로 설정
  void setEraser() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.erase),
    );
  }

  /// 올가미 선택 모드로 설정
  void setLassoSelection() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.lasso),
    );
  }

  /// 텍스트 모드로 설정
  void setText() {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: InkModes.text),
    );
  }

  /// Sets the color of the pen to the given color.
  void setColor(Color color) {
    state = ScribbleModeState(
      inkGroupInfo: state.inkGroupInfo.copyWith(inkColor: color),
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
    );
  }

  /// allowedPointersMode만 변경하는 함수
  void setAllowedPointersMode(ScribblePointerMode mode) {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: mode,
      inkGroupInfo: state.inkGroupInfo,
    );
  }

  /// 현재 선택된 도구(selectedInk)만 복원하는 메서드
  void setSelectedInk(String inkType) {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: inkType),
    );
  }
}
