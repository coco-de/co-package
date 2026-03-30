import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_board/src/module/managers/scribble_cache_manager.dart';
import 'package:open_board/src/module/widgets/scribble_drawing_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockScribbleCacheManager extends Mock
    with ChangeNotifier
    implements ScribbleCacheManager {}

void main() {
  group('ScribbleDrawingToolbar', () {
    late MockScribbleCacheManager mockManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockManager = MockScribbleCacheManager();

      // 기본 스텁 설정
      when(() => mockManager.currentTool).thenReturn('pen');
      when(() => mockManager.currentColor).thenReturn(Colors.black);
      when(() => mockManager.currentStrokeWidth).thenReturn(2.0);
      when(() => mockManager.isPageEmpty(any())).thenReturn(true);
    });

    Widget buildTestWidget({
      String currentContentId = 'test-content',
      String currentPageIndex = '0',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ScribbleDrawingToolbar(
            scribbleManager: mockManager,
            currentContentId: currentContentId,
            currentPageIndex: currentPageIndex,
          ),
        ),
      );
    }

    testWidgets('툴바가 정상적으로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ScribbleDrawingToolbar), findsOneWidget);
    });

    testWidgets('도구 버튼들이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 펜, 연필, 마커, 지우개 아이콘이 표시되는지 확인
      expect(find.byIcon(Icons.edit), findsOneWidget); // 펜
      expect(find.byIcon(Icons.create), findsOneWidget); // 연필
      expect(find.byIcon(Icons.format_paint), findsOneWidget); // 마커
      expect(find.byIcon(Icons.cleaning_services), findsOneWidget); // 지우개
    });

    testWidgets('undo/redo 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });

    testWidgets('전체 지우기 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('색상 선택 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.palette), findsOneWidget);
    });
  });
}
