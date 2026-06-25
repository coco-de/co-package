// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

// 🌎 Project imports:
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

@immutable
class ScribbleModeState {
  final InkGroupInfo inkGroupInfo;

  // double selectedWidth;
  final double scaleFactor;

  final ScribblePointerMode allowedPointersMode;

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

  /// 펜 크기 — 두께 정책을 스트로크 생성(`ScribbleNotifier`)과 일치시킨다
  /// (단일 진실 공급원). 커서 미리보기 원 크기가 실제 그려질 두께와 일치한다.
  ///
  /// BrushMode 표준안(kobic #7160): `fixedPen`(화면비례)만 줌 배율로 보정해
  /// 화면상 물리 두께를 유지(반응형)하고, 그 외(`pen`=필압, `uniformPen`=균일)는
  /// 콘텐츠 좌표계 고정 두께라 확대 시 본문과 함께 스케일된다(캔버스가
  /// InteractiveViewer 자식).
  StrokeOptions get options => .new(
    size: inkGroupInfo.selectedInk == InkModes.fixedPen
        ? inkGroupInfo.seletedStrokeWidth / scaleFactor
        : inkGroupInfo.seletedStrokeWidth,
  );

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
