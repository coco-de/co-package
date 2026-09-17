// Presentation — Media Overlays (open_epub 1.0)
// Story: S15.2 (#109) — just_audio 기반 MediaAudioPlayer 기본 구현 (gap #6 재생분)
//
// 아카이브에서 읽은 오디오 바이트를 StreamAudioSource로 감싸 just_audio로
// 재생한다. 플러그인 경계라 단위 테스트 대상이 아니며(테스트는 fake player),
// 호스트는 [MediaAudioPlayer]를 구현해 자체 오디오 스택으로 교체할 수 있다.

// StreamAudioSource/Response는 just_audio에서 @experimental이지만 인메모리
// 오디오 재생의 표준 경로다. 플러그인 API에 준하므로 파일 단위로 허용한다.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'media_audio_player.dart';

/// just_audio [AudioPlayer]로 오디오를 재생하는 기본 [MediaAudioPlayer].
class JustAudioMediaPlayer implements MediaAudioPlayer {
  JustAudioMediaPlayer([AudioPlayer? player])
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> load(Uint8List bytes,
      {String contentType = 'audio/mpeg'}) async {
    await _player.setAudioSource(_BytesAudioSource(bytes, contentType));
  }

  // just_audio의 play()는 재생이 끝날 때 완료되므로 await하지 않고 즉시 반환한다
  // — 컨트롤러는 positionStream으로 진행을 감시한다(계약).
  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<void> dispose() => _player.dispose();
}

/// 인메모리 오디오 바이트를 서빙하는 [StreamAudioSource](아카이브 오디오용).
class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes, this._contentType);

  final Uint8List _bytes;
  final String _contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: _contentType,
    );
  }
}
