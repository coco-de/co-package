import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/module/scribble_controller.dart';
import 'package:open_note/src/module/state/drawing_state.dart';

/// 지연 초기화 중(전역 [DrawingState] 등록이 도구를 맞추며 리스너를 깨우는
/// 순간) 컨트롤러를 다시 읽어도 초기화가 두 번 돌지 않아야 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('초기화 도중 콜백에서 컨트롤러를 읽어도 예외가 없다', () {
    // 전역 도구를 컨트롤러 초기 도구와 다르게 두어, 등록 즉시 도구 변경
    // 알림이 일어나게 한다.
    DrawingState().selectedTool.value = DrawingTool.marker;
    addTearDown(() => DrawingState().selectedTool.value = DrawingTool.pen);

    late final ScribbleController controller;
    var reentered = 0;
    // ChangeNotifier 는 리스너의 예외를 삼키므로, 콜백 안에서 직접 모은다.
    Object? failure;
    controller = ScribbleController(
      onToolChanged: (_) {
        reentered++;
        try {
          controller.currentScribble;
          // ignore: avoid_catches_without_on_clauses
        } catch (error) {
          failure ??= error;
        }
      },
    );
    addTearDown(controller.dispose);

    expect(() => controller.scribbleNotifier, returnsNormally);
    expect(reentered, greaterThan(0), reason: '재진입 경로를 실제로 지나야 한다');
    expect(failure, isNull);
  });
}
