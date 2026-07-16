import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';

/// 이슈 #241 회귀 방지 위젯 테스트.
///
/// 검증 대상:
///  1. 소프트 키보드가 떠 있는 동안 인라인 에디터가 키보드 상단에 도킹되어
///     입력 중인 텍스트가 가려지지 않음 (터치 지점과 무관)
///  2. 키보드 높이 변화 시 도킹 위치가 실시간으로 따라감
///  3. 키보드가 없을 때는 기존 터치 지점 중심 배치/경계 클램프 유지
///  4. 키보드 해제 시 자동 편집 완료 동작 무변경 (기존 didChangeMetrics 경로)
void main() {
  /// 키보드 도킹 여백 — inline_text_editor.dart 의 keyboardGap 과 동일 값.
  const keyboardGap = 8.0;

  /// 논리 픽셀 단위 키보드 높이를 테스트 뷰 인셋으로 반영한다.
  void setKeyboardInset(WidgetTester tester, double logicalHeight) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: logicalHeight * tester.view.devicePixelRatio,
    );
  }

  /// 테스트 뷰의 논리 화면 크기 (기본 800x600).
  Size logicalScreenSize(WidgetTester tester) =>
      tester.view.physicalSize / tester.view.devicePixelRatio;

  /// 에디터(파란 테두리 컨테이너)의 렌더링 rect.
  Rect editorRect(WidgetTester tester) => tester.getRect(
    find.byKey(const ValueKey('inline_text_editor_container')),
  );

  /// [position] 에 새 텍스트용 인라인 에디터를 띄우고 완료 콜백 기록을 반환한다.
  Future<List<TextDrawable?>> pumpEditor(
    WidgetTester tester, {
    required Offset position,
  }) async {
    final completions = <TextDrawable?>[];
    final drawable = TextDrawableFactory.create(
      id: 'test-text',
      text: '',
      position: const Offset(100, 100),
      style: const TextStyle(fontSize: 16, color: Colors.black),
      alignment: TextAlignment.center,
      hidden: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InlineTextEditor(
          drawable: drawable,
          position: position,
          textSettings: const TextSettings(),
          isNew: true,
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

  group('InlineTextEditor 키보드 도킹 (#241)', () {
    testWidgets('키보드가 없으면 터치 지점을 중심으로 배치된다', (tester) async {
      const position = Offset(400, 300);
      await pumpEditor(tester, position: position);

      final rect = editorRect(tester);
      expect(rect.center.dx, moreOrLessEquals(position.dx));
      expect(rect.center.dy, moreOrLessEquals(position.dy));
    });

    testWidgets('키보드가 없으면 기존 하단 경계 클램프가 유지된다', (tester) async {
      final screen = logicalScreenSize(tester);
      await pumpEditor(tester, position: Offset(400, screen.height - 20));

      // 기존 클램프: top + height <= screenHeight - 100
      expect(editorRect(tester).bottom, moreOrLessEquals(screen.height - 100));
    });

    testWidgets('키보드가 올라오면 에디터가 키보드 상단에 도킹된다', (tester) async {
      const keyboardHeight = 250.0;
      setKeyboardInset(tester, keyboardHeight);
      addTearDown(tester.view.reset);

      final screen = logicalScreenSize(tester);
      // 키보드에 가려질 하단부 터치
      await pumpEditor(tester, position: Offset(400, screen.height - 30));

      final rect = editorRect(tester);
      expect(
        rect.bottom,
        moreOrLessEquals(screen.height - keyboardHeight - keyboardGap),
      );
    });

    testWidgets('터치 지점이 위쪽이어도 키보드가 떠 있는 동안은 키보드 위에 도킹된다', (tester) async {
      const keyboardHeight = 250.0;
      setKeyboardInset(tester, keyboardHeight);
      addTearDown(tester.view.reset);

      final screen = logicalScreenSize(tester);
      await pumpEditor(tester, position: const Offset(400, 100));

      final rect = editorRect(tester);
      expect(
        rect.bottom,
        moreOrLessEquals(screen.height - keyboardHeight - keyboardGap),
      );
    });

    testWidgets('키보드 높이가 변하면 도킹 위치가 따라간다', (tester) async {
      setKeyboardInset(tester, 250);
      addTearDown(tester.view.reset);

      final screen = logicalScreenSize(tester);
      await pumpEditor(tester, position: Offset(400, screen.height - 30));
      expect(
        editorRect(tester).bottom,
        moreOrLessEquals(screen.height - 250 - keyboardGap),
      );

      // 예측 입력 바 노출 등으로 키보드가 더 커진 경우
      setKeyboardInset(tester, 300);
      await tester.pump();
      expect(
        editorRect(tester).bottom,
        moreOrLessEquals(screen.height - 300 - keyboardGap),
      );
    });

    testWidgets('여러 줄 입력으로 에디터가 커져도 하단은 키보드 위에 고정된다', (tester) async {
      const keyboardHeight = 250.0;
      setKeyboardInset(tester, keyboardHeight);
      addTearDown(tester.view.reset);

      final screen = logicalScreenSize(tester);
      await pumpEditor(tester, position: Offset(400, screen.height - 30));
      final singleLineRect = editorRect(tester);

      await tester.enterText(find.byType(TextField), 'first\nsecond\nthird');
      await tester.pump();

      final multiLineRect = editorRect(tester);
      expect(multiLineRect.height, greaterThan(singleLineRect.height));
      // 하단(키보드 쪽)은 고정된 채 위로 자란다
      expect(
        multiLineRect.bottom,
        moreOrLessEquals(screen.height - keyboardHeight - keyboardGap),
      );
      expect(multiLineRect.top, lessThan(singleLineRect.top));
    });

    testWidgets('키보드가 극단적으로 크면 상단 경계(50) 유지를 우선한다', (tester) async {
      setKeyboardInset(tester, 520);
      addTearDown(tester.view.reset);

      final screen = logicalScreenSize(tester);
      await pumpEditor(tester, position: Offset(400, screen.height - 30));

      // 완전 회피 시 top 이 50 미만이 되는 상황 → 상단 경계 클램프 우선
      final rect = editorRect(tester);
      expect(rect.top, moreOrLessEquals(50));
      // 상단 경계~키보드 사이 공간(22)이 최소 높이(30)보다 작으므로
      // 에디터는 최소 높이로 재제한되고 키보드 상단(80)에 맞닿는다
      expect(rect.height, moreOrLessEquals(30));
      expect(rect.bottom, lessThanOrEqualTo(screen.height - 520));
    });

    testWidgets('키보드가 내려가면 기존처럼 편집이 자동 완료된다 (회귀 가드)', (tester) async {
      final completions = await pumpEditor(
        tester,
        position: const Offset(400, 300),
      );
      addTearDown(tester.view.reset);

      // didChangeMetrics 는 MediaQuery 갱신보다 한 프레임 먼저 호출되므로
      // 실기기의 키보드 애니메이션처럼 다단계로 인셋을 변화시켜야
      // 감소 시퀀스가 관측된다.
      setKeyboardInset(tester, 250);
      await tester.pump();
      setKeyboardInset(tester, 100);
      await tester.pump();
      // NOTE: 이 시점에 완료가 안 된 것은 테스트 하네스의 MediaQuery 1프레임
      // 지연 관측일 뿐, "부분 축소는 완료하지 않는다"는 스펙이 아니다.
      expect(completions, isEmpty);

      // 키보드 해제 → 빈 텍스트라 취소(null) 완료
      setKeyboardInset(tester, 0);
      await tester.pump();
      expect(completions, [null]);
    });
  });
}
