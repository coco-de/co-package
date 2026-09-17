import 'dart:ui';

/// 개별 렌더링 단위를 나타내는 인터페이스
abstract class PaintDelegate {
  void paint(Canvas canvas, Size size);
}
