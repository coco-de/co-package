// Domain Entity — open_epub 1.0
// Story: S1.4 (#10) — Spine 파싱 + rendition:layout 감지

/// EPUB의 layout 모드. `rendition:layout` 메타(EPUB 3) 또는 default(EPUB 2)
/// 로부터 도출된다. Architecture §2.1의 public API.
enum EpubLayout {
  /// 글자 크기·줄간격에 따라 본문이 동적 재배치되는 일반 EPUB.
  reflowable,

  /// 페이지 디자인이 고정된 EPUB (그림책·만화·전공서 등).
  fixedLayout,
}

/// EPUB의 spread 모드. `rendition:spread` 메타로 결정.
enum EpubSpread {
  /// 단면 페이지 (2-page spread 사용 안함).
  none,

  /// 항상 2-page spread.
  both,

  /// 화면 폭/디바이스에 따라 자동 결정 (default).
  auto,

  /// 가로 화면(landscape)에서만 2-page spread.
  landscape,

  /// 세로 화면(portrait)에서만 2-page spread.
  portrait,
}

/// EPUB OPF의 `<metadata>` 추출 결과.
class EpubMetadata {
  const EpubMetadata({
    required this.title,
    required this.epubVersion,
    this.language,
    this.author,
    this.identifier,
    this.layout = EpubLayout.reflowable,
    this.spread = EpubSpread.auto,
  });

  final String title;
  final String epubVersion; // "2.0" | "3.0" | "3.3"
  final String? language;
  final String? author;
  final String? identifier;

  /// `rendition:layout` 메타로 결정. EPUB 2 또는 미명시 시 [EpubLayout.reflowable].
  final EpubLayout layout;

  /// `rendition:spread` 메타로 결정. EPUB 2 또는 미명시 시 [EpubSpread.auto].
  final EpubSpread spread;
}
