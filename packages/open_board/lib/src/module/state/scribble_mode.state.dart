  // 🐦 Flutter imports:
  import 'package:flutter/gestures.dart';
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
      /// How much the widget is scaled at the moment.
      ///
      /// Can be used if zoom functionality is needed
      /// (e.g. through InteractiveViewer) so that the pen width remains the same.
      this.scaleFactor = 1,

      /// Which pointers are allowed for drawing and will be captured by the
      /// scribble widget.
      this.allowedPointersMode = ScribblePointerMode.all,
      required this.inkGroupInfo,
    });

    StrokeOptions get options =>
        .new(size: inkGroupInfo.seletedStrokeWidth / scaleFactor);

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
