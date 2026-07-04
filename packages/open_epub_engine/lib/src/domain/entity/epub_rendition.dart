// Domain Entity — open_epub 1.0
// Story: S13.4 (#101) — multiple renditions (gap #7)
//
// EPUB Multiple-Rendition Publications는 container.xml에 여러 `<rootfile>`을
// 둔다(예: reflowable + fixed-layout, 또는 언어별). 엔진은 기본 rendition으로
// 세션을 열되, 나머지 rendition 목록을 노출해 호스트가 선택·재-open할 수 있게 한다.

/// container.xml의 한 `<rootfile>` (하나의 rendition).
class EpubRendition {
  const EpubRendition({
    required this.fullPath,
    required this.mediaType,
    this.label,
    this.isDefault = false,
  });

  /// OPF 패키지 파일의 ZIP 내부 경로(full-path).
  final String fullPath;
  final String mediaType;

  /// `rendition:label` 속성(사람용 이름). 없으면 null.
  final String? label;

  /// 엔진이 기본으로 여는 rendition인지(OPF media-type을 가진 첫 rootfile).
  final bool isDefault;

  @override
  bool operator ==(Object other) =>
      other is EpubRendition &&
      fullPath == other.fullPath &&
      mediaType == other.mediaType &&
      label == other.label &&
      isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(fullPath, mediaType, label, isDefault);

  @override
  String toString() =>
      'EpubRendition($fullPath, $mediaType, label=$label, default=$isDefault)';
}
