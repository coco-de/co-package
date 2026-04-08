import 'dart:typed_data';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// 진행 중인 스트로크 포인트 배치 (Lossy 채널)
class StrokePointsBatch {
  final String pageId;
  final String strokeId;
  final List<Point> points;
  final int color;
  final double width;
  final String ink;
  final int sequenceNum;

  const StrokePointsBatch({
    required this.pageId,
    required this.strokeId,
    required this.points,
    required this.color,
    required this.width,
    required this.ink,
    required this.sequenceNum,
  });

  @override
  String toString() =>
      'StrokePointsBatch(page=$pageId, stroke=$strokeId, '
      'points=${points.length}, seq=$sequenceNum)';
}

/// 완료된 스트로크 메시지 (Reliable 채널)
class StrokeCompleteMessage {
  final String pageId;
  final String strokeId;
  final Stroke stroke;
  final int strokeIndex;
  final int timestampMicros;

  const StrokeCompleteMessage({
    required this.pageId,
    required this.strokeId,
    required this.stroke,
    required this.strokeIndex,
    required this.timestampMicros,
  });

  @override
  String toString() =>
      'StrokeCompleteMessage(page=$pageId, idx=$strokeIndex, '
      't=$timestampMicros)';
}

/// 뷰포트 메시지 (Lossy 채널)
class ViewportMessage {
  final String pageId;
  final double scale;
  final double centerX;
  final double centerY;
  final double viewportWidth;
  final double viewportHeight;
  final int timestampMicros;

  const ViewportMessage({
    required this.pageId,
    required this.scale,
    required this.centerX,
    required this.centerY,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.timestampMicros,
  });

  @override
  String toString() =>
      'ViewportMessage(page=$pageId, scale=$scale, '
      'center=($centerX,$centerY), t=$timestampMicros)';
}

/// 동기화 요청 메시지 (Reliable 채널)
class SyncRequestMessage {
  final String participantId;
  final int requestTimestamp;

  const SyncRequestMessage({
    required this.participantId,
    required this.requestTimestamp,
  });

  @override
  String toString() =>
      'SyncRequestMessage($participantId, t=$requestTimestamp)';
}

/// 동기화 응답 메시지 (Reliable 채널, 분할 전송)
class SyncResponseMessage {
  final int chunkIndex;
  final int totalChunks;
  final Uint8List scribbleSnapshot;
  final List<String> pageIds;
  final int activePageIndex;
  final ViewportMessage? lastViewport;
  final int snapshotTimestamp;

  const SyncResponseMessage({
    required this.chunkIndex,
    required this.totalChunks,
    required this.scribbleSnapshot,
    required this.pageIds,
    required this.activePageIndex,
    this.lastViewport,
    required this.snapshotTimestamp,
  });

  bool get isLastChunk => chunkIndex == totalChunks - 1;

  @override
  String toString() =>
      'SyncResponseMessage(chunk=${chunkIndex + 1}/$totalChunks, '
      'pages=${pageIds.length})';
}
