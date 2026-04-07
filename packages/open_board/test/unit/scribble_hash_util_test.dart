import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/core/utils/scribble_hash_util.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

Stroke _createStroke({
  List<List<double>>? points,
  int color = 0xFF000000,
  double width = 2.0,
  String ink = 'pen',
}) {
  final stroke = Stroke()
    ..color = color
    ..width = width
    ..ink = ink;

  for (final p in (points ?? [[10.0, 20.0], [30.0, 40.0], [50.0, 60.0]])) {
    stroke.points.add(Point()..x = p[0]..y = p[1]);
  }

  return stroke;
}

void main() {
  group('ScribbleHashUtil', () {
    test('동일 스트로크는 같은 해시를 가진다', () {
      final s1 = _createStroke();
      final s2 = _createStroke();

      expect(
        ScribbleHashUtil.generateStrokeHash(s1),
        equals(ScribbleHashUtil.generateStrokeHash(s2)),
      );
    });

    test('다른 좌표의 스트로크는 다른 해시를 가진다', () {
      final s1 = _createStroke(points: [[10, 20], [30, 40], [50, 60]]);
      final s2 = _createStroke(points: [[100, 200], [300, 400], [500, 600]]);

      expect(
        ScribbleHashUtil.generateStrokeHash(s1),
        isNot(equals(ScribbleHashUtil.generateStrokeHash(s2))),
      );
    });

    test('빈 스트로크의 해시는 0', () {
      final stroke = Stroke();
      expect(ScribbleHashUtil.generateStrokeHash(stroke), 0);
    });

    test('generateStrokeHashSet은 중복 없는 Set을 반환한다', () {
      final strokes = [
        _createStroke(points: [[1, 2], [3, 4], [5, 6]]),
        _createStroke(points: [[10, 20], [30, 40], [50, 60]]),
        _createStroke(points: [[1, 2], [3, 4], [5, 6]]), // 중복
      ];

      final hashSet = ScribbleHashUtil.generateStrokeHashSet(strokes);
      expect(hashSet.length, 2); // 중복 제거
    });

    test('excludeByHashes는 지정된 해시를 제외한다', () {
      final s1 = _createStroke(points: [[1, 2], [3, 4], [5, 6]]);
      final s2 = _createStroke(points: [[10, 20], [30, 40], [50, 60]]);
      final strokes = [s1, s2];

      final excludeSet = {ScribbleHashUtil.generateStrokeHash(s1)};
      final filtered = ScribbleHashUtil.excludeByHashes(
        strokes: strokes,
        excludeHashes: excludeSet,
      );

      expect(filtered.length, 1);
      expect(
        ScribbleHashUtil.generateStrokeHash(filtered.first),
        ScribbleHashUtil.generateStrokeHash(s2),
      );
    });
  });
}
