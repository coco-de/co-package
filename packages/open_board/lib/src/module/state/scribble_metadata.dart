import 'package:open_board/open_board.dart';

/// 🔄 동기화 소스 구분
enum ScribbleSyncSource {
  local, // 로컬에서 생성/수정
  server, // 서버에서 다운로드
  conflictResolved, // 충돌 해결됨
  merged, // 병합됨
}

/// ⚔️ 충돌 해결 방식
enum ConflictResolution {
  none, // 충돌 없음
  localWins, // 로컬 버전 우선
  serverWins, // 서버 버전 우선
  merged, // 두 버전 병합
  manual, // 수동 해결 필요
}

/// 📊 필기 메타데이터 (동기화 최적화용)
class ScribbleMetadata {
  const ScribbleMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.hash,
    this.strokeCount = 0,
    this.lastSyncTime,
    this.syncSource = ScribbleSyncSource.local,
    this.conflictResolution = ConflictResolution.none,
  });

  /// 생성 시간 (ISO 8601 format)
  final String createdAt;

  /// 최종 수정 시간 (ISO 8601 format)
  final String updatedAt;

  /// 버전 정보 (UUID v4 or timestamp-based)
  final String version;

  /// 데이터 해시 (변경 감지용, Simple Hash)
  final String hash;

  /// 스트로크 개수 (빠른 비교용)
  final int strokeCount;

  /// 마지막 동기화 시간
  final DateTime? lastSyncTime;

  /// 동기화 소스 (로컬, 서버, 충돌 해결됨)
  final ScribbleSyncSource syncSource;

  /// 충돌 해결 상태
  final ConflictResolution conflictResolution;

  /// 📊 서버 데이터와 비교하여 동기화 필요 여부 확인
  bool needsSync(ScribbleMetadata? serverMetadata) {
    if (serverMetadata == null) return true; // 서버에 없으면 업로드 필요

    // 해시가 다르면 동기화 필요
    if (hash != serverMetadata.hash) return true;

    // 최종 수정 시간이 다르면 동기화 필요
    final localUpdated = DateTime.tryParse(updatedAt);
    final serverUpdated = DateTime.tryParse(serverMetadata.updatedAt);

    if (localUpdated != null && serverUpdated != null) {
      return localUpdated.isAfter(serverUpdated);
    }

    return false;
  }

  /// 📈 충돌 해결: 최신 버전 우선
  static ScribbleMetadata resolveConflict(
    ScribbleMetadata local,
    ScribbleMetadata server,
  ) {
    final localUpdated = DateTime.tryParse(local.updatedAt);
    final serverUpdated = DateTime.tryParse(server.updatedAt);

    // 시간 비교로 최신 버전 선택
    if (localUpdated != null && serverUpdated != null) {
      if (localUpdated.isAfter(serverUpdated)) {
        return local.copyWith(
          conflictResolution: ConflictResolution.localWins,
          syncSource: ScribbleSyncSource.conflictResolved,
        );
      } else {
        return server.copyWith(
          conflictResolution: ConflictResolution.serverWins,
          syncSource: ScribbleSyncSource.conflictResolved,
        );
      }
    }

    // 시간 정보가 없으면 스트로크 수로 판단
    return local.strokeCount >= server.strokeCount ? local : server;
  }

  /// 📊 필기 데이터로부터 메타데이터 생성
  factory ScribbleMetadata.fromScribbleData(
    List<int> scribbleData, {
    String? existingCreatedAt,
    ScribbleSyncSource syncSource = ScribbleSyncSource.local,
  }) {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    // 간단한 해시 계산 (데이터 크기 + CRC32 스타일)
    final hash = _calculateSimpleHash(scribbleData);

    // 스트로크 수 추정 (데이터 크기 기반)
    final estimatedStrokeCount = (scribbleData.length / 100).round();

    return ScribbleMetadata(
      createdAt: existingCreatedAt ?? nowIso,
      updatedAt: nowIso,
      version: 'v${now.millisecondsSinceEpoch}',
      hash: hash,
      strokeCount: estimatedStrokeCount,
      lastSyncTime: now,
      syncSource: syncSource,
      conflictResolution: ConflictResolution.none,
    );
  }

  /// 📊 빈 메타데이터 생성
  factory ScribbleMetadata.empty() {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    return ScribbleMetadata(
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 'v${now.millisecondsSinceEpoch}',
      hash: '',
      strokeCount: 0,
      lastSyncTime: now,
      syncSource: ScribbleSyncSource.local,
      conflictResolution: ConflictResolution.none,
    );
  }

  /// 두 메타데이터가 다른지 비교 (해시 기반)
  bool isDifferentFrom(ScribbleMetadata other) {
    return hash != other.hash ||
        strokeCount != other.strokeCount ||
        updatedAt != other.updatedAt;
  }

  /// 📊 Scribble 객체로부터 메타데이터 생성
  factory ScribbleMetadata.fromScribble(
    Scribble? scribble, {
    ScribbleSyncSource syncSource = ScribbleSyncSource.local,
    ConflictResolution conflictResolution = ConflictResolution.none,
    DateTime? lastSyncTime,
  }) {
    final now = DateTime.now().toIso8601String();

    // Scribble 객체에서 정보 추출
    final createdAt = _extractCreatedAt(scribble) ?? now;
    final updatedAt = _extractUpdatedAt(scribble) ?? now;
    final version = _extractVersion(scribble) ?? _generateVersion();
    final strokeCount = _extractStrokeCount(scribble);

    // 해시 생성 (간단한 방식)
    final hash = _generateSimpleHash([
      createdAt,
      updatedAt,
      version,
      strokeCount.toString(),
    ]);

    return ScribbleMetadata(
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      hash: hash,
      strokeCount: strokeCount,
      lastSyncTime: lastSyncTime,
      syncSource: syncSource,
      conflictResolution: conflictResolution,
    );
  }

  /// Scribble에서 생성 시간 추출
  static String? _extractCreatedAt(Scribble? scribble) {
    try {
      // Protobuf Scribble 객체에서 createdAt 필드 확인
      if (scribble != null && scribble.hasCreatedAt()) {
        return scribble.createdAt;
      }
    } on Exception {
      // 필드가 없으면 null 반환
    }
    return null;
  }

  /// Scribble에서 수정 시간 추출
  static String? _extractUpdatedAt(Scribble? scribble) {
    try {
      // Protobuf Scribble 객체에서 updatedAt 필드 확인
      if (scribble != null && scribble.hasUpdatedAt()) {
        return scribble.updatedAt;
      }
    } on Exception {
      // 필드가 없으면 null 반환
    }
    return null;
  }

  /// Scribble에서 버전 정보 추출
  static String? _extractVersion(Scribble? scribble) {
    try {
      // Protobuf Scribble 객체에서 version 필드 확인
      if (scribble != null && scribble.hasVersion()) {
        return scribble.version;
      }
    } on Exception {
      // 필드가 없으면 null 반환
    }
    return null;
  }

  /// Scribble에서 스트로크 개수 추출
  static int _extractStrokeCount(Scribble? scribble) {
    try {
      // Protobuf Scribble 객체에서 strokes 필드 확인
      if (scribble != null && scribble.strokes != null) {
        return scribble.strokes.length as int;
      }
    } on Exception {
      // 오류 시 0 반환
    }
    return 0;
  }

  /// 버전 생성 (UUID 대신 타임스탬프 기반)
  static String _generateVersion() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 간단한 해시 계산 (crypto 의존성 없이)
  static String _calculateSimpleHash(List<int> data) {
    if (data.isEmpty) return '0';

    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash) + data[i];
      hash = hash & 0xFFFFFFFF; // 32비트로 제한
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// String 리스트로부터 간단한 해시 생성
  static String _generateSimpleHash(List<String> stringList) {
    if (stringList.isEmpty) return '0';

    // String들을 연결한 후 각 문자의 UTF-16 코드 유닛으로 변환
    final combinedString = stringList.join('|'); // 구분자로 | 사용
    final codeUnits = <int>[];

    for (int i = 0; i < combinedString.length; i++) {
      codeUnits.add(combinedString.codeUnitAt(i));
    }

    // 기존 _calculateSimpleHash 함수 활용
    return _calculateSimpleHash(codeUnits);
  }

  ScribbleMetadata copyWith({
    String? createdAt,
    String? updatedAt,
    String? version,
    String? hash,
    int? strokeCount,
    DateTime? lastSyncTime,
    ScribbleSyncSource? syncSource,
    ConflictResolution? conflictResolution,
  }) {
    return ScribbleMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      hash: hash ?? this.hash,
      strokeCount: strokeCount ?? this.strokeCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncSource: syncSource ?? this.syncSource,
      conflictResolution: conflictResolution ?? this.conflictResolution,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
      'hash': hash,
      'strokeCount': strokeCount,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'syncSource': syncSource.name,
      'conflictResolution': conflictResolution.name,
    };
  }

  factory ScribbleMetadata.fromJson(Map<String, dynamic> json) {
    return ScribbleMetadata(
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      version: json['version'] as String,
      hash: json['hash'] as String,
      strokeCount: json['strokeCount'] as int? ?? 0,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.tryParse(json['lastSyncTime'] as String)
          : null,
      syncSource: ScribbleSyncSource.values.firstWhere(
        (source) => source.name == json['syncSource'],
        orElse: () => ScribbleSyncSource.local,
      ),
      conflictResolution: ConflictResolution.values.firstWhere(
        (resolution) => resolution.name == json['conflictResolution'],
        orElse: () => ConflictResolution.none,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScribbleMetadata &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.version == version &&
        other.hash == hash &&
        other.strokeCount == strokeCount &&
        other.lastSyncTime == lastSyncTime &&
        other.syncSource == syncSource &&
        other.conflictResolution == conflictResolution;
  }

  @override
  int get hashCode {
    return Object.hash(
      createdAt,
      updatedAt,
      version,
      hash,
      strokeCount,
      lastSyncTime,
      syncSource,
      conflictResolution,
    );
  }

  @override
  String toString() =>
      'ScribbleMetadata('
      'version: $version, '
      'strokeCount: $strokeCount, '
      'syncSource: $syncSource, '
      'conflictResolution: $conflictResolution'
      ')';
}
