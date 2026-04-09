import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'timeline_models.dart';

/// ScribbleTimeline의 바이너리 직렬화/역직렬화
///
/// JSON 기반 직렬화를 사용한다.
/// 향후 protoc 코드 생성이 가능해지면 Protobuf 바이너리로 전환 가능.
class TimelineSerializer {
  const TimelineSerializer._();

  static Uint8List serialize(ScribbleTimeline timeline) {
    final map = _timelineToMap(timeline);
    final jsonStr = jsonEncode(map);
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  static ScribbleTimeline deserialize(Uint8List bytes) {
    final jsonStr = utf8.decode(bytes);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _mapToTimeline(map);
  }

  // ===== Timeline =====

  static Map<String, dynamic> _timelineToMap(ScribbleTimeline tl) => {
        'contentId': tl.contentId,
        'startTimestamp': tl.startTimestamp.toString(),
        'endTimestamp': tl.endTimestamp.toString(),
        'version': tl.version,
        'pageIds': tl.pageIds,
        'events': tl.events.map(_eventToMap).toList(),
        'snapshots': tl.snapshots.map(_snapshotToMap).toList(),
        'pageUpdatedAt': tl.pageUpdatedAt,
        if (tl.contentFingerprint != null)
          'contentFingerprint': _fingerprintToMap(tl.contentFingerprint!),
      };

  static ScribbleTimeline _mapToTimeline(Map<String, dynamic> m) =>
      ScribbleTimeline(
        contentId: m['contentId'] as String? ?? '',
        startTimestamp: Int64.parseInt(m['startTimestamp'] as String? ?? '0'),
        endTimestamp: Int64.parseInt(m['endTimestamp'] as String? ?? '0'),
        version: m['version'] as String? ?? '1.0.0',
        pageIds: (m['pageIds'] as List?)?.cast<String>() ?? [],
        events: (m['events'] as List?)
                ?.map((e) => _mapToEvent(e as Map<String, dynamic>))
                .toList() ??
            [],
        snapshots: (m['snapshots'] as List?)
                ?.map((s) => _mapToSnapshot(s as Map<String, dynamic>))
                .toList() ??
            [],
        pageUpdatedAt:
            (m['pageUpdatedAt'] as Map?)?.cast<String, String>() ?? {},
        contentFingerprint: m['contentFingerprint'] != null
            ? _mapToFingerprint(
                m['contentFingerprint'] as Map<String, dynamic>)
            : null,
      );

  // ===== Event =====

  static Map<String, dynamic> _eventToMap(TimelineEvent event) => {
        'timestamp': event.timestamp.toString(),
        'type': event.event._typeTag,
        'data': _eventDataToMap(event.event),
      };

  static TimelineEvent _mapToEvent(Map<String, dynamic> m) => TimelineEvent(
        timestamp: Int64.parseInt(m['timestamp'] as String? ?? '0'),
        event:
            _mapToEventData(m['type'] as String, m['data'] as Map<String, dynamic>),
      );

  static Map<String, dynamic> _eventDataToMap(TimelineEventData e) =>
      switch (e) {
        TlPageChanged e => {
            'fromIndex': e.fromIndex,
            'toIndex': e.toIndex,
            'fromPageId': e.fromPageId,
            'toPageId': e.toPageId,
          },
        TlStrokeAdded e => {
            'pageId': e.pageId,
            'strokeIndex': e.strokeIndex,
          },
        TlStrokeRemoved e => {
            'pageId': e.pageId,
            'strokeIndex': e.strokeIndex,
          },
        TlUndo e => {'pageId': e.pageId},
        TlRedo e => {'pageId': e.pageId},
        TlPageAdded e => {'pageId': e.pageId, 'atIndex': e.atIndex},
        TlPageRemoved e => {'pageId': e.pageId, 'atIndex': e.atIndex},
        TlPageCleared e => {'pageId': e.pageId},
        TlViewportChanged e => {
            'pageId': e.pageId,
            'scale': e.scale,
            'centerX': e.centerX,
            'centerY': e.centerY,
            'viewportWidth': e.viewportWidth,
            'viewportHeight': e.viewportHeight,
          },
        TlSessionParticipant e => {
            'participantId': e.participantId,
            'displayName': e.displayName,
            'role': e.role,
            'action': e.action,
          },
      };

  static TimelineEventData _mapToEventData(
    String type,
    Map<String, dynamic> d,
  ) =>
      switch (type) {
        'pageChanged' => TlPageChanged(
            fromIndex: d['fromIndex'] as int,
            toIndex: d['toIndex'] as int,
            fromPageId: d['fromPageId'] as String,
            toPageId: d['toPageId'] as String,
          ),
        'strokeAdded' => TlStrokeAdded(
            pageId: d['pageId'] as String,
            strokeIndex: d['strokeIndex'] as int,
          ),
        'strokeRemoved' => TlStrokeRemoved(
            pageId: d['pageId'] as String,
            strokeIndex: d['strokeIndex'] as int,
          ),
        'undo' => TlUndo(pageId: d['pageId'] as String),
        'redo' => TlRedo(pageId: d['pageId'] as String),
        'pageAdded' => TlPageAdded(
            pageId: d['pageId'] as String,
            atIndex: d['atIndex'] as int,
          ),
        'pageRemoved' => TlPageRemoved(
            pageId: d['pageId'] as String,
            atIndex: d['atIndex'] as int,
          ),
        'pageCleared' => TlPageCleared(pageId: d['pageId'] as String),
        'viewportChanged' => TlViewportChanged(
            pageId: d['pageId'] as String,
            scale: (d['scale'] as num).toDouble(),
            centerX: (d['centerX'] as num).toDouble(),
            centerY: (d['centerY'] as num).toDouble(),
            viewportWidth: (d['viewportWidth'] as num).toDouble(),
            viewportHeight: (d['viewportHeight'] as num).toDouble(),
          ),
        'sessionParticipant' => TlSessionParticipant(
            participantId: d['participantId'] as String,
            displayName: d['displayName'] as String,
            role: d['role'] as String,
            action: d['action'] as String,
          ),
        _ => throw FormatException('Unknown event type: $type'),
      };

  // ===== Snapshot =====

  static Map<String, dynamic> _snapshotToMap(TimelineSnapshot s) => {
        'offsetMicros': s.offsetMicros.toString(),
        'activePageIndex': s.activePageIndex,
        'pageStrokeCounts': s.pageStrokeCounts,
      };

  static TimelineSnapshot _mapToSnapshot(Map<String, dynamic> m) =>
      TimelineSnapshot(
        offsetMicros: Int64.parseInt(m['offsetMicros'] as String? ?? '0'),
        activePageIndex: m['activePageIndex'] as int? ?? 0,
        pageStrokeCounts:
            (m['pageStrokeCounts'] as Map?)?.cast<String, int>() ?? {},
      );

  // ===== Fingerprint =====

  static Map<String, dynamic> _fingerprintToMap(ContentFingerprint f) => {
        'hash': f.hash,
        'algorithm': f.algorithm,
        'metadata': f.metadata,
      };

  static ContentFingerprint _mapToFingerprint(Map<String, dynamic> m) =>
      ContentFingerprint(
        hash: m['hash'] as String? ?? '',
        algorithm: m['algorithm'] as String? ?? 'sha256',
        metadata: (m['metadata'] as Map?)?.cast<String, String>() ?? {},
      );
}

/// TimelineEventData의 타입 태그
extension on TimelineEventData {
  String get _typeTag => switch (this) {
        TlPageChanged() => 'pageChanged',
        TlStrokeAdded() => 'strokeAdded',
        TlStrokeRemoved() => 'strokeRemoved',
        TlUndo() => 'undo',
        TlRedo() => 'redo',
        TlPageAdded() => 'pageAdded',
        TlPageRemoved() => 'pageRemoved',
        TlPageCleared() => 'pageCleared',
        TlViewportChanged() => 'viewportChanged',
        TlSessionParticipant() => 'sessionParticipant',
      };
}
