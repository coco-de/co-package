import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

void main() {
  group('ScribbleModeNotifier dispose 라이프사이클', () {
    test('dispose 후 setter 호출은 예외 없이 무시된다', () {
      final n = ScribbleModeNotifier();
      n.dispose();

      // PageView 전환·hot reload 직후 stale notifier가 build에서
      // 접근하는 시나리오를 모사한다. 어떤 setter도 예외를 던지지 않아야 한다.
      expect(n.setPen, returnsNormally);
      expect(n.setPencil, returnsNormally);
      expect(n.setEraser, returnsNormally);
      expect(() => n.setStrokeWidth(2), returnsNormally);
      expect(() => n.setColor(const Color(0xFFFF0000)), returnsNormally);
      expect(
        () => n.setAllowedPointersMode(ScribblePointerMode.penOnly),
        returnsNormally,
      );
    });

    test('dispose 후 state setter 직접 호출도 예외 없이 무시된다', () {
      final n = ScribbleModeNotifier();
      final initialState = n.state;
      n.dispose();

      // ValueNotifier dispose 후 value 변경은 normally 무시되어야 한다.
      expect(() => n.state = initialState, returnsNormally);
    });
  });
}
