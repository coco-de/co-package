import 'dart:typed_data';

/// 세션 데이터 저장소 추상 인터페이스
///
/// .obt 타임라인 및 .bin 필기 데이터를 Object Store(S3/R2)에
/// 업로드/다운로드하는 인터페이스.
///
/// 소비자 앱에서 S3, R2, MinIO 등에 맞는 구현체를 주입한다.
abstract class SessionStorage {
  /// .obt 타임라인 파일 업로드
  ///
  /// [sessionId] 세션 식별자
  /// [data] .obt 파일 바이너리 데이터
  /// Returns: 업로드된 파일의 URL
  Future<String> uploadTimeline(String sessionId, Uint8List data);

  /// .obt 타임라인 파일 다운로드
  ///
  /// [sessionId] 세션 식별자
  /// Returns: .obt 파일 바이너리 데이터
  Future<Uint8List> downloadTimeline(String sessionId);

  /// 필기 바이너리 데이터 업로드 (페이지별)
  ///
  /// [sessionId] 세션 식별자
  /// [pageId] 페이지 식별자
  /// [data] Scribble protobuf 바이너리
  /// Returns: 업로드된 파일의 URL
  Future<String> uploadScribbleData(
      String sessionId, String pageId, Uint8List data);

  /// 필기 바이너리 데이터 다운로드
  Future<Uint8List> downloadScribbleData(String sessionId, String pageId);

  /// MP4 녹화 파일 URL 조회
  ///
  /// [sessionId] 세션 식별자
  /// Returns: MP4 파일 접근 URL (Egress 종료 후 사용 가능)
  Future<String?> getRecordingUrl(String sessionId);
}
