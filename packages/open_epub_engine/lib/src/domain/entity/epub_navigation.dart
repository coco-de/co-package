// Domain Entity — open_epub 1.0
// Story: S13.1 (#98) — landmarks / page-list (gap #2)
//
// EPUB 3 nav.xhtml은 toc 외에도 `epub:type="landmarks"`(주요 위치 바로가기)와
// `epub:type="page-list"`(인쇄본 페이지 번호)를 담을 수 있다. toc는 [EpubOutline]
// 으로, 이 둘은 [EpubNavigation]으로 노출한다.

/// nav.xhtml `epub:type="landmarks"`의 한 항목. 표지·본문 시작·목차 등 주요
/// 위치로의 바로가기. [href]는 fragment(#...)를 포함할 수 있다(위치가 유의미).
class EpubLandmark {
  const EpubLandmark({
    required this.type,
    required this.title,
    required this.href,
  });

  /// `epub:type` 값 — cover / toc / bodymatter / ... (여러 개면 공백 구분 원문).
  final String type;
  final String title;
  final String href;

  @override
  bool operator ==(Object other) =>
      other is EpubLandmark &&
      type == other.type &&
      title == other.title &&
      href == other.href;

  @override
  int get hashCode => Object.hash(type, title, href);

  @override
  String toString() => 'EpubLandmark(type=$type, title=$title, href=$href)';
}

/// nav.xhtml `epub:type="page-list"`의 한 항목 — 인쇄본 페이지 번호. 사용자가
/// "N페이지로 이동"할 때 쓴다.
class EpubPageTarget {
  const EpubPageTarget({required this.label, required this.href});

  /// 페이지 라벨(대개 인쇄본 페이지 번호 "12", "xiv" 등).
  final String label;
  final String href;

  @override
  bool operator ==(Object other) =>
      other is EpubPageTarget && label == other.label && href == other.href;

  @override
  int get hashCode => Object.hash(label, href);

  @override
  String toString() => 'EpubPageTarget(label=$label, href=$href)';
}

/// toc 외 보조 내비게이션(landmarks / page-list) 묶음. 부재 시 빈 리스트.
class EpubNavigation {
  const EpubNavigation({
    this.landmarks = const [],
    this.pageList = const [],
  });

  final List<EpubLandmark> landmarks;
  final List<EpubPageTarget> pageList;

  /// 보조 내비게이션이 전혀 없는 책의 기본값.
  static const EpubNavigation empty = EpubNavigation();

  bool get isEmpty => landmarks.isEmpty && pageList.isEmpty;
}
