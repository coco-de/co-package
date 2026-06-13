// 하이라이트 데모 테스트 (#43)
// BDD: example/test/bdd/example_highlight.feature
//
// 실제 제스처 기반 텍스트 선택(SelectionArea 드래그)은 플랫폼 의존이라
// startHighlightFlow(textOverride:)로 치환 — 시트 UI부터 저장·렌더·영속까지는
// 실제 위젯 경로로 검증한다.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub_v1.dart';
import 'package:open_epub_example/highlight_demo_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 최소 EPUB 픽스처 ---

Uint8List _zipEpub(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// 번들 example.epub처럼 비선형(linear="no") cover가 spine 앞에 있는 책.
/// linear 필터 인덱스 vs 전체 spine 인덱스 불일치 회귀 검증용.
Uint8List _coverFirstEpub() => _zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''
<?xml version="1.0"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>cover-first 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:hl-demo-0002</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="cover" linear="no"/>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="ch1.xhtml">1장</a></li></ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/cover.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>표지</p></body></html>',
      'OEBPS/ch1.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>고래는 바다에 산다.</p></body></html>',
      'OEBPS/ch2.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>사자는 초원의 왕이다.</p></body></html>',
    });

Uint8List _demoEpub() => _zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': '''
<?xml version="1.0"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>하이라이트 데모 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:hl-demo-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="ch1.xhtml">1장</a></li>
        <li><a href="ch2.xhtml">2장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>고래는 바다에 산다. 바다는 넓다.</p></body></html>',
      'OEBPS/ch2.xhtml':
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>사자는 초원의 왕이다.</p></body></html>',
    });

Widget _wrap() => MaterialApp(
      home: HighlightDemoPage(bytesOverride: _demoEpub()),
    );

HighlightDemoPageState _state(WidgetTester tester) =>
    tester.state<HighlightDemoPageState>(find.byType(HighlightDemoPage));

