import 'dart:async';

import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

/// 스트로크 포인트를 100ms 윈도우로 배칭하여 전송하는 유틸리티
///
/// Apple Pencil은 ~6ms 간격으로 포인트를 생성한다.
/// 매 포인트마다 전송하면 네트워크 오버헤드가 크므로,
/// 100ms 윈도우 내 포인트를 모아서 한 번에 전송한다.
///
/// 플러시 조건:
/// 1. 100ms 타이머 만료
/// 2. 포인트 수가 [maxPointsPerBatch] 이상
/// 3. [finishStroke] 호출 (스트로크 종료)
class EventBatcher {
  /// 배치 윈도우 (밀리초)
  static const batchWindowMs = 100;

  /// 배치당 최대 포인트 수
  static const maxPointsPerBatch = 20;

  final void Function(StrokePointsBatch batch) _onBatchReady;

  Timer? _batchTimer;
  final List<Point> _pendingPoints = [];
  int _sequenceNum = 0;

  String? _currentPageId;
  String? _currentStrokeId;
  int _currentColor = 0;
  double _currentWidth = 1.0;
  String _currentInk = '';

  EventBatcher({required void Function(StrokePointsBatch batch) onBatchReady})
      : _onBatchReady = onBatchReady;

  /// 새로운 스트로크를 시작한다.
  void beginStroke({
    required String pageId,
    required String strokeId,
    required int color,
    required double width,
    required String ink,
  }) {
    // 이전 스트로크의 잔여 포인트 플러시
    if (_pendingPoints.isNotEmpty) {
      _flush();
    }

    _currentPageId = pageId;
    _currentStrokeId = strokeId;
    _currentColor = color;
    _currentWidth = width;
    _currentInk = ink;
    _sequenceNum = 0;
  }

  /// 포인트를 추가한다. 배칭 조건 충족 시 자동 플러시.
  void addPoint(Point point) {
    _pendingPoints.add(point);

    if (_pendingPoints.length >= maxPointsPerBatch) {
      _flush();
      return;
    }

    _batchTimer ??= Timer(
      const Duration(milliseconds: batchWindowMs),
      _flush,
    );
  }

  /// 스트로크를 종료한다. 잔여 포인트를 즉시 플러시.
  void finishStroke() {
    _flush();
    _currentPageId = null;
    _currentStrokeId = null;
  }

  void _flush() {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pendingPoints.isEmpty) return;
    if (_currentPageId == null || _currentStrokeId == null) return;

    final batch = StrokePointsBatch(
      pageId: _currentPageId!,
      strokeId: _currentStrokeId!,
      points: List.unmodifiable(_pendingPoints),
      color: _currentColor,
      width: _currentWidth,
      ink: _currentInk,
      sequenceNum: _sequenceNum++,
    );
    _pendingPoints.clear();

    _onBatchReady(batch);
  }

  /// 리소스 해제
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _pendingPoints.clear();
  }
}
