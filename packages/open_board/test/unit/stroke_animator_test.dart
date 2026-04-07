import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/replay/stroke_animator.dart';

Stroke _createTimedStroke({
  required List<int> timestamps,
  int color = 0xFF000000,
}) {
  return Stroke(
    points: [
      for (final t in timestamps)
        Point(x: t.toDouble(), y: t.toDouble(), timestamp: Int64(t)),
    ],
    color: color,
    ink: 'pen',
    width: 2,
  );
}

void main() {
  group('StrokeAnimator.createPartialStroke', () {
    test('빈 스트로크 → null', () {
      final stroke = Stroke(points: []);
      expect(StrokeAnimator.createPartialStroke(stroke, 1000), isNull);
    });

    test('시작 전 → null', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.createPartialStroke(stroke, 50), isNull);
    });

    test('완료 후 → 원본 반환', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      final result = StrokeAnimator.createPartialStroke(stroke, 300);
      expect(identical(result, stroke), isTrue);
    });

    test('완료 이후 → 원본 반환', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      final result = StrokeAnimator.createPartialStroke(stroke, 500);
      expect(identical(result, stroke), isTrue);
    });

    test('중간 시점 → 부분 스트로크', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300, 400, 500]);
      final result = StrokeAnimator.createPartialStroke(stroke, 250);

      expect(result, isNotNull);
      expect(result!.points.length, 2); // 100, 200
      expect(result.points.last.timestamp, Int64(200));
      expect(result.color, stroke.color);
      expect(result.ink, stroke.ink);
    });

    test('포인트 1개만 → null (최소 2개 필요)', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      final result = StrokeAnimator.createPartialStroke(stroke, 100);
      expect(result, isNull);
    });

    test('포인트 2개 시점 → 부분 스트로크', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      final result = StrokeAnimator.createPartialStroke(stroke, 200);

      expect(result, isNotNull);
      expect(result!.points.length, 2);
    });
  });

  group('StrokeAnimator.getProgress', () {
    test('빈 스트로크 → 0', () {
      expect(StrokeAnimator.getProgress(Stroke(points: []), 1000), 0);
    });

    test('시작 전 → 0', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.getProgress(stroke, 50), 0);
    });

    test('완료 → 1', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.getProgress(stroke, 300), 1);
    });

    test('중간 → 0.5', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.getProgress(stroke, 200), 0.5);
    });

    test('단일 포인트 → 1', () {
      final stroke = _createTimedStroke(timestamps: [100]);
      expect(StrokeAnimator.getProgress(stroke, 100), 1);
    });
  });

  group('StrokeAnimator.isActive', () {
    test('범위 내 → true', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.isActive(stroke, 200), isTrue);
    });

    test('시작 시점 → true', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.isActive(stroke, 100), isTrue);
    });

    test('끝 시점 → true', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.isActive(stroke, 300), isTrue);
    });

    test('시작 전 → false', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.isActive(stroke, 50), isFalse);
    });

    test('종료 후 → false', () {
      final stroke = _createTimedStroke(timestamps: [100, 200, 300]);
      expect(StrokeAnimator.isActive(stroke, 301), isFalse);
    });

    test('빈 스트로크 → false', () {
      expect(StrokeAnimator.isActive(Stroke(points: []), 100), isFalse);
    });
  });
}
