// Presentation Engine — open_epub 1.0
// Story: S1.6 (#12) — Reflowable 페이지뷰
// BDD: F2.2 (글자 크기), F2.3 (줄간격), F2.4 (페이지 전환 ≤ 150ms)
//
// spine 단위 PageView + 화면 단위 윈도잉 기반 페이지 모드 (open-epub#221).
// spine(chapter) 콘텐츠는 한 번만 렌더링하고, 실제 렌더 높이를 측정해
// [OverflowBox]+[Transform.translate]로 화면 높이만큼의 "창"만 보여준다 —
// 텍스트를 실제로 재분할하지 않으므로 이미지·표·링크가 그대로 유지된다.
// 화면 하나(윈도우)가 좌우 스와이프 1회에 대응하고, spine의 첫/마지막
// 윈도우에서 계속 스와이프하면 다음/이전 spine으로 자연스럽게 넘어간다.
// 윈도우 높이는 화면 높이가 아니라 본문 줄 높이(fontSize*lineHeight)의
// 정수 배로 내림한 값이라, 본문 텍스트 줄은 페이지 경계에서 잘리지 않고
// 다음 윈도우로 넘어간다(남는 자투리는 페이지 아래쪽 여백, open-epub#228
// 후속). 제목·이미지·표처럼 본문 줄 높이와 다른 요소는 여전히 경계에서
// 잘릴 수 있다.
//
// spine 간 이동은 여전히 [PageView]가 담당하지만, 사용자 스와이프는 윈도우
// 이동과 spine 이동을 함께 판단해야 하므로 PageView 자체의 드래그
// (physics)는 끄고 최상위 [GestureDetector] 하나가 두 이동을 모두 구동한다
// (같은 축의 중첩 PageView 제스처 경합을 피하기 위함).
//
// 페이지 넘김은 **드래그-투-턴**(drag-to-turn)이다 (kobic#8240): 손가락 이동량
// 만큼 현재 페이지가 실시간으로 따라 밀리고, 반대편에서 다음/이전 페이지가
// 함께 슬라이드해 들어온다(현재 PageView를 [Transform.translate]로 밀고 이웃
// 페이지를 오버레이). 손가락을 놓으면 이동 비율이 절반 이상이거나 fling 속도가
// 임계([_swipeVelocityThreshold])를 넘으면 전진/후퇴를 확정하고, 아니면 원위치로
// 복귀한다 — 두 경우 모두 ease-out ≤150ms 스냅(F2.4 준수)으로 마무리한다. 확정
// 시 실제 이동은 애니메이션 없이(instant) 적용되고, 시각적 슬라이드는 오버레이가
// 담당하므로 이중 애니메이션이 없다. 문서 끝/시작에서 더 넘길 이웃이 없으면 따라
// 오지 않는다(하드 스톱). RTL(reverse)·단면/양면(spread) 모두 동일한 제스처로
// 동작하며, 넘김 단위만 각각(방향 반전 / pair 2윈도우)에 맞춰진다.
//
// 프로그램적 이동(페이지 버튼·목차·[EpubViewController])은 드래그와 무관하게
// 기존처럼 [_advance]/[goToPage](150ms) 경로를 그대로 쓴다.
//
// 글자 크기·줄간격 변경 시 현재 spineIndex가 보존된다 (PageController.page
// 유지 + Html style만 갱신, 윈도우 수는 새 크기로 재측정).

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:open_epub_engine/open_epub_engine.dart';
import '../fixed_layout/fixed_layout_engine.dart'
    show FixedLayoutContentBuilder;
import '../fixed_layout/viewport_fitter.dart';
import 'pagination_strategy.dart';
import 'reflowable_engine.dart';

class ReflowablePageView extends StatefulWidget {
  const ReflowablePageView({
    super.key,
    required this.book,
    required this.xhtmlLoader,
    this.imageLoader,
    this.initialSpineIndex = 0,
    this.initialWindowIndex = 0,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.fontFamily,
    this.paginationStrategy = const SinglePagePerSpineStrategy(),
    this.onPageChanged,
    this.onLinkTap,
    this.onNavigatorReady,
    this.onPageStepReady,
    this.onWindowChanged,
    this.contentRevision,
    this.reverse = false,
    this.forceVertical = false,
    this.fixedPageSize,
    this.contentBuilder,
    this.spread,
  });

  final EpubBook book;
  final XhtmlLoader xhtmlLoader;
  final ImageLoader? imageLoader;
  final int initialSpineIndex;

  /// 복원된 위치의 윈도우(가상 페이지) 인덱스 힌트. 해당 spine 측정 완료
  /// 전에는 그대로 유지되다가, 측정 후 범위를 벗어나면 clamp된다.
  /// [fixedPageSize] 모드에서만 의미가 있다 — 그 외 모드는 항상 0에서
  /// 시작한다(기존 동작 불변).
  final int initialWindowIndex;
  final double fontSize;
  final double lineHeight;

  /// 본문 강제 서체(kobic 가로 페이지 넘김 A4 고정 페이지네이션, Epic #7964 S3
  /// — fontSize/lineHeight와 함께 필기 앵커 좌표가 서체 변경으로 흔들리지
  /// 않도록 고정). null(기본값)이면 원본 XHTML/기본 서체를 그대로 따른다.
  final String? fontFamily;

  /// 미사용 — 화면 단위 윈도잉(open-epub#221)은 [PaginationStrategy] 없이
  /// 렌더 높이 측정으로 직접 처리한다. 향후 정밀 페이지네이션(문단 단위 재분할)
  /// 도입 시 재사용을 위해 필드만 유지.
  final PaginationStrategy paginationStrategy;
  final ValueChanged<int>? onPageChanged;

  /// 우→좌 진행(RTL, `page-progression-direction=rtl`). true면 PageView 스크롤
  /// 방향을 반전해 다음 페이지가 왼쪽에서 나타난다. 페이지 인덱스 계약(다음=+1)은
  /// 불변이며 시각적 방향만 바뀐다. (S14.1, gap #4)
  final bool reverse;

  /// 세로쓰기 강제 — 단순 텍스트 spine을 [VerticalTextBlock]으로 렌더. (S15.4)
  final bool forceVertical;

  /// 본문 링크/하이라이트 탭 콜백. (S7.3/S7.5)
  final EpubLinkTapCallback? onLinkTap;

  /// 마운트 시 페이지 이동 함수(goToPage)를 부모에게 넘긴다 — 부모(EpubReader)가
  /// EpubViewController에 연결해 prev/next 등 프로그램적 내비게이션을 제공. (S8.1)
  final void Function(Future<void> Function(int index) goToPage)?
      onNavigatorReady;

