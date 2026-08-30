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

/// 인라인 텍스트 에디터 링크 편집 UX 회귀 방지 테스트.
///
/// 검증 대상:
///  1. 편집 중 링크 구간이 커밋 후 렌더링과 동일한 스타일(파랑+밑줄)로 표시 (#8481)
///  2. 커서가 링크 위(collapsed)에 있어도 링크 편집/삭제 가능 — 굿노트 동작 (#8481)
///  3. 상시 노출 링크 버튼 **부재** — 대상 없을 때 조용히 무동작이라 죽은 버튼으로
///     체감됐고, 컨텍스트 메뉴와 중복 진입점이었다 (kobic #9838)
///  4. 선택이 없어도 링크 추가 가능 — 링크 타깃을 커서 위치에 삽입 (kobic #9838)
///  5. 링크 입력 UI 를 호스트 앱이 주입 가능 ([LinkTargetResolver]), 미주입 시
///     내장 Material 다이얼로그로 폴백 (kobic #9838)
void main() {
  TextLinkSpan span(int start, int end, [String url = 'https://example.com']) =>
      TextLinkSpan()
        ..start = start
        ..end = end
        ..url = url;

  /// [text] 와 [linkSpans] 를 가진 기존 텍스트용 인라인 에디터를 띄운다.
  ///
  /// [linkTargetResolver] 를 주면 내장 다이얼로그 대신 그 콜백이 쓰인다.
  Future<List<TextDrawable?>> pumpEditor(
    WidgetTester tester, {
    String text = 'hello world',
    List<TextLinkSpan> linkSpans = const [],
    LinkTargetResolver? linkTargetResolver,
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
          linkTargetResolver: linkTargetResolver,
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

  /// 선택 툴바를 띄운다 (모바일에서 커서/선택 핸들 탭에 해당).
  Future<void> showToolbar(WidgetTester tester) async {
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();
  }

  /// 컨텍스트 메뉴에서 [label] 항목을 탭한다.
  Future<void> tapMenuItem(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// 배경 탭으로 편집을 커밋한다.
  Future<void> commitByBackgroundTap(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  }

  /// 항상 [target] 을 반환하는 resolver (호출 인자를 [captured] 에 기록).
  LinkTargetResolver stubResolver(String? target, {List<String?>? captured}) =>
      (context, {String? initialTarget}) async {
        captured?.add(initialTarget);
        return target;
      };

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

  group('상시 노출 링크 버튼 제거 (kobic #9838)', () {
    testWidgets('링크 버튼이 렌더링되지 않는다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);

      expect(
        find.byKey(const ValueKey('inline_text_editor_link_button')),
        findsNothing,
      );
      expect(find.byIcon(Icons.link), findsNothing);
    });
  });

  group('날짜 버튼 → 완료 버튼 교체 (kobic UB-631)', () {
    testWidgets('날짜 삽입 버튼(캘린더 아이콘)이 더 이상 렌더링되지 않는다', (tester) async {
      await pumpEditor(tester);

      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('완료 버튼이 렌더링되고, 탭하면 편집이 즉시 완료된다', (tester) async {
      final completions = await pumpEditor(tester);

      final doneButton = find.byKey(
        const ValueKey('inline_text_editor_done_button'),
      );
      expect(doneButton, findsOneWidget);
      expect(
        find.descendant(of: doneButton, matching: find.text('완료')),
        findsOneWidget,
      );

      await tester.tap(doneButton);
      await tester.pump();

      expect(completions, hasLength(1));
      expect(completions.single?.text, 'hello world');
    });
  });

  group('컨텍스트 메뉴 진입점 (kobic #9838)', () {
    testWidgets('드래그 선택 시 링크 추가가 노출된다', (tester) async {
      await pumpEditor(tester);
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);

      expect(find.text('링크 추가'), findsOneWidget);
      expect(find.text('링크 삭제'), findsNothing);
    });

    testWidgets('선택이 없어도 링크 추가가 노출된다 — 유일한 진입점이므로 도달 가능해야 한다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 8);
      await tester.pump();

      await showToolbar(tester);

      expect(find.text('링크 추가'), findsOneWidget);
      expect(find.text('링크 편집'), findsNothing);
      expect(find.text('링크 삭제'), findsNothing);
    });

    testWidgets('커서가 링크 위면 링크 편집/삭제가 노출된다', (tester) async {
      await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await showToolbar(tester);

      expect(find.text('링크 편집'), findsOneWidget);
      expect(find.text('링크 삭제'), findsOneWidget);
      expect(find.text('링크 추가'), findsNothing);
    });
  });

  group('선택 없이 링크 추가 — 커서 위치 삽입 (kobic #9838)', () {
    testWidgets('링크 타깃이 커서 위치에 삽입되고 그 범위에 링크가 걸린다', (tester) async {
      final completions = await pumpEditor(
        tester,
        linkTargetResolver: stubResolver('https://a.com'),
      );
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');
      await commitByBackgroundTap(tester);

      final committed = completions.single!;
      expect(committed.text, 'hellohttps://a.com world');
      final result = committed.linkSpans.single;
      expect(result.start, 5);
      expect(result.end, 5 + 'https://a.com'.length);
      expect(result.url, 'https://a.com');
    });

    testWidgets('삽입 후 커서는 삽입분 뒤에 놓인다 — 이어지는 입력이 링크를 지우지 않는다', (tester) async {
      await pumpEditor(
        tester,
        text: '',
        linkTargetResolver: stubResolver('https://a.com'),
      );

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');

      final selection = controllerOf(tester).selection;
      expect(selection.isCollapsed, isTrue);
      expect(selection.baseOffset, 'https://a.com'.length);
    });

    testWidgets('드래그 선택이 있으면 삽입하지 않고 선택 텍스트에 링크를 건다', (tester) async {
      final completions = await pumpEditor(
        tester,
        linkTargetResolver: stubResolver('https://a.com'),
      );
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');
      await commitByBackgroundTap(tester);

      final committed = completions.single!;
      expect(committed.text, 'hello world'); // 텍스트 불변
      final result = committed.linkSpans.single;
      expect(result.start, 6);
      expect(result.end, 11);
    });

    testWidgets('취소하면 텍스트도 링크도 변하지 않는다', (tester) async {
      final completions = await pumpEditor(
        tester,
        linkTargetResolver: stubResolver(null), // 취소
      );
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');
      await commitByBackgroundTap(tester);

      final committed = completions.single!;
      expect(committed.text, 'hello world');
      expect(committed.linkSpans, isEmpty);
    });
  });

  group('링크 입력 UI 주입 (kobic #9838)', () {
    testWidgets('resolver 를 주입하면 내장 다이얼로그가 열리지 않는다', (tester) async {
      await pumpEditor(
        tester,
        linkTargetResolver: stubResolver('https://a.com'),
      );
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('링크 입력'), findsNothing);
    });

    testWidgets('기존 링크 편집 시 resolver 에 현재 타깃이 전달된다', (tester) async {
      final captured = <String?>[];
      await pumpEditor(
        tester,
        linkSpans: [span(0, 5, 'https://old.com')],
        linkTargetResolver: stubResolver('https://new.com', captured: captured),
      );
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 편집');

      expect(captured, ['https://old.com']);
    });

    testWidgets('새 링크 추가 시 resolver 에 전달되는 타깃은 null 이다', (tester) async {
      final captured = <String?>[];
      await pumpEditor(
        tester,
        linkTargetResolver: stubResolver('https://a.com', captured: captured),
      );
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');

      expect(captured, [null]);
    });

    testWidgets('resolver 미주입 시 내장 Material 다이얼로그로 폴백한다', (tester) async {
      await pumpEditor(tester);
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');

      expect(find.text('링크 입력'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('링크 적용/편집/삭제 (kobic #8481 회귀)', () {
    testWidgets('드래그 선택 후 내장 다이얼로그로 새 링크를 적용할 수 있다', (tester) async {
      final completions = await pumpEditor(tester);
      controllerOf(tester).selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      );
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 추가');
      await tester.enterText(dialogUrlField(), 'example.org');
      await tapMenuItem(tester, '확인');

      await commitByBackgroundTap(tester);

      final result = completions.single!.linkSpans.single;
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

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 편집');
      await tester.enterText(dialogUrlField(), 'https://new.com');
      await tapMenuItem(tester, '확인');

      await commitByBackgroundTap(tester);

      final result = completions.single!.linkSpans.single;
      expect(result.start, 0);
      expect(result.end, 5);
      expect(result.url, 'https://new.com');
    });

    testWidgets('커서 위치에서 링크 삭제 시 커밋 결과에 링크가 없다', (tester) async {
      final completions = await pumpEditor(tester, linkSpans: [span(0, 5)]);
      controllerOf(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await showToolbar(tester);
      await tapMenuItem(tester, '링크 삭제');

      await commitByBackgroundTap(tester);

      expect(completions.single!.linkSpans, isEmpty);
    });
  });
}
