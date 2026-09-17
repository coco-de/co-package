// S10.6 (#83) — version-branching 교차검증 (gap #9).
//
// `<package version>` 선언과 feature-detection(nav 문서/NCX 존재)을 교차검증한다.
// 파서 분기의 foundational 작업으로, 선언이 누락·왜곡된 책에서도 실효 버전을 도출하고
// 선언과 실제 구조의 모순을 진단으로 드러낸다. (아키텍처 §14.2, roadmap §6 #9)

import 'epub_version.dart';

/// `package@version` 선언과 목차 구조(nav/NCX) feature-detection의 교차검증 결과.
///
/// EPUB 3는 Navigation Document(nav)를 필수로 요구하고 NCX는 선택(하위호환)이다.
/// EPUB 2는 NCX를 사용하고 nav 개념이 없다. 이 규칙에 근거해:
/// - 선언이 없거나 [EpubVersion.unknown]이면 feature로 실효 버전을 추론한다.
/// - 선언과 feature가 모순되면 [hasMismatch]로 표시한다(선언 자체는 보존).
class EpubVersionDetection {
  const EpubVersionDetection({
    required this.declared,
    required this.resolved,
    required this.hasNav,
    required this.hasNcx,
    required this.hasMismatch,
  });

  /// `<package version>` 에서 파싱된 선언 버전([EpubVersion.parse]).
  final EpubVersion declared;

  /// feature-detection으로 보정한 실효 버전.
  ///
  /// [declared]가 [EpubVersion.unknown]이 아니면 그대로(사양상 선언이 권위), 아니면
  /// nav→[EpubVersion.epub3], NCX→[EpubVersion.epub2], 둘 다 없으면 unknown.
  final EpubVersion resolved;

  /// EPUB 3 Navigation Document(manifest item `properties="nav"`) 존재 여부.
  final bool hasNav;

  /// NCX(`application/x-dtbncx+xml` 또는 `<spine toc>`) 존재 여부.
  final bool hasNcx;

  /// 선언 버전과 feature-detection이 모순될 때 true.
  ///
  /// - EPUB 3/3.1 선언인데 nav가 없음(EPUB 3는 nav 필수) → mismatch
  /// - EPUB 2 선언인데 nav가 있음(nav는 EPUB 3 구성요소) → mismatch
  final bool hasMismatch;

  /// [declared]와 feature signal(nav/NCX 존재)을 교차검증한다.
  factory EpubVersionDetection.resolve({
    required EpubVersion declared,
    required bool hasNav,
    required bool hasNcx,
  }) {
    final resolved = declared != EpubVersion.unknown
        ? declared
        : hasNav
            ? EpubVersion.epub3
            : hasNcx
                ? EpubVersion.epub2
                : EpubVersion.unknown;

    final isEpub3Family =
        declared == EpubVersion.epub3 || declared == EpubVersion.epub31;
    final hasMismatch = (isEpub3Family && !hasNav) ||
        (declared == EpubVersion.epub2 && hasNav);

    return EpubVersionDetection(
      declared: declared,
      resolved: resolved,
      hasNav: hasNav,
      hasNcx: hasNcx,
      hasMismatch: hasMismatch,
    );
  }

  @override
  String toString() => 'EpubVersionDetection(declared: $declared, '
      'resolved: $resolved, hasNav: $hasNav, hasNcx: $hasNcx, '
      'hasMismatch: $hasMismatch)';
}
