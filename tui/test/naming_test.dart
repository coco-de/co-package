import 'dart:math';

import 'package:coarc_tui/coarc_tui.dart';
import 'package:test/test.dart';

void main() {
  group('hostSlug', () {
    test('.local 접미사 제거 + 소문자화', () {
      expect(hostSlug('Cocode-M2-Ultra.local'), 'cocode-m2-ultra');
    });

    test('영문/숫자 외 문자는 -로 치환하고 양끝 - 제거', () {
      expect(hostSlug('My Mac (2)!'), 'my-mac-2');
      expect(hostSlug('__weird__'), 'weird');
    });

    test('빈 결과는 runner로 대체', () {
      expect(hostSlug('...'), 'runner');
      expect(hostSlug('   '), 'runner');
    });
  });

  group('generateRunnerName', () {
    test('{호스트}-{공룡} 형식이고 공룡은 풀에 있는 값', () {
      final name = generateRunnerName('host', const {}, rng: Random(1));
      expect(name, startsWith('host-'));
      final dino = name.substring('host-'.length);
      expect(dinosaurNames, contains(dino));
    });

    test('이미 쓰인 이름은 피한다', () {
      // Random(1)이 첫 번째로 고르는 이름을 미리 알아내 taken에 넣고,
      // 같은 시드로 다시 생성하면 그 이름은 반환되지 않아야 한다.
      final first = generateRunnerName('host', const {}, rng: Random(1));
      final second =
          generateRunnerName('host', {first}, rng: Random(1));
      expect(second, isNot(first));
      expect(second, startsWith('host-'));
    });

    test('공룡 풀이 전부 소진되면 -2, -3 접미사로 유일화', () {
      final taken = {for (final d in dinosaurNames) 'host-$d'};
      final name = generateRunnerName('host', taken, rng: Random(1));
      expect(name, matches(RegExp(r'^host-[a-z]+-\d+$')));
      expect(taken, isNot(contains(name)));
    });

    test('첫 접미사도 쓰였으면 다음 번호로', () {
      final taken = {
        for (final d in dinosaurNames) 'host-$d',
      };
      // -2까지 선점 → -3 이상이 나와야 한다.
      final base = generateRunnerName('host', taken, rng: Random(1));
      final baseWithoutNum = base.substring(0, base.lastIndexOf('-'));
      final taken2 = {...taken, '$baseWithoutNum-2'};
      final next = generateRunnerName('host', taken2, rng: Random(1));
      expect(next, isNot('$baseWithoutNum-2'));
      expect(taken2, isNot(contains(next)));
    });
  });

  group('LocalRunner.dirFor', () {
    test('<root>/<이름> 경로를 만든다', () {
      final local = LocalRunner(dir: '/x/actions/old', root: '/x/actions');
      expect(local.dirFor('cocode-01'), '/x/actions/cocode-01');
    });

    test('withDir은 root를 유지한 채 dir만 바꾼다', () {
      final local = LocalRunner(dir: '/x/actions/old', root: '/x/actions');
      final next = local.withDir('/x/actions/new');
      expect(next.dir, '/x/actions/new');
      expect(next.root, '/x/actions');
    });
  });
}
