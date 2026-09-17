import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/domain/sync/late_join_synchronizer.dart';

void main() {
  group('LateJoinSynchronizer', () {
    late LateJoinSynchronizer synchronizer;
    late List<_SyncResult> completedSyncs;

    setUp(() {
      completedSyncs = [];
      synchronizer = LateJoinSynchronizer(
        onSyncComplete: (snapshot, pageIds, activePageIndex, viewport) {
          completedSyncs.add(_SyncResult(
            snapshot: snapshot,
            pageIds: pageIds,
            activePageIndex: activePageIndex,
          ));
        },
      );
    });

    tearDown(() => synchronizer.dispose());

    test('동기화 전에는 이벤트 버퍼링 안 함', () {
      final event = PageClearedEvent(pageId: 'p1', timestampMicros: 1000);
      final buffered = synchronizer.bufferEvent(event);
      expect(buffered, false);
    });

    test('beginSync 후 이벤트 버퍼링', () {
      synchronizer.beginSync();
      expect(synchronizer.isSyncing, true);

      final event = PageClearedEvent(pageId: 'p1', timestampMicros: 1000);
      final buffered = synchronizer.bufferEvent(event);
      expect(buffered, true);
      expect(synchronizer.bufferedEventCount, 1);
    });

    test('단일 청크 동기화 완료', () {
      synchronizer.beginSync();

      synchronizer.onSyncResponse(SyncResponseMessage(
        chunkIndex: 0,
        totalChunks: 1,
        scribbleSnapshot: Uint8List.fromList([1, 2, 3]),
        pageIds: ['p1', 'p2'],
        activePageIndex: 0,
        snapshotTimestamp: 5000,
      ));

      expect(completedSyncs, hasLength(1));
      expect(completedSyncs[0].snapshot, [1, 2, 3]);
      expect(completedSyncs[0].pageIds, ['p1', 'p2']);
    });

    test('다중 청크 조립', () {
      synchronizer.beginSync();

      synchronizer.onSyncResponse(SyncResponseMessage(
        chunkIndex: 0,
        totalChunks: 3,
        scribbleSnapshot: Uint8List.fromList([1, 2]),
        pageIds: [],
        activePageIndex: 0,
        snapshotTimestamp: 5000,
      ));

      expect(completedSyncs, isEmpty); // 아직 완료 아님

      synchronizer.onSyncResponse(SyncResponseMessage(
        chunkIndex: 1,
        totalChunks: 3,
        scribbleSnapshot: Uint8List.fromList([3, 4]),
        pageIds: [],
        activePageIndex: 0,
        snapshotTimestamp: 5000,
      ));

      expect(completedSyncs, isEmpty);

      synchronizer.onSyncResponse(SyncResponseMessage(
        chunkIndex: 2,
        totalChunks: 3,
        scribbleSnapshot: Uint8List.fromList([5, 6]),
        pageIds: ['p1'],
        activePageIndex: 0,
        snapshotTimestamp: 5000,
      ));

      expect(completedSyncs, hasLength(1));
      expect(completedSyncs[0].snapshot, [1, 2, 3, 4, 5, 6]);
    });

    test('flushBuffer는 snapshotTimestamp 이후 이벤트만 반환', () {
      synchronizer.beginSync();

      // 스냅샷 이전 이벤트
      synchronizer.bufferEvent(
        PageClearedEvent(pageId: 'p1', timestampMicros: 3000),
      );
      // 스냅샷 이후 이벤트
      synchronizer.bufferEvent(
        PageClearedEvent(pageId: 'p2', timestampMicros: 7000),
      );

      synchronizer.onSyncResponse(SyncResponseMessage(
        chunkIndex: 0,
        totalChunks: 1,
        scribbleSnapshot: Uint8List(0),
        pageIds: ['p1'],
        activePageIndex: 0,
        snapshotTimestamp: 5000,
      ));

      final events = synchronizer.flushBuffer();
      expect(events, hasLength(1));
      expect(events[0].timestampMicros, 7000);
      expect(synchronizer.isSyncing, false);
    });
  });
}

class _SyncResult {
  final Uint8List snapshot;
  final List<String> pageIds;
  final int activePageIndex;

  _SyncResult({
    required this.snapshot,
    required this.pageIds,
    required this.activePageIndex,
  });
}
