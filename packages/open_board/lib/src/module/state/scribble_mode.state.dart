// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

@immutable
class ScribbleModeState {
  InkGroupInfo inkGroupInfo;

  // double selectedWidth;
  double scaleFactor;

  ScribblePointerMode allowedPointersMode;

  ScribbleModeState({
    /// 현재 위젯 줌 배율 (InteractiveViewer).
    ///
    /// ⚠️ 펜 두께 계산에는 더 이상 사용하지 않는다. 두께는 문서(캔버스) 좌표
    /// 기준으로 고정되어 줌과 무관하게 항상 동일하게 그려진다. ([options] 참조)
    /// 줌 인지가 필요한 다른 로직을 위해 값 자체는 유지한다.
    this.scaleFactor = 1,

    /// Which pointers are allowed for drawing and will be captured by the
    /// scribble widget.
    this.allowedPointersMode = ScribblePointerMode.all,
    required this.inkGroupInfo,
  });

  /// 펜 두께를 문서(캔버스) 좌표 기준으로 고정한다.
  ///
  /// 이전에는 `seletedStrokeWidth / scaleFactor` 로 줌을 보정해 그리는 순간의
  /// 화면 픽셀 두께만 일정하게 맞췄으나(= fixed pen 동작), 그 결과 서로 다른 줌
  /// 레벨에서 그린 선이 다른 문서 두께로 저장돼 같은 슬라이더 값이라도 두께가
  /// 제각각이 되는 문제가 있었다. 줌과 무관하게 항상 동일한 두께로 필기되도록
  /// scaleFactor 나눗셈을 제거한다 — 캔버스는 InteractiveViewer 자식이라 본문과
  /// 함께 자연스럽게 스케일된다.
  StrokeOptions get options => .new(size: inkGroupInfo.seletedStrokeWidth);

  /// Returns a set of [PointerDeviceKind] that represents the currently
  /// supported devices, depending on [state.allowedPointersMode].
  Set<PointerDeviceKind> get supportedPointerKinds {
    switch (allowedPointersMode) {
      case .all:
        return Set.from(PointerDeviceKind.values);
      case .mouseOnly:
        return const {PointerDeviceKind.mouse};
      case .penOnly:
        return const {
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        };
      case .mouseAndPen:
        return const {
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        };
    }
  }
}
