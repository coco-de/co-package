// Domain Entity — open_epub 1.0
// Story: S13.6 (#103) — SMIL 미디어 오버레이 (gap #6 파싱분)
//
// EPUB Media Overlays(.smil)는 본문 텍스트 조각과 오디오 클립을 동기화한다.
// 파싱 계층만 담당한다 — 오디오 재생·문장 하이라이트 동기화는 reader(E14/별도).

/// SMIL `<par>` 하나 — 텍스트 조각 ↔ 오디오 클립 동기화 단위.
class EpubMediaPar {
  const EpubMediaPar({
    required this.textSrc,
    this.audioSrc,
    this.clipBegin = Duration.zero,
    this.clipEnd,
  });

  /// `<text src>` — 본문 문서의 fragment 포함 참조(예: ch1.xhtml#s1).
  final String textSrc;

  /// `<audio src>` — 오디오 파일 참조(없을 수 있음).
  final String? audioSrc;

  /// 오디오 클립 시작 시각.
  final Duration clipBegin;

  /// 오디오 클립 종료 시각(없으면 파일 끝까지).
  final Duration? clipEnd;

  @override
  bool operator ==(Object other) =>
      other is EpubMediaPar &&
      textSrc == other.textSrc &&
      audioSrc == other.audioSrc &&
      clipBegin == other.clipBegin &&
      clipEnd == other.clipEnd;

  @override
  int get hashCode => Object.hash(textSrc, audioSrc, clipBegin, clipEnd);

  @override
  String toString() =>
      'EpubMediaPar(text=$textSrc, audio=$audioSrc, $clipBegin..$clipEnd)';
}

/// 하나의 .smil 문서(미디어 오버레이). `<par>`들을 document 순서로 담는다
/// (`<seq>` 중첩은 평탄화).
class EpubMediaOverlay {
  const EpubMediaOverlay({required this.pars});

  final List<EpubMediaPar> pars;

  static const EpubMediaOverlay empty = EpubMediaOverlay(pars: []);

  bool get isEmpty => pars.isEmpty;
}
