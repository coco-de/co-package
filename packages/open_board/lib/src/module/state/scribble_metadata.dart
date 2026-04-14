  import 'package:flutter/foundation.dart' show immutable;
  import 'package:open_board/src/core/utils/scribble_hash_util.dart';
  import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

  /// 📊 필기 동기화 소스
  enum ScribbleSyncSource {
    /// 로컬에서 생성/수정됨
    local,

    /// 서버에서 다운로드됨
    server,

    /// 로컬 + 서버 병합
    merged,

    /// 충돌 해결 후 동기화됨
    conflictResolved,
  }

  /// ⚔️ 충돌 해결 방법
  enum ConflictResolution {
    /// 충돌 해결하지 않음
    none,

    /// 로컬 버전 우선
    localWins,

    /// 서버 버전 우선
    serverWins,

    /// 로컬 + 서버 병합
    merged,

    /// 사용자 수동 해결
    manual,
  }

  /// 📊 필기 메타데이터
  ///
  /// 필기 데이터의 동기화 상태 및 버전 정보를 관리합니다.
  @immutable
  class ScribbleMetadata {
    /// 생성 시각 (ISO 8601 문자열)
    final String createdAt;

    /// 마지막 수정 시각 (ISO 8601 문자열)
    final String updatedAt;

    /// 버전 문자열
    final String version;

    /// 콘텐츠 해시
    final String hash;

    /// 스트로크 개수
    final int strokeCount;

    /// 동기화 소스
    final ScribbleSyncSource syncSource;

    /// 마지막 동기화 시각
    final DateTime? lastSyncTime;

    /// 충돌 해결 방법
    final ConflictResolution conflictResolution;

    /// ScribbleMetadata 생성자
    const ScribbleMetadata({
      required this.updatedAt,
      required this.strokeCount,
      this.createdAt = '',
      this.version = '',
      this.hash = '',
      this.syncSource = ScribbleSyncSource.local,
      this.lastSyncTime,
      this.conflictResolution = ConflictResolution.none,
    });

    /// Scribble 객체로부터 메타데이터 생성
    factory ScribbleMetadata.fromScribble(
      Scribble? scribble, {
      ScribbleSyncSource syncSource = .local,
      DateTime? lastSyncTime,
      ConflictResolution conflictResolution = .none,
    }) {
      final List<Stroke> strokes = scribble?.strokes ?? [];
      final now = DateTime.now().toIso8601String();

      // 해시 생성: 각 stroke의 해시를 합쳐서 전체 해시 생성
      final hash = strokes.isEmpty
          ? ''
          : Object.hashAll(
              strokes.map(ScribbleHashUtil.generateStrokeHash),
            ).toString();

      return ScribbleMetadata(
        createdAt: scribble?.createdAt ?? now,
        updatedAt: scribble?.updatedAt ?? now,
        version: scribble?.version ?? '1.0.0',
        hash: hash,
        strokeCount: strokes.length,
        syncSource: syncSource,
        lastSyncTime: lastSyncTime,
        conflictResolution: conflictResolution,
      );
    }

    /// JSON에서 메타데이터 복원
    factory ScribbleMetadata.fromJson(Map<String, dynamic> json) {
      return ScribbleMetadata(
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        version: json['version'] as String? ?? '',
        hash: json['hash'] as String? ?? '',
        strokeCount: json['strokeCount'] as int? ?? 0,
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
    int get hashCode => Object.hash(
      createdAt,
      updatedAt,
      version,
      hash,
      strokeCount,
      syncSource,
      lastSyncTime,
      conflictResolution,
    );

    /// 충돌 해결 (두 메타데이터 비교 후 병합)
    static ScribbleMetadata resolveConflict(
      ScribbleMetadata local,
      ScribbleMetadata server,
    ) {
      // 기본 전략: 서버 메타데이터 + conflictResolved 마크
      return ScribbleMetadata(
        createdAt: local.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        version: server.version,
        hash: server.hash,
        strokeCount: server.strokeCount,
        syncSource: .conflictResolved,
        lastSyncTime: DateTime.now(),
        conflictResolution: .merged,
      );
    }

    /// 서버 메타데이터와 비교하여 동기화 필요 여부 판단
    bool needsSync(ScribbleMetadata? serverMeta) {
      if (serverMeta == null) return true;

      return hash != serverMeta.hash;
    }

    /// JSON 직렬화
    Map<String, dynamic> toJson() => {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': version,
      'hash': hash,
      'strokeCount': strokeCount,
      'syncSource': syncSource.name,
      'conflictResolution': conflictResolution.name,
    };

    @override
    bool operator ==(Object other) {
      if (identical(this, other)) return true;

      return other is ScribbleMetadata &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.version == version &&
          other.hash == hash &&
          other.strokeCount == strokeCount &&
          other.syncSource == syncSource &&
          other.lastSyncTime == lastSyncTime &&
          other.conflictResolution == conflictResolution;
    }

    @override
    String toString() =>
        'ScribbleMetadata(strokes: $strokeCount, hash: $hash, sync: $syncSource)';
  }
