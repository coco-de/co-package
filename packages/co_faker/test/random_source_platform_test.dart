// 같은 seed · key 가 VM 과 웹(dart2js · dart2wasm)에서 같은 파생 seed 를 내는지 고정한다 (#69).
//
// 기대값은 수정 전 VM 구현(64비트 정수라 정확했다)으로 계산한 값이다. 수정은 VM 결과를 바꾸지
// 않아야 하므로 이 표가 그대로 통과해야 하고, 웹에서도 같은 값이 나와야 한다.
// CI 는 VM(`melos run test:dart`)과 브라우저(`dart test -p chrome`) 양쪽에서 이 파일을 돌린다.
@TestOn('vm || browser')
library;

import 'package:co_faker/co_faker.dart';
import 'package:test/test.dart';

class _Case {
  const _Case(this.seed, this.key, this.expected);

  final int seed;
  final String key;
  final int expected;
}

const List<_Case> _cases = <_Case>[
  _Case(0, '', 1441645609),
  _Case(0, 'a', 223083864),
  _Case(0, 'course/title', 1637546061),
  _Case(0, 'pet/pet-0001/name', 1192917206),
  _Case(0, '한글/키', 1883583670),
  _Case(0, 'business', 1437579383),
  _Case(0, 'display', 1987249569),
  _Case(
    0,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    1906937129,
  ),
  _Case(1, '', 1340832800),
  _Case(1, 'a', 280271443),
  _Case(1, 'course/title', 1517199640),
  _Case(1, 'pet/pet-0001/name', 1599541113),
  _Case(1, '한글/키', 475523543),
  _Case(1, 'business', 901469994),
  _Case(1, 'display', 1376283022),
  _Case(
    1,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    901536288,
  ),
  _Case(7, '', 1407545918),
  _Case(7, 'a', 1899170701),
  _Case(7, 'course/title', 287395202),
  _Case(7, 'pet/pet-0001/name', 1867284087),
  _Case(7, '한글/키', 530007225),
  _Case(7, 'business', 1293150460),
  _Case(7, 'display', 470918252),
  _Case(
    7,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    1885583934,
  ),
  _Case(42, '', 1781264493),
  _Case(42, 'a', 791339748),
  _Case(42, 'course/title', 2098247841),
  _Case(42, 'pet/pet-0001/name', 627662898),
  _Case(42, '한글/키', 1244981586),
  _Case(42, 'business', 1800953811),
  _Case(42, 'display', 2031281693),
  _Case(
    42,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    153498989,
  ),
  _Case(436, '', 1202295882),
  _Case(436, 'a', 2062827441),
  _Case(436, 'course/title', 199951694),
  _Case(436, 'pet/pet-0001/name', 894934459),
  _Case(436, '한글/키', 981744125),
  _Case(436, 'business', 374235328),
  _Case(436, 'display', 1070443344),
  _Case(
    436,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    454317130,
  ),
  _Case(2147483647, '', 1306369103),
  _Case(2147483647, 'a', 1104993386),
  _Case(2147483647, 'course/title', 1687723927),
  _Case(2147483647, 'pet/pet-0001/name', 1313510860),
  _Case(2147483647, '한글/키', 344666968),
  _Case(2147483647, 'business', 140196537),
  _Case(2147483647, 'display', 1171825111),
  _Case(
    2147483647,
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    1792146255,
  ),
];

const List<int> _derivedDraws = <int>[613598, 698705, 282109, 96482, 148829];

void main() {
  group('CoRandom.deriveSeed', () {
    test('matches the VM reference table on every platform', () {
      for (final c in _cases) {
        expect(
          CoRandom.deriveSeed(c.seed, c.key),
          c.expected,
          reason: 'seed=${c.seed} key=${c.key.length > 20 ? 'x*64' : c.key}',
        );
      }
    });

    test('derived streams draw the same values on every platform', () {
      final derived = CoRandom(436).derive('pet/pet-0001/name');
      expect(
        List<int>.generate(5, (_) => derived.int(max: 1000000)),
        _derivedDraws,
      );
    });

    test('stays a non-negative 31-bit seed', () {
      for (final c in _cases) {
        final value = CoRandom.deriveSeed(c.seed, c.key);
        expect(value, inInclusiveRange(0, 0x7fffffff));
      }
    });
  });
}
