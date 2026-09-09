import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/text_settings.dart';
import 'package:open_board/src/module/text/inline_text_editor.dart';
import 'package:open_board/src/module/text/text_drawable_factory.dart';

/// UB-695 / unibook#13507 — 입력 중 마지막 글자가 에디터 폭에 잘리는 회귀 가드.
void main() {
  group('computeInlineEditorWidth', () {
    test('짧은 단어에서도 텍스트 필드 안쪽이 잉크폭+캐럿을 남긴다', () {
      const textWidth = 30.0;
      const fontSize = 20.0;
      const doneButtonWidth = 44.0;
      const cursorWidth = 2.0;
      const contentPadding = 8.0;

      final editorWidth = computeInlineEditorWidth(
        textWidth: textWidth,
        fontSize: fontSize,
        doneButtonWidth: doneButtonWidth,
        cursorWidth: cursorWidth,
      );

      final fieldInnerWidth = editorWidth - doneButtonWidth - contentPadding;
      expect(fieldInnerWidth, greaterThanOrEqualTo(textWidth + cursorWidth));
    });

    test('1.05 배율보다 짧은 단어에서 더 넓다', () {
      const textWidth = 30.0;
      const doneButtonWidth = 44.0;
      final legacy = textWidth * 1.05 + 8 + doneButtonWidth + 8;
      final next = computeInlineEditorWidth(
        textWidth: textWidth,
        fontSize: 20,
        doneButtonWidth: doneButtonWidth,
      );
      expect(next, greaterThan(legacy));
    });
  });

  group('InlineTextEditor 입력 중 마지막 글자', () {
    Future<void> pumpEditor(
      WidgetTester tester, {
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: InlineTextEditor(
            drawable: drawable,
            position: const Offset(400, 300),
            textSettings: const TextSettings(),
            isNew: true,
            scale: 1,
            selectedColor: Colors.black,
            onComplete: (_) {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('test 입력 후 TextField 폭이 잉크폭+캐럿 이상이다', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      final style = field.style!;
      final painter = TextPainter(
        text: TextSpan(text: 'test', style: style),
        textDirection: .ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      addTearDown(painter.dispose);

      final fieldWidth = tester.getSize(find.byType(TextField)).width;
      // contentPadding horizontal: 4 → 안쪽 8
      expect(fieldWidth - 8, greaterThanOrEqualTo(painter.width + 2));
    });

    testWidgets('textScaler 1.3 에서도 마지막 글자 폭을 수용한다', (tester) async {
      const scaler = TextScaler.linear(1.3);
      await pumpEditor(tester, textScaler: scaler);
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      final style = field.style!;
      final painter = TextPainter(
        text: TextSpan(text: 'test', style: style),
        textDirection: .ltr,
        textScaler: scaler,
      )..layout();
      addTearDown(painter.dispose);

      final fieldWidth = tester.getSize(find.byType(TextField)).width;
      expect(fieldWidth - 8, greaterThanOrEqualTo(painter.width + 2));
    });
  });
}
