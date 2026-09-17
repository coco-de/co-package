import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';

void main() {
  group('ex_color', () {
    group('colorToInt', () {
      test('검정색', () {
        expect(colorToInt(const Color(0xFF000000)), 0xFF000000);
      });

      test('흰색', () {
        expect(colorToInt(const Color(0xFFFFFFFF)), 0xFFFFFFFF);
      });

      test('빨간색', () {
        final result = colorToInt(const Color(0xFFFF0000));
        expect(result, 0xFFFF0000);
      });
    });
  });
}
