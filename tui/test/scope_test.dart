import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

void main() {
  group('Scope.parse', () {
    test('슬래시가 없으면 org', () {
      final s = Scope.parse('coco-de');
      expect(s.isOrg, isTrue);
      expect(s.apiBase, 'orgs/coco-de');
      expect(s.scriptArgs, ['--org', 'coco-de']);
    });

    test('슬래시가 있으면 repo', () {
      final s = Scope.parse('coco-de/co-arc');
      expect(s.isOrg, isFalse);
      expect(s.apiBase, 'repos/coco-de/co-arc');
      expect(s.scriptArgs, ['--repo', 'coco-de/co-arc']);
    });
  });

  group('Scope JSON 직렬화', () {
    test('org 왕복', () {
      final s = Scope.fromJson(const Scope.org('coco-de').toJson());
      expect(s!.isOrg, isTrue);
      expect(s.name, 'coco-de');
    });

    test('repo 왕복', () {
      final s = Scope.fromJson(const Scope.repo('coco-de/x').toJson());
      expect(s!.isOrg, isFalse);
      expect(s.name, 'coco-de/x');
    });

    test('손상된 JSON은 null', () {
      expect(Scope.fromJson(null), isNull);
      expect(Scope.fromJson({'type': 'org'}), isNull);
      expect(Scope.fromJson({'type': 'org', 'name': ''}), isNull);
      expect(Scope.fromJson('coco-de'), isNull);
    });
  });
}
