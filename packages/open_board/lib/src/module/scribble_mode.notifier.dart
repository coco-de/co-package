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
  ScribbleModeNotifier({
    /// The supported widths, mainly useful for rendering UI, you can still set
    /// the width to any arbitrary value from code. The first entry in this list
    /// will be the starting width.
    this.widths = const [0.5, 1.5, 2.5, 4.0, 6.0],

    /// Which pointers can be drawn with and are captured.
    ScribblePointerMode allowedPointersMode = ScribblePointerMode.all,
  }) : super(
         ScribbleModeState(
           allowedPointersMode: allowedPointersMode,
           inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
         ),
       );

  /// The supported widths, mainly useful for rendering UI, you can still set
  /// the width to any arbitrary value from code.
  List<double> widths;

  ScribbleModeState get state => value;
  set state(ScribbleModeState newState) => value = newState;

  void updateWidths(List<double> widths) {
    final index = this.widths.indexOf(state.inkGroupInfo.seletedStrokeWidth);
    this.widths = widths;
    setStrokeWidth(widths[index]);
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

  void setStrokeWidthMap(String inkType, double strokeWidth) {
    state = ScribbleModeState(
      inkGroupInfo: state.inkGroupInfo.copyWith(
        selectedInk: inkType,
        strokeWidth: strokeWidth,
      ),
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
    );
  }

  /// Sets the zoom factor to allow for adjusting line width.
  ///
  /// If the factor is 2 for example, lines will be drawn half as thick as
  /// actually selected to allow for drawing details.
  void setScaleFactor(double factor) {
    assert(factor >= 0);
    state = ScribbleModeState(
      scaleFactor: factor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(),
    );
    // temporaryState = state.copyWith(
    //   scaleFactor: factor,
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

  /// 지우개 두께 설정
  void setEraserWidth(double width) {
    state = ScribbleModeState(
      scaleFactor: state.scaleFactor,
      allowedPointersMode: state.allowedPointersMode,
      inkGroupInfo: state.inkGroupInfo.copyWith(
        selectedInk: InkModes.erase,
        strokeWidth: width,
      ),
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

  /// 올가미 선택 모드로 전환
  void setLassoMode() {
    state = ScribbleModeState(
      inkGroupInfo: state.inkGroupInfo.copyWith(selectedInk: 'lasso'),
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