/// 화면의 모든 RichText에서 [color] 배경의 span(스타일 상속 포함)에 속한
/// 평문을 모은다. flutter_html이 배경색을 box(Container/ColoredBox)로
/// 그리는 경우도 함께 탐지한다.
String _highlightedPlainText(WidgetTester tester, Color color) {
  final buffer = StringBuffer();

  void collect(InlineSpan span, bool inHighlight) {
    if (span is! TextSpan) return;
    final isHighlighted =
        inHighlight || span.style?.backgroundColor == color;
    if (isHighlighted && span.text != null) buffer.write(span.text);
    for (final child in span.children ?? const <InlineSpan>[]) {
      collect(child, isHighlighted);
    }
  }

  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    collect(richText.text, false);
  }
  if (buffer.isNotEmpty) return buffer.toString();

  // fallback: 배경색 box 안의 텍스트
  final boxFinder = find.byWidgetPredicate(
    (widget) =>
        (widget is Container && widget.color == color) ||
        (widget is ColoredBox && widget.color == color) ||
        (widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == color),
  );
  for (final element in boxFinder.evaluate()) {
    for (final richText
        in tester.widgetList<RichText>(find.descendant(
      of: find.byWidget(element.widget),
      matching: find.byType(RichText),
    ))) {
      buffer.write(richText.text.toPlainText());
    }
  }
  return buffer.toString();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DemoHighlight / injectHighlightSpans (unit)', () {
    test('JSON round-trip 무손실', () {
      const original = DemoHighlight(
        id: 'h1',
        spineHref: 'ch1.xhtml',
        text: '고래는 바다에',
        colorName: '초록',
        note: '중요한 문장',
      );
      final restored = DemoHighlight.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.id, original.id);
      expect(restored.spineHref, original.spineHref);
      expect(restored.text, original.text);
      expect(restored.colorName, original.colorName);
      expect(restored.note, original.note);
    });

    test('첫 일치 구간을 배경색 span으로 감싼다', () {
      const xhtml = '<p>고래는 바다에 산다.</p>';
      const highlight = DemoHighlight(
        id: 'h1',
        spineHref: 'ch1.xhtml',
        text: '고래는 바다에',
        colorName: '초록',
      );
      final out = injectHighlightSpans(xhtml, const [highlight]);
      expect(
        out,
        '<p><span style="background-color:#C8E6C9;">고래는 바다에</span>'
        ' 산다.</p>',
      );
    });

    test('본문과 일치하지 않으면 원문 그대로 (@edge)', () {
      const xhtml = '<p>고래는 바다에 산다.</p>';
      const highlight = DemoHighlight(
        id: 'h1',
        spineHref: 'ch1.xhtml',
        text: '여러 문단에 걸친 선택 텍스트',
        colorName: '노랑',
      );
      expect(injectHighlightSpans(xhtml, const [highlight]), xhtml);
    });

    test('하이라이트 여러 건을 각각 주입한다', () {
      const xhtml = '<p>고래는 바다에 산다. 바다는 넓다.</p>';
      const highlights = [
        DemoHighlight(
            id: 'h1', spineHref: 'c', text: '고래는', colorName: '노랑'),
        DemoHighlight(
            id: 'h2', spineHref: 'c', text: '넓다', colorName: '분홍'),
      ];
      final out = injectHighlightSpans(xhtml, highlights);
      expect(out, contains('background-color:#FFF59D;">고래는</span>'));
      expect(out, contains('background-color:#F8BBD0;">넓다</span>'));
    });

    test('태그명과 일치하는 본문 단어는 태그를 파손하지 않는다', () {
      // 본문 단어 "head"의 raw 첫 일치는 <head> 태그명 — 태그 내부 일치는
      // 건너뛰고 본문 텍스트에만 주입되어야 한다.
      const xhtml = '<html><head><title>제목</title></head>'
          '<body><p>the head of the whale</p></body></html>';
      const highlight = DemoHighlight(
        id: 'h1',
        spineHref: 'c',
        text: 'head',
        colorName: '노랑',
      );
      final out = injectHighlightSpans(xhtml, const [highlight]);
      expect(out, contains('<head><title>제목</title></head>'));
      expect(
        out,
        contains('the <span style="background-color:#FFF59D;">head</span>'),
      );
    });

    test('속성 값과 일치하는 텍스트는 속성을 파손하지 않는다', () {
      const xhtml = '<body><p><img alt="고래 그림"/>고래 그림 설명</p></body>';
      const highlight = DemoHighlight(
        id: 'h1',
        spineHref: 'c',
        text: '고래 그림',
        colorName: '파랑',
      );
      final out = injectHighlightSpans(xhtml, const [highlight]);
      expect(out, contains('<img alt="고래 그림"/>'));
      expect(
        out,
        contains('<span style="background-color:#BBDEFB;">고래 그림</span> 설명'),
      );
    });

    test('body 이전 영역(title 텍스트)에는 주입하지 않는다', () {
      const xhtml = '<html><head><title>고래 이야기</title></head>'
          '<body><p>고래 이야기의 시작</p></body></html>';
      const highlight = DemoHighlight(
        id: 'h1',
        spineHref: 'c',
        text: '고래 이야기',
        colorName: '초록',
      );
      final out = injectHighlightSpans(xhtml, const [highlight]);
      expect(out, contains('<title>고래 이야기</title>'));
      expect(
        out,
        contains('<span style="background-color:#C8E6C9;">고래 이야기</span>의'),
      );
    });
  });

  group('HighlightStore (unit)', () {
    test('손상된 저장 데이터는 무시하고 빈 목록을 반환한다', () async {
      SharedPreferences.setMockInitialValues({
        HighlightStore.storageKey: 'not-json{{{',
      });
      expect(await const HighlightStore().load(), isEmpty);
    });
  });

  group('F5-demo: 텍스트 선택 → 색상 하이라이트 + 메모', () {
    testWidgets('텍스트 선택 후 색상 하이라이트 (@P0 @smoke)', (tester) async {
      // Given 하이라이트 데모 페이지에 EPUB 책이 열려 있다
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);
      final toolUseEvents = <EpubToolUseEvent>[];
      state.session!.toolUseEvents.listen(toolUseEvents.add);

      // When 사용자가 본문 텍스트 "고래는 바다에"를 선택하고
      // 컨텍스트 메뉴에서 "하이라이트"를 탭한다 (제스처 치환).
      // flow의 future는 시트가 닫혀야 완료되므로 await하지 않는다.
      unawaited(state.startHighlightFlow(textOverride: '고래는 바다에'));
      await tester.pumpAndSettle();

      // And 색상 "초록"을 선택하고 저장한다
      await tester.tap(find.bySemanticsLabel('색상 초록'));
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Then 본문에서 해당 구간이 초록 배경으로 표시된다
      expect(
        _highlightedPlainText(tester, highlightPalette['초록']!),
        contains('고래는 바다에'),
      );
      // And 하이라이트 목록에 1개 항목이 추가된다
      expect(state.highlights, hasLength(1));
      expect(state.highlights.single.colorName, '초록');
      // And 영속 저장소에도 기록된다 (save 경로)
      final stored = await const HighlightStore().load();
      expect(stored, hasLength(1));
      expect(stored.single.text, '고래는 바다에');
      // And toolUseEvents에 EpubHighlightToolUse가 발사된다
      await tester.pump();
      expect(toolUseEvents.whereType<EpubHighlightToolUse>(), hasLength(1));
    });

    testWidgets('선택 시 하이라이트 FAB 노출·소비 (@P0 회귀 #45)', (tester) async {
      // Given 책이 열려 있고 선택이 없으면 FAB가 보이지 않는다
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);
      final fab = find.widgetWithText(FloatingActionButton, '하이라이트');
      expect(fab, findsNothing);

      // When 본문 텍스트를 선택하면 (SelectionArea 드래그 치환)
      state.debugSetSelection('고래는 바다에');
      await tester.pump();

      // Then "하이라이트" FAB가 나타난다 (데스크톱 웹 진입점)
      expect(fab, findsOneWidget);
      // 그리고 FAB의 onPressed는 선택 상태 기반 플로우를 연다
      expect(
        tester.widget<FloatingActionButton>(fab).onPressed,
        isNotNull,
      );

      // When FAB가 여는 플로우(선택 상태 사용)로 색상을 저장하면
      unawaited(state.startHighlightFlow());
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('색상 노랑'));
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Then 하이라이트가 저장·렌더되고 선택이 소비되어 FAB가 사라진다
      expect(state.highlights, hasLength(1));
      expect(
        _highlightedPlainText(tester, highlightPalette['노랑']!),
        contains('고래는 바다에'),
      );
      expect(fab, findsNothing);
    });

    testWidgets('비선형 cover가 있는 책 — 챕터·하이라이트 정합 (@P0 회귀)', (tester) async {
      // Given linear="no" cover가 spine 첫 항목인 책이 열려 있다
      // (번들 example.epub와 같은 구조 — 인덱스 공간 불일치 회귀 검증)
      await tester.pumpWidget(
        MaterialApp(home: HighlightDemoPage(bytesOverride: _coverFirstEpub())),
      );
      await tester.pumpAndSettle();
      final state = _state(tester);

      // Then 첫 화면은 cover가 아닌 1장(첫 linear 챕터)을 표시한다
      expect(find.textContaining('고래는 바다에'), findsOneWidget);
      expect(find.textContaining('표지'), findsNothing);

      // When 하이라이트를 추가하면
      await state.addHighlight(text: '고래는 바다에', colorName: '노랑');
      await tester.pumpAndSettle();

      // Then 표시 중인 챕터의 href(ch1)로 저장되고 본문에 렌더된다
      expect(state.highlights.single.spineHref, 'ch1.xhtml');
      expect(
        _highlightedPlainText(tester, highlightPalette['노랑']!),
        contains('고래는 바다에'),
      );

      // And 다음 챕터 이동도 라벨과 본문이 일치한다 (2/2 = ch2)
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.textContaining('사자는 초원의 왕이다'), findsOneWidget);
      expect(state.session!.position.spineHref, 'ch2.xhtml');
    });

    testWidgets('챕터 이동 후 하이라이트 — analytics 위치가 화면과 일치 (@P0 회귀)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);
      final toolUseEvents = <EpubToolUseEvent>[];
      state.session!.toolUseEvents.listen(toolUseEvents.add);

      // When 2장으로 이동해 하이라이트를 추가하면
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      await state.addHighlight(text: '사자는 초원의', colorName: '분홍');
      await tester.pump();

      // Then toolUse 이벤트의 position은 2장을 가리킨다
      final event =
          toolUseEvents.whereType<EpubHighlightToolUse>().single;
      expect(event.position.spineHref, 'ch2.xhtml');
    });

    testWidgets('메모와 함께 하이라이트 (@P0)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);

      // When "바다는 넓다"를 선택하고 색상 "파랑"과 메모를 입력하고 저장한다
      unawaited(state.startHighlightFlow(textOverride: '바다는 넓다'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('색상 파랑'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '중요한 문장');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Then 하이라이트 목록 항목에 메모가 표시된다
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      expect(find.text('메모: 중요한 문장'), findsOneWidget);
      expect(state.highlights.single.note, '중요한 문장');
    });

    testWidgets('하이라이트 영속 — 재시작 후 유지 (@P0)', (tester) async {
      // Given 하이라이트 "고래는 바다에"(노랑)가 저장되어 있다
      SharedPreferences.setMockInitialValues({
        HighlightStore.storageKey: jsonEncode([
          const DemoHighlight(
            id: 'h1',
            spineHref: 'ch1.xhtml',
            text: '고래는 바다에',
            colorName: '노랑',
          ).toJson(),
        ]),
      });

      // When 데모 페이지를 다시 연다
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Then 본문에서 해당 구간이 노랑 배경으로 표시된다
      expect(
        _highlightedPlainText(tester, highlightPalette['노랑']!),
        contains('고래는 바다에'),
      );
      // And 하이라이트 목록에 1개 항목이 있다
      expect(_state(tester).highlights, hasLength(1));
    });

    testWidgets('하이라이트 목록에서 이동 (@P0)', (tester) async {
      // Given 2장에 하이라이트 "사자는 초원의"(분홍)가 저장되어 있다
      SharedPreferences.setMockInitialValues({
        HighlightStore.storageKey: jsonEncode([
          const DemoHighlight(
            id: 'h2',
            spineHref: 'ch2.xhtml',
            text: '사자는 초원의',
            colorName: '분홍',
          ).toJson(),
        ]),
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);
      // And 뷰어는 1장을 표시하고 있다
      expect(state.spineIndex, 0);
      expect(find.textContaining('고래는'), findsOneWidget);

      // When 하이라이트 목록에서 해당 항목을 탭한다
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('사자는 초원의'));
      await tester.pumpAndSettle();

      // Then 뷰어는 2장으로 이동한다
      expect(state.spineIndex, 1);
      expect(state.session!.position.spineHref, 'ch2.xhtml');
      expect(find.textContaining('사자는 초원의 왕이다'), findsOneWidget);
    });

    testWidgets('하이라이트 삭제 (@P1)', (tester) async {
      SharedPreferences.setMockInitialValues({
        HighlightStore.storageKey: jsonEncode([
          const DemoHighlight(
            id: 'h1',
            spineHref: 'ch1.xhtml',
            text: '고래는 바다에',
            colorName: '노랑',
          ).toJson(),
        ]),
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);
      expect(
        _highlightedPlainText(tester, highlightPalette['노랑']!),
        isNotEmpty,
      );

      // When 하이라이트 목록에서 삭제를 탭한다
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('하이라이트 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      // Then 본문 하이라이트 표시가 사라지고 목록은 비어 있다
      expect(
        _highlightedPlainText(tester, highlightPalette['노랑']!),
        isEmpty,
      );
      expect(state.highlights, isEmpty);
      // 영속 저장소에서도 제거된다
      final stored = await const HighlightStore().load();
      expect(stored, isEmpty);
    });

    testWidgets('본문과 일치하지 않는 선택 텍스트 (@edge)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final state = _state(tester);

      // Given 본문 원문과 일치하지 않는 텍스트가 저장된다
      await state.addHighlight(
        text: '여러 문단에 걸친\n선택 텍스트',
        colorName: '초록',
      );
      await tester.pumpAndSettle();

      // Then 목록에는 항목이 보이지만 본문 표시는 생략된다 + 크래시 없음
      expect(state.highlights, hasLength(1));
      expect(
        _highlightedPlainText(tester, highlightPalette['초록']!),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('메모 편집 (@P1)', (tester) async {
      SharedPreferences.setMockInitialValues({
        HighlightStore.storageKey: jsonEncode([
          const DemoHighlight(
            id: 'h1',
            spineHref: 'ch1.xhtml',
            text: '고래는 바다에',
            colorName: '노랑',
          ).toJson(),
        ]),
      });
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('하이라이트 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('메모 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '다시 읽기');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(_state(tester).highlights.single.note, '다시 읽기');
    });
  });
}
