import 'package:open_board/src/module/events/scribble_book_event.dart';

export 'package:open_board/src/module/events/scribble_book_event.dart'
    show ParticipantRole, ParticipantAction;

/// 원격 참가자 정보
class RemoteParticipant {
  final String participantId;
  final String displayName;
  final ParticipantRole role;

  const RemoteParticipant({
    required this.participantId,
    required this.displayName,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteParticipant &&
          runtimeType == other.runtimeType &&
          participantId == other.participantId;

  @override
  int get hashCode => participantId.hashCode;

  @override
  String toString() =>
      'RemoteParticipant($participantId, $displayName, ${role.name})';
}

/// 참가자 변경 이벤트
class ParticipantEvent {
  final RemoteParticipant participant;
  final ParticipantAction action;
  final int timestampMicros;

  const ParticipantEvent({
    required this.participant,
    required this.action,
    required this.timestampMicros,
  });

  @override
  String toString() =>
      'ParticipantEvent(${participant.participantId}, ${action.name})';
}