  /// 마운트 시 "한 페이지(윈도우) 이동" 함수([_advance])를 부모에게 넘긴다 —
  /// [onNavigatorReady](spine 단위 goToPage)와 별개로, EpubViewController의
  /// nextPage()/previousPage()가 spine 전체가 아닌 화면 단위 윈도우로 이동하게
  /// 한다. 인자는 +1(다음)/-1(이전). (open-epub#221 후속 — 페이지 버튼이
  /// 챕터 단위로 건너뛰던 문제)
  final void Function(Future<void> Function(int direction) step)?
      onPageStepReady;

  /// (spine 인덱스, 윈도우 인덱스, 현재 spine의 윈도우 수)가 바뀔 때마다
  /// 호출된다 — 부모(EpubReader)가 EpubViewController.syncState에 윈도우
  /// 정보를 함께 반영해 hasNext/hasPrevious/windowIndex/windowCount가 화면
  /// 단위 윈도잉을 정확히 반영하도록 한다. 마운트 시 초기값(측정 전)으로도
  /// 한 번 호출되고, 측정 완료·윈도우 이동·spine 전환마다 다시 호출된다.
  /// (open-epub#228 — 이전엔 창 이동이 controller에 전혀 반영되지 않아
  /// hasNext 등이 stale했다)
  final void Function(int spineIndex, int windowIndex, int windowCount)?
      onWindowChanged;

  /// [xhtmlLoader] 결과에 영향을 주는 외부 상태의 revision(예: 하이라이트
  /// 목록). identity가 바뀌면 캐시된 spine XHTML을 버리고 다시 로드한다.
  /// (open-epub#62)
  final Object? contentRevision;

  /// 논리 고정 크기(예: A4 210:297 근사, 595×842)로 윈도잉을 강제한다
  /// (kobic Epic #7964 S1). null(기본값)이면 기존처럼 실제 화면 크기로
  /// 윈도잉한다(화면 회전·글자 크기에 따라 윈도우 수가 달라짐). 값이 있으면
  /// 본문 리플로우·윈도우 분할이 이 고정 크기 기준으로 이루어지고, 결과
  /// 페이지가 실제 화면에 [ViewportFitter]로 contain-fit 스케일된다(진짜
  /// fixed-layout 페이지와 동일한 좌표 안정성 — 필기가 이 고정 논리 좌표에
  /// 앵커링될 수 있다). 이 모드에서는 핀치 줌을 제공하지 않는다(스와이프
  /// 페이지 넘김과의 제스처 경합 회피 — fixed-layout 엔진의
  /// FixedLayoutPage가 InteractiveViewer 자체 fling 감지로 이를 해결하는
  /// 것과 달리, 본 위젯은 외부 GestureDetector 기반 스와이프를 그대로
  /// 유지한다).
  final Size? fixedPageSize;

  /// [fixedPageSize] 모드에서 각 윈도우(가상 페이지) 콘텐츠를 논리 좌표
  /// 공간에서 감싸는 빌더 — fixed-layout 엔진의 [FixedLayoutContentBuilder]와
  /// 동일 계약을 재사용한다(open-board 절대좌표 필기 캔버스 등, S8.6 참조).
  /// 전달되는 [EpubSpineItem]은 원본 spine 항목에 윈도우 인덱스를 반영한
  /// 합성 href(`baseHref#p{windowIndex}`)를 가진 값으로, 호출자가 윈도우별
  /// 고유 앵커/캐시 키를 얻을 수 있게 한다. [fixedPageSize]가 null이면
  /// 무시된다.
  final FixedLayoutContentBuilder? contentBuilder;

  /// EPUB 메타의 spread 모드(`rendition:spread`). null(기본값)이면 항상 단면
  /// (기존 동작 불변). 값이 있으면 [ViewportFitter.shouldUseTwoPageSpread]로
  /// 뷰포트 크기와 함께 유효 spread 여부를 판정해, 활성 시 한 화면에 **연속
  /// 두 윈도우(왼쪽=W, 오른쪽=W+1)를** 좌우로 배치한다(reflowable 2-up).
  /// fixed-layout처럼 spine을 쌍짓는 게 아니라 같은 spine 내 연속 윈도우를
  /// 좌우 컬럼으로 나란히 둔다. (kobic Epic #7964 후속 — 2-up spread)
  final EpubSpread? spread;

  @override
  State<ReflowablePageView> createState() => ReflowablePageViewState();
}

