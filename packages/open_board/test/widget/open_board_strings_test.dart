import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/open_board.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';
import 'package:open_board/src/module/text/text_interaction_manager.dart';
import 'package:open_board/src/module/widgets/scribble_widget_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

/// 패키지가 직접 그리는 문구 주입 (co-package#43).
///
/// 검증 대상:
///  1. 기본값이 지금까지의 글과 같다 — 문구 묶음을 넣지 않은 사용처는 그대로
///  2. 인라인 에디터의 완료 버튼 · 링크 메뉴 · 링크 대화상자가 주입 문구를 쓴다
///  3. 에디터는 Overlay 에 뜨므로, 필기 위젯 위치의 스코프 문구가 넘어간다
///  4. 플로팅 도구 패널의 도구 이름 · undo/redo/clear 툴팁이 주입 문구를 쓴다
void main() {
  const fr = OpenBoardStrings(
    addLink: 'Ajouter un lien',
    editLink: 'Modifier le lien',
    removeLink: 'Supprimer le lien',
    done: 'Terminé',
    linkDialogTitle: 'Saisir un lien',
    externalLink: 'URL externe',
    internalPage: 'Page interne',
    pageNumber: 'Numéro de page',
    cancel: 'Annuler',
    confirm: 'OK',
    undo: 'Défaire',
    redo: 'Rétablir',
    clear: 'Effacer',
    toolPen: 'Stylo',
    toolEraser: 'Gomme',
  );

  TextDrawable drawable() => TextDrawableFactory.create(
    id: 'test-text',
    text: 'hello world',
    position: const Offset(100, 100),
    style: const TextStyle(fontSize: 16, color: Colors.black),
    alignment: TextAlignment.center,
    hidden: true,
  );

  InlineTextEditor editor({OpenBoardStrings? strings}) => InlineTextEditor(
    drawable: drawable(),
    position: const Offset(400, 300),
    textSettings: const TextSettings(),
    isNew: false,
    scale: 1.0,
    selectedColor: Colors.black,
    strings: strings,
    onComplete: (_) {},
  );

  Future<void> showToolbar(WidgetTester tester) async {
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
  }

  group('OpenBoardStrings 기본값', () {
    test('지금까지 보여 주던 글과 같다', () {
      const strings = OpenBoardStrings();

      expect(strings.addLink, '링크 추가');
      expect(strings.editLink, '링크 편집');
      expect(strings.removeLink, '링크 삭제');
      expect(strings.done, '완료');
      expect(strings.linkDialogTitle, '링크 입력');
      expect(strings.cancel, '취소');
      expect(strings.confirm, '확인');
      expect(strings.undo, 'Undo');
      expect(strings.toolLabel(DrawingTool.fixedPen), 'Fixed');
      expect(drawingToolLabel(DrawingTool.erase), 'Eraser');
    });

    test('같은 글이면 같은 값이다 — 스코프가 불필요하게 다시 빌드하지 않는다', () {
      expect(const OpenBoardStrings(), const OpenBoardStrings());
      expect(
        const OpenBoardStrings(cancel: 'Cancel'),
        const OpenBoardStrings(cancel: 'Cancel'),
      );
      expect(const OpenBoardStrings(cancel: 'Cancel'), isNot(fr));
    });
  });

  group('InlineTextEditor 문구 주입', () {
    testWidgets('스코프 문구가 완료 버튼 · 링크 메뉴 · 링크 대화상자에 쓰인다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              OpenBoardStringsScope(strings: fr, child: child!),
          home: editor(),
        ),
      );
      await tester.pump();

      expect(find.text('Terminé'), findsOneWidget);
      expect(find.text('완료'), findsNothing);

      await showToolbar(tester);
      expect(find.text('Ajouter un lien'), findsOneWidget);
      expect(find.text('링크 추가'), findsNothing);

      await tester.tap(find.text('Ajouter un lien'));
      await tester.pumpAndSettle();

      expect(find.text('Saisir un lien'), findsOneWidget);
      expect(find.text('URL externe'), findsOneWidget);
      expect(find.text('Page interne'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('생성자 문구가 스코프보다 우선한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => OpenBoardStringsScope(
            strings: const OpenBoardStrings(done: 'Done'),
            child: child!,
          ),
          home: editor(strings: fr),
        ),
      );
      await tester.pump();

      expect(find.text('Terminé'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });
  });

  group('TextInteractionManager — Overlay 에디터로 문구 전달', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;
    late ScribbleWidgetState widgetState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(scribble: createScribble());
      modeNotifier = ScribbleModeNotifier();
      widgetState = ScribbleWidgetState();
      DrawingState().pointerMode.value = DrawingPointerMode.mouseOnly;
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
      widgetState.dispose();
    });

    testWidgets('스코프가 Overlay 아래(필기 위젯 쪽)에만 있어도 에디터가 그 문구를 쓴다', (tester) async {
      late TextInteractionManager manager;
      final repaintBoundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Overlay(
            initialEntries: [
              OverlayEntry(
                // 스코프는 이 엔트리 안쪽 — 에디터가 삽입되는 Overlay 에서는
                // 보이지 않는다. 매니저가 필기 위젯 위치에서 읽어 넘겨야 한다.
                builder: (context) => OpenBoardStringsScope(
                  strings: fr,
                  child: Builder(
                    builder: (context) {
                      manager = TextInteractionManager(
                        scribbleNotifier: scribbleNotifier,
                        modeNotifier: modeNotifier,
                        onStateChanged: () {},
                        context: context,
                        transformationController: null,
                        repaintBoundaryKey: repaintBoundaryKey,
                        onTextSelected: (_) {},
                        onTextEdit: (_) {},
                        onTextUpdated: (_) {},
                        onTextDeselected: () {},
                        widgetState: widgetState,
                      );
                      return RepaintBoundary(
                        key: repaintBoundaryKey,
                        child: const SizedBox(width: 400, height: 600),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      const tapPosition = Offset(100, 150);
      manager.handlePointerDown(PointerDownEvent(position: tapPosition));
      manager.handlePointerUp(PointerUpEvent(position: tapPosition));
      await tester.pump();

      final opened = tester.widget<InlineTextEditor>(
        find.byType(InlineTextEditor),
      );
      expect(opened.strings, fr);
      expect(find.text('Terminé'), findsOneWidget);

      manager.dispose();
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group('ScribbleFloatingToolbar 문구 주입', () {
    late DrawingState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = DrawingState();
      state.selectedTool.value = DrawingTool.pen;
    });

    Widget harness({OpenBoardStrings? strings, OpenBoardStrings? scope}) {
      final toolbar = MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ScribbleFloatingToolbar(state: state, strings: strings),
              ),
            ],
          ),
        ),
      );
      return scope == null
          ? toolbar
          : OpenBoardStringsScope(strings: scope, child: toolbar);
    }

    testWidgets('문구 묶음이 없으면 지금과 같은 영어 툴팁이다', (tester) async {
      await tester.pumpWidget(harness());

      expect(find.byTooltip('Pen'), findsOneWidget);
      expect(find.byTooltip('Eraser'), findsOneWidget);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Clear'), findsOneWidget);
    });

    testWidgets('생성자 문구로 도구 이름 · undo/redo/clear 툴팁이 바뀐다', (tester) async {
      await tester.pumpWidget(harness(strings: fr));

      expect(find.byTooltip('Stylo'), findsOneWidget);
      expect(find.byTooltip('Gomme'), findsOneWidget);
      expect(find.byTooltip('Défaire'), findsOneWidget);
      expect(find.byTooltip('Rétablir'), findsOneWidget);
      expect(find.byTooltip('Effacer'), findsOneWidget);
      expect(find.byTooltip('Pen'), findsNothing);
    });

    testWidgets('스코프 문구도 따른다', (tester) async {
      await tester.pumpWidget(harness(scope: fr));

      expect(find.byTooltip('Stylo'), findsOneWidget);
      expect(find.byTooltip('Effacer'), findsOneWidget);
    });
  });
}
