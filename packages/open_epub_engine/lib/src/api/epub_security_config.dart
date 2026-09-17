// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.24, S5.7.
// BDD: Edge-security (zip slip, script block, CORS)

/// EPUB 파싱·렌더링 시 적용되는 보안 가드 설정.
/// Architecture §9.2 — Threat Model 매핑.
class EpubSecurityConfig {
  const EpubSecurityConfig({
    this.maxFileSizeBytes = 200 * 1024 * 1024,
    this.blockExternalScripts = true,
    this.blockIframes = true,
    this.normalizePaths = true,
    this.allowCrossOriginImages = false,
    this.parseTimeout = const Duration(seconds: 30),
  });

  final int maxFileSizeBytes;
  final bool blockExternalScripts;
  final bool blockIframes;
  final bool normalizePaths;
  final bool allowCrossOriginImages;
  final Duration parseTimeout;
}
