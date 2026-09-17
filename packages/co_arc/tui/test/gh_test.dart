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
      expect(r.customLabels, ['flutter']);
      expect(r.readOnlyLabels, {'self-hosted', 'macos'});
    });

    test('누락 필드는 안전한 기본값', () {
      final r = RunnerInfo.fromJson({'id': 1});
      expect(r.name, '?');
      expect(r.online, isFalse);
      expect(r.busy, isFalse);
      expect(r.labels, isEmpty);
      expect(r.customLabels, isEmpty);
      expect(r.readOnlyLabels, isEmpty);
    });
  });

  group('runnerLabelsPath', () {
    test('org 스코프', () {
      expect(
        runnerLabelsPath(const Scope.org('coco-de'), 7),
        'orgs/coco-de/actions/runners/7/labels',
      );
    });

    test('repo 스코프', () {
      expect(
        runnerLabelsPath(const Scope.repo('coco-de/co-arc'), 42),
        'repos/coco-de/co-arc/actions/runners/42/labels',
      );
    });
  });

  group('labelFieldArgs', () {
    test('라벨마다 -f labels[]= 인자를 만든다', () {
      expect(
        labelFieldArgs(['flutter', 'ios']),
        ['-f', 'labels[]=flutter', '-f', 'labels[]=ios'],
      );
    });

    test('빈 리스트는 빈 인자', () {
      expect(labelFieldArgs(const []), isEmpty);
    });
  });
}
