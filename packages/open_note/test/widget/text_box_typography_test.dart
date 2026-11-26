import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/open_note.dart';
import 'package:open_note/src/module/state/text_settings.dart';
import 'package:open_note/src/module/text/inline_text_editor.dart';
import 'package:open_note/src/module/text/text_span_builder.dart';

void main() {
  const typography = (
    regular: FontWeight.w300,
    bold: FontWeight.w600,
    fontFamily: 'ExampleFont',
  );
  const cases = [
    (name: 'new regular', isNew: true, isBold: false, weight: FontWeight.w300),
    (
      name: 'saved regular',
      isNew: false,
      isBold: false,
      weight: FontWeight.w300,
    ),
    (name: 'saved bold', isNew: false, isBold: true, weight: FontWeight.w600),
  ];

  for (final item in cases) {
    testWidgets('uses display weight and preserves ${item.name} formatting', (
      tester,
    ) async {
      final drawable = TextDrawable(
        id: 'box',
        text: item.isNew ? '' : 'Example text',
        fontSize: 24,
        color: Colors.black.toARGB32(),
        isBold: item.isBold,
        textAlign: 'left',
      );
      final completions = <TextDrawable?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: InlineTextEditor(
            drawable: drawable,
            position: const Offset(400, 300),
            textSettings: const TextSettings(
              textStyle: TextStyle(fontSize: 24),
            ),
            selectedColor: Colors.black,
            isNew: item.isNew,
            scale: 1,
            textBoxTypography: typography,
            onComplete: completions.add,
          ),
        ),
      );
      await tester.pump();

      final field = find.byType(TextField);
      final style = tester.widget<TextField>(field).style!;
      expect(style.fontWeight, item.weight);
      expect(style.fontFamily, typography.fontFamily);

      await tester.enterText(field, 'Updated example text');
      await tester.tapAt(const Offset(5, 590));
      await tester.pumpAndSettle();

      final saved = completions.single!;
      expect(saved.isBold, item.isBold);
      expect(saved.fontSize, 24);
      expect(
        buildLinkAwareTextSpan(saved).style!.fontWeight,
        item.isBold ? FontWeight.bold : FontWeight.normal,
      );
      expect(
        buildLinkAwareTextSpan(
          saved,
          textBoxTypography: typography,
        ).style!.fontWeight,
        item.weight,
      );
    });
  }

  test('keeps an explicitly stored font family', () {
    final drawable = TextDrawable(text: 'example', fontFamily: 'StoredFont');
    final span = buildLinkAwareTextSpan(
      drawable,
      textBoxTypography: typography,
    );
    expect(span.style!.fontFamily, 'StoredFont');
  });

  test('applies configured weight to hyperlink runs', () {
    final drawable = TextDrawable(
      text: 'link',
      isBold: true,
      linkSpans: [TextLinkSpan(start: 0, end: 4, url: 'page:3')],
    );

    final span = buildLinkAwareTextSpan(
      drawable,
      textBoxTypography: typography,
    );
    final link = span.children!.single as TextSpan;
    expect(link.style!.fontWeight, FontWeight.w600);
    expect(link.style!.fontFamily, typography.fontFamily);
    expect(link.style!.decoration, TextDecoration.underline);
  });
}
