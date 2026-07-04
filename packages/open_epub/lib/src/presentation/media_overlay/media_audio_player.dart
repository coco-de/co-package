// Presentation — Media Overlays (open_epub 1.0)
// Story: S15.2 (#109) — MO 오디오 재생 추상 인터페이스 (gap #6 재생분)
//
// [MediaOverlayController]가 이 인터페이스에만 의존하므로, 기본 구현
// (JustAudioMediaPlayer)을 호스트가 자체 오디오 스택으로 교체할 수 있고 테스트는
// fake player로 결정적으로 검증한다(플러그인 경계 미단언).

import 'dart:typed_data';

/// Media Overlays 오디오 재생 추상 인터페이스.
///
/// 계약:
/// - [play]는 즉시 반환해야 한다(재생 완료를 기다리지 않음). 컨트롤러는
///   [positionStream]으로 진행을 감시해 par를 넘긴다.
/// - [positionStream]은 현재 재생 위치를 주기적으로 방출한다.
abstract class MediaAudioPlayer {
  /// 새 오디오 파일 바이트를 로드한다(이전 소스 교체). [contentType]은 MIME.
  Future<void> load(Uint8List bytes, {String contentType});

  /// 재생을 시작/재개한다. 즉시 반환한다(완료 대기 금지).
  Future<void> play();

  /// 재생을 일시정지한다.
  Future<void> pause();

  /// 재생 위치를 이동한다.
  Future<void> seek(Duration position);

  /// 현재 재생 위치 업데이트 스트림.
  Stream<Duration> get positionStream;

  /// 리소스 해제.
  Future<void> dispose();
}
