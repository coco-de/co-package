import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';

/// 원격 스트로크 점진적 렌더링
///
/// Lossy 채널로 수신되는 [StrokePointsBatch]를 임시 스트로크로 점진적 렌더링하고,
/// Reliable 채널로 [StrokeCompleteMessage] 수신 시 전체 Stroke로 교체한다.
///
/// 렌더링 흐름:
/// 1. [appendPoints] → 임시 스트로크에 포인트 추가 → [onStrokesChanged] 콜백
/// 2. [finalizeStroke] → 임시 스트로크를 완전한 Stroke로 교체
///
/// 패킷 손실 처리:
/// - Lossy 포인트가 일부 누락되어도 임시 스트로크는 수신된 포인트만으로 렌더링
/// - [finalizeStroke] 시 전체 포인트를 가진 완전한 Stroke로 교체하므로 최종 상태는 정확
class RemoteStrokeRenderer {
  /// 진행 중인 원격 스트로크 (strokeId → 임시 Stroke)
  final Map<String, _InProgressStroke> _inProgressStrokes = {};

  /// 스트로크 변경 시 호출되는 콜백
  ///
  /// 페이지에 표시할 추가 스트로크 목록을 전달한다.
  /// 호출자는 이 스트로크를 기존 Scribble 위에 오버레이 렌더링해야 한다.
  final void Function(String pageId) _onStrokesChanged;

  RemoteStrokeRenderer({
    required void Function(String pageId) onStrokesChanged,
  }) : _onStrokesChanged = onStrokesChanged;

  /// 페이지별 진행 중인 원격 스트로크 목록
  ///
  /// UI에서 이 스트로크들을 기존 캔버스 위에 오버레이 렌더링한다.
  List<Stroke> getInProgressStrokes(String pageId) {
    return _inProgressStrokes.entries
        .where((e) => e.value.pageId == pageId)
        .map((e) => e.value.stroke)
        .toList();
  }

  /// Lossy 포인트 배치를 수신하여 임시 스트로크에 추가
  void appendPoints(StrokePointsBatch batch) {
    var inProgress = _inProgressStrokes[batch.strokeId];

    if (inProgress == null) {
      // 새로운 원격 스트로크 시작
      final stroke = Stroke()
        ..color = batch.color
        ..width = batch.width
        ..ink = batch.ink;

      inProgress = _InProgressStroke(
        pageId: batch.pageId,
        stroke: stroke,
        lastSequenceNum: -1,
      );
      _inProgressStrokes[batch.strokeId] = inProgress;
    }

    // 순서 역전된 패킷은 무시 (Lossy 특성상 가능)
    if (batch.sequenceNum <= inProgress.lastSequenceNum) return;
    inProgress.lastSequenceNum = batch.sequenceNum;

    // 포인트 추가
    inProgress.stroke.points.addAll(batch.points);

    _onStrokesChanged(batch.pageId);
  }

  /// Reliable 완료 메시지를 수신하여 임시 스트로크를 전체 Stroke로 교체
  ///
  /// 반환값: 완성된 Stroke와 메타데이터. 호출자가 ScribbleController에 적용.
  FinalizedStroke? finalizeStroke(StrokeCompleteMessage message) {
    // 임시 스트로크 제거
    _inProgressStrokes.remove(message.strokeId);

    _onStrokesChanged(message.pageId);

    return FinalizedStroke(
      pageId: message.pageId,
      stroke: message.stroke,
      strokeIndex: message.strokeIndex,
      timestampMicros: message.timestampMicros,
    );
  }

  /// 모든 진행 중 스트로크 초기화 (페이지 전환, 동기화 등)
  void clearPage(String pageId) {
    _inProgressStrokes.removeWhere((_, v) => v.pageId == pageId);
  }

  /// 전체 초기화
  void clearAll() {
    _inProgressStrokes.clear();
  }

  void dispose() {
    _inProgressStrokes.clear();
  }
}

class _InProgressStroke {
  final String pageId;
  final Stroke stroke;
  int lastSequenceNum;

  _InProgressStroke({
    required this.pageId,
    required this.stroke,
    required this.lastSequenceNum,
  });
}

/// 완성된 원격 스트로크 정보
class FinalizedStroke {
  final String pageId;
  final Stroke stroke;
  final int strokeIndex;
  final int timestampMicros;

  const FinalizedStroke({
    required this.pageId,
    required this.stroke,
    required this.strokeIndex,
    required this.timestampMicros,
  });
}
