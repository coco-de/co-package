import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/ink_group_info.dart';

void main() {
  group('InkModes', () {
    test('상수 값 확인', () {
      expect(InkModes.pen, 'pen');
      expect(InkModes.pencil, 'pencil');
      expect(InkModes.marker, 'marker');
      expect(InkModes.erase, 'erase');
      expect(InkModes.lasso, 'lasso');
      expect(InkModes.shape, 'shape');
      expect(InkModes.text, 'text');
    });
  });

  group('InkGroupInfo', () {
    test('기본 생성자', () {
      final info = InkGroupInfo(selectedInk: InkModes.pencil);
      expect(info.selectedInk, InkModes.pencil);
      expect(info.selectedColor, isA<Color>());
      expect(info.seletedStrokeWidth, isA<double>());
    });

    test('selectedColor 반환', () {
      final info = InkGroupInfo(selectedInk: InkModes.pen);
      expect(info.selectedColor, isNotNull);
    });

    test('seletedStrokeWidth 반환', () {
      final info = InkGroupInfo(selectedInk: InkModes.pen);
      expect(info.seletedStrokeWidth, greaterThan(0));
    });

    group('copyWith', () {
      test('잉크 타입 변경', () {
        final info = InkGroupInfo(selectedInk: InkModes.pen);
        final copied = info.copyWith(selectedInk: InkModes.marker);
        expect(copied.selectedInk, InkModes.marker);
      });

      test('색상 변경', () {
        final info = InkGroupInfo(selectedInk: InkModes.pen);
        final copied = info.copyWith(inkColor: Colors.red);
        expect(copied.selectedColor, Colors.red);
      });

      test('두께 변경', () {
        final info = InkGroupInfo(selectedInk: InkModes.pen);
        final copied = info.copyWith(strokeWidth: 5.0);
        expect(copied.seletedStrokeWidth, 5.0);
      });

      test('copyWith은 새 인스턴스 반환', () {
        final info = InkGroupInfo(selectedInk: InkModes.pen);
        final copied = info.copyWith(strokeWidth: 99.0);
        // copyWith은 내부 Map을 공유하므로 원본도 변경됨 (현재 구현)
        expect(copied.seletedStrokeWidth, 99.0);
        expect(copied, isNot(same(info)));
      });
    });

    test('지우개 모드 색상', () {
      final info = InkGroupInfo(selectedInk: InkModes.erase);
      expect(info.selectedColor, isNotNull);
    });

    test('setColorBox / setStrokeBox', () {
      final info = InkGroupInfo(selectedInk: InkModes.pen);
      info.setColorBox({InkModes.pen: Colors.green});
      expect(info.selectedColor, Colors.green);

      info.setStrokeBox({InkModes.pen: 10.0});
      expect(info.seletedStrokeWidth, 10.0);
    });
  });
}
