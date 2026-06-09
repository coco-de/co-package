import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/widgets/scribble_floating_toolbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ScribbleFloatingToolbar', () {
    late DrawingState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = DrawingState();
      // 테스트 격리: 기본값 초기화
      state.selectedTool.value = DrawingTool.pen;
      state.selectedColor.value = Colors.black;
      state.selectedThickness.value = 2.0;
    });

    Widget buildHarness({
      List<DrawingTool>? tools,
      List<Color>? colors,
      bool draggable = true,
      PanelContainerBuilder? containerBuilder,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ScribbleFloatingToolbar(
                  state: state,
                  tools: tools ?? kDefaultToolbarTools,
                  colors: colors ?? kDefaultToolbarColors,
                  draggable: draggable,
                  containerBuilder: containerBuilder,
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('정상적으로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.byType(ScribbleFloatingToolbar), findsOneWidget);
    });

    testWidgets('도구 버튼 탭 시 DrawingState.selectedTool이 변경된다', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(state.selectedTool.value, DrawingTool.pen);

      // Marker 도구 탭
      await tester.tap(find.byTooltip('Marker'));
      await tester.pumpAndSettle(); // 디바운스 autoSave 타이머 소진

      expect(state.selectedTool.value, DrawingTool.marker);
    });

    testWidgets('색상 스와치 탭 시 DrawingState.selectedColor가 변경된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(colors: const [Colors.red, Colors.blue]),
      );
      await tester.pumpAndSettle();

      // 파랑 원형 스와치 Container를 정확히 식별(Slider 내부 GestureDetector 등 배제)
      final blueSwatch = find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final deco = w.decoration;
        return deco is BoxDecoration &&
            deco.shape == BoxShape.circle &&
            deco.color?.toARGB32() == Colors.blue.toARGB32();
      });
      await tester.tap(blueSwatch);
      await tester.pumpAndSettle();

      expect(state.selectedColor.value.toARGB32(), Colors.blue.toARGB32());
    });

    testWidgets('두께 슬라이더 조작 시 DrawingState.selectedThickness가 변경된다', (
      tester,
    ) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      final before = state.selectedThickness.value;
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(state.selectedThickness.value, isNot(before));
    });

    testWidgets('containerBuilder 주입 시 커스텀 셸이 렌더된다', (tester) async {
      const customKey = Key('custom-shell');
      await tester.pumpWidget(
        buildHarness(
          // 외부 셸이 크기 제약을 책임진다(CoDraggablePanel 역할 모사)
          containerBuilder: (context, content) => SizedBox(
            width: 280,
            child: Container(key: customKey, color: Colors.amber, child: content),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(customKey), findsOneWidget);
      // 커스텀 셸 내부에 콘텐츠(슬라이더)가 렌더된다
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('드래그 핸들로 패널을 이동하면 위치가 바뀐다', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      final handle = find.byIcon(Icons.drag_handle);
      expect(handle, findsOneWidget);

      final before = tester.getTopLeft(handle);
      await tester.drag(handle, const Offset(60, 40));
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(handle);

      expect(after, isNot(before));
    });

    testWidgets('draggable=false면 드래그 핸들이 없다', (tester) async {
      await tester.pumpWidget(buildHarness(draggable: false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });
  });
}
