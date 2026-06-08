import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/scribble.state.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ScribbleModeNotifier', () {
    late ScribbleModeNotifier notifier;

    setUp(() {
      notifier = ScribbleModeNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    group('초기 상태', () {
      test('초기 잉크 모드는 pencil이다', () {
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pencil);
      });

      test('초기 scaleFactor는 1이다', () {
        expect(notifier.state.scaleFactor, 1.0);
      });

      test('초기 allowedPointersMode는 all이다', () {
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.all,
        );
      });

      test('state와 value는 동일한 객체를 반환한다', () {
        expect(identical(notifier.state, notifier.value), isTrue);
      });
    });

    group('setStrokeWidth()', () {
      test('현재 잉크의 선 두께를 변경한다', () {
        notifier.setStrokeWidth(3.0);
        expect(notifier.state.inkGroupInfo.seletedStrokeWidth, 3.0);
      });

      test('다른 설정(scaleFactor, allowedPointersMode)은 유지된다', () {
        notifier.setScaleFactor(2.0);
        notifier.setAllowedPointersMode(.penOnly);

        notifier.setStrokeWidth(5.0);

        expect(notifier.state.scaleFactor, 2.0);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.penOnly,
        );
        expect(notifier.state.inkGroupInfo.seletedStrokeWidth, 5.0);
      });
    });

    group('setPen()', () {
      test('잉크 모드를 pen으로 설정한다', () {
        notifier.setPen();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);
      });

      test('scaleFactor와 allowedPointersMode는 유지된다', () {
        notifier.setScaleFactor(1.5);
        notifier.setAllowedPointersMode(.mouseOnly);

        notifier.setPen();

        expect(notifier.state.scaleFactor, 1.5);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.mouseOnly,
        );
      });
    });

    group('setPencil()', () {
      test('잉크 모드를 pencil로 설정한다', () {
        // 다른 모드로 전환 후 pencil로 복귀
        notifier.setPen();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);

        notifier.setPencil();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pencil);
      });
    });

    group('setMarker()', () {
      test('잉크 모드를 marker로 설정한다', () {
        notifier.setMarker();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.marker);
      });
    });

    group('setFixedPen()', () {
      test('잉크 모드를 fixedPen으로 설정한다', () {
        notifier.setFixedPen();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.fixedPen);
      });

      test('scaleFactor와 allowedPointersMode는 유지된다', () {
        notifier.setScaleFactor(1.5);
        notifier.setAllowedPointersMode(.mouseOnly);

        notifier.setFixedPen();

        expect(notifier.state.scaleFactor, 1.5);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.mouseOnly,
        );
      });
    });

    group('setShape()', () {
      test('잉크 모드를 shape으로 설정한다', () {
        notifier.setShape();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.shape);
      });
    });

    group('setEraser()', () {
      test('잉크 모드를 erase로 설정한다', () {
        notifier.setEraser();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.erase);
      });
    });

    group('setLassoSelection()', () {
      test('잉크 모드를 lasso로 설정한다', () {
        notifier.setLassoSelection();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.lasso);
      });
    });

    group('setText()', () {
      test('잉크 모드를 text로 설정한다', () {
        notifier.setText();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.text);
      });
    });

    group('setColor()', () {
      test('선택된 잉크의 색상을 변경한다', () {
        const red = Color(0xFFFF0000);
        notifier.setColor(red);
        expect(notifier.state.inkGroupInfo.selectedColor, red);
      });

      test('색상 변경 후 다른 설정은 유지된다', () {
        notifier.setScaleFactor(2.0);
        notifier.setPen();

        const blue = Color(0xFF0000FF);
        notifier.setColor(blue);

        expect(notifier.state.inkGroupInfo.selectedColor, blue);
        expect(notifier.state.scaleFactor, 2.0);
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);
      });
    });

    group('setScaleFactor()', () {
      test('scaleFactor를 변경한다', () {
        notifier.setScaleFactor(2.5);
        expect(notifier.state.scaleFactor, 2.5);
      });

      test('scaleFactor 0도 허용된다', () {
        notifier.setScaleFactor(0);
        expect(notifier.state.scaleFactor, 0);
      });
    });

    group('setAllowedPointersMode()', () {
      test('포인터 모드를 mouseOnly로 변경한다', () {
        notifier.setAllowedPointersMode(.mouseOnly);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.mouseOnly,
        );
      });

      test('포인터 모드를 penOnly로 변경한다', () {
        notifier.setAllowedPointersMode(.penOnly);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.penOnly,
        );
      });

      test('포인터 모드를 mouseAndPen으로 변경한다', () {
        notifier.setAllowedPointersMode(.mouseAndPen);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.mouseAndPen,
        );
      });
    });

    group('setSelectedInk()', () {
      test('잉크 타입만 변경한다', () {
        notifier.setScaleFactor(1.5);
        notifier.setAllowedPointersMode(.mouseOnly);

        notifier.setSelectedInk(InkModes.marker);

        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.marker);
        expect(notifier.state.scaleFactor, 1.5);
        expect(
          notifier.state.allowedPointersMode,
          ScribblePointerMode.mouseOnly,
        );
      });
    });

    group('ValueNotifier 리스너', () {
      test('상태 변경 시 리스너가 호출된다', () {
        final tracker = ValueChangeTracker(notifier);
        addTearDown(() => tracker.dispose(notifier));

        notifier.setPen();
        expect(tracker.hasChanged, isTrue);
        expect(tracker.changeCount, 1);
      });

      test('여러 번 변경 시 리스너가 매번 호출된다', () {
        final tracker = ValueChangeTracker(notifier);
        addTearDown(() => tracker.dispose(notifier));

        notifier.setPen();
        notifier.setMarker();
        notifier.setEraser();

        expect(tracker.changeCount, 3);
      });
    });

    group('잉크 모드 간 전환', () {
      test('pen -> eraser -> pencil 전환이 올바르게 동작한다', () {
        notifier.setPen();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pen);

        notifier.setEraser();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.erase);

        notifier.setPencil();
        expect(notifier.state.inkGroupInfo.selectedInk, InkModes.pencil);
      });

      test('각 잉크 모드에서 색상 설정이 독립적으로 유지된다', () {
        const red = Color(0xFFFF0000);
        const blue = Color(0xFF0000FF);

        notifier.setPen();
        notifier.setColor(red);
        expect(notifier.state.inkGroupInfo.selectedColor, red);

        notifier.setPencil();
        notifier.setColor(blue);
        expect(notifier.state.inkGroupInfo.selectedColor, blue);

        // pen으로 돌아가면 pen의 색상이 유지됨
        notifier.setPen();
        expect(notifier.state.inkGroupInfo.selectedColor, red);
      });
    });
  });
}
