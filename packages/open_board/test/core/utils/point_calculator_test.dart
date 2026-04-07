import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/point_calculator.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('point_calculator', () {
    group('neg', () {
      test('부호 반전', () {
        final p = createPoint(x: 3, y: -4);
        final result = neg(p);
        expect(result.x, -3);
        expect(result.y, 4);
      });
    });

    group('add / sub', () {
      test('벡터 덧셈', () {
        final a = createPoint(x: 1, y: 2);
        final b = createPoint(x: 3, y: 4);
        final result = add(a, b);
        expect(result.x, 4);
        expect(result.y, 6);
      });

      test('벡터 뺄셈', () {
        final a = createPoint(x: 5, y: 7);
        final b = createPoint(x: 2, y: 3);
        final result = sub(a, b);
        expect(result.x, 3);
        expect(result.y, 4);
      });
    });

    group('mul / div', () {
      test('스칼라 곱셈', () {
        final p = createPoint(x: 3, y: 4);
        final result = mul(p, 2);
        expect(result.x, 6);
        expect(result.y, 8);
      });

      test('스칼라 나눗셈', () {
        final p = createPoint(x: 6, y: 8);
        final result = div(p, 2);
        expect(result.x, 3);
        expect(result.y, 4);
      });
    });

    group('mulV / divV', () {
      test('벡터 성분별 곱셈', () {
        final a = createPoint(x: 2, y: 3);
        final b = createPoint(x: 4, y: 5);
        final result = mulV(a, b);
        expect(result.x, 8);
        expect(result.y, 15);
      });

      test('벡터 성분별 나눗셈', () {
        final a = createPoint(x: 8, y: 15);
        final b = createPoint(x: 4, y: 5);
        final result = divV(a, b);
        expect(result.x, 2);
        expect(result.y, 3);
      });
    });

    group('per', () {
      test('수직 벡터', () {
        final p = createPoint(x: 1, y: 0);
        final result = per(p);
        expect(result.x, 0);
        expect(result.y, -1);
      });
    });

    group('uni', () {
      test('단위 벡터 길이는 1', () {
        final p = createPoint(x: 3, y: 4);
        final result = uni(p);
        expect(len(result), closeTo(1, 0.001));
      });
    });

    group('lerp / med', () {
      test('선형 보간 t=0은 시작점', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 10, y: 10);
        final result = lerp(a, b, 0);
        expect(result.x, 0);
        expect(result.y, 0);
      });

      test('선형 보간 t=1은 끝점', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 10, y: 10);
        final result = lerp(a, b, 1);
        expect(result.x, 10);
        expect(result.y, 10);
      });

      test('med는 중간점', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 10, y: 10);
        final result = med(a, b);
        expect(result.x, 5);
        expect(result.y, 5);
      });
    });

    group('len / dist', () {
      test('3-4-5 벡터 길이', () {
        final p = createPoint(x: 3, y: 4);
        expect(len(p), 5);
      });

      test('len2는 제곱 길이', () {
        final p = createPoint(x: 3, y: 4);
        expect(len2(p), 25);
      });

      test('두 점 거리', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 3, y: 4);
        expect(dist(a, b), 5);
      });

      test('dist2는 제곱 거리', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 3, y: 4);
        expect(dist2(a, b), 25);
      });
    });

    group('dpr', () {
      test('내적 계산', () {
        final a = createPoint(x: 1, y: 0);
        final b = createPoint(x: 0, y: 1);
        expect(dpr(a, b), 0); // 수직이면 0
      });

      test('같은 방향 내적은 양수', () {
        final a = createPoint(x: 1, y: 0);
        final b = createPoint(x: 2, y: 0);
        expect(dpr(a, b), greaterThan(0));
      });
    });

    group('isEqual', () {
      test('같은 좌표는 true', () {
        final a = createPoint(x: 5, y: 10);
        final b = createPoint(x: 5, y: 10);
        expect(isEqual(a, b), true);
      });

      test('다른 좌표는 false', () {
        final a = createPoint(x: 5, y: 10);
        final b = createPoint(x: 5, y: 11);
        expect(isEqual(a, b), false);
      });
    });

    group('prj', () {
      test('투영 계산', () {
        final a = createPoint(x: 0, y: 0);
        final b = createPoint(x: 1, y: 0);
        final result = prj(a, b, 5);
        expect(result.x, 5);
        expect(result.y, 0);
      });
    });

    group('rotAround', () {
      test('90도 회전', () {
        final a = createPoint(x: 1, y: 0);
        final c = createPoint(x: 0, y: 0);
        final result = rotAround(a, c, pi / 2);
        expect(result.x, closeTo(0, 0.001));
        expect(result.y, closeTo(1, 0.001));
      });

      test('360도 회전은 원래 위치', () {
        final a = createPoint(x: 5, y: 3);
        final c = createPoint(x: 0, y: 0);
        final result = rotAround(a, c, 2 * pi);
        expect(result.x, closeTo(5, 0.001));
        expect(result.y, closeTo(3, 0.001));
      });
    });
  });
}
