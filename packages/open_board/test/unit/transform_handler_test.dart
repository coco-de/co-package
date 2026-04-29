import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/coordinate_transformer.dart';
import 'package:open_board/src/module/transform_handler.dart';

void main() {
  group('TransformHandler', () {
    late TransformHandler handler;

    setUp(() {
      // CoordinateTransformer with null controller (identity transform)
      const transformer = CoordinateTransformer(null);
      handler = TransformHandler(transformer);
    });

    group('초기 상태', () {
      test('isTransforming은 false', () {
        expect(handler.isTransforming, isFalse);
      });

      test('isMoving은 false', () {
        expect(handler.isMoving, isFalse);
      });

      test('isResizeRotating은 false', () {
        expect(handler.isResizeRotating, isFalse);
      });

      test('originalPoints는 null', () {
        expect(handler.originalPoints, isNull);
      });

      test('currentRotation은 0.0', () {
        expect(handler.currentRotation, 0.0);
      });
    });

    group('이동 (Move)', () {
      test('startMove 후 isMoving은 true', () {
        handler.startMove(const Offset(100, 100));
        expect(handler.isMoving, isTrue);
        expect(handler.isTransforming, isTrue);
      });

      test('applyMove: delta 기반 이동 정확성', () {
        handler.startMove(const Offset(100, 100));

        final points = [
          [const Offset(10, 10), const Offset(20, 20)],
          [const Offset(30, 30)],
        ];

        // 현재 위치가 (150, 120)이면 delta는 (50, 20)
        final result = handler.applyMove(points, const Offset(150, 120));

        expect(result[0][0], const Offset(60, 30)); // 10+50, 10+20
        expect(result[0][1], const Offset(70, 40)); // 20+50, 20+20
        expect(result[1][0], const Offset(80, 50)); // 30+50, 30+20
      });

      test('applyMove: 음수 delta 이동', () {
        handler.startMove(const Offset(200, 200));

        final points = [
          [const Offset(100, 100)],
        ];

        // 현재 위치가 (150, 180)이면 delta는 (-50, -20)
        final result = handler.applyMove(points, const Offset(150, 180));

        expect(result[0][0], const Offset(50, 80)); // 100-50, 100-20
      });

      test('getMoveDeleta: delta 반환', () {
        handler.startMove(const Offset(100, 100));

        final delta = handler.getMoveDeleta(const Offset(150, 120));

        expect(delta, const Offset(50, 20));
      });

      test('getMoveDeleta: startMove 전에는 null', () {
        final delta = handler.getMoveDeleta(const Offset(150, 120));
        expect(delta, isNull);
      });

      test('applyMove: startMove 없이 호출하면 원본 반환', () {
        final points = [
          [const Offset(10, 10)],
        ];

        final result = handler.applyMove(points, const Offset(150, 120));

        expect(result[0][0], const Offset(10, 10));
      });

      test('endMove 후 isMoving은 false', () {
        handler.startMove(const Offset(100, 100));
        expect(handler.isMoving, isTrue);

        handler.endMove();
        expect(handler.isMoving, isFalse);
        expect(handler.isTransforming, isFalse);
      });

      test('endMove 후 getMoveDeleta는 null', () {
        handler.startMove(const Offset(100, 100));
        handler.endMove();

        final delta = handler.getMoveDeleta(const Offset(150, 120));
        expect(delta, isNull);
      });
    });

    group('크기조절/회전 (Resize/Rotate)', () {
      test('startResizeRotate 후 isResizeRotating은 true', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        expect(handler.isResizeRotating, isTrue);
        expect(handler.isTransforming, isTrue);
      });

      test('computeResizeRotate: 스케일 정확성 - 거리가 2배가 되면 스케일 2.0', () {
        // 핸들 위치: (200, 100), 중심: (100, 100) → 거리 100
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 현재 위치: (300, 100) → 거리 200 → 스케일 2.0
        final result = handler.computeResizeRotate(const Offset(300, 100));

        expect(result.scale, closeTo(2.0, 0.01));
        expect(result.deltaAngle, closeTo(0.0, 0.01));
      });

      test('computeResizeRotate: 스케일 정확성 - 거리가 절반이면 스케일 0.5', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 현재 위치: (150, 100) → 거리 50 → 스케일 0.5
        final result = handler.computeResizeRotate(const Offset(150, 100));

        expect(result.scale, closeTo(0.5, 0.01));
      });

      test('computeResizeRotate: 스케일 클램프 - 최솟값 0.1', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 매우 가까운 위치 → 거리 5 → 스케일 0.05 → 클램프 0.1
        final result = handler.computeResizeRotate(const Offset(105, 100));

        expect(result.scale, closeTo(0.1, 0.01));
      });

      test('computeResizeRotate: 스케일 클램프 - 최댓값 3.0', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 매우 먼 위치 → 거리 500 → 스케일 5.0 → 클램프 3.0
        final result = handler.computeResizeRotate(const Offset(600, 100));

        expect(result.scale, closeTo(3.0, 0.01));
      });

      test('computeResizeRotate: 90도 회전', () {
        // 핸들: (200, 100), 중심: (100, 100) → 각도 0
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 현재 위치: (100, 200) → 각도 pi/2
        final result = handler.computeResizeRotate(const Offset(100, 200));

        expect(result.deltaAngle, closeTo(math.pi / 2, 0.01));
      });

      test('computeResizeRotate: -90도 회전', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );

        // 현재 위치: (100, 0) → 각도 -pi/2
        final result = handler.computeResizeRotate(const Offset(100, 0));

        expect(result.deltaAngle, closeTo(-math.pi / 2, 0.01));
      });

      test('computeResizeRotate: 초기화 전에는 기본값 반환', () {
        final result = handler.computeResizeRotate(const Offset(200, 200));

        expect(result.scale, 1.0);
        expect(result.deltaAngle, 0.0);
      });

      test('computeResizeRotate: initialRotation 적용', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
          initialRotation: math.pi / 4,
        );

        // 동일 위치 → 스케일 1.0, deltaAngle 0
        final result = handler.computeResizeRotate(const Offset(200, 100));

        expect(result.scale, closeTo(1.0, 0.01));
        expect(result.deltaAngle, closeTo(0.0, 0.01));
        // finalRotation = deltaAngle (TransformHandler는 deltaAngle만 반환)
        expect(result.finalRotation, closeTo(0.0, 0.01));
      });

      test('applyResizeRotate: 스케일 2배 적용', () {
        final points = [
          [const Offset(110, 100), const Offset(120, 100)],
        ];

        final result = handler.applyResizeRotate(
          points,
          center: const Offset(100, 100),
          scale: 2.0,
          rotation: 0.0,
        );

        // (110-100)*2 + 100 = 120, (120-100)*2 + 100 = 140
        expect(result[0][0].dx, closeTo(120, 0.01));
        expect(result[0][0].dy, closeTo(100, 0.01));
        expect(result[0][1].dx, closeTo(140, 0.01));
        expect(result[0][1].dy, closeTo(100, 0.01));
      });

      test('applyResizeRotate: 90도 회전 적용', () {
        final points = [
          [const Offset(110, 100)],
        ];

        final result = handler.applyResizeRotate(
          points,
          center: const Offset(100, 100),
          scale: 1.0,
          rotation: math.pi / 2,
        );

        // (10, 0) → 회전 90도 → (0, 10) → + center → (100, 110)
        expect(result[0][0].dx, closeTo(100, 0.01));
        expect(result[0][0].dy, closeTo(110, 0.01));
      });

      test('applyResizeRotate: 스케일 + 회전 동시 적용', () {
        final points = [
          [const Offset(110, 100)],
        ];

        final result = handler.applyResizeRotate(
          points,
          center: const Offset(100, 100),
          scale: 2.0,
          rotation: math.pi / 2,
        );

        // relative: (10, 0) → scale: (20, 0) → 회전 90도: (0, 20) → + center: (100, 120)
        expect(result[0][0].dx, closeTo(100, 0.01));
        expect(result[0][0].dy, closeTo(120, 0.01));
      });

      test('endResizeRotate 후 isResizeRotating은 false', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        expect(handler.isResizeRotating, isTrue);

        handler.endResizeRotate();
        expect(handler.isResizeRotating, isFalse);
        expect(handler.isTransforming, isFalse);
      });
    });

    group('원본 포인트 캐싱', () {
      test('cacheOriginalPoints 후 originalPoints 접근 가능', () {
        final points = [
          [const Offset(10, 20), const Offset(30, 40)],
          [const Offset(50, 60)],
        ];

        handler.cacheOriginalPoints(points);

        expect(handler.originalPoints, isNotNull);
        expect(handler.originalPoints!.length, 2);
        expect(handler.originalPoints![0].length, 2);
        expect(handler.originalPoints![0][0], const Offset(10, 20));
        expect(handler.originalPoints![1][0], const Offset(50, 60));
      });

      test('cacheOriginalPoints는 깊은 복사 수행', () {
        final points = [
          [const Offset(10, 20)],
        ];

        handler.cacheOriginalPoints(points);

        // 원본 변경
        points[0].add(const Offset(99, 99));

        // 캐시는 변경되지 않아야 함
        expect(handler.originalPoints![0].length, 1);
      });
    });

    group('상태 추적 (isTransforming)', () {
      test('이동 중에는 isTransforming이 true', () {
        handler.startMove(const Offset(100, 100));
        expect(handler.isTransforming, isTrue);
      });

      test('크기조절/회전 중에는 isTransforming이 true', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        expect(handler.isTransforming, isTrue);
      });

      test('이동과 크기조절/회전 동시 활성화 시 isTransforming은 true', () {
        handler.startMove(const Offset(100, 100));
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        expect(handler.isTransforming, isTrue);
      });

      test('이동만 종료해도 크기조절/회전 중이면 isTransforming은 true', () {
        handler.startMove(const Offset(100, 100));
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        handler.endMove();
        expect(handler.isTransforming, isTrue);
      });
    });

    group('리셋', () {
      test('reset 후 모든 상태 초기화', () {
        handler.startMove(const Offset(100, 100));
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        handler.cacheOriginalPoints([
          [const Offset(10, 20)],
        ]);

        handler.reset();

        expect(handler.isMoving, isFalse);
        expect(handler.isResizeRotating, isFalse);
        expect(handler.isTransforming, isFalse);
        expect(handler.originalPoints, isNull);
        expect(handler.currentRotation, 0.0);
      });

      test('reset 후 getMoveDeleta는 null', () {
        handler.startMove(const Offset(100, 100));
        handler.reset();

        final delta = handler.getMoveDeleta(const Offset(150, 120));
        expect(delta, isNull);
      });

      test('reset 후 computeResizeRotate는 기본값', () {
        handler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        handler.reset();

        final result = handler.computeResizeRotate(const Offset(300, 100));

        expect(result.scale, 1.0);
        expect(result.deltaAngle, 0.0);
      });
    });

    group('CoordinateTransformer null 케이스', () {
      test('null controller로 생성한 TransformHandler 정상 동작', () {
        const transformer = CoordinateTransformer(null);
        final nullHandler = TransformHandler(transformer);

        // 이동 테스트
        nullHandler.startMove(const Offset(100, 100));
        final points = [
          [const Offset(10, 10)],
        ];
        final result = nullHandler.applyMove(points, const Offset(150, 120));
        expect(result[0][0], const Offset(60, 30));

        nullHandler.endMove();

        // 크기조절/회전 테스트
        nullHandler.startResizeRotate(
          const Offset(200, 100),
          const Offset(100, 100),
        );
        final resizeResult = nullHandler.computeResizeRotate(
          const Offset(300, 100),
        );
        expect(resizeResult.scale, closeTo(2.0, 0.01));

        nullHandler.endResizeRotate();
      });
    });

    group('빈 포인트 그룹 처리', () {
      test('applyMove: 빈 포인트 그룹', () {
        handler.startMove(const Offset(100, 100));

        final result = handler.applyMove([], const Offset(150, 120));

        expect(result, isEmpty);
      });

      test('applyResizeRotate: 빈 포인트 그룹', () {
        final result = handler.applyResizeRotate(
          [],
          center: const Offset(100, 100),
          scale: 2.0,
          rotation: 0.0,
        );

        expect(result, isEmpty);
      });

      test('cacheOriginalPoints: 빈 리스트', () {
        handler.cacheOriginalPoints([]);

        expect(handler.originalPoints, isNotNull);
        expect(handler.originalPoints, isEmpty);
      });
    });
  });
}
