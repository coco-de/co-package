import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// ScribbleBookController에서 발생하는 모든 이벤트
///
/// 리플레이 타임라인 기록 및 외부 동기화에 사용됩니다.
/// 모든 이벤트에 마이크로초 타임스탬프가 포함됩니다.
sealed class ScribbleBookEvent {
  /// 이벤트 발생 시각 (마이크로초)
  final int timestampMicros;

  const ScribbleBookEvent({required this.timestampMicros});

  /// 현재 시각으로 타임스탬프 생성
  static int now() => DateTime.now().microsecondsSinceEpoch;
}

/// 페이지 전환 이벤트
class PageChangedEvent extends ScribbleBookEvent {
  final int fromIndex;
  final int toIndex;
  final String fromPageId;
  final String toPageId;

  const PageChangedEvent({
    required this.fromIndex,
    required this.toIndex,
    required this.fromPageId,
    required this.toPageId,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'PageChangedEvent($fromIndex→$toIndex, t=$timestampMicros)';
}

/// 스트로크 추가 이벤트
class StrokeAddedEvent extends ScribbleBookEvent {
  final String pageId;
  final Stroke stroke;
  final int strokeIndex;

  const StrokeAddedEvent({
    required this.pageId,
    required this.stroke,
    required this.strokeIndex,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'StrokeAddedEvent(page=$pageId, idx=$strokeIndex, t=$timestampMicros)';
}

/// 스트로크 삭제 이벤트
class StrokeRemovedEvent extends ScribbleBookEvent {
  final String pageId;
  final int strokeIndex;

  const StrokeRemovedEvent({
    required this.pageId,
    required this.strokeIndex,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'StrokeRemovedEvent(page=$pageId, idx=$strokeIndex, t=$timestampMicros)';
}

/// Undo 이벤트
class UndoPerformedEvent extends ScribbleBookEvent {
  final String pageId;

  const UndoPerformedEvent({
    required this.pageId,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'UndoPerformedEvent(page=$pageId, t=$timestampMicros)';
}

/// Redo 이벤트
class RedoPerformedEvent extends ScribbleBookEvent {
  final String pageId;

  const RedoPerformedEvent({
    required this.pageId,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'RedoPerformedEvent(page=$pageId, t=$timestampMicros)';
}

/// 페이지 추가 이벤트
class PageAddedEvent extends ScribbleBookEvent {
  final String pageId;
  final int atIndex;

  const PageAddedEvent({
    required this.pageId,
    required this.atIndex,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'PageAddedEvent(page=$pageId, at=$atIndex, t=$timestampMicros)';
}

/// 페이지 삭제 이벤트
class PageRemovedEvent extends ScribbleBookEvent {
  final String pageId;
  final int atIndex;

  const PageRemovedEvent({
    required this.pageId,
    required this.atIndex,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'PageRemovedEvent(page=$pageId, at=$atIndex, t=$timestampMicros)';
}

/// 양면 모드 토글 이벤트
class DoublePageToggledEvent extends ScribbleBookEvent {
  final bool enabled;

  const DoublePageToggledEvent({
    required this.enabled,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'DoublePageToggledEvent(enabled=$enabled, t=$timestampMicros)';
}

/// 필기 전체 지우기 이벤트
class PageClearedEvent extends ScribbleBookEvent {
  final String pageId;

  const PageClearedEvent({
    required this.pageId,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'PageClearedEvent(page=$pageId, t=$timestampMicros)';
}

/// 뷰포트(줌/팬) 변경 이벤트
class ViewportChangedEvent extends ScribbleBookEvent {
  final String pageId;
  final double scale;
  final double centerX;
  final double centerY;
  final double viewportWidth;
  final double viewportHeight;

  const ViewportChangedEvent({
    required this.pageId,
    required this.scale,
    required this.centerX,
    required this.centerY,
    required this.viewportWidth,
    required this.viewportHeight,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'ViewportChangedEvent(page=$pageId, scale=$scale, '
      'center=($centerX,$centerY), t=$timestampMicros)';
}

/// 세션 참가자 이벤트 (타임라인 기록용)
class SessionParticipantEvent extends ScribbleBookEvent {
  final String participantId;
  final String displayName;
  final ParticipantRole role;
  final ParticipantAction action;

  const SessionParticipantEvent({
    required this.participantId,
    required this.displayName,
    required this.role,
    required this.action,
    required super.timestampMicros,
  });

  @override
  String toString() =>
      'SessionParticipantEvent(${participantId}, ${action.name}, '
      't=$timestampMicros)';
}

/// 참가자 역할
enum ParticipantRole { teacher, student }

/// 참가자 액션
enum ParticipantAction { joined, left }
