// 테스트 더블(_Painter)이 첫 클래스라 파일명과 불일치 — 의도된 패턴.
// ignore_for_file: prefer-match-file-name

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/painters/sketch_line_painter.dart';

/// SketchLinePainter mixin 사용을 위한 테스트 더블.
class _Painter with SketchLinePainter {}

Point _point(double x, double y) => Point()
  ..x = x
  ..y = y;

Stroke _stroke(List<Point> points) => Stroke()..points.addAll(points);

/// path 위에 [target]과 (허용 오차 내) 일치하는 점이 존재하는지 검사한다.
bool _pathReaches(Path path, Offset target, {double tolerance = 1.5}) {
  for (final metric in path.computeMetrics()) {
    // 끝점 직접 비교 (마지막 세그먼트가 target 으로 끝나는지)
    final end = metric.getTangentForOffset(metric.length)?.position;
    if (end != null && (end - target).distance <= tolerance) {
      return true;
    }
  }
  // bounds 기반 보조 검사 (round cap/join 으로 끝점이 약간 확장될 수 있음)
  return path.getBounds().inflate(tolerance).contains(target);
}

void main() {
  group('getSimplePathForStroke (마커 경로)', () {
    test('2점 직선 스트로크가 빈 path 가 되지 않는다 (마커 사라짐 회귀)', () {
      final painter = _Painter();
      final path = painter.getSimplePathForStroke(
        _stroke([_point(10, 10), _point(110, 60)]),
      );

      expect(path, isNotNull);
      // 회귀 전: moveTo 만 남아 length == 0 (사라짐)
      final totalLength = path!.computeMetrics().fold<double>(
        0,
        (sum, m) => sum + m.length,
      );
      expect(totalLength, greaterThan(0));
    });

    test('2점 직선의 끝점이 마지막 포인트까지 이어진다', () {
      final painter = _Painter();
      final path = painter.getSimplePathForStroke(
        _stroke([_point(0, 0), _point(100, 50)]),
      );

      expect(_pathReaches(path!, const Offset(100, 50)), isTrue);
    });

    test('N점 스트로크도 마지막 포인트까지 이어진다', () {
      final painter = _Painter();
      final path = painter.getSimplePathForStroke(
        _stroke([
          _point(0, 0),
          _point(30, 40),
          _point(70, 20),
          _point(120, 80),
        ]),
      );

      expect(_pathReaches(path!, const Offset(120, 80)), isTrue);
    });

    test('빈 점은 null 을 반환한다', () {
      final painter = _Painter();
      expect(painter.getSimplePathForStroke(_stroke([])), isNull);
    });

    test('단일 점은 작은 원 path 를 반환한다', () {
      final painter = _Painter();
      final path = painter.getSimplePathForStroke(_stroke([_point(5, 5)]));
      expect(path, isNotNull);
      expect(path!.getBounds().contains(const Offset(5, 5)), isTrue);
    });
  });

  group('getPathForStrokeOld (펜 outline 경로)', () {
    test('직선화된 2점 스트로크의 outline 이 끝점 근처까지 도달한다 (펜 끝점 미연결 회귀)', () {
      final painter = _Painter();
      final stroke = _stroke([_point(0, 0), _point(200, 0)])
        ..options = (StrokeOptions()..size = 4.0);

      final path = painter.getPathForStrokeOld(stroke);
      expect(path, isNotNull);

      // outline 의 우측 끝(마지막 포인트 x≈200)이 채워지는지 확인.
      // 회귀 전: 마지막 outline 점 누락으로 끝부분이 비어 bounds.right 가 짧아짐.
      expect(path!.getBounds().right, greaterThan(190));
    });
  });
}