@visibleForTesting
class ReflowablePageViewState extends State<ReflowablePageView>
    with SingleTickerProviderStateMixin {
  late PageController _controller;
  late int _pageIndex;

  /// 현재 spine 내 윈도우(화면 단위 페이지) 인덱스. spine 콘텐츠가 화면보다
  /// 길면 0..[windowCount)-1 사이를 좌우 스와이프로 이동한다. (open-epub#221)
  late int _windowIndex;

  /// spine별 측정된 윈도우 수 캐시. 아직 측정 전이면 1(창 없음)로 취급.
  final Map<int, int> _windowCounts = {};

  /// spine 경계를 넘는 스와이프(`_advance`) 직후, 대상 spine에 착지할 윈도우
  /// 인덱스를 한 번만 소비하기 위한 슬롯. 프로그램적 이동(controller 등)은
  /// 항상 0으로 착지한다.
  int? _pendingLandingWindow;

  /// spine 경계를 넘는(비동기) 이동이 진행 중인지 — 진행 중에 또 다른 이동
  /// 요청(중복 탭/스와이프)이 오면 무시해, 애니메이션 도중 재진입해 동일
  /// 목표로 두 번째 이동이 겹쳐 걸리는 것을 막는다. 같은 spine 내 윈도우
  /// 이동(동기)은 이 가드가 필요 없다. (open-epub#228)
  bool _crossingSpine = false;

  /// 현재 뷰포트 기준으로 2-up spread가 활성인지. build의 [LayoutBuilder]
  /// 안에서만 뷰포트 크기를 알 수 있으므로, 판정 결과를 여기에 캐시해
  /// [_advance]/리포팅이 참조한다. build에서 값이 바뀌면 post-frame에
  /// [_reportWindowState]를 다시 호출해 부모 상태를 갱신한다.
  bool _spreadActive = false;

  static const double _swipeVelocityThreshold = 250;

  /// 손가락을 놓았을 때 이동 비율이 이 값 이상이면(속도가 낮아도) 전진/후퇴를
  /// 확정한다. 미만이면 원위치로 복귀. (kobic#8240)
  static const double _commitFractionThreshold = 0.5;

  /// 드래그 확정/복귀 스냅 애니메이션 상한(F2.4: 페이지 전환 ≤ 150ms). 남은
  /// 이동 거리에 비례해 축소하되 이 값을 넘지 않는다. (kobic#8240)
  static const int _snapMaxMillis = 150;

  // --- 드래그-투-턴 상태 (kobic#8240) ---

  /// 스냅(확정/복귀) 애니메이션 구동 컨트롤러. 0→1 진행값을 [_turnStartDx]→
  /// [_turnEndDx] 구간에 ease-out으로 매핑해 [_dragDx]를 갱신한다.
  late final AnimationController _turnController;

  /// 현재 페이지의 수평 오프셋(px, 부호=손가락 진행 방향). 0이면 넘김 중이 아님.
  double _dragDx = 0;

  /// 확정된 논리 이동 방향(+1=다음/-1=이전). 0이면 아직 방향 미확정(넘김 없음).
  /// 드래그 시작 후 첫 유효 이동에서 래치되고, 손가락이 반대로 넘어가도 유지된다
  /// (한 넘김 안에서 이웃 페이지가 바뀌지 않도록).
  int _turnDir = 0;

  /// 손가락이 페이지를 드러내는 방향의 부호(-1=왼쪽 드래그→오른쪽 이웃 노출,
  /// +1=오른쪽 드래그→왼쪽 이웃 노출). 넘김 중 부호가 뒤집히지 않게 래치한다.
  int _revealSign = 0;

  /// 사용자가 손가락으로 드래그 중인지(스냅 애니메이션 진행 중과 구분).
  bool _dragging = false;

  /// 스냅 애니메이션 보간 구간.
  double _turnStartDx = 0;
  double _turnEndDx = 0;

  /// 스냅 애니메이션 완료 시 확정할 이동 방향(0=복귀, 확정 아님).
  int _pendingCommitDir = 0;

  /// build의 [LayoutBuilder]에서 캐시한 최신 뷰포트 크기 — 제스처 핸들러가
  /// 페이지 폭/높이를 알기 위해 참조한다.
  Size _lastViewport = Size.zero;

  /// spine href별 XHTML 로드 future 캐시 — 매 rebuild마다 loader를 재호출해
  /// FutureBuilder가 스피너로 리셋되던 안티패턴 해소. (open-epub#62)
  final Map<String, Future<String>> _loads = {};

  int get pageIndex => _pageIndex;
  int get pageCount => widget.book.spine.length;

  /// 현재 보이는 페이지(윈도우/스프레드) 인덱스(0-based). 테스트 전용 노출.
  /// 2-up spread가 활성이면 pair 단위(윈도우 인덱스 / 2)로 환산한다 — 부모
  /// (kobic 페이지 인디케이터)가 보이는 페이지 단위로 인식하도록.
  @visibleForTesting
  int get windowIndex => _spreadActive ? _windowIndex ~/ 2 : _windowIndex;

  /// 현재 spine의 보이는 페이지 수(아직 미측정이면 1). 테스트 전용 노출.
  /// 2-up spread가 활성이면 pair 단위(ceil(윈도우 수 / 2))로 환산한다.
  @visibleForTesting
  int get windowCount {
    final raw = _windowCounts[_pageIndex] ?? 1;
    return _spreadActive ? (raw + 1) ~/ 2 : raw;
  }

  /// 현재 spine의 raw(스프레드 미환산) 윈도우 수. 테스트 전용 노출 —
  /// spread 검증에서 홀/짝 윈도우 경계 케이스를 판정하는 데 쓴다.
  @visibleForTesting
  int get rawWindowCount => _windowCounts[_pageIndex] ?? 1;

  /// 현재 2-up spread 활성 여부. 테스트 전용 노출.
  @visibleForTesting
  bool get spreadActive => _spreadActive;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialSpineIndex.clamp(
      0,
      widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
    );
    // initialWindowIndex는 fixedPageSize 모드의 위치 복원 힌트 — 그 외
    // 모드는 항상 기본값 0으로 기존 동작과 동일하다.
    _windowIndex =
        widget.initialWindowIndex < 0 ? 0 : widget.initialWindowIndex;
    _controller = PageController(initialPage: _pageIndex);
    _turnController = AnimationController(vsync: this)
      ..addListener(_onTurnTick)
      ..addStatusListener(_onTurnStatus);
    widget.onNavigatorReady?.call(goToPage);
    widget.onPageStepReady?.call(_advance);
    // 측정 전 초기값(윈도우 0/1개)으로 우선 보고 — 측정이 끝나면
    // _handleWindowMeasured가 정확한 windowCount로 다시 보고한다.
    _reportWindowState();
  }

  /// 현재 (spine, 윈도우 인덱스, 윈도우 수)를 부모에 보고한다 — 측정 완료·
  /// 윈도우 이동·spine 전환마다 호출해 EpubViewController의
  /// hasNext/hasPrevious/windowIndex/windowCount를 최신 상태로 유지한다.
  /// (open-epub#228)
  void _reportWindowState() {
    // spread 활성 시 보이는 페이지(스프레드) 단위로 환산해 보고한다 — kobic
    // 페이지 인디케이터/hasNext가 스프레드 단위로 동작하도록. 미활성이면 raw
    // 윈도우 그대로(기존 동작 불변).
    widget.onWindowChanged?.call(_pageIndex, windowIndex, windowCount);
  }

  @override
  void didUpdateWidget(ReflowablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fontSize/lineHeight만 바뀐 경우 PageController/page는 그대로 유지.
    // book이 바뀌면 controller 재생성.
    if (oldWidget.book != widget.book) {
      _cancelTurnImmediately();
      _loads.clear();
      _windowCounts.clear();
      _windowIndex = 0;
      _pageIndex = widget.initialSpineIndex.clamp(
        0,
        widget.book.spine.isEmpty ? 0 : widget.book.spine.length - 1,
      );
      _controller.dispose();
      _controller = PageController(initialPage: _pageIndex);
      _reportWindowState();
      return;
    }
    if (!identical(oldWidget.contentRevision, widget.contentRevision)) {
      // 하이라이트 등 콘텐츠 revision 변경 — 캐시를 버리고 재로드. 각 페이지는
      // 재로드 동안 직전 콘텐츠를 유지한다(_SpinePageView). (open-epub#62)
      _loads.clear();
      _windowCounts.clear();
    }
    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.lineHeight != widget.lineHeight ||
        oldWidget.fontFamily != widget.fontFamily ||
        oldWidget.fixedPageSize != widget.fixedPageSize) {
      // 글자 크기·줄간격·서체·고정 페이지 크기가 바뀌면 렌더 높이가 달라지므로
      // 윈도우 수를 재측정한다 — 이전 윈도우 경계는 새 크기에서 더 이상
      // 유효하지 않다.
      _windowCounts.clear();
      _windowIndex = 0;
      _reportWindowState();
    }
  }

  @override
  void dispose() {
    _turnController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 페이지 이동 (animation). animation 종료를 기다리려면 반환 Future를 await.
  /// 항상 대상 spine의 첫 윈도우(0)로 착지한다.
  Future<void> goToPage(int index) async {
    if (index < 0 || index >= pageCount) return;
    await _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  /// 즉시 페이지 이동 (animation 없음). 테스트·외부 직접 점프 시 유리.
  void jumpToPage(int index) {
    if (index < 0 || index >= pageCount) return;
    _controller.jumpToPage(index);
  }

  Future<void> nextPage() => goToPage(_pageIndex + 1);
  Future<void> previousPage() => goToPage(_pageIndex - 1);

  Future<String> _loadSpine(String href) =>
      _loads.putIfAbsent(href, () => widget.xhtmlLoader(href));

  void _handleWindowMeasured(int spineIndex, int measuredCount) {
    if (!mounted || _windowCounts[spineIndex] == measuredCount) return;
    _windowCounts[spineIndex] = measuredCount;
    if (spineIndex != _pageIndex) return;
    if (_windowIndex >= measuredCount) {
      // 범위 밖이면 마지막 윈도우로 clamp. spread 활성 시엔 pair 시작(짝수)로
      // 내림해 왼쪽 컬럼이 항상 짝수 윈도우가 되게 한다.
      var clamped = measuredCount - 1;
      if (_spreadActive) clamped -= clamped % 2;
      setState(() => _windowIndex = clamped);
    } else if (_spreadActive) {
      // spread 모드에서는 오른쪽 컬럼 존재 여부(rightW < rawCount)가 측정된
      // 윈도우 수에 좌우된다 — 미측정(1개)일 땐 오른쪽이 비어 있다가 측정 후
      // 채워져야 하므로, 윈도우 수가 바뀌면 부모를 리빌드한다. (단면 경로는
      // 윈도잉이 내부 Transform으로만 처리돼 리빌드가 불필요.)
      setState(() {});
    }
    _reportWindowState();
  }

  // ---- 드래그-투-턴 제스처 (kobic#8240) ----

  /// 손가락 진행 방향([revealSign]: -1=왼쪽 드래그, +1=오른쪽 드래그)을 논리
  /// 이동 방향(+1=다음/-1=이전)으로 매핑한다. reverse(RTL)면 의미가 반전된다
  /// (다음=우향 진행). fixed_layout_page의 rightToLeft 처리와 동일 원칙(S14.1),
  /// 기존 fling 판정과 동일한 규칙.
  int _directionFor(int revealSign) {
    final swipedLeft = revealSign < 0;
    final forward = widget.reverse ? !swipedLeft : swipedLeft;
    return forward ? 1 : -1;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // 스냅 애니메이션 진행 중이거나 spine 전환 중이면 새 드래그를 시작하지
    // 않는다(핸드오프 도중 재진입 방지).
    if (_crossingSpine || _turnController.isAnimating) return;
    _dragging = true;
    _dragDx = 0;
    _turnDir = 0;
    _revealSign = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final width = _lastViewport.width;
    if (width <= 0) return;
    final delta = details.primaryDelta ?? 0.0;
    if (delta == 0) return;

    if (_turnDir == 0) {
      // 첫 유효 이동에서 노출 방향과 논리 이동 방향을 래치한다.
      _revealSign = delta < 0 ? -1 : 1;
      _turnDir = _directionFor(_revealSign);
    }

    // 넘김 중 부호가 뒤집히지 않도록, 래치된 노출 방향 쪽으로만 [0, width]
    // 범위에서 따라오게 한다(반대로 넘기면 0에서 멈춤 = 원위치).
    var next = _dragDx + delta;
    next = _revealSign < 0 ? next.clamp(-width, 0.0) : next.clamp(0.0, width);

    // 더 넘길 이웃이 없으면(문서 끝/시작) 따라오지 않는다 — 하드 스톱.
    if (_turnTarget(_turnDir) == null) next = 0;

    if (next != _dragDx) setState(() => _dragDx = next);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final width = _lastViewport.width;
    // 이동이 없었거나(탭 수준) 이웃이 없으면 원위치로 복귀.
    if (_turnDir == 0 || _dragDx == 0 || width <= 0) {
      _cancelTurnImmediately();
      return;
    }
    final velocity = details.primaryVelocity ?? 0.0;
    final fraction = _dragDx.abs() / width;
    final flungTowardReveal = velocity.abs() >= _swipeVelocityThreshold &&
        velocity.sign == _revealSign;
    final canCommit = _turnTarget(_turnDir) != null;
    final commit = canCommit &&
        (fraction >= _commitFractionThreshold || flungTowardReveal);

    if (commit) {
      _animateTurnTo(_revealSign * width, commitDir: _turnDir);
    } else {
      _animateTurnTo(0, commitDir: 0);
    }
  }

  /// [_dragDx]를 [endDx]까지 ease-out으로 스냅한다. 남은 거리에 비례해 지속
  /// 시간을 정하되 [_snapMaxMillis](F2.4 ≤150ms)를 넘지 않는다. 완료 시
  /// [_onTurnStatus]가 [commitDir]≠0이면 실제 이동을 즉시 적용한다.
  void _animateTurnTo(double endDx, {required int commitDir}) {
    final width = _lastViewport.width;
    _turnStartDx = _dragDx;
    _turnEndDx = endDx;
    _pendingCommitDir = commitDir;
    final distance = (endDx - _turnStartDx).abs();
    final ms = width <= 0
        ? _snapMaxMillis
        : (_snapMaxMillis * (distance / width))
            .round()
            .clamp(1, _snapMaxMillis);
    _turnController
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _onTurnTick() {
    final t = Curves.easeOut.transform(_turnController.value);
    final dx = lerpDouble(_turnStartDx, _turnEndDx, t) ?? _turnEndDx;
    if (dx != _dragDx) setState(() => _dragDx = dx);
  }

  void _onTurnStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final dir = _pendingCommitDir;
    // 실제 이동은 애니메이션 없이 즉시 적용한다 — 시각적 슬라이드는 오버레이가
    // 이미 담당했으므로 이중 애니메이션이 없다. 적용 후 오버레이를 걷는다.
    if (dir != 0) unawaited(_step(dir, animated: false));
    _resetTurnState();
  }

  /// 진행 중인 넘김(드래그/스냅)을 즉시 취소하고 원위치로 되돌린다 — book 교체
  /// 등 외부 요인으로 트리를 리셋해야 할 때.
  void _cancelTurnImmediately() {
    if (_turnController.isAnimating) _turnController.stop();
    _resetTurnState();
  }

  void _resetTurnState() {
    if (!mounted) {
      _dragDx = 0;
      _turnDir = 0;
      _revealSign = 0;
      _pendingCommitDir = 0;
      _dragging = false;
      return;
    }
    setState(() {
      _dragDx = 0;
      _turnDir = 0;
      _revealSign = 0;
      _pendingCommitDir = 0;
      _dragging = false;
    });
  }

  /// [direction] = +1(다음)/-1(이전)로 한 윈도우(spread 시 한 pair) 이동한다 —
  /// 프로그램적 경로(페이지 버튼·목차·[EpubViewController], [onPageStepReady])
  /// 전용으로 spine 경계 이동 시 150ms 애니메이션을 쓴다. 드래그-투-턴 확정은
  /// [_step]을 animated:false로 호출해 오버레이 슬라이드와 이중 애니메이션을
  /// 피한다.
  Future<void> _advance(int direction) => _step(direction, animated: true);

  /// 실제 한 스텝 이동을 적용한다. [_turnTarget]으로 착지점을 계산해, 같은
  /// spine이면 동기 setState로, spine 경계를 넘으면 [animated]에 따라
  /// [goToPage](150ms)/[jumpToPage](즉시)로 이동한다.
  Future<void> _step(int direction, {required bool animated}) async {
    final target = _turnTarget(direction);
    if (target == null) return; // 문서 끝/시작 — 이동 없음.
    if (target.spine == _pageIndex) {
      setState(() => _windowIndex = target.window);
      _reportWindowState();
      return;
    }
    // 이미 진행 중인 spine 전환(애니메이션)이 있으면 중복 요청은 무시한다 —
    // 없으면 빠른 연속 탭/스와이프가 같은 목표로 두 번 걸려 하나를 삼킨다.
    // (open-epub#228)
    if (_crossingSpine) return;
    _crossingSpine = true;
    _pendingLandingWindow = target.window;
    try {
      if (animated) {
        await goToPage(target.spine);
      } else {
        jumpToPage(target.spine);
      }
    } finally {
      _crossingSpine = false;
    }
  }

  /// [direction](+1/-1)으로 한 스텝 이동했을 때 착지할 (spine, 윈도우). 현재
  /// spine의 윈도우 범위 안이면 같은 spine의 다음/이전 윈도우(spread 시 pair),
  /// 벗어나면 다음/이전 spine의 첫(다음) 또는 마지막 pair(이전) 윈도우. 문서
  /// 끝/시작이라 더 넘길 곳이 없으면 null. [_step]과 드래그 오버레이가 같은
  /// 계산을 공유해 미리보기와 실제 착지가 일치하도록 한다. (kobic#8240)
  ({int spine, int window})? _turnTarget(int direction) {
    final count = _windowCounts[_pageIndex] ?? 1;
    // spread 활성 시 한 번에 두 윈도우(스프레드 하나)씩 이동한다.
    final step = _spreadActive ? 2 : 1;
    var next = _windowIndex + direction * step;
    if (_spreadActive && next > 0) next -= next % 2; // pair 시작(짝수)로 정렬
    if (next >= 0 && next < count) return (spine: _pageIndex, window: next);
    final targetSpine = _pageIndex + direction;
    if (targetSpine < 0 || targetSpine >= pageCount) return null;
    return (
      spine: targetSpine,
      window: direction > 0 ? 0 : _lastPairStartWindow(targetSpine),
    );
  }

  /// 이전 방향으로 spine 경계를 넘을 때 착지할 윈도우 — 대상 spine의 마지막
  /// 페이지. spread 활성이면 마지막 pair 시작 윈도우(`((C-1)~/2)*2`), 아니면
  /// 마지막 윈도우(`C-1`).
  int _lastPairStartWindow(int spineIndex) {
    final count = _windowCounts[spineIndex] ?? 1;
    if (_spreadActive) return ((count - 1) ~/ 2) * 2;
    return count - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.spine.isEmpty) {
      return const Center(child: Text('이 책에는 표시할 내용이 없습니다.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = constraints.biggest;
        // 제스처 핸들러가 페이지 폭/높이를 알 수 있도록 최신 뷰포트를 캐시.
        _lastViewport = viewportSize;
        final useSpread = _resolveSpread(viewportSize);
        _syncSpreadActive(useSpread);

        // 스와이프는 GestureDetector가 전담(윈도우/spine 이동 통합 판단) —
        // PageView 자체 드래그는 꺼서 같은 축 제스처 경합을 막는다.
        final base = PageView.builder(
          controller: _controller,
          reverse: widget.reverse,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pageCount,
          onPageChanged: (i) {
            setState(() {
              _pageIndex = i;
              _windowIndex = _pendingLandingWindow ?? 0;
              _pendingLandingWindow = null;
            });
            widget.onPageChanged?.call(i);
            _reportWindowState();
          },
          itemBuilder: (context, index) =>
              _buildSpineItem(index, viewportSize, useSpread),
        );

        return GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: _buildTurnStack(base, viewportSize, useSpread),
        );
      },
    );
  }

  /// 현재 페이지([base])와 넘김 중 이웃 페이지를 오버레이한다. 넘김 중이 아닐
  /// 때도(idempotent) 동일한 Stack 구조를 유지해 [base](PageView)의 Element가
  /// 보존되도록 한다 — 구조가 바뀌면 넘김 시작/종료마다 현재 페이지가 재빌드·
  /// 재측정돼 깜빡인다. 유휴 시 [_dragDx]=0(항등 이동) + 이웃 없음이라 기존
  /// 단면/양면 렌더와 시각적으로 동일하다. (kobic#8240)
  Widget _buildTurnStack(Widget base, Size viewportSize, bool useSpread) {
    final width = viewportSize.width;
    final target = _turnDir == 0 ? null : _turnTarget(_turnDir);
    final Widget? neighbor = target == null
        ? null
        : SizedBox.fromSize(
            size: viewportSize,
            child: _composePage(
              spineIndex: target.spine,
              leftWindow: target.window,
              viewportSize: viewportSize,
              useSpread: useSpread,
              keyNamespace: 'turn',
            ),
          );
    return ClipRect(
      child: Stack(
        children: [
          Transform.translate(offset: Offset(_dragDx, 0), child: base),
          if (neighbor != null)
            Transform.translate(
              // 노출 방향 반대편에서 손가락과 함께 들어온다: revealSign<0(왼쪽
              // 드래그)이면 이웃은 오른쪽(+width)에서, revealSign>0이면 왼쪽
              // (-width)에서 시작해 _dragDx가 ±width에 도달하면 0(완전 노출).
              offset: Offset(_dragDx - _revealSign * width, 0),
              child: neighbor,
            ),
        ],
      ),
    );
  }

  /// 뷰포트 크기 기준으로 2-up spread 활성 여부를 판정한다. [widget.spread]가
  /// null이면 항상 false(단면, 기존 동작 불변).
  bool _resolveSpread(Size viewportSize) {
    final spread = widget.spread;
    if (spread == null) return false;
    return const ViewportFitter().shouldUseTwoPageSpread(
      screenWidth: viewportSize.width,
      screenHeight: viewportSize.height,
      spread: spread,
    );
  }

  /// build 도중 계산된 spread 활성 여부를 [_spreadActive]에 반영한다. build 중
  /// setState는 금지이므로, 값이 바뀌면 post-frame에 리포팅을 갱신한다. 또한
  /// spread가 켜지는 순간 왼쪽 컬럼이 짝수 윈도우가 되도록 [_windowIndex]를
  /// pair 시작으로 내림한다.
  void _syncSpreadActive(bool useSpread) {
    if (_spreadActive == useSpread) return;
    _spreadActive = useSpread;
    if (useSpread && _windowIndex.isOdd) _windowIndex -= 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportWindowState();
    });
  }

  /// PageView 아이템 하나(한 spine)를 빌드한다 — 활성 spine은 현재
  /// [_windowIndex], 비활성 spine은 0에서 시작한다. 기본 key 네임스페이스('')로
  /// [_composePage]에 위임한다(기존 동작 불변).
  Widget _buildSpineItem(int index, Size viewportSize, bool useSpread) {
    return _composePage(
      spineIndex: index,
      leftWindow: index == _pageIndex ? _windowIndex : 0,
      viewportSize: viewportSize,
      useSpread: useSpread,
      keyNamespace: '',
    );
  }

  /// 한 페이지([spineIndex]의 [leftWindow] 윈도우)를 구성한다. spread 활성 시
  /// 연속 두 윈도우(왼쪽=pair 시작, 오른쪽=+1)를 좌우 컬럼으로 배치하고,
  /// 미활성 시 단일 윈도우를 렌더한다. [keyNamespace]로 base(PageView) 페이지와
  /// 넘김 오버레이('turn') 페이지의 key/측정 상태를 분리한다 — 같은 spine을
  /// base와 오버레이가 동시에 그려도 서로 상태가 섞이지 않는다. (kobic#8240)
  Widget _composePage({
    required int spineIndex,
    required int leftWindow,
    required Size viewportSize,
    required bool useSpread,
    required String keyNamespace,
  }) {
    if (!useSpread) {
      // 단면 경로는 윈도우 인덱스가 바뀌어도 같은 위젯을 유지해야 측정/로드
      // 상태가 보존된다(윈도우 이동은 Transform.translate로만 처리) — 안정된
      // key를 쓴다.
      return _spinePageView(
        index: spineIndex,
        keySuffix: keyNamespace,
        viewportSize: viewportSize,
        windowIndex: leftWindow,
      );
    }

    // 왼쪽 컬럼 = pair 시작 윈도우(짝수)로 정렬.
    final leftW = leftWindow - (leftWindow % 2);
    final rightW = leftW + 1;
    final rawCount = _windowCounts[spineIndex] ?? 1;
    // 각 컬럼은 절반 폭 뷰포트로 렌더한다 — non-fixed는 반폭 리플로우,
    // fixedPageSize(A4)는 반폭 컬럼에 contain-fit된다.
    final columnSize = Size(viewportSize.width / 2, viewportSize.height);

    // 좌우 컬럼은 슬롯 고정 key(L/R)를 써서, 윈도우를 넘겨도 같은 위젯을
    // 유지한다(windowIndex만 바뀌어 측정/로드 상태 보존).
    final leftColumn = _spinePageView(
      index: spineIndex,
      keySuffix: '${keyNamespace}L',
      viewportSize: columnSize,
      windowIndex: leftW,
    );
    // 오른쪽 윈도우가 실제로 존재할 때만 렌더한다(홀수 마지막 페이지의 없는
    // verso는 빈칸). 측정 전(rawCount==1)에는 오른쪽이 비어 있다가 측정 후
    // 채워지는 것이 정상.
    final Widget rightColumn = rightW < rawCount
        ? _spinePageView(
            index: spineIndex,
            keySuffix: '${keyNamespace}R',
            viewportSize: columnSize,
            windowIndex: rightW,
          )
        : const SizedBox.expand();

    // RTL(reverse)이면 왼쪽 슬롯에 오른쪽 페이지를 두어 물리적 배치를 반전한다
    // (fixed_layout_spread의 RTL 원칙과 동일). 읽기 순서(다음=+1)는 불변.
    final columns = widget.reverse
        ? <Widget>[
            Expanded(child: rightColumn),
            Expanded(child: leftColumn),
          ]
        : <Widget>[
            Expanded(child: leftColumn),
            Expanded(child: rightColumn),
          ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columns,
    );
  }

  /// 한 컬럼(또는 단면)의 [_SpinePageView]를 생성하는 공용 헬퍼. 두 컬럼이
  /// 각각 측정을 보고해도 부모 캐시 비교로 idempotent하다.
  Widget _spinePageView({
    required int index,
    required String keySuffix,
    required Size viewportSize,
    required int windowIndex,
  }) {
    return _SpinePageView(
      // 같은 href가 spine에 중복 등장할 수 있어 index로 구분. spread 컬럼은
      // 슬롯(L/R) 접미로 구분해 좌우 상태가 섞이지 않게 한다.
      key: ValueKey('reflowable-page-$index$keySuffix'),
      load: _loadSpine(widget.book.spine[index].href),
      baseHref: widget.book.spine[index].href,
      spineItem: widget.book.spine[index],
      fontSize: widget.fontSize,
      lineHeight: widget.lineHeight,
      fontFamily: widget.fontFamily,
      imageLoader: widget.imageLoader,
      onLinkTap: widget.onLinkTap,
      forceVertical: widget.forceVertical,
      viewportSize: viewportSize,
      fixedPageSize: widget.fixedPageSize,
      contentBuilder: widget.contentBuilder,
      windowIndex: windowIndex,
      onWindowCountMeasured: (count) => _handleWindowMeasured(index, count),
    );
  }
}

