import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/state/text_settings.dart';

void main() {
  group('TextAlignment', () {
    test('value 문자열 변환', () {
      expect(TextAlignment.left.value, 'left');
      expect(TextAlignment.center.value, 'center');
      expect(TextAlignment.right.value, 'right');
    });

    test('textAlign 변환', () {
      expect(TextAlignment.left.textAlign, TextAlign.left);
      expect(TextAlignment.center.textAlign, TextAlign.center);
      expect(TextAlignment.right.textAlign, TextAlign.right);
    });

    test('fromString 변환', () {
      expect(TextAlignmentExtension.fromString('left'), TextAlignment.left);
      expect(
        TextAlignmentExtension.fromString('center'),
        TextAlignment.center,
      );
      expect(TextAlignmentExtension.fromString('right'), TextAlignment.right);
    });

    test('fromString 잘못된 값은 center', () {
      expect(
        TextAlignmentExtension.fromString('unknown'),
        TextAlignment.center,
      );
    });
  });

  group('TextSettings', () {
    test('기본값', () {
      const settings = TextSettings();
      expect(settings.textStyle.fontSize, 16);
      expect(settings.textStyle.color, Colors.black);
      expect(settings.textAlignment, TextAlignment.center);
      expect(settings.focusNode, isNull);
    });

    test('copyWith', () {
      const settings = TextSettings();
      final copied = settings.copyWith(
        textAlignment: TextAlignment.right,
      );
      expect(copied.textAlignment, TextAlignment.right);
      expect(copied.textStyle.fontSize, 16); // 변경 안 된 필드 유지
    });

    test('동등성 비교', () {
      const a = TextSettings();
      const b = TextSettings();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('다른 설정은 불일치', () {
      const a = TextSettings();
      final b = a.copyWith(textAlignment: TextAlignment.right);
      expect(a, isNot(equals(b)));
    });
  });
}
