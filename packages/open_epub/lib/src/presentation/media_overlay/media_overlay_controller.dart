// Presentation — Media Overlays (open_epub 1.0)
// Story: S15.2 (#109) — MO 재생 컨트롤러 (par 시퀀싱 auto-advance) (gap #6 재생분)
//
// [EpubMediaOverlay]의 par 시퀀스를 오디오로 재생한다. 각 par의 clipBegin으로
// seek 후 재생하고, [MediaAudioPlayer.positionStream]을 감시해 clipEnd 도달 시
// 다음 par로 자동 전환한다. 같은 오디오 파일을 공유하는 par는 재로드 없이 seek만
// 한다. 활성 par 인덱스는 [activeParIndex]로 노출해 낭독 하이라이트(S15.3)가
// 구독한다.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:open_epub_engine/open_epub_engine.dart';

import 'media_audio_player.dart';

/// par.audioSrc(OPF 기준 상대) → 오디오 바이트 로더. 리더가
/// `session.resources.readBytes`를 래핑해 넘긴다. null이면 해당 par는 건너뛴다.
typedef MediaOverlayAudioLoader = Future<Uint8List?> Function(String audioSrc);

/// MO 재생 상태.
enum MediaOverlayState { idle, playing, paused }

/// Media Overlays 재생을 제어한다. [ChangeNotifier]로 상태 변경을 알리고,
/// [activeParIndex]로 현재 낭독 중인 par를 노출한다.
class MediaOverlayController extends ChangeNotifier {
  MediaOverlayController({required MediaAudioPlayer player})
      : _player = player {
    _posSub = _player.positionStream.listen(_onPosition);
  }

  final MediaAudioPlayer _player;
  StreamSubscription<Duration>? _posSub;

  EpubMediaOverlay _overlay = EpubMediaOverlay.empty;
  MediaOverlayAudioLoader? _loadAudio;

  /// 현재 플레이어에 로드된 오디오 src — 같으면 재로드 없이 seek만 한다.
  String? _loadedAudioSrc;

  /// par 전환의 async 구간 재진입 방지 가드.
  bool _transitioning = false;

  /// 현재 낭독 중인 par 인덱스. 정지 시 -1. (S15.3 하이라이트가 구독)
  final ValueNotifier<int> activeParIndex = ValueNotifier<int>(-1);

  MediaOverlayState _state = MediaOverlayState.idle;
  MediaOverlayState get state => _state;
  bool get isPlaying => _state == MediaOverlayState.playing;

  /// 현재 활성 par(없으면 null).
  EpubMediaPar? get activePar {
    final i = activeParIndex.value;
    return (i >= 0 && i < _overlay.pars.length) ? _overlay.pars[i] : null;
  }

  /// [overlay]를 par [from]부터 재생 시작한다. 빈 오버레이는 무시한다.
  Future<void> start(
    EpubMediaOverlay overlay, {
    required MediaOverlayAudioLoader loadAudio,
    int from = 0,
  }) async {
    if (overlay.isEmpty) return;
    _overlay = overlay;
    _loadAudio = loadAudio;
    _loadedAudioSrc = null;
    await _playPar(from.clamp(0, overlay.pars.length - 1));
  }

  /// 일시정지.
  Future<void> pause() async {
    if (_state != MediaOverlayState.playing) return;
    await _player.pause();
    _setState(MediaOverlayState.paused);
  }

  /// 일시정지 지점부터 재개.
  Future<void> resume() async {
    if (_state != MediaOverlayState.paused) return;
    await _player.play();
    _setState(MediaOverlayState.playing);
  }

  /// 정지 — 활성 par 해제, idle로 전환.
  Future<void> stop() async {
    await _player.pause();
    _loadedAudioSrc = null;
    _setActivePar(-1);
    _setState(MediaOverlayState.idle);
  }

  Future<void> _playPar(int index) async {
    if (index < 0 || index >= _overlay.pars.length) {
      await stop();
      return;
    }
    final par = _overlay.pars[index];
    final src = par.audioSrc;

    // 오디오 없는 par(텍스트 전용) → 활성만 표시하고 다음으로.
    if (src == null) {
      _setActivePar(index);
      _setState(MediaOverlayState.playing);
      await _advance(index);
      return;
    }

    if (src != _loadedAudioSrc) {
      final bytes = await _loadAudio?.call(src);
      if (bytes == null) {
        // 로드 실패 → 활성만 갱신하고 다음 par로 건너뜀(무한루프 방지).
        _setActivePar(index);
        await _advance(index);
        return;
      }
      await _player.load(bytes);
      _loadedAudioSrc = src;
    }
    await _player.seek(par.clipBegin);
    await _player.play();
    _setActivePar(index);
    _setState(MediaOverlayState.playing);
  }

  void _onPosition(Duration pos) {
    if (_state != MediaOverlayState.playing || _transitioning) return;
    final par = activePar;
    final clipEnd = par?.clipEnd;
    if (par != null && clipEnd != null && pos >= clipEnd) {
      unawaited(_advance(activeParIndex.value));
    }
  }

  Future<void> _advance(int fromIndex) async {
    _transitioning = true;
    try {
      await _playPar(fromIndex + 1);
    } finally {
      _transitioning = false;
    }
  }

  void _setActivePar(int index) {
    if (activeParIndex.value != index) activeParIndex.value = index;
  }

  void _setState(MediaOverlayState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    activeParIndex.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }
}
