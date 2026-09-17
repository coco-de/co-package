// Domain Entity — open_epub 1.0
// Story: S13.3 (#100) — page-progression-direction + BookCapabilities (gap #3)
// 아키텍처 §4.4 — 읽기전용 capability 플래그(RTL/MO 신호를 에픽 이전에 노출).

/// 페이지 진행 방향(`<spine page-progression-direction>`).
enum EpubPageProgression {
  /// 좌→우 (기본 다수 언어).
  ltr,

  /// 우→좌 (아랍어·히브리어·일부 CJK).
  rtl,

  /// 명시 안 됨 — 리딩 시스템이 언어로 결정("default"). (S13.3)
  auto,
}

/// 조판 방향. EPUB 3 세로쓰기(vertical-rl 등)는 CSS `writing-mode`로 지정되며
/// OPF에는 없다 — 본 플래그는 기본 [horizontalTb]이고, 세로쓰기 실감지·조판은
/// 별도 에픽(Phase 5)이다. capability 표면 완성을 위해 노출한다.
enum EpubWritingMode {
  /// 가로쓰기, 위→아래 줄바꿈 (기본).
  horizontalTb,

  /// 세로쓰기, 우→좌 줄바꿈 (일본어 전통 조판 등).
  verticalRl,

  /// 세로쓰기, 좌→우 줄바꿈.
  verticalLr,
}

/// 책의 읽기전용 렌더링 능력 신호. 호스트가 RTL/미디어오버레이 존재 등을
/// 파싱 없이 확인할 수 있게 한다. (아키텍처 §4.4)
class BookCapabilities {
  const BookCapabilities({
    this.pageProgressionDirection = EpubPageProgression.auto,
    this.writingMode = EpubWritingMode.horizontalTb,
    this.hasMediaOverlay = false,
  });

  final EpubPageProgression pageProgressionDirection;
  final EpubWritingMode writingMode;

  /// 책에 미디어 오버레이(SMIL) 리소스가 존재하는지. 오디오 재생 자체는
  /// 별도 에픽이지만, 존재 신호는 여기서 노출한다. (gap #6 신호분)
  final bool hasMediaOverlay;

  /// RTL 진행 방향인지 편의 getter.
  bool get isRightToLeft => pageProgressionDirection == EpubPageProgression.rtl;

  static const BookCapabilities defaults = BookCapabilities();
}
