import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_enum.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_offset.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_rect.dart';
import 'package:open_board/src/core/utils/extensions/paint_extension/ex_radius.dart';

void main() {
  group('ex_color', () {
    group('stringToColor', () {
      test('Color 문자열 파싱', () {
        final color = stringToColor('Color(0xff000000)');
        expect(color, isNotNull);
        expect(colorToInt(color!), 0xff000000);
      });

      test('ColorSwatch 문자열 파싱', () {
        final color = stringToColor(
          'ColorSwatch(primary value: Color(0xffff0000))',
        );
        expect(color, isNotNull);
      });

      test('잘못된 문자열은 null', () {
        expect(stringToColor('invalid'), isNull);
        expect(stringToColor(''), isNull);
      });
    });

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

  group('ex_enum', () {
    group('ExEnum.tryParse', () {
      test('null 입력은 null 반환', () {
        expect(ExEnum.tryParse(BlendMode.values, null), isNull);
      });

      test('잘못된 타입이면 예외', () {
        expect(
          () => ExEnum.tryParse(BlendMode.values, 'wrong.value'),
          throwsA(isA<Exception>()),
        );
      });

      test('유효한 enum 파싱', () {
        final result = ExEnum.tryParse(
          BlendMode.values,
          'BlendMode.srcOver',
        );
        expect(result, BlendMode.srcOver);
      });
    });
  });

  group('ex_offset', () {
    test('toJson / jsonToOffset 왕복', () {
      const offset = Offset(3.5, -7.2);
      final json = offset.toJson();
      final restored = jsonToOffset(json);
      expect(restored.dx, 3.5);
      expect(restored.dy, -7.2);
    });

    test('영점', () {
      final json = Offset.zero.toJson();
      final restored = jsonToOffset(json);
      expect(restored, Offset.zero);
    });
  });

  group('ex_rect', () {
    test('toJson / jsonToRect 왕복', () {
      const rect = Rect.fromLTRB(1, 2, 3, 4);
      final json = rect.toJson();
      final restored = jsonToRect(json);
      expect(restored, rect);
    });

    test('Rect.zero', () {
      final json = Rect.zero.toJson();
      final restored = jsonToRect(json);
      expect(restored, Rect.zero);
    });
  });

  group('ex_radius', () {
    test('toJson / jsonToRadius 왕복', () {
      const radius = Radius.elliptical(5, 10);
      final json = radius.toJson();
      final restored = jsonToRadius(json);
      expect(restored.x, 5);
      expect(restored.y, 10);
    });

    test('Radius.zero', () {
      final json = Radius.zero.toJson();
      final restored = jsonToRadius(json);
      expect(restored, Radius.zero);
    });
  });
}
