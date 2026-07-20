// 테스트 단언에서 `.single`/`.first` 는 "정확히 1개"/"비어있지 않음"을 의도적으로
// 단언하는 관용구다 — 가정 위반 시 즉시 실패하는 것이 기대 동작이라 safe 변형
// (singleOrNull/firstOrNull) 으로 바꾸지 않는다.
// ignore_for_file: avoid-unsafe-collection-methods
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/link_aware_text_editing_controller.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';
import 'package:open_board/src/module/text/text_span_builder.dart';

/// kobic #8481 회귀 방지 테스트 — 인라인 텍스트 에디터 링크 편집 UX.
///
/// 검증 대상:
///  1. 편집 중 링크 구간이 커밋 후 렌더링과 동일한 스타일(파랑+밑줄)로 표시
///  2. 커서가 링크 위(collapsed)에 있어도 링크 편집/삭제 가능 (굿노트 동작)
///  3. 상시 노출 링크 버튼 — 대상 있으면 다이얼로그 진입, 없으면 무시
void main() {
  const linkButtonKey = ValueKey('inline_text_editor_link_button');

  TextLinkSpan span(int start, int end, [String url = 'https://example.com']) =>
      TextLinkSpan()
        ..start = start
        ..end = end
        ..url = url;

  /// [text] 와 [linkSpans] 를 가진 기존 텍스트용 인라인 에디터를 띄운다.
  Future<List<TextDrawable?>> pumpEditor(
    WidgetTester tester, {
    String text = 'hello world',
    List<TextLinkSpan> linkSpans = const [],
  }) async {
    final completions = <TextDrawable?>[];
    final drawable = TextDrawableFactory.create(
      id: 'test-text',
      text: text,
      position: const Offset(100, 100),
      style: const TextStyle(fontSize: 16, color: Colors.black),
      alignment: TextAlignment.center,
      hidden: true,
    )..linkSpans.addAll(linkSpans);

    await tester.pumpWidget(
      MaterialApp(
        home: InlineTextEditor(
          drawable: drawable,
          position: const Offset(400, 300),
          textSettings: const TextSettings(),
          isNew: false,
          scale: 1.0,
          selectedColor: Colors.black,
          onComplete: completions.add,
        ),
      ),
    );
    // postFrame 포커스 요청 반영
    await tester.pump();
    return completions;
  }

  /// 에디터 TextField 의 컨트롤러.
  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  /// 링크 다이얼로그의 URL 입력 필드.
  Finder dialogUrlField() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  /// 배경 탭으로 편집을 커밋한다.
  Future<void> commitByBackgroundTap(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  group('LinkAwareTextEditingController — 편집 중 링크 스타일 (kobic #8481)', () {
    testWidgets('링크 구간은 파랑+밑줄, 나머지는 기본 스타일로 분할된다', (tester) async {
      final spans = [span(6, 11)];
      final controller = LinkAwareTextEditingController(
        linkSpansProvider: () => spans,
      )..text = 'hello world';
      addTearDown(controller.dispose);

      late TextSpan built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              built = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16, color: Colors.black),
                withComposing: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final children = built.children!.cast<TextSpan>();
      expect(children.map((child) => child.text), ['hello ', 'world']);
      expect(children[0].style, isNull); // 기본 스타일 상속
      expect(children[1].style?.color, kTextLinkColor);
      expect(children[1].style?.decoration, TextDecoration.underline);
    });

    testWidgets('IME 조합 구간은 밑줄로 표시된다', (tester) async {
      final controller =
          LinkAwareTextEditingController(linkSpansProvider: () => const [])
            ..value = const TextEditingValue(
              text: 'hello',
              composing: TextRange(start: 0, end: 2),
            );
      addTearDown(controller.dispose);

      late TextSpan built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              built = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final children = built.children!.cast<TextSpan>();
      expect(children.map((child) => child.text), ['he', 'llo']);
      expect(children[0].style?.decoration, TextDecoration.underline);
      expect(children[0].style?.color, isNot(kTextLinkColor));
      expect(children[1].style, isNull);
    });

    testWidgets('에디터의 TextField 가 링크 인지 컨트롤러를 사용한다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      expect(controllerOf(tester), isA<LinkAwareTextEditingController>());
    });
  });

  group('링크 버튼 (kobic #8481)', () {
    testWidgets('커서가 링크 위(collapsed)면 기존 URL 이 채워진 다이얼로그가 열린다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5, 'https://old.com')]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await tester.tap(find.byKey(linkButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('링크 입력'), findsOneWidget);
      final urlField = tester.widget<TextField>(dialogUrlField());
      expect(urlField.controller?.text, 'https://old.com');
    });

    testWidgets('커서가 링크 밖이고 선택도 없으면 다이얼로그가 열리지 않는다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 8);
      await tester.pump();

      await tester.tap(find.byKey(linkButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('링크 입력'), findsNothing);
    });

    testWidgets('드래그 선택 후 링크 버튼으로 새 링크를 적용할 수 있다', (tester) async {
      final completions = await pumpEditor(tester);
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await tester.tap(find.byKey(linkButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(dialogUrlField(), 'example.org');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      await commitByBackgroundTap(tester);

      final committed = completions.single!;
      final result = committed.linkSpans.single;
      expect(result.start, 6);
      expect(result.end, 11);
      // scheme 없는 입력은 https 로 정규화된다
      expect(result.url, 'https://example.org');
    });

    testWidgets('커서만 올려 두고 기존 링크 URL 을 수정할 수 있다', (tester) async {
      final completions = await pumpEditor(
        tester,
        linkSpans: [span(0, 5, 'https://old.com')],
      );
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();

      await tester.tap(find.byKey(linkButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(dialogUrlField(), 'https://new.com');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      await commitByBackgroundTap(tester);

      final result = completions.single!.linkSpans.single;
      expect(result.start, 0);
      expect(result.end, 5);
      expect(result.url, 'https://new.com');
    });
  });

  group('커서 기반 컨텍스트 메뉴 (kobic #8481)', () {
    testWidgets('커서가 링크 위면 툴바에 링크 편집/삭제가 노출된다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();

      expect(find.text('링크 편집'), findsOneWidget);
      expect(find.text('링크 삭제'), findsOneWidget);
    });

    testWidgets('커서가 링크 밖이면 링크 항목이 노출되지 않는다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 8);
      await tester.pump();

      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();

      expect(find.text('링크 편집'), findsNothing);
      expect(find.text('링크 추가'), findsNothing);
      expect(find.text('링크 삭제'), findsNothing);
    });

    testWidgets('커서 위치에서 링크 삭제 시 커밋 결과에 링크가 없다', (tester) async {
      final completions = await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
      await tester.pumpAndSettle();
      await tester.tap(find.text('링크 삭제'));
      await tester.pumpAndSettle();

      await commitByBackgroundTap(tester);

      expect(completions.single!.linkSpans, isEmpty);
    });
  });
}
