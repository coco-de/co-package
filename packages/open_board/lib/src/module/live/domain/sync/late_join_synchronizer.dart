import 'dart:collection';
import 'dart:typed_data';

import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

/// 늦은 참가자 동기화 관리자
///
/// 학생이 중간에 입장하거나 재접속할 때 현재 상태를 동기화한다.
///
/// 동기화 흐름:
/// 1. [beginSync] → 동기화 시작, 이벤트 버퍼링 활성화
/// 2. 원격 이벤트는 [bufferEvent]로 큐에 저장
/// 3. [onSyncResponse]로 스냅샷 청크 수집
/// 4. 모든 청크 도착 → [onSyncComplete] 콜백 호출
/// 5. 스냅샷 적용 후 [flushBuffer]로 버퍼링된 이벤트 적용
class LateJoinSynchronizer {
  final void Function(Uint8List snapshot, List<String> pageIds,
      int activePageIndex, ViewportMessage? viewport) _onSyncComplete;

  bool _isSyncing = false;
  final Queue<ScribbleBookEvent> _eventBuffer = Queue();
  final Map<int, SyncResponseMessage> _chunks = {};
  int _expectedTotalChunks = 0;
  int _snapshotTimestamp = 0;

  LateJoinSynchronizer({
    required void Function(Uint8List snapshot, List<String> pageIds,
            int activePageIndex, ViewportMessage? viewport)
        onSyncComplete,
  }) : _onSyncComplete = onSyncComplete;

  /// 동기화 중 여부
  bool get isSyncing => _isSyncing;

  /// 버퍼된 이벤트 수
  int get bufferedEventCount => _eventBuffer.length;

  /// 동기화 시작
  void beginSync() {
    _isSyncing = true;
    _eventBuffer.clear();
    _chunks.clear();
    _expectedTotalChunks = 0;
    _snapshotTimestamp = 0;
  }

  /// 동기화 중 이벤트 버퍼링
  ///
  /// 동기화 중이면 버퍼에 저장, 아니면 false 반환하여 즉시 적용하도록 한다.
  bool bufferEvent(ScribbleBookEvent event) {
    if (!_isSyncing) return false;
    _eventBuffer.add(event);
    return true;
  }

  /// 동기화 응답 청크 수신
  void onSyncResponse(SyncResponseMessage response) {
    _chunks[response.chunkIndex] = response;
    _expectedTotalChunks = response.totalChunks;
    _snapshotTimestamp = response.snapshotTimestamp;

    if (response.isLastChunk && response.pageIds.isNotEmpty) {
      // 마지막 청크에만 메타데이터가 있음
    }

    // 모든 청크가 도착했는지 확인
    if (_chunks.length == _expectedTotalChunks) {
      _assembleAndComplete();
    }
  }

  /// 버퍼링된 이벤트를 반환 (snapshotTimestamp 이후만)
  ///
  /// 호출자가 스냅샷 적용 후 이 이벤트들을 순차 적용해야 한다.
  List<ScribbleBookEvent> flushBuffer() {
    _isSyncing = false;

    final events = _eventBuffer
        .where((e) => e.timestampMicros > _snapshotTimestamp)
        .toList();
    _eventBuffer.clear();

    return events;
  }

  void _assembleAndComplete() {
    // 청크를 순서대로 조립
    final sortedChunks = _chunks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final totalBytes = sortedChunks.fold<int>(
        0, (sum, e) => sum + e.value.scribbleSnapshot.length);
    final assembled = Uint8List(totalBytes);
    var offset = 0;

    for (final entry in sortedChunks) {
      final chunk = entry.value.scribbleSnapshot;
      assembled.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // 마지막 청크에서 메타데이터 추출
    final lastChunk = sortedChunks.last.value;

    _onSyncComplete(
      assembled,
      lastChunk.pageIds,
      lastChunk.activePageIndex,
      lastChunk.lastViewport,
    );
  }

  void dispose() {
    _eventBuffer.clear();
    _chunks.clear();
  }
}
