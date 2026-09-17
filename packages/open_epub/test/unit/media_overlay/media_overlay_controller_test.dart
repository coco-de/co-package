// Story: S15.2 (#109) — MediaOverlayController par 시퀀싱 테스트 (fake player)
// gap #6 재생분

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

void main() {
  group('MediaOverlayController — par 시퀀싱 (S15.2)', () {
    late FakeMediaAudioPlayer player;
    late MediaOverlayController controller;

    setUp(() {
      player = FakeMediaAudioPlayer();
      controller = MediaOverlayController(player: player);
    });

    tearDown(() => controller.dispose());

    test('start → par0 활성, load 1회, clipBegin seek, play', () async {
      await controller.start(_overlay2SameFile(), loadAudio: _bytesLoader);
      expect(controller.activeParIndex.value, 0);
      expect(controller.state, MediaOverlayState.playing);
      expect(player.loads, hasLength(1));
      expect(player.seeks, [Duration.zero]);
      expect(player.playCount, 1);
    });

    test('clipEnd 도달 → 다음 par로 auto-advance (같은 파일=재로드 없음, seek만)', () async {
      await controller.start(_overlay2SameFile(), loadAudio: _bytesLoader);
      // par0 clipEnd=2.5s 도달
      player.emitPosition(const Duration(milliseconds: 2500));
      await pumpEventQueue();

      expect(controller.activeParIndex.value, 1);
      expect(player.loads, hasLength(1)); // 같은 오디오 → 재로드 없음
      expect(
          player.seeks.last, const Duration(milliseconds: 2500)); // clipBegin1
    });

    test('마지막 par clipEnd 도달 → stop (활성 -1, idle, pause)', () async {
      await controller.start(_overlay2SameFile(), loadAudio: _bytesLoader);
      player.emitPosition(const Duration(milliseconds: 2500)); // → par1
      await pumpEventQueue();
      player.emitPosition(const Duration(seconds: 5)); // par1 clipEnd
      await pumpEventQueue();

      expect(controller.activeParIndex.value, -1);
      expect(controller.state, MediaOverlayState.idle);
      expect(player.pauseCount, greaterThanOrEqualTo(1));
    });

    test('파일이 다른 par는 재로드', () async {
      await controller.start(_overlay2DiffFiles(), loadAudio: _bytesLoader);
      player.emitPosition(const Duration(seconds: 2));
      await pumpEventQueue();
      expect(controller.activeParIndex.value, 1);
      expect(player.loads, hasLength(2)); // 다른 오디오 → 재로드
    });

    test('pause/resume 상태 전환', () async {
      await controller.start(_overlay2SameFile(), loadAudio: _bytesLoader);
      await controller.pause();
      expect(controller.state, MediaOverlayState.paused);
      await controller.resume();
      expect(controller.state, MediaOverlayState.playing);
    });

    test('일시정지 중 position 이벤트는 advance하지 않음', () async {
      await controller.start(_overlay2SameFile(), loadAudio: _bytesLoader);
      await controller.pause();
      player.emitPosition(const Duration(seconds: 3));
      await pumpEventQueue();
      expect(controller.activeParIndex.value, 0); // 그대로
    });

    test('빈 오버레이 start는 no-op', () async {
      await controller.start(EpubMediaOverlay.empty, loadAudio: _bytesLoader);
      expect(controller.state, MediaOverlayState.idle);
      expect(controller.activeParIndex.value, -1);
      expect(player.loads, isEmpty);
    });

    test('from 인덱스로 중간 par부터 시작', () async {
      await controller.start(_overlay2SameFile(),
          loadAudio: _bytesLoader, from: 1);
      expect(controller.activeParIndex.value, 1);
      expect(player.seeks.last, const Duration(milliseconds: 2500));
    });

    test('오디오 로드 실패(null) par는 건너뜀', () async {
      await controller.start(
        _overlay2SameFile(),
        loadAudio: (src) async => null, // 항상 실패
      );
      await pumpEventQueue();
      // 두 par 모두 로드 실패 → 끝까지 건너뛰고 정지
      expect(controller.state, MediaOverlayState.idle);
      expect(controller.activeParIndex.value, -1);
    });
  });
}

// -------- helpers --------

Future<Uint8List?> _bytesLoader(String src) async =>
    Uint8List.fromList([1, 2, 3]);

EpubMediaOverlay _overlay2SameFile() => const EpubMediaOverlay(pars: [
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s1',
        audioSrc: 'audio/ch1.mp3',
        clipBegin: Duration.zero,
        clipEnd: Duration(milliseconds: 2500),
      ),
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s2',
        audioSrc: 'audio/ch1.mp3',
        clipBegin: Duration(milliseconds: 2500),
        clipEnd: Duration(seconds: 5),
      ),
    ]);

EpubMediaOverlay _overlay2DiffFiles() => const EpubMediaOverlay(pars: [
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s1',
        audioSrc: 'audio/a.mp3',
        clipBegin: Duration.zero,
        clipEnd: Duration(seconds: 2),
      ),
      EpubMediaPar(
        textSrc: 'ch1.xhtml#s2',
        audioSrc: 'audio/b.mp3',
        clipBegin: Duration.zero,
        clipEnd: Duration(seconds: 2),
      ),
    ]);

class FakeMediaAudioPlayer implements MediaAudioPlayer {
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();
  final List<int> loads = [];
  final List<Duration> seeks = [];
  int playCount = 0;
  int pauseCount = 0;
  bool disposed = false;

  void emitPosition(Duration d) => _positions.add(d);

  @override
  Future<void> load(Uint8List bytes,
      {String contentType = 'audio/mpeg'}) async {
    loads.add(bytes.length);
  }

  @override
  Future<void> play() async => playCount++;

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positions.close();
  }
}
