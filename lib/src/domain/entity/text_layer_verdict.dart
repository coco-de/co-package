// Domain Entity — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.13.
// BDD: F5 (Fixed Layout 텍스트 선택 가능 여부)
// RFC-2: Text Layer Detection — XHTML 가시 텍스트 ≥ 50자 시 active

/// Fixed Layout 페이지의 텍스트 레이어 감지 결과.
class TextLayerVerdict {
  const TextLayerVerdict({
    required this.hasSelectableText,
    required this.visibleCharCount,
    required this.reason,
  });

  final bool hasSelectableText;
  final int visibleCharCount;
  final String reason; // "≥50 chars" | "image-only" | "css-hidden"
}
