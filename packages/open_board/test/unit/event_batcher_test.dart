import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/live/domain/batcher/event_batcher.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

void main() {
  group('EventBatcher', () {
    late EventBatcher batcher;
    late List<StrokePointsBatch> emittedBatches;

    setUp(() {
      emittedBatches = [];
      batcher = EventBatcher(
        onBatchReady: emittedBatches.add,
      );
    });

    tearDown(() => batcher.dispose());

    test('beginStroke 전에는 addPoint가 배치를 생성하지 않음', () {
      fakeAsync((async) {
        batcher.addPoint(Point(x: 1, y: 1));
        async.elapse(const Duration(milliseconds: 200));
        expect(emittedBatches, isEmpty);
      });
    });

    test('100ms 타이머 만료 시 배치를 플러시', () {
      fakeAsync((async) {
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's1',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        batcher.addPoint(Point(x: 10, y: 20));
        batcher.addPoint(Point(x: 11, y: 21));

        expect(emittedBatches, isEmpty);

        async.elapse(const Duration(milliseconds: 100));

        expect(emittedBatches, hasLength(1));
        expect(emittedBatches[0].pageId, 'p1');
        expect(emittedBatches[0].strokeId, 's1');
        expect(emittedBatches[0].points, hasLength(2));
        expect(emittedBatches[0].sequenceNum, 0);
        expect(emittedBatches[0].color, 0xFF000000);
        expect(emittedBatches[0].width, 2.0);
        expect(emittedBatches[0].ink, 'pen');
      });
    });

    test('maxPointsPerBatch 도달 시 즉시 플러시', () {
      fakeAsync((async) {
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's1',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        for (var i = 0; i < EventBatcher.maxPointsPerBatch; i++) {
          batcher.addPoint(Point(x: i.toDouble(), y: i.toDouble()));
        }

        // 타이머 대기 없이 즉시 플러시
        expect(emittedBatches, hasLength(1));
        expect(emittedBatches[0].points, hasLength(EventBatcher.maxPointsPerBatch));
        expect(emittedBatches[0].sequenceNum, 0);
      });
    });

    test('finishStroke 호출 시 잔여 포인트 즉시 플러시', () {
      fakeAsync((async) {
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's1',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        batcher.addPoint(Point(x: 1, y: 1));
        batcher.addPoint(Point(x: 2, y: 2));

        expect(emittedBatches, isEmpty);

        batcher.finishStroke();

        expect(emittedBatches, hasLength(1));
        expect(emittedBatches[0].points, hasLength(2));
      });
    });

    test('sequenceNum이 배치마다 증가', () {
      fakeAsync((async) {
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's1',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        // 첫 번째 배치
        for (var i = 0; i < EventBatcher.maxPointsPerBatch; i++) {
          batcher.addPoint(Point(x: i.toDouble(), y: i.toDouble()));
        }
        expect(emittedBatches[0].sequenceNum, 0);

        // 두 번째 배치
        for (var i = 0; i < EventBatcher.maxPointsPerBatch; i++) {
          batcher.addPoint(Point(x: i.toDouble(), y: i.toDouble()));
        }
        expect(emittedBatches[1].sequenceNum, 1);
      });
    });

    test('beginStroke 재호출 시 이전 잔여 포인트 플러시', () {
      fakeAsync((async) {
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's1',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        batcher.addPoint(Point(x: 1, y: 1));

        // 새 스트로크 시작 → 이전 잔여 포인트 플러시
        batcher.beginStroke(
          pageId: 'p1',
          strokeId: 's2',
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
        );

        expect(emittedBatches, hasLength(1));
        expect(emittedBatches[0].strokeId, 's1');
      });
    });
  });
}
