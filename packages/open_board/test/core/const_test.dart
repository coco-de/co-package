import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/const.dart';

void main() {
  group('const.dart', () {
    test('maxScale 상수', () {
      expect(maxScale, 3.0);
    });

    group('applyTransparencyToMarkerColorValue', () {
      test('대상 색상에 투명도 적용', () {
        const targetColors = [
          0xFFDAD9FF,
          0xFFFFD9EC,
          0xFFFAF4C0,
          0xFFE4F7BA,
          0xFFD4F4FA,
        ];

        for (final color in targetColors) {
          final result = applyTransparencyToMarkerColorValue(color);
          // 투명도가 적용되면 alpha 채널이 변경됨
          expect(result, isNot(color),
              reason: '0x${color.toRadixString(16)}에 투명도가 적용되어야 함');
        }
      });

      test('비대상 색상은 그대로 통과', () {
        const nonTargetColor = 0xFF000000; // 검정색
        expect(applyTransparencyToMarkerColorValue(nonTargetColor), nonTargetColor);
      });

      test('이미 투명한 색상도 비대상이면 통과', () {
        const transparentColor = 0x80FF0000;
        expect(applyTransparencyToMarkerColorValue(transparentColor), transparentColor);
      });
    });
  });
}
