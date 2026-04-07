import 'package:open_board/src/data/model/timeline/timeline_models.dart';
import 'package:open_board/src/module/replay/timeline_file.dart';

/// .obt 포맷 버전 간 마이그레이션 처리
///
/// [TimelineFile.read]에서 구 버전 파일 로드 시 자동 호출된다.
/// 순차적 체인 방식: v1 → v2 → v3 → ... → currentFormatVersion
class TimelineMigrator {
  const TimelineMigrator._();

  /// [from] 버전에서 [TimelineFile.currentFormatVersion]까지 순차 마이그레이션
  ///
  /// Throws [FormatException] if [from] version has no registered migration.
  static ScribbleTimeline migrate(
    ScribbleTimeline timeline, {
    required int from,
  }) {
    if (from >= TimelineFile.currentFormatVersion) return timeline;
    if (from < 1) {
      throw FormatException(
        'Invalid .obt format version: $from (minimum: 1)',
      );
    }

    var current = timeline;
    var version = from;

    while (version < TimelineFile.currentFormatVersion) {
      final migrateFn = _migrations[version];
      if (migrateFn == null) {
        throw FormatException(
          'No migration registered for .obt format version $version → '
          '${version + 1}',
        );
      }
      current = migrateFn(current);
      version++;
    }

    return current;
  }

  /// 특정 버전에서 현재 버전까지 마이그레이션이 가능한지 확인
  static bool canMigrate(int fromVersion) {
    if (fromVersion >= TimelineFile.currentFormatVersion) return true;
    if (fromVersion < 1) return false;

    for (var v = fromVersion; v < TimelineFile.currentFormatVersion; v++) {
      if (!_migrations.containsKey(v)) return false;
    }
    return true;
  }

  /// 등록된 마이그레이션 함수 맵 (fromVersion → transform)
  static final Map<int, ScribbleTimeline Function(ScribbleTimeline)>
      _migrations = {
    // 현재 formatVersion=1 이므로 등록된 마이그레이션 없음.
    // 향후 예시:
    // 1: _migrateV1ToV2,
    // 2: _migrateV2ToV3,
  };
}
