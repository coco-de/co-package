import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

void main() {
  group('RunnerInfo.fromJson', () {
    test('GitHub API 응답 형태를 파싱', () {
      final r = RunnerInfo.fromJson({
        'id': 42,
        'name': 'cody-macbook-local',
        'os': 'macos',
        'status': 'online',
        'busy': true,
        'labels': [
          {'id': 1, 'name': 'self-hosted', 'type': 'read-only'},
          {'id': 2, 'name': 'macos', 'type': 'read-only'},
          {'id': 3, 'name': 'flutter', 'type': 'custom'},
        ],
      });
      expect(r.id, 42);
      expect(r.name, 'cody-macbook-local');
      expect(r.online, isTrue);
      expect(r.busy, isTrue);
      expect(r.labels, ['self-hosted', 'macos', 'flutter']);
    });

    test('누락 필드는 안전한 기본값', () {
      final r = RunnerInfo.fromJson({'id': 1});
      expect(r.name, '?');
      expect(r.online, isFalse);
      expect(r.busy, isFalse);
      expect(r.labels, isEmpty);
    });
  });
}