/// 단일 spine 페이지 뷰 — spine 콘텐츠를 한 번 렌더링해 실제 높이를 측정하고,
/// [OverflowBox]+[Transform.translate]로 화면 크기([viewportSize]) 만큼의
/// "윈도우"만 잘라 보여준다(open-epub#221). 텍스트를 재분할하지 않으므로
/// 이미지·표·링크는 그대로 유지된다. 윈도우 높이는 화면 높이가 아니라 본문
/// 줄 높이의 정수 배로 내림한 값([_SpinePageViewState._pageHeight]) — 남는
/// 자투리는 페이지 아래쪽 여백으로 두어, 본문 텍스트 줄이 페이지 경계에서
/// 위아래로 잘리지 않는다(open-epub#228 후속). 제목·이미지·표처럼 본문 줄
/// 높이와 다른 요소는 이 격자에 완전히 맞지 않아 여전히 경계에서 잘릴 수
/// 있다.
///
/// 콘텐츠 revision 변경으로 [load]가 교체되면 새 로드가 끝날 때까지 직전
/// 콘텐츠를 유지한다(스피너 flash 방지). (open-epub#62)
class _SpinePageView extends StatefulWidget {
  const _SpinePageView({
    super.key,
    required this.load,
    required this.baseHref,
    required this.fontSize,
    required this.lineHeight,
    required this.imageLoader,
    required this.onLinkTap,
    required this.forceVertical,
    required this.viewportSize,
    required this.windowIndex,
    required this.onWindowCountMeasured,
    this.spineItem,
    this.fixedPageSize,
    this.contentBuilder,
    this.fontFamily,
  });

