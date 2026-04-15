import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

/// .obt 파일의 Protobuf payload에 대응하는 Dart 모델
///
/// 사양: res/proto/timeline.proto
/// protoc 코드 생성이 가능해지면 이 파일을 대체할 수 있다.

class ScribbleTimeline {
  String contentId;
  Int64 startTimestamp;
  Int64 endTimestamp;
  String version;
  List<String> pageIds;
  List<TimelineEvent> events;
  List<TimelineSnapshot> snapshots;
  Map<String, String> pageUpdatedAt;
  ContentFingerprint? contentFingerprint;

  ScribbleTimeline({
    this.contentId = '',
    Int64? startTimestamp,
    Int64? endTimestamp,
    this.version = '1.0.0',
    List<String>? pageIds,
    List<TimelineEvent>? events,
    List<TimelineSnapshot>? snapshots,
    Map<String, String>? pageUpdatedAt,
    this.contentFingerprint,
  }) : startTimestamp = startTimestamp ?? .ZERO,
       endTimestamp = endTimestamp ?? .ZERO,
       pageIds = pageIds ?? [],
       events = events ?? [],
       snapshots = snapshots ?? [],
       pageUpdatedAt = pageUpdatedAt ?? {};

  /// 전체 재생 시간 (마이크로초)
  int get durationMicros => (endTimestamp - startTimestamp).toInt();
}

@immutable
class TimelineEvent {
  final Int64 timestamp;
  final TimelineEventData event;

  const TimelineEvent({
    required this.timestamp,
    required this.event,
  });
}

/// 타임라인 이벤트 데이터 (sealed class)
sealed class TimelineEventData {
  const TimelineEventData();
}

class TlPageChanged extends TimelineEventData {
  final int fromIndex;
  final int toIndex;
  final String fromPageId;
  final String toPageId;

  const TlPageChanged({
    required this.fromIndex,
    required this.toIndex,
    required this.fromPageId,
    required this.toPageId,
  });
}

class TlStrokeAdded extends TimelineEventData {
  final String pageId;
  final int strokeIndex;

  const TlStrokeAdded({required this.pageId, required this.strokeIndex});
}

class TlStrokeRemoved extends TimelineEventData {
  final String pageId;
  final int strokeIndex;

  const TlStrokeRemoved({required this.pageId, required this.strokeIndex});
}

class TlUndo extends TimelineEventData {
  final String pageId;

  const TlUndo({required this.pageId});
}

class TlRedo extends TimelineEventData {
  final String pageId;

  const TlRedo({required this.pageId});
}

class TlPageAdded extends TimelineEventData {
  final String pageId;
  final int atIndex;

  const TlPageAdded({required this.pageId, required this.atIndex});
}

class TlPageRemoved extends TimelineEventData {
  final String pageId;
  final int atIndex;

  const TlPageRemoved({required this.pageId, required this.atIndex});
}

class TlPageCleared extends TimelineEventData {
  final String pageId;

  const TlPageCleared({required this.pageId});
}

class TimelineSnapshot {
  final Int64 offsetMicros;
  final int activePageIndex;
  final Map<String, int> pageStrokeCounts;

  const TimelineSnapshot({
    required this.offsetMicros,
    required this.activePageIndex,
    required this.pageStrokeCounts,
  });
}

class ContentFingerprint {
  final String hash;
  final String algorithm;
  final Map<String, String> metadata;

  const ContentFingerprint({
    required this.hash,
    this.algorithm = 'sha256',
    this.metadata = const {},
  });
}
