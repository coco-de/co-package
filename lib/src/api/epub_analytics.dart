// Public API — open_epub 1.0
// Story: S1.23 (#39) — Analytics Exposure API (lifecycle/progress/toolUse)
// BDD: F11 (lifecycle/progress/toolUse streams)
// RFC-4: Analytics Exposure API

import 'epub_position.dart';

/// open_epub이 외부에 노출하는 3개 stream.
/// kobic 등 외부 앱이 listen하여 자체 분석 서비스로 변환.
abstract class EpubBookSessionAnalytics {
  Stream<EpubLifecycleEvent> get lifecycleEvents;
  Stream<EpubProgressEvent> get progressEvents; // throttle 30s
  Stream<EpubToolUseEvent> get toolUseEvents;
}

sealed class EpubLifecycleEvent {
  const EpubLifecycleEvent();
}

class EpubSessionStarted extends EpubLifecycleEvent {
  const EpubSessionStarted({required this.epubVersion});
  final String epubVersion;
}

class EpubSessionEnded extends EpubLifecycleEvent {
  const EpubSessionEnded({required this.sessionElapsed});
  final Duration sessionElapsed;
}

class EpubProgressEvent {
  const EpubProgressEvent({
    required this.progress,
    required this.sessionElapsed,
  });

  final double progress;
  final Duration sessionElapsed;
}

sealed class EpubToolUseEvent {
  const EpubToolUseEvent();
  Map<String, dynamic> toAnalyticsMap();
}

/// 하이라이트 도구 사용. [position]에서 발생.
class EpubHighlightToolUse extends EpubToolUseEvent {
  const EpubHighlightToolUse({required this.position});
  final EpubPosition position;
  @override
  Map<String, dynamic> toAnalyticsMap() => {
        'tool': 'highlight',
        'spineHref': position.spineHref,
        'progress': position.progress,
      };
}

/// 북마크 도구 사용. [position]에서 발생.
class EpubBookmarkToolUse extends EpubToolUseEvent {
  const EpubBookmarkToolUse({required this.position});
  final EpubPosition position;
  @override
  Map<String, dynamic> toAnalyticsMap() => {
        'tool': 'bookmark',
        'spineHref': position.spineHref,
        'progress': position.progress,
      };
}
