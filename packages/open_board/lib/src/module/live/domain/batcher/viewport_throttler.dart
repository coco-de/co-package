import 'dart:async';

import 'package:open_board/src/module/live/domain/model/transport_message.dart';

/// 뷰포트 변경을 100ms 간격으로 쓰로틀링하는 유틸리티
///
/// pinch-zoom/pan 제스처 중 초당 60~120회 뷰포트 변경이 발생할 수 있다.
/// 중간값은 불필요하므로 100ms 윈도우 내 최신 값만 전송한다 (last-write-wins).
class ViewportThrottler {
  /// 쓰로틀 윈도우 (밀리초)
  static const throttleMs = 100;

  final void Function(ViewportMessage message) _onThrottled;

  Timer? _timer;
  ViewportMessage? _pending;

  ViewportThrottler(
      {required void Function(ViewportMessage message) onThrottled})
      : _onThrottled = onThrottled;

  /// 뷰포트 변경을 등록한다. 윈도우 내 최신 값만 전송.
  void onViewportChanged(ViewportMessage message) {
    _pending = message;

    _timer ??= Timer(
      const Duration(milliseconds: throttleMs),
      _flush,
    );
  }

  void _flush() {
    _timer = null;
    if (_pending == null) return;

    final message = _pending!;
    _pending = null;

    _onThrottled(message);
  }

  /// 리소스 해제
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
