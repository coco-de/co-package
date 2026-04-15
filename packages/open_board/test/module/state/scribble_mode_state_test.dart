import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/state/scribble.state.dart';
import 'package:open_board/src/module/state/scribble_mode.state.dart';

void main() {
  group('ScribbleModeState', () {
    test('기본 생성', () {
      final state = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pencil),
      );
      expect(state.scaleFactor, 1);
      expect(state.allowedPointersMode, ScribblePointerMode.all);
    });

    group('supportedPointerKinds', () {
      test('all 모드 — 모든 포인터', () {
        final state = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
          allowedPointersMode: .all,
        );
        expect(
          state.supportedPointerKinds,
          containsAll(PointerDeviceKind.values),
        );
      });

      test('mouseOnly 모드', () {
        final state = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
          allowedPointersMode: .mouseOnly,
        );
        expect(state.supportedPointerKinds, {PointerDeviceKind.mouse});
      });

      test('penOnly 모드', () {
        final state = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
          allowedPointersMode: .penOnly,
        );
        expect(
          state.supportedPointerKinds,
          contains(PointerDeviceKind.stylus),
        );
        expect(
          state.supportedPointerKinds,
          contains(PointerDeviceKind.invertedStylus),
        );
      });

      test('mouseAndPen 모드', () {
        final state = ScribbleModeState(
          inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
          allowedPointersMode: .mouseAndPen,
        );
        expect(
          state.supportedPointerKinds,
          contains(PointerDeviceKind.mouse),
        );
        expect(
          state.supportedPointerKinds,
          contains(PointerDeviceKind.stylus),
        );
      });
    });

    test('options — scaleFactor 반영', () {
      final state = ScribbleModeState(
        inkGroupInfo: InkGroupInfo(selectedInk: InkModes.pen),
        scaleFactor: 2.0,
      );
      final options = state.options;
      expect(options.size, greaterThan(0));
    });
  });
}