  final Future<String> load;

  /// 이 spine 문서의 OPF 기준 href — 본문 내 상대 리소스(`<img>`) 해석 기준.
  final String baseHref;
  final double fontSize;
  final double lineHeight;

  /// 본문 강제 서체(kobic Epic #7964 S3). null이면 기본 서체.
  final String? fontFamily;
  final ImageLoader? imageLoader;
  final EpubLinkTapCallback? onLinkTap;
  final bool forceVertical;

  /// 실제 화면(페이지) 크기. [fixedPageSize]가 없으면 이 크기만큼씩
  /// 콘텐츠를 잘라 보여준다(기존 동작). 있으면 고정 크기 결과물을 이
  /// 실제 화면에 맞추는 contain-fit의 대상 viewport로 쓰인다.
  final Size viewportSize;

  /// 지금 보여줄 윈도우 인덱스(0-based).
  final int windowIndex;

  /// 콘텐츠 전체 높이 측정이 끝나면(또는 갱신되면) 호출 — 윈도우 수 =
  /// `ceil(측정높이 / 리플로우 기준 높이)`.
  final ValueChanged<int> onWindowCountMeasured;

  /// 원본 spine 항목 — [contentBuilder]에 전달할 합성 [EpubSpineItem] 구성용
  /// (kobic Epic #7964 S1). null이면 `baseHref`만으로 최소 정보를 구성한다.
  final EpubSpineItem? spineItem;

