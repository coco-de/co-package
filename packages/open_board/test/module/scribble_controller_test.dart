import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ScribbleController', () {
    late ScribbleController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      try {
        // DrawingState 싱글톤 초기화
        // ignore: invalid_use_of_visible_for_testing_member
      } catch (_) {}
      controller = ScribbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('초기 상태', () {
      test('초기 도구는 pencil (DrawingState 기본값)', () {
        // DrawingState 기본값이 DrawingTool.pencil이므로 컨트롤러 등록 시 pencil로 설정됨
        expect(controller.currentTool, InkModes.pencil);
      });

      test('초기 색상은 검정', () {
        expect(controller.currentColor, Colors.black);
      });

      test('초기 스트로크 너비는 2.0', () {
        expect(controller.currentStrokeWidth, 2.0);
      });

      test('isEmpty는 true', () {
        expect(controller.isEmpty, true);
      });

      test('canUndo는 false', () {
        expect(controller.canUndo, false);
      });

      test('canRedo는 false', () {
        expect(controller.canRedo, false);
      });

      test('initialScribble 전달 시 반영됨', () {
        final scribble = createScribbleWithStrokes(strokeCount: 2);
        final ctrl = ScribbleController(initialScribble: scribble);
        expect(ctrl.currentScribble.strokes.length, 2);
        ctrl.dispose();
      });

      test('initialTool은 DrawingState 값으로 덮어씌워짐', () {
        // DrawingState.registerNotifier()가 즉시 applyToModeNotifier()를 호출하여
        // initialTool 파라미터보다 DrawingState 현재 값이 우선됨
        final ctrl = ScribbleController(initialTool: InkModes.marker);
        expect(ctrl.currentTool, InkModes.pencil); // DrawingState 기본값
        ctrl.dispose();
      });

      test('initialColor은 DrawingState 값으로 덮어씌워짐', () {
        // DrawingState.selectedColor 기본값은 Colors.black
        final ctrl = ScribbleController(initialColor: Colors.red);
        expect(ctrl.currentColor, Colors.black); // DrawingState 기본값
        ctrl.dispose();
      });

      test('initialStrokeWidth은 DrawingState 값으로 덮어씌워짐', () {
        // DrawingState.selectedThickness 기본값은 2.0
        final ctrl = ScribbleController(initialStrokeWidth: 5.0);
        expect(ctrl.currentStrokeWidth, 2.0); // DrawingState 기본값
        ctrl.dispose();
      });
    });

    group('notifier 접근', () {
      test('scribbleNotifier 접근 가능', () {
        expect(controller.scribbleNotifier, isNotNull);
      });

      test('modeNotifier 접근 가능', () {
        expect(controller.modeNotifier, isNotNull);
      });

      test('같은 인스턴스 반환', () {
        final n1 = controller.scribbleNotifier;
        final n2 = controller.scribbleNotifier;
        expect(identical(n1, n2), true);
      });
    });

    group('도구 변경', () {
      test('setTool() 도구 변경', () {
        controller.setTool(InkModes.pencil);
        expect(controller.currentTool, InkModes.pencil);
      });

      test('setPen() 펜으로 변경', () {
        controller.setTool(InkModes.marker);
        controller.setPen();
        expect(controller.currentTool, InkModes.pen);
      });

      test('setPencil() 연필로 변경', () {
        controller.setPencil();
        expect(controller.currentTool, InkModes.pencil);
      });

      test('setMarker() 마커로 변경', () {
        controller.setMarker();
        expect(controller.currentTool, InkModes.marker);
      });

      test('setEraser() 지우개로 변경', () {
        controller.setEraser();
        expect(controller.currentTool, InkModes.erase);
      });

      test('setLasso() 올가미로 변경', () {
        controller.setLasso();
        expect(controller.currentTool, InkModes.lasso);
      });

      test('setText() 텍스트로 변경', () {
        controller.setText();
        expect(controller.currentTool, InkModes.text);
      });
    });

    group('색상 / 두께 변경', () {
      test('setColor() 색상 변경', () {
        controller.setColor(Colors.red);
        expect(controller.currentColor, Colors.red);
      });

      test('setStrokeWidth() 두께 변경', () {
        controller.setStrokeWidth(8.0);
        expect(controller.currentStrokeWidth, 8.0);
      });
    });

    group('필기 데이터 관리', () {
      test('loadScribble() 데이터 로드', () {
        final scribble = createScribbleWithStrokes(strokeCount: 3);
        controller.loadScribble(scribble);
        expect(controller.currentScribble.strokes.length, 3);
        expect(controller.isEmpty, false);
      });

      test('loadScribbleWithSize() 크기 적용', () {
        // rebuild()는 frozen protobuf에서만 동작하므로 freeze() 필요
        final frozenScribble = createScribbleWithStrokes(strokeCount: 1)
          ..freeze();
        controller.loadScribbleWithSize(frozenScribble, const Size(800, 600));
        expect(controller.currentScribble.width, 800.0);
        expect(controller.currentScribble.height, 600.0);
      });

      test('clear() 전체 지우기', () {
        controller.loadScribble(createScribbleWithStrokes(strokeCount: 2));
        controller.clear();
        expect(controller.isEmpty, true);
      });
    });

    group('exportAsBytes / importFromBytes', () {
      test('바이트 내보내기 후 가져오기 왕복', () {
        final scribble = createScribbleWithStrokes(strokeCount: 2);
        controller.loadScribble(scribble);

        final bytes = controller.exportAsBytes();
        expect(bytes.isNotEmpty, true);

        final ctrl2 = ScribbleController();
        ctrl2.importFromBytes(bytes);
        expect(ctrl2.currentScribble.strokes.length, 2);
        ctrl2.dispose();
      });
    });

    group('undo / redo', () {
      test('데이터 없으면 undo 무시', () {
        // clearQueue()로 초기화된 상태에서 canUndo는 false
        expect(controller.canUndo, false);
        controller.undo(); // 에러 없이 실행
      });

      test('데이터 없으면 redo 무시', () {
        expect(controller.canRedo, false);
        controller.redo(); // 에러 없이 실행
      });
    });

    group('onScribbleChanged 콜백', () {
      test('loadScribble 시 콜백 호출', () {
        int callCount = 0;
        final ctrl = ScribbleController(
          onScribbleChanged: (_) => callCount++,
        );
        ctrl.loadScribble(createScribbleWithStrokes(strokeCount: 1));
        expect(callCount, greaterThan(0));
        ctrl.dispose();
      });
    });

    group('onToolChanged 콜백', () {
      test('setTool 시 콜백 호출', () {
        String? receivedTool;
        final ctrl = ScribbleController(
          onToolChanged: (tool) => receivedTool = tool,
        );
        ctrl.setTool(InkModes.marker);
        expect(receivedTool, InkModes.marker);
        ctrl.dispose();
      });
    });

    group('repaintBoundaryKey', () {
      test('GlobalKey 존재', () {
        expect(controller.repaintBoundaryKey, isNotNull);
      });
    });
  });
}
