// Domain Entity — open_epub 1.0
// Story: S1.13 — Text Layer Detection (Fixed Layout)
// BDD: F5.5, F5.6, F7.4 (Fixed Layout 텍스트 레이어 자동 감지)
// RFC-2: XHTML 가시 텍스트 ≥ 50자 또는 비이미지 요소 ≥ 3개(+텍스트>0) 시 available

/// Fixed Layout 페이지의 텍스트 레이어 감지 결과.
///
/// [hasSelectableText]가 false면 이미지-온리/희소/숨김 페이지로 간주하여
/// 텍스트 선택·검색·하이라이트를 비활성화한다. (BDD F5.6 / F7.4)
class TextLayerVerdict {
  const TextLayerVerdict({
    required this.hasSelectableText,
    required this.visibleCharCount,
    required this.reason,
  });

  /// 텍스트 선택 가능 페이지 (텍스트 충분 또는 혼합 콘텐츠).
  factory TextLayerVerdict.available({
    required int visibleCharCount,
    required String reason,
  }) {
    return TextLayerVerdict(
      hasSelectableText: true,
      visibleCharCount: visibleCharCount,
      reason: reason,
    );
  }

  /// 텍스트 선택 불가 페이지 (`image-only` / `too-sparse` / `css-hidden`).
  factory TextLayerVerdict.unavailable({
    int visibleCharCount = 0,
    required String reason,
  }) {
    return TextLayerVerdict(
      hasSelectableText: false,
      visibleCharCount: visibleCharCount,
      reason: reason,
    );
  }

  /// 가시 텍스트 기반 선택 활성 여부.
  final bool hasSelectableText;

  /// 정규화된 가시 텍스트 글자 수 (공백 축약·trim 후).
  final int visibleCharCount;

  /// 판정 근거. 예: `text:120` · `mixed:4/12` · `image-only` · `too-sparse:8`.
  final String reason;

  bool get isAvailable => hasSelectableText;

  bool get isUnavailable => !hasSelectableText;

  @override
  bool operator ==(Object other) =>
      other is TextLayerVerdict &&
      other.hasSelectableText == hasSelectableText &&
      other.visibleCharCount == visibleCharCount &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(hasSelectableText, visibleCharCount, reason);

  @override
  String toString() => 'TextLayerVerdict(selectable: $hasSelectableText, '
      'chars: $visibleCharCount, reason: $reason)';
}
