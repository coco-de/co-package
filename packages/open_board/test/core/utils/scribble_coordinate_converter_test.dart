import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/scribble_coordinate_converter.dart';

void main() {
  group('ScribbleCoordinateConverter', () {
    late ScribbleCoordinateConverter converter;

    setUp(() {
      converter = const ScribbleCoordinateConverter(
        pdfOriginalSize: Size(595, 842), // A4
        pdfDisplayRect: Rect.fromLTWH(0, 0, 375, 530),
        scribbleCanvasSize: Size(375, 530),
      );
    });

    test('기본 생성자 값 확인', () {
      expect(converter.scaleFactor, 1.0);
      expect(converter.scrollOffset, Offset.zero);
      expect(converter.rotationAngle, 0.0);
      expect(converter.isDoublePage, false);
    });

    test('PDF 원본 크기 보존', () {
      expect(converter.pdfOriginalSize.width, 595);
      expect(converter.pdfOriginalSize.height, 842);
    });

    test('양면 모드 설정', () {
      final doublePageConverter = ScribbleCoordinateConverter(
        pdfOriginalSize: const Size(595, 842),
        pdfDisplayRect: const Rect.fromLTWH(0, 0, 375, 530),
        scribbleCanvasSize: const Size(375, 530),
        isDoublePage: true,
        isLeftPage: false,
      );
      expect(doublePageConverter.isDoublePage, true);
      expect(doublePageConverter.isLeftPage, false);
    });

    test('스케일 팩터 적용', () {
      final scaledConverter = ScribbleCoordinateConverter(
        pdfOriginalSize: const Size(595, 842),
        pdfDisplayRect: const Rect.fromLTWH(0, 0, 375, 530),
        scribbleCanvasSize: const Size(375, 530),
        scaleFactor: 2.0,
      );
      expect(scaledConverter.scaleFactor, 2.0);
    });
  });
}
