// Domain Entity — open_epub 1.0
// Story: S1.4 (#10) — Spine 파싱 + rendition:layout 감지
// Story: S10.6 (#83) — version getter (package@version → EpubVersion enum)

import '../../schema/opf/package/epub_version.dart';

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

/// EPUB의 렌더링 방향(`rendition:orientation`, EPUB 3). FXL에서 주로 의미.
enum EpubOrientation {
  /// 디바이스/화면에 따라 자동 (default).
  auto,

  /// 가로 고정.
  landscape,

  /// 세로 고정.
  portrait,
}

/// FXL 논리 뷰포트 크기(`rendition:viewport` = "width=W, height=H", EPUB 3.0).
/// 순수-Dart 값(Flutter Size 아님) — reader가 Size로 매핑한다. (S13.2, gap #1)
class EpubViewport {
  const EpubViewport({required this.width, required this.height});

  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      other is EpubViewport && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'EpubViewport(${width}x$height)';
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
    this.orientation = EpubOrientation.auto,
    this.viewport,
    this.modified,
  });

  final String title;
  final String epubVersion; // "2.0" | "3.0" | "3.3"

  /// [epubVersion] 원문을 [EpubVersion] enum으로 파싱한 값 (package@version → enum).
  /// nav/NCX 교차검증이 필요하면 `OpfParser.detectVersion`을 사용한다. (S10.6, gap #9)
  EpubVersion get version => EpubVersion.parse(epubVersion);
  final String? language;
  final String? author;
  final String? identifier;

  /// `rendition:layout` 메타로 결정. EPUB 2 또는 미명시 시 [EpubLayout.reflowable].
  final EpubLayout layout;

  /// `rendition:spread` 메타로 결정. EPUB 2 또는 미명시 시 [EpubSpread.auto].
  final EpubSpread spread;

  /// `rendition:orientation` 메타. EPUB 2 또는 미명시 시 [EpubOrientation.auto].
  /// (S13.2, gap #1)
  final EpubOrientation orientation;

  /// `rendition:viewport` 메타(FXL 논리 크기). 없으면 null — FXL은 각 spine 문서의
  /// `<meta name="viewport">`가 우선이며, 이는 책 전역 기본값이다. (S13.2, gap #1)
  final EpubViewport? viewport;

  /// `<meta property="dcterms:modified">` 최종 수정 시각(ISO8601 원문). EPUB 3
  /// 필수 확장 메타. 없으면 null. (S13.4, gap #7)
  final String? modified;
}
