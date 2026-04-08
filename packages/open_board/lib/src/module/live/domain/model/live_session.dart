import 'package:open_board/src/module/events/scribble_book_event.dart';

/// 세션 상태
enum SessionState {
  /// 세션 생성됨, 아직 아무도 입장하지 않음
  created,

  /// 선생님 입장, 학생 대기 중
  waiting,

  /// 양측 모두 입장, 수업 진행 중
  active,

  /// 수업 종료
  ended,
}

/// 실시간 과외 세션
class LiveSession {
  final String sessionId;
  final String contentId;
  final String roomName;
  SessionState state;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? endedAt;
  final List<SessionParticipantInfo> participants;
  final SessionConfig config;

  LiveSession({
    required this.sessionId,
    required this.contentId,
    String? roomName,
    this.state = SessionState.created,
    DateTime? createdAt,
    this.startedAt,
    this.endedAt,
    List<SessionParticipantInfo>? participants,
    SessionConfig? config,
  })  : roomName = roomName ?? sessionId,
        createdAt = createdAt ?? DateTime.now(),
        participants = participants ?? [],
        config = config ?? const SessionConfig();
}

/// 세션 참가자 정보
class SessionParticipantInfo {
  final String participantId;
  final String displayName;
  final ParticipantRole role;
  final String token;

  const SessionParticipantInfo({
    required this.participantId,
    required this.displayName,
    required this.role,
    required this.token,
  });
}

/// 세션 설정
class SessionConfig {
  final bool audioEnabled;
  final bool videoEnabled;
  final bool egressEnabled;
  final int maxParticipants;

  const SessionConfig({
    this.audioEnabled = true,
    this.videoEnabled = false,
    this.egressEnabled = true,
    this.maxParticipants = 2,
  });
}
