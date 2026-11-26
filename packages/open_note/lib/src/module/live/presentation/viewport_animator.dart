import 'package:flutter/animation.dart';

/// 뷰포트 변경 시 부드러운 전환 애니메이션을 제공하는 유틸리티
///
/// 뷰포트가 급격하게 변할 때 (페이지 전환 직후 등)
/// 200ms AnimationController로 부드럽게 전환한다.
class ViewportAnimator {
  final TickerProvider _tickerProvider;

  late final AnimationController _controller;
  Offset _fromCenter = Offset.zero;
  Offset _toCenter = Offset.zero;
  double _fromScale = 1.0;
  double _toScale = 1.0;

  /// 현재 보간된 중심점
  Offset get currentCenter => Offset.lerp(
        _fromCenter,
        _toCenter,
        _controller.value,
      )!;

  /// 현재 보간된 배율
  double get currentScale =>
      _fromScale + (_toScale - _fromScale) * _controller.value;

  /// 애니메이션 진행 중 여부
  bool get isAnimating => _controller.isAnimating;

  /// 애니메이션 값 변경 리스너 등록
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  /// 애니메이션 값 변경 리스너 제거
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  ViewportAnimator({required TickerProvider tickerProvider})
      : _tickerProvider = tickerProvider {
    _controller = AnimationController(
      vsync: _tickerProvider,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// 뷰포트를 지정 위치로 애니메이션 전환
  void animateTo({
    required Offset center,
    required double scale,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    _fromCenter = currentCenter;
    _fromScale = currentScale;
    _toCenter = center;
    _toScale = scale;

    _controller.duration = duration;
    _controller.forward(from: 0);
  }

  /// 애니메이션 없이 즉시 이동
  void jumpTo({required Offset center, required double scale}) {
    _controller.stop();
    _fromCenter = center;
    _toCenter = center;
    _fromScale = scale;
    _toScale = scale;
  }

  void dispose() {
    _controller.dispose();
  }
}
