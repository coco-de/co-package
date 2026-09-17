import 'package:flutter/widgets.dart';

import 'package:open_board/src/module/live/domain/transport/live_session_transport.dart';
import 'package:open_board/src/module/live/presentation/live_session_controller.dart';

/// InheritedWidget 기반 DI 스코프
///
/// live session 관련 의존성을 위젯 트리에 제공한다.
/// 소비자 앱에서 Transport 구현체를 주입할 때 사용한다.
///
/// ```dart
/// LiveSessionScope(
///   controller: liveSessionController,
///   transport: liveKitTransport,
///   child: MyScribbleWidget(),
/// )
/// ```
class LiveSessionScope extends InheritedWidget {
  final LiveSessionController controller;
  final LiveSessionTransport transport;

  const LiveSessionScope({
    required this.controller,
    required this.transport,
    required super.child,
    super.key,
  });

  /// 가장 가까운 [LiveSessionScope]를 찾는다.
  static LiveSessionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiveSessionScope>();
  }

  /// 가장 가까운 [LiveSessionScope]를 찾는다. 없으면 예외.
  static LiveSessionScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'LiveSessionScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(LiveSessionScope oldWidget) =>
      controller != oldWidget.controller || transport != oldWidget.transport;
}
