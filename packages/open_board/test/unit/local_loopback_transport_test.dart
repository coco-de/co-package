import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/live/data/transport/local_loopback_transport.dart';
import 'package:open_board/src/module/live/domain/model/transport_message.dart';
import 'package:open_board/src/module/live/domain/model/transport_state.dart';

void main() {
  group('LocalLoopbackTransport', () {
    late LocalLoopbackTransport teacher;
    late LocalLoopbackTransport student;

    setUp(() {
      teacher = LocalLoopbackTransport(latency: Duration.zero);
      student = LocalLoopbackTransport(latency: Duration.zero);
      teacher.linkPeer(student);
    });

    tearDown(() {
      teacher.dispose();
      student.dispose();
    });

    test('connect/disconnect 상태 전이', () async {
      final states = <TransportConnectionState>[];
      teacher.connectionState.listen(states.add);

      await teacher.connect('session-1', 'token-teacher');
      // Duration.zero도 microtask 스케줄링이 필요
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        TransportConnectionState.connecting,
        TransportConnectionState.connected,
      ]);

      await teacher.disconnect();

      expect(states.last, TransportConnectionState.disconnected);
    });

    test('sendEvent가 피어에게 전달됨', () async {
      await teacher.connect('s1', 't1');
      await student.connect('s1', 't2');

      final received = <ScribbleBookEvent>[];
      student.remoteEvents.listen(received.add);

      teacher.sendEvent(PageClearedEvent(
        pageId: 'p1',
        timestampMicros: 1000,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received[0], isA<PageClearedEvent>());
    });

    test('sendStrokePoints가 피어에게 전달됨', () async {
      await teacher.connect('s1', 't1');
      await student.connect('s1', 't2');

      final received = <StrokePointsBatch>[];
      student.remoteStrokePoints.listen(received.add);

      teacher.sendStrokePoints(StrokePointsBatch(
        pageId: 'p1',
        strokeId: 'stroke-1',
        points: [Point(x: 10, y: 20)],
        color: 0xFF000000,
        width: 2.0,
        ink: 'pen',
        sequenceNum: 0,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received[0].points, hasLength(1));
    });

    test('sendStrokeComplete가 피어에게 전달됨', () async {
      await teacher.connect('s1', 't1');
      await student.connect('s1', 't2');

      final received = <StrokeCompleteMessage>[];
      student.remoteStrokeCompletes.listen(received.add);

      teacher.sendStrokeComplete(StrokeCompleteMessage(
        pageId: 'p1',
        strokeId: 'stroke-1',
        stroke: Stroke(),
        strokeIndex: 0,
        timestampMicros: 1000,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received[0].strokeIndex, 0);
    });

    test('sendViewport가 피어에게 전달됨', () async {
      await teacher.connect('s1', 't1');
      await student.connect('s1', 't2');

      final received = <ViewportMessage>[];
      student.remoteViewports.listen(received.add);

      teacher.sendViewport(ViewportMessage(
        pageId: 'p1',
        scale: 2.0,
        centerX: 100,
        centerY: 200,
        viewportWidth: 800,
        viewportHeight: 600,
        timestampMicros: 1000,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received[0].scale, 2.0);
    });

    test('sync request/response 양방향 동작', () async {
      await teacher.connect('s1', 't1');
      await student.connect('s1', 't2');

      final requests = <SyncRequestMessage>[];
      teacher.syncRequests.listen(requests.add);

      final responses = <SyncResponseMessage>[];
      student.syncResponses.listen(responses.add);

      // 학생이 동기화 요청
      await student.requestSync(SyncRequestMessage(
        participantId: 'student-1',
        requestTimestamp: 1000,
      ));

      await Future<void>.delayed(Duration.zero);
      expect(requests, hasLength(1));
      expect(requests[0].participantId, 'student-1');

      // 선생님이 응답
      await teacher.sendSyncResponse(SyncResponseMessage(
        chunkIndex: 0,
        totalChunks: 1,
        scribbleSnapshot: Uint8List(0),
        pageIds: ['p1'],
        activePageIndex: 0,
        snapshotTimestamp: 2000,
      ));

      await Future<void>.delayed(Duration.zero);
      expect(responses, hasLength(1));
      expect(responses[0].pageIds, ['p1']);
    });

    group('네트워크 시뮬레이션', () {
      test('freezeConnection 시 Reliable 메시지 큐잉', () async {
        await teacher.connect('s1', 't1');
        await student.connect('s1', 't2');

        final received = <ScribbleBookEvent>[];
        student.remoteEvents.listen(received.add);

        teacher.freezeConnection();

        teacher.sendEvent(PageClearedEvent(
          pageId: 'p1',
          timestampMicros: 1000,
        ));
        teacher.sendEvent(PageClearedEvent(
          pageId: 'p2',
          timestampMicros: 2000,
        ));

        await Future<void>.delayed(Duration.zero);
        expect(received, isEmpty); // freeze 중에는 도달하지 않음

        teacher.resumeConnection();
        await Future<void>.delayed(Duration.zero);

        expect(received, hasLength(2)); // 큐에 쌓였던 메시지 전달
      });

      test('freezeConnection 시 Lossy 메시지 드롭', () async {
        await teacher.connect('s1', 't1');
        await student.connect('s1', 't2');

        final received = <StrokePointsBatch>[];
        student.remoteStrokePoints.listen(received.add);

        teacher.freezeConnection();

        teacher.sendStrokePoints(StrokePointsBatch(
          pageId: 'p1',
          strokeId: 's1',
          points: [Point(x: 1, y: 1)],
          color: 0xFF000000,
          width: 2.0,
          ink: 'pen',
          sequenceNum: 0,
        ));

        teacher.resumeConnection();
        await Future<void>.delayed(Duration.zero);

        expect(received, isEmpty); // Lossy는 freeze 중 드롭
      });
    });
  });
}
