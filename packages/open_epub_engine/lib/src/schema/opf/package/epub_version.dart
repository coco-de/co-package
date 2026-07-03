/// EPUB 사양 버전. `<package version="...">` 속성에 대응한다.
///
/// vers-one/EpubReader `Schema/Opf/Package/EpubVersion.cs` 포팅.
/// https://www.w3.org/TR/epub-33/#attrdef-package-version
enum EpubVersion {
  /// EPUB 2 (2.0 또는 2.0.1).
  epub2('2'),

  /// EPUB 3 (3.0, 3.0.1, 3.2, 3.3).
  epub3('3'),

  /// EPUB 3.1 (deprecated 표준).
  epub31('3.1'),

  /// 이 열거형에 없는 알 수 없는 버전.
  unknown('');

  const EpubVersion(this.versionString);

  /// 사람이 읽는 버전 문자열("2", "3", "3.1").
  final String versionString;

  /// `<package version>` 원시 문자열을 [EpubVersion]으로 해석한다.
  ///
  /// "2.0"/"2.0.1" → [epub2], "3.0"/"3.0.1"/"3.2"/"3.3" → [epub3],
  /// "3.1" → [epub31], 그 외/누락 → [unknown].
  static EpubVersion parse(String? raw) {
    if (raw == null || raw.isEmpty) return EpubVersion.unknown;
    final normalized = raw.trim();
    if (normalized == '3.1') return EpubVersion.epub31;
    if (normalized.startsWith('2')) return EpubVersion.epub2;
    if (normalized.startsWith('3')) return EpubVersion.epub3;
    return EpubVersion.unknown;
  }
}
