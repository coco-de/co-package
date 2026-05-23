// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.23.
// BDD: F11 (lifecycle/progress/toolUse streams)
// RFC-4: Analytics Exposure API

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
