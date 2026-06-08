import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/module/events/scribble_book_event.dart';
import 'package:open_board/src/module/replay/scribble_replay_controller.dart';

/// 테스트용 타임라인 생성
List<ScribbleBookEvent> _createTimeline({
  int startMicros = 1000000, // 1초
  int count = 10,
  int intervalMicros = 1000000, // 1초 간격
}) {
  final events = <ScribbleBookEvent>[];
  for (var i = 0; i < count; i++) {
    events.add(
      PageChangedEvent(
        fromIndex: i,
        toIndex: i + 1,
        fromPageId: 'page$i',
        toPageId: 'page${i + 1}',
        timestampMicros: startMicros + (i * intervalMicros),
      ),
    );
  }
  return events;
}

void main() {
  group('ScribbleReplayController', () {
    late ScribbleReplayController replay;

    setUp(() {
      replay = ScribbleReplayController();
    });

    tearDown(() => replay.dispose());

    group('초기 상태', () {
      test('idle 상태로 시작', () {
        expect(replay.state, ReplayState.idle);
        expect(replay.isPlaying, isFalse);
        expect(replay.eventCount, 0);
        expect(replay.durationMicros, 0);
      });
    });

    group('타임라인 로드', () {
      test('loadTimeline 후 paused 상태', () {
        replay.loadTimeline(_createTimeline());

        expect(replay.state, ReplayState.paused);
        expect(replay.eventCount, 10);
        expect(replay.currentIndex, 0);
      });

      test('빈 타임라인 로드 시 idle 유지', () {
        replay.loadTimeline([]);

        expect(replay.state, ReplayState.idle);
        expect(replay.eventCount, 0);
      });

      test('duration이 올바르게 계산된다', () {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 5,
            intervalMicros: 2000000, // 2초 간격
          ),
        );

        // 0, 2, 4, 6, 8 → duration = 8초 = 8000000μs
        expect(replay.durationMicros, 8000000);
        expect(replay.duration, const Duration(seconds: 8));
      });

      test('타임라인이 시간순으로 정렬된다', () {
        final unordered = [
          PageChangedEvent(
            fromIndex: 0,
            toIndex: 1,
            fromPageId: 'a',
            toPageId: 'b',
            timestampMicros: 3000000,
          ),
          PageChangedEvent(
            fromIndex: 1,
            toIndex: 2,
            fromPageId: 'b',
            toPageId: 'c',
            timestampMicros: 1000000,
          ),
        ];

        replay.loadTimeline(unordered);
        expect(replay.eventCount, 2);
        // 첫 이벤트의 시작 시각이 올바르게 설정됨
        expect(replay.durationMicros, 2000000);
      });
    });

    group('재생 제어', () {
      setUp(() {
        replay.loadTimeline(_createTimeline());
      });

      test('play 호출 시 playing 상태', () {
        replay.play();

        expect(replay.state, ReplayState.playing);
        expect(replay.isPlaying, isTrue);
      });

      test('pause 호출 시 paused 상태', () {
        replay.play();
        replay.pause();

        expect(replay.state, ReplayState.paused);
        expect(replay.isPlaying, isFalse);
      });

      test('빈 타임라인에서 play 무시', () {
        final emptyReplay = ScribbleReplayController();
        emptyReplay.play();

        expect(emptyReplay.state, ReplayState.idle);

        emptyReplay.dispose();
      });

      test('paused 상태에서 pause 호출 무시', () {
        replay.pause(); // 이미 paused

        expect(replay.state, ReplayState.paused);
      });
    });

    group('속도 제어', () {
      test('기본 속도는 1.0', () {
        expect(replay.speed, 1.0);
      });

      test('setSpeed로 속도 변경', () {
        replay.setSpeed(2.0);
        expect(replay.speed, 2.0);
      });

      test('0 이하 속도는 assert 에러', () {
        expect(() => replay.setSpeed(0), throwsA(isA<AssertionError>()));
        expect(() => replay.setSpeed(-1), throwsA(isA<AssertionError>()));
      });
    });

    group('seek', () {
      setUp(() {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 10,
            intervalMicros: 1000000,
          ),
        );
      });

      test('seek 후 위치가 변경된다', () {
        replay.seek(const Duration(seconds: 5));

        expect(replay.positionMicros, 5000000);
      });

      test('seek으로 범위 밖 위치는 clamping', () {
        replay.seek(const Duration(seconds: 100));
        expect(replay.positionMicros, replay.durationMicros);

        replay.seek(const Duration(seconds: -5));
        expect(replay.positionMicros, 0);
      });
    });

    group('이벤트 발행', () {
      test('play 시 이벤트가 스트림으로 발행된다', () async {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 3,
            intervalMicros: 10000, // 10ms 간격 (빠른 테스트용)
          ),
        );

        final events = <ScribbleBookEvent>[];
        replay.onEvent.listen(events.add);

        replay.play();

        // 이벤트 발행 대기
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(events, isNotEmpty);
        expect(events.first, isA<PageChangedEvent>());
      });

      test('seek 시 이전 이벤트가 빠르게 발행된다', () async {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 5,
            intervalMicros: 1000000,
          ),
        );

        final events = <ScribbleBookEvent>[];
        replay.onEvent.listen(events.add);

        // 3초 지점으로 seek → 0,1,2,3초 이벤트 발행
        replay.seek(const Duration(seconds: 3));
        await pumpEventQueue();

        expect(events.length, 4); // index 0,1,2,3
      });
    });

    group('위치 스트림', () {
      test('onPositionChanged로 위치를 구독할 수 있다', () async {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 3,
            intervalMicros: 10000,
          ),
        );

        final positions = <int>[];
        replay.onPositionChanged.listen(positions.add);

        replay.play();
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(positions, isNotEmpty);
      });
    });

    group('syncTo', () {
      test('syncTo는 seek의 alias', () {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 10,
            intervalMicros: 1000000,
          ),
        );

        replay.syncTo(const Duration(seconds: 5));
        expect(replay.positionMicros, 5000000);
      });
    });

    group('completed 상태에서 재시작', () {
      test('completed 후 play하면 처음부터 재생', () async {
        replay.loadTimeline(
          _createTimeline(
            startMicros: 0,
            count: 2,
            intervalMicros: 10000,
          ),
        );

        replay.play();
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(replay.state, ReplayState.completed);

        // 재시작
        replay.play();
        expect(replay.state, ReplayState.playing);
        expect(replay.currentIndex, 0);
      });
    });

    group('ReplaySnapshot', () {
      test('생성 확인', () {
        const snapshot = ReplaySnapshot(
          eventIndex: 5,
          offsetMicros: 5000000,
        );

        expect(snapshot.eventIndex, 5);
        expect(snapshot.offsetMicros, 5000000);
      });
    });
  });
}
