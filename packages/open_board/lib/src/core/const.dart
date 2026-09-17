import 'dart:ui';

import 'package:open_board/src/core/utils/extensions/paint_extension/ex_color.dart';

const maxScale = 3.0;

/// 마커 색상에 투명도를 적용하는 함수
///
/// - 만약 마커 색상인데도 불구하고 투명도가 적용 안 되어 있으면 투명도를 50% 먹인다
int applyTransparencyToMarkerColorValue(int strokeColor) {
  final isNonAlphaColors = [
    0xFFDAD9FF,
    0xFFFFD9EC,
    0xFFFAF4C0,
    0xFFE4F7BA,
    0xFFD4F4FA,
  ].contains(strokeColor);
  if (isNonAlphaColors) {
    return colorToInt(Color(strokeColor).withValues(alpha: 0.5));
  }
  return strokeColor;
}