  /// 논리 고정 페이지 크기(A4 등, kobic Epic #7964 S1). 값이 있으면
  /// 리플로우·윈도잉이 이 고정 크기 기준으로 이루어지고, 결과가
  /// [viewportSize]에 contain-fit 스케일된다. null이면 기존처럼 실제 화면
  /// 크기 기준으로 윈도잉한다.
  final Size? fixedPageSize;

  /// [fixedPageSize] 모드 전용 콘텐츠 래핑 훅(필기 캔버스 등, S8.6과 동일
  /// 계약). [fixedPageSize]가 null이면 무시된다.
  final FixedLayoutContentBuilder? contentBuilder;

  @override
  State<_SpinePageView> createState() => _SpinePageViewState();
}

class _SpinePageViewState extends State<_SpinePageView> {
  /// 마지막으로 성공 로드된 XHTML — 재로드 동안 표시 유지용.
  String? _lastData;

  /// 콘텐츠 실제 렌더 높이 측정용 키. 패딩을 포함한 전체 콘텐츠에 부착한다.
  final GlobalKey _measureKey = GlobalKey();
  double? _measuredHeight;

  /// 마지막으로 윈도우 수를 계산한 리플로우 기준 크기([_reflowSize]).
  /// [fixedPageSize] 전환처럼 콘텐츠 높이는 그대로인데 페이지 높이 기준만
  /// 바뀌는 경우, 측정 높이만으로는 재계산 필요 여부를 판단할 수 없다 —
  /// 이 값도 함께 비교해야 한다(kobic Epic #7964 S1, 회귀 방지).
  Size? _lastMeasuredReflowSize;

