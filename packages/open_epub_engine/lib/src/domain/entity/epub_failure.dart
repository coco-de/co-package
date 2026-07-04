// Domain Entity — open_epub 1.0
// Story: S1.25 (#41) — EpubFailure 계층
// Architecture §11.2 — 타입 안전한 오류 표현
//
// 책 열기/소스/보안 경로의 실패를 sealed 계층으로 수렴시킨다. 호출자는
// switch로 모든 케이스를 망라 처리할 수 있다.

/// open_epub의 모든 실패의 sealed 루트.
sealed class EpubFailure implements Exception {
  const EpubFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// EPUB 형식이 아님(ZIP은 맞으나 container/OPF 누락 등) 또는 입력 부재.
class EpubInvalidFile extends EpubFailure {
  const EpubInvalidFile(super.message);
}

/// 파일 크기가 [EpubSecurityConfig.maxFileSizeBytes]를 초과.
class EpubFileTooLarge extends EpubFailure {
  EpubFileTooLarge({required this.actualBytes, required this.limitBytes})
      : super('EPUB size $actualBytes bytes exceeds limit $limitBytes bytes');

  final int actualBytes;
  final int limitBytes;
}

/// 네트워크 소스(url) 읽기 실패.
class EpubNetworkFailure extends EpubFailure {
  const EpubNetworkFailure(super.message);
}

/// ZIP 해제 실패 등 컨테이너 손상.
class EpubCorrupted extends EpubFailure {
  const EpubCorrupted(super.message);
}

/// 콘텐츠가 미지원 암호화(상업 DRM: ADEPT/LCP/AES 등)로 보호되어 열 수 없음.
/// IDPF/Adobe 폰트 난독화는 [FontObfuscation]으로 투명 해제되므로 여기 해당 안 함.
/// (S13.5, #102, gap #8)
class EpubEncryptedUnsupported extends EpubFailure {
  EpubEncryptedUnsupported({required this.algorithm, this.uri})
      : super(
          'content is protected by unsupported encryption '
          '"$algorithm"${uri != null ? ' ($uri)' : ''}',
        );

  /// XML Encryption의 EncryptionMethod Algorithm URI.
  final String algorithm;

  /// 암호화된 리소스 경로(있으면).
  final String? uri;
}

/// 분류되지 않은 기타 실패.
class EpubUnknown extends EpubFailure {
  const EpubUnknown(super.message);
}
