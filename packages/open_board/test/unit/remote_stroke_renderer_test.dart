import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/live/data/renderer/remote_stroke_renderer.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

void main() {
  group('RemoteStrokeRenderer', () {
    late RemoteStrokeRenderer renderer;
    late List<String> changedPages;

    setUp(() {
      changedPages = [];
      renderer = RemoteStrokeRenderer(
        onStrokesChanged: changedPages.add,
      );
    });

    tearDown(() => renderer.dispose());

    test('appendPoints로 임시 스트로크 생성', () {
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 10, y: 20), Point(x: 11, y: 21)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      final strokes = renderer.getInProgressStrokes('p1');
      expect(strokes, hasLength(1));
      expect(strokes[0].points, hasLength(2));
      expect(changedPages, ['p1']);
    });

    test('추가 배치로 포인트 누적', () {
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 10, y: 20)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 11, y: 21), Point(x: 12, y: 22)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 1,
      ));

      final strokes = renderer.getInProgressStrokes('p1');
      expect(strokes[0].points, hasLength(3));
    });

    test('순서 역전 패킷 무시', () {
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 10, y: 20)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 1,
      ));

      // 이전 sequence → 무시
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 99, y: 99)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      final strokes = renderer.getInProgressStrokes('p1');
      expect(strokes[0].points, hasLength(1));
      expect(strokes[0].points[0].x, 10);
    });

    test('finalizeStroke로 임시 스트로크 제거 및 완성 반환', () {
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 10, y: 20)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      expect(renderer.getInProgressStrokes('p1'), hasLength(1));

      final finalized = renderer.finalizeStroke(StrokeCompleteMessage(
        pageId: 'p1',
        strokeId: 's1',
        stroke: Stroke(points: [Point(x: 10, y: 20), Point(x: 11, y: 21)]),
        strokeIndex: 0,
        timestampMicros: 1000,
      ));

      expect(renderer.getInProgressStrokes('p1'), isEmpty);
      expect(finalized, isNotNull);
      expect(finalized!.stroke.points, hasLength(2));
      expect(finalized.strokeIndex, 0);
    });

    test('다른 페이지 스트로크 독립 관리', () {
      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 's1',
        points: [Point(x: 1, y: 1)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      renderer.appendPoints(StrokePointsBatch(
        pageId: 'p2',
        strokeId: 's2',
        points: [Point(x: 2, y: 2)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      expect(renderer.getInProgressStrokes('p1'), hasLength(1));
      expect(renderer.getInProgressStrokes('p2'), hasLength(1));

      renderer.clearPage('p1');

      expect(renderer.getInProgressStrokes('p1'), isEmpty);
      expect(renderer.getInProgressStrokes('p2'), hasLength(1));
    });
  });
}