  /// 리플로우·윈도잉 기준 크기 — [_SpinePageView.fixedPageSize]가 있으면
  /// 그 고정 크기, 없으면 실제 화면 크기(기존 동작과 동일).
  Size get _reflowSize => widget.fixedPageSize ?? widget.viewportSize;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.load,
      builder: (context, snap) {
        if (snap.hasData) _lastData = snap.data;
        final data = snap.hasData ? snap.data : _lastData;
        if (data == null) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '본문을 불러올 수 없습니다.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        // SizeChangedLayoutNotifier로 감싸 콘텐츠 실제 렌더 높이가 바뀔 때마다
        // 알림을 받는다 — 이미지가 placeholder(32x32)로 먼저 그려졌다가 비동기
        // 로드 후 실제 크기로 바뀌는 경우처럼, 이 위젯이 다시 build되지 않아도
        // (오직 하위 _RemoteImage만 rebuild) 레이아웃 크기는 바뀌므로 재측정이
        // 필요하다. 이게 없으면 이미지가 있는 spine에서 윈도우 수가 과소
        // 측정돼 뒷부분 콘텐츠에 영영 스와이프로 도달할 수 없다.
        final content = SizeChangedLayoutNotifier(
          key: _measureKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: buildReflowableHtml(
              data: data,
              baseHref: widget.baseHref,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              fontFamily: widget.fontFamily,
              imageLoader: widget.imageLoader,
              onLinkTap: widget.onLinkTap,
              forceVertical: widget.forceVertical,
            ),
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

        final reflowSize = _reflowSize;
        final pageWidth = reflowSize.width;
        final pageHeight = _pageHeight(reflowSize.height);
        final windowed = NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (notification) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
            return false;
          },
          child: ClipRect(
            child: SizedBox(
              width: pageWidth,
              height: pageHeight,
              // 화면(또는 고정 페이지) 높이가 줄 높이의 정확한 배수가
              // 아니면 남는 자투리는 아래쪽 여백으로 남긴다(콘텐츠는 위쪽에
              // 정렬) — 그래야 글자 줄이 페이지 경계에서 위아래로 잘리지
              // 않는다. (open-epub#228 후속)
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: pageWidth,
                  height: pageHeight,
                  child: OverflowBox(
                    minWidth: pageWidth,
                    maxWidth: pageWidth,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(0, -widget.windowIndex * pageHeight),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final fixedPageSize = widget.fixedPageSize;
        if (fixedPageSize == null) return windowed;
        // 고정 크기 모드 — 실제 화면에 contain-fit 스케일하고, 있으면
        // 필기 등 콘텐츠 래핑 훅을 논리 좌표 공간(스케일 전)에서 적용한다.
        // (kobic Epic #7964 S1)
        return _FixedSizeFit(
          logicalSize: fixedPageSize,
          viewportSize: widget.viewportSize,
          content: windowed,
          contentBuilder: widget.contentBuilder == null
              ? null
              : (ctx, logicalSize, wrappedContent) => widget.contentBuilder!(
                    ctx,
                    _windowSpineItem(),
                    logicalSize,
                    wrappedContent,
                  ),
        );
      },
    );
  }

  /// 원본 spine 항목에 윈도우 인덱스를 합성한 [EpubSpineItem]. href/idref에
  /// `#p{windowIndex}` 접미를 붙여 소비자(kobic)가 윈도우별 고유 앵커/캐시
  /// 키를 얻을 수 있게 한다. (kobic Epic #7964 S1)
  EpubSpineItem _windowSpineItem() {
    final base = widget.spineItem;
    final suffix = '#p${widget.windowIndex}';
    return EpubSpineItem(
      idref: '${base?.idref ?? widget.baseHref}$suffix',
      href: '${widget.baseHref}$suffix',
      mediaType: base?.mediaType ?? 'application/xhtml+xml',
      linear: base?.linear ?? true,
      properties: base?.properties ?? const [],
      mediaOverlayHref: base?.mediaOverlayHref,
    );
  }

  /// 실제 페이지(윈도우) 높이 — 리플로우 기준 높이([_reflowSize])를 본문 줄
  /// 높이(`fontSize * lineHeight`)의 정수 배로 내림한 값. 기준 높이가 줄
  /// 하나보다 작거나 줄 높이를 계산할 수 없으면(0 이하) 기준 높이를 그대로
  /// 쓴다(폴백). 표·이미지·제목처럼 본문 줄 높이와 다른 요소는 이 격자에
  /// 완전히 맞지 않아 여전히 경계에서 잘릴 수 있다 — 본문 텍스트 줄이
  /// 잘리는 흔한 경우를 우선 해결한다. (open-epub#228 후속)
  double _pageHeight(double baseHeight) {
    final lineHeightPx = widget.fontSize * widget.lineHeight;
    if (lineHeightPx <= 0 || baseHeight <= 0) return baseHeight;
    final lines = (baseHeight / lineHeightPx).floor();
    return lines >= 1 ? lines * lineHeightPx : baseHeight;
  }

  /// 콘텐츠(패딩 포함) 렌더 높이를 읽어 윈도우 수를 계산해 보고한다. 초기
  /// 빌드 후(post-frame)와 [SizeChangedLayoutNotification] 수신 시(비동기
  /// 이미지 로드 등으로 렌더 높이가 바뀔 때) 모두 호출된다. 결과가 같으면
  /// [onWindowCountMeasured]를 다시 호출하지 않으므로(부모의 캐시 비교)
  /// 반복 호출 비용이 크지 않다.
  void _measure() {
    if (!mounted) return;
    final renderObject = _measureKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final height = renderObject.size.height;
    final reflowSize = _reflowSize;
    // 측정 높이와 리플로우 기준 크기가 둘 다 이전과 같으면 재계산 불필요.
    // 콘텐츠는 그대로인데 fixedPageSize만 바뀌는 경우 높이만으로는 이
    // 판단이 불가능하다 — reflowSize도 함께 비교해야 한다. (kobic Epic
    // #7964 S1)
    if (height == _measuredHeight && reflowSize == _lastMeasuredReflowSize) {
      return;
    }
    _measuredHeight = height;
    _lastMeasuredReflowSize = reflowSize;
    final pageHeight = _pageHeight(reflowSize.height);
    final windowCount = pageHeight <= 0
        ? 1
        : (height / pageHeight).ceil().clamp(1, 1 << 20).toInt();
    widget.onWindowCountMeasured(windowCount);
  }
}

/// [_SpinePageView.fixedPageSize] 모드 전용 — 고정 논리 크기 콘텐츠를 실제
/// [viewportSize]에 contain-fit 스케일한다([ViewportFitter], fixed-layout
/// 엔진(`FixedLayoutPage`)과 동일 원칙 — 필기가 이 고정 논리 좌표에
/// 앵커링될 수 있도록 스케일 전 좌표 공간을 [contentBuilder]에 노출한다).
/// (kobic Epic #7964 S1)
class _FixedSizeFit extends StatelessWidget {
  const _FixedSizeFit({
    required this.logicalSize,
    required this.viewportSize,
    required this.content,
    this.contentBuilder,
  });

  final Size logicalSize;
  final Size viewportSize;
  final Widget content;

  /// (context, logicalSize, content) → 스케일 전 논리 좌표 공간에서 감싼
  /// 위젯. null이면 [content]를 그대로 스케일한다.
  final Widget Function(BuildContext, Size, Widget)? contentBuilder;

  static const _fitter = ViewportFitter();

  @override
  Widget build(BuildContext context) {
    final wrap = contentBuilder;
    final logicalChild =
        wrap == null ? content : wrap(context, logicalSize, content);
    final scale = _fitter.computeScale(
      pageWidth: logicalSize.width,
      pageHeight: logicalSize.height,
      viewportWidth: viewportSize.width,
      viewportHeight: viewportSize.height,
    );
    final fittedW = logicalSize.width * scale;
    final fittedH = logicalSize.height * scale;
    return Align(
      child: SizedBox(
        width: fittedW,
        height: fittedH,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: logicalChild,
          ),
        ),
      ),
    );
  }
}
