import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/scribble_controller.dart';
import 'package:open_board/src/module/widgets/simple_scribble_widget.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SimpleScribbleWidget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({
      ScribbleController? controller,
      Widget child = const SizedBox(width: 300, height: 400),
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: SimpleScribbleWidget(
              controller: controller,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('SimpleScribbleWidget이 정상적으로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SimpleScribbleWidget), findsOneWidget);
    });

    testWidgets('기본 props로 생성 가능하다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 내부적으로 ScribbleWidget이 생성되는지 확인
      expect(find.byType(ScribbleWidget), findsOneWidget);
    });

    testWidgets('외부 컨트롤러를 전달받아 사용할 수 있다', (tester) async {
      final controller = ScribbleController();

      await tester.pumpWidget(buildTestWidget(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleScribbleWidget), findsOneWidget);
      expect(find.byType(ScribbleWidget), findsOneWidget);

      controller.dispose();
    });

    testWidgets('child가 위젯 트리에 전달된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // SimpleScribbleWidget 내부의 ScribbleWidget이 child를 받았는지 확인
      final widget = tester.widget<ScribbleWidget>(find.byType(ScribbleWidget));
      expect(widget.child, isNotNull);
    });
  });
}
