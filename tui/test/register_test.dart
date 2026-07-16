import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

void main() {
  group('registerArgs', () {
    test('dir을 항상 명시하고 name/labels 없으면 스코프 인자만 추가', () {
      final args = registerArgs(const Scope.org('coco-de'), '/tmp/runner');
      expect(args, ['--org', 'coco-de', '--dir', '/tmp/runner']);
    });

    test('name/labels가 있으면 각각 --name/--labels로 추가', () {
      final args = registerArgs(
        const Scope.repo('coco-de/co-arc'),
        '/tmp/runner-02',
        name: 'action-02',
        labels: 'self-hosted,macOS',
      );
      expect(args, [
        '--repo',
        'coco-de/co-arc',
        '--dir',
        '/tmp/runner-02',
        '--name',
        'action-02',
        '--labels',
        'self-hosted,macOS',
      ]);
    });

    test('빈 문자열 name/labels는 무시', () {
      final args = registerArgs(
        const Scope.org('coco-de'),
        '/tmp/runner',
        name: '',
        labels: '',
      );
      expect(args, ['--org', 'coco-de', '--dir', '/tmp/runner']);
    });
  });

  group('removeArgs', () {
    test('org 스코프와 설치 경로만 넘긴다', () {
      final args = removeArgs(const Scope.org('coco-de'), '/tmp/runner');
      expect(args, ['--org', 'coco-de', '--dir', '/tmp/runner']);
    });

    test('repo 스코프도 owner/repo 그대로 넘긴다', () {
      final args =
          removeArgs(const Scope.repo('coco-de/co-arc'), '/tmp/runner-02');
      expect(args, ['--repo', 'coco-de/co-arc', '--dir', '/tmp/runner-02']);
    });
  });

  group('parseRegisterInput', () {
    test('빈 입력은 (null, null)', () {
      expect(parseRegisterInput(''), (null, null));
      expect(parseRegisterInput('   '), (null, null));
    });

    test('이름만 입력', () {
      expect(parseRegisterInput('action-02'), ('action-02', null));
    });

    test('이름 + 라벨 CSV', () {
      expect(
        parseRegisterInput('action-02 self-hosted,macOS,flutter'),
        ('action-02', 'self-hosted,macOS,flutter'),
      );
    });

    test('이름과 라벨 사이 공백이 여러 개여도 라벨은 trim됨', () {
      expect(
        parseRegisterInput('action-02   self-hosted,macOS'),
        ('action-02', 'self-hosted,macOS'),
      );
    });

    test('앞뒤 공백은 무시', () {
      expect(parseRegisterInput('  action-02  '), ('action-02', null));
    });
  });
}
