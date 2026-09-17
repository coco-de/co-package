import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';
import 'package:open_board/src/module/text/text_painter.dart';

/// 인라인 에디터 커밋 시 줄바꿈 폭 기록 (kobic unibook#12538/#12548).
///
/// 검증 대상:
///  1. 편집 완료 시 TextField 의 실제 콘텐츠 폭(필드 폭 - contentPadding)이
///     `TextDrawable.maxWidth` 로 기록된다
///  2. scale 이 1 이 아니면 캔버스 단위로 환산되어 기록된다
///  3. 커밋된 drawable 을 정적 렌더링(getTextBounds)하면 편집 중 폭 안에서
///     줄바꿈된다 — 확정 순간 한 줄로 펴지는 원 결함의 종단 회귀 가드
void main() {
  Future<List<TextDrawable?>> pumpEditor(
    WidgetTester tester, {
    double scale = 1.0,
  }) async {
    final completions = <TextDrawable?>[];
    final drawable = TextDrawableFactory.create(
      id: 'test-text',
      text: '',
      position: const Offset(100, 100),
      style: const TextStyle(fontSize: 16, color: Colors.black),
      alignment: TextAlignment.left,
      hidden: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InlineTextEditor(
          drawable: drawable,
          position: const Offset(400, 300),
          textSettings: const TextSettings(),
          isNew: true,
          scale: scale,
          selectedColor: Colors.black,
          onComplete: completions.add,
        ),
      ),
    );
    // postFrame 포커스 요청 반영
    await tester.pump();
    return completions;
  }

  /// 배경 탭으로 편집을 완료시킨다 (inline_text_editor 의 완료 경로 중 하나).
  Future<void> completeByBackgroundTap(WidgetTester tester) async {
    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
  }

  group('InlineTextEditor 커밋 시 줄바꿈 폭 기록', () {
    testWidgets('완료 시 TextField 콘텐츠 폭이 maxWidth 로 기록된다', (tester) async {
      final completions = await pumpEditor(tester);

      await tester.enterText(find.byType(TextField), 'a' * 40);
      await tester.pump();

      final fieldWidth = tester.getSize(find.byType(TextField)).width;
      await completeByBackgroundTap(tester);

      expect(completions, hasLength(1));
      final committed = completions.single;
      expect(committed, isNotNull);
      // contentPadding(horizontal: 4) 안쪽이 실제 줄바꿈 폭이다.
      expect(committed!.maxWidth, closeTo(fieldWidth - 8, 0.5));
    });

    testWidgets('scale 을 나눠 캔버스 단위로 기록한다', (tester) async {
      final completions = await pumpEditor(tester, scale: 2.0);

      await tester.enterText(find.byType(TextField), 'a' * 40);
      await tester.pump();

      final fieldWidth = tester.getSize(find.byType(TextField)).width;
      await completeByBackgroundTap(tester);

      final committed = completions.single;
      expect(committed, isNotNull);
      expect(committed!.maxWidth, closeTo((fieldWidth - 8) / 2.0, 0.5));
    });

    testWidgets('커밋된 drawable 은 편집 폭 안에서 줄바꿈 렌더링된다 (종단 가드)',
        (tester) async {
      final completions = await pumpEditor(tester);

      // 에디터 폭을 확실히 넘는 길이 — 편집 중 소프트 줄바꿈이 생긴다.
      await tester.enterText(find.byType(TextField), 'a' * 120);
      await tester.pump();

      final fieldWidth = tester.getSize(find.byType(TextField)).width;
      await completeByBackgroundTap(tester);

      final committed = completions.single!;
      final bounds = TextDrawablePainter.getTextBounds(committed);

      // 확정 후에도 편집 중 폭을 넘지 않고, 여러 줄로 렌더링된다.
      expect(bounds.width, lessThanOrEqualTo(fieldWidth));
      expect(
        bounds.height,
        greaterThan(committed.fontSize * 1.5),
        reason: '한 줄로 펴졌다면 높이가 1줄분이다 — 원 결함(UB-627) 재발',
      );
    });
  });
}
