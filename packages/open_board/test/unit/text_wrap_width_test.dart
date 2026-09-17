import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/text/text_drawable_extensions.dart';
import 'package:open_board/src/module/text/text_painter.dart';

import '../helpers/protobuf_factories.dart';

/// 텍스트박스 소프트 줄바꿈 보존 (kobic unibook#12538/#12548 — UB-627/UB-632).
///
/// 인라인 에디터가 커밋 시점의 줄바꿈 폭을 `TextDrawable.maxWidth` 에 기록하고,
/// 정적 렌더링·히트테스트가 그 폭으로 레이아웃해야 편집 중 보이던 줄바꿈이
/// 확정 후에도 유지된다. 검증 축:
///  1. `layoutMaxWidth` — 미기록(0) 은 무제한(레거시 호환), 기록값은 그대로
///  2. `getTextBounds` — maxWidth 가 있으면 소프트 줄바꿈으로 여러 줄이 된다
///  3. 하드 `\n` 은 maxWidth 와 무관하게 줄바꿈된다 (UB-632 의 엔터 축)
///  4. `copyWithMaxWidth` 는 다른 필드를 보존한다
void main() {
  group('TextDrawable.layoutMaxWidth', () {
    test('maxWidth 미기록(0)이면 무제한 폭(레거시 데이터 호환)', () {
      final drawable = createTextDrawable();
      expect(drawable.maxWidth, 0);
      expect(drawable.layoutMaxWidth, double.infinity);
    });

    test('maxWidth 기록 시 그 값을 레이아웃 폭으로 쓴다', () {
      final drawable = createTextDrawable().copyWithMaxWidth(120);
      expect(drawable.layoutMaxWidth, 120);
    });

    test('copyWithMaxWidth 는 다른 필드를 보존한다', () {
      final base = createTextDrawable(
        text: '보존 확인',
        x: 33,
        y: 44,
        fontSize: 24,
        textAlign: 'center',
      );
      final copied = base.copyWithMaxWidth(200);
      expect(copied.maxWidth, 200);
      expect(copied.text, base.text);
      expect(copied.x, base.x);
      expect(copied.y, base.y);
      expect(copied.fontSize, base.fontSize);
      expect(copied.textAlign, base.textAlign);
    });
  });

  group('TextDrawablePainter.getTextBounds 소프트 줄바꿈', () {
    // 테스트 환경 폰트(Ahem)는 글자 하나가 fontSize 정사각형이라
    // 레이아웃 수치가 결정적이다: 'a' 20자 × 16px = 무제한 폭 320px.
    test('maxWidth 미기록이면 종전대로 한 줄로 펴진다', () {
      final drawable = createTextDrawable(text: 'a' * 20, fontSize: 16);
      final bounds = TextDrawablePainter.getTextBounds(drawable);
      expect(bounds.width, closeTo(320, 1));
    });

    test('maxWidth 기록 시 그 폭에서 줄바꿈되어 여러 줄 높이가 된다', () {
      final base = createTextDrawable(text: 'a' * 20, fontSize: 16);
      final legacy = TextDrawablePainter.getTextBounds(base);
      final wrapped =
          TextDrawablePainter.getTextBounds(base.copyWithMaxWidth(100));

      // 랜드마크 2개 — 폭은 기록값 이하, 높이는 여러 줄(6자/줄 → 4줄).
      expect(wrapped.width, lessThanOrEqualTo(100));
      expect(wrapped.height, closeTo(legacy.height * 4, 1));
      // 무제한 레이아웃과 달라졌다는 직접 증거 (동등 변이 방지).
      expect(wrapped.width, isNot(closeTo(legacy.width, 1)));
    });

    test('하드 개행(\\n)은 maxWidth 미기록이어도 줄바꿈된다 (UB-632 엔터 축)', () {
      final single =
          TextDrawablePainter.getTextBounds(createTextDrawable(text: 'aaa'));
      final multi = TextDrawablePainter.getTextBounds(
        createTextDrawable(text: 'aaa\nbbb'),
      );
      expect(multi.height, closeTo(single.height * 2, 0.5));
      expect(multi.width, closeTo(single.width, 0.5));
    });
  });
}
