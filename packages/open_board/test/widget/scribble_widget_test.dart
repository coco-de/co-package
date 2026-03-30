import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScribbleWidget', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      modeNotifier = ScribbleModeNotifier();
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
    });

    Widget buildTestWidget({Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: ScribbleWidget(
              notifier: scribbleNotifier,
              modeNotifier: modeNotifier,
              child: child ?? const SizedBox(width: 300, height: 400),
            ),
          ),
        ),
      );
    }

    testWidgets('ScribbleWidget이 정상적으로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ScribbleWidget이 위젯 트리에 존재하는지 확인
      expect(find.byType(ScribbleWidget), findsOneWidget);
    });

    testWidgets('ScribbleNotifier와 ScribbleModeNotifier를 전달받아 초기화된다',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final widget =
          tester.widget<ScribbleWidget>(find.byType(ScribbleWidget));
      expect(widget.notifier, same(scribbleNotifier));
      expect(widget.modeNotifier, same(modeNotifier));
    });

    testWidgets('CustomPaint가 포함되어 있다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ScribbleWidget 내부에 CustomPaint가 존재하는지 확인
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('child 위젯이 위젯 트리에 전달된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ScribbleWidget의 child 프로퍼티가 정상적으로 전달되었는지 확인
      final widget =
          tester.widget<ScribbleWidget>(find.byType(ScribbleWidget));
      expect(widget.child, isNotNull);
    });
  });
}
