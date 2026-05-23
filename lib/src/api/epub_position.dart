// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.10~S1.12.
// BDD: F1.2 (BookPosition v1 round-trip)
// ADR-001: 자체 canonical 포맷 (CFI 미채택), JSON ≤ 512 bytes

/// BookPosition v1 — Reflowable 또는 Fixed Layout 위치 표현.
sealed class EpubPosition {
  const EpubPosition({required this.spineHref, required this.progress});

  final String spineHref;
  final double progress; // 0.0 ~ 1.0

  Map<String, dynamic> toJson();
  String toToken();

  static EpubPosition fromToken(String token) {
    throw UnimplementedError('S1.10');
  }
}

/// Reflowable 위치: spine + 문자 오프셋 + (선택) 페이지 인덱스
class EpubReflowablePosition extends EpubPosition {
  const EpubReflowablePosition({
    required super.spineHref,
    required super.progress,
    required this.charOffset,
    this.pageIndex,
  });

  final int charOffset;
  final int? pageIndex;

  @override
  Map<String, dynamic> toJson() => throw UnimplementedError('S1.11');

  @override
  String toToken() => throw UnimplementedError('S1.11');
}

/// Fixed Layout 위치: spine + 페이지 인덱스
class EpubFixedPosition extends EpubPosition {
  const EpubFixedPosition({
    required super.spineHref,
    required super.progress,
    required this.pageIndex,
  });

  final int pageIndex;

  @override
  Map<String, dynamic> toJson() => throw UnimplementedError('S1.12');

  @override
  String toToken() => throw UnimplementedError('S1.12');
}
