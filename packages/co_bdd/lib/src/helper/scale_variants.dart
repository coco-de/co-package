// 스케일 불변성 테스트 코어 (coco-de/unibook#9231 · Epic #9228 에서 이관).
//
// ## 왜 필요한가
//
// 실기기에서는 두 개의 독립된 배율축이 **곱셈 합성**된다:
//
// - **디자인 시스템 크기 배율** (예: coui `AdaptiveScaling` 1.25 — Android·iOS 에
//   자동 적용) — 글꼴·아이콘·radius·간격에 **전부** 걸린다.
// - **`MediaQuery.textScaler`** (1.0~2.0) — OS 글꼴 크기 설정. 텍스트 렌더에만
//   걸린다.
//
// 본문 글꼴의 실효 배율은 `scaling × textScaler` 이고, 시스템 글꼴을 한 단계
// 올린 기기(1.15)에서는 1.25 × 1.15 = **1.4375배**가 된다. 고정 픽셀 높이
// 예산을 합산해 둔 레이아웃은 이 지점에서 터진다 — 배율 1.0 단일 조건의 위젯
// 테스트는 통과한 채로 실기기 E2E 를 깨뜨린 실사고가 있다.
//
// ## 무엇을 소유하는가
//
// 조합 **축**(textScaler 목록 · 조합별 테스트 등록)과 **판정**(레이아웃 예외 ·
// 무음 텍스트 클리핑)만 둔다. 배율을 실제 위젯 트리에 적용하는 방법(디자인
// 시스템 테마 · 기본 크기 배율)은 프로젝트 어댑터가 소유한다 — co_bdd 는 디자인
// 시스템에 의존하지 않는다.
import 'package:flutter/rendering.dart'
    show RenderObject, RenderParagraph, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart' show immutable, isTest;

/// 스케일 불변성 검증의 표준 `textScaler` 축.
///
/// - `1.0` — 기준선(회귀 감지용)
/// - `1.15` — 실기기 재현값(시스템 글꼴 한 단계 상향)
/// - `1.3` — 중간 상향
/// - `2.0` — WCAG 1.4.4 AA 상한(200%)
///
/// `textScaler` 를 클램프하는 구현은 규약 위반이다 — 2.0 조합이 그 회귀를
/// 잡는다.
const List<double> kDefaultScaleInvariantTextScalers = <double>[
  1,
  1.15,
  1.3,
  2,
];

/// 스케일 조건 한 조합. [testScaleVariants] 가 본문에 주입한다.
@immutable
class ScaleVariant {
  /// [scaling] × [textScaler] 조합.
  const ScaleVariant({required this.scaling, required this.textScaler});

  /// 디자인 시스템 크기 배율 — 글꼴·아이콘·radius·간격 전부에 걸린다.
  final double scaling;

  /// `MediaQuery.textScaler` 선형 배율 — 텍스트 렌더에만 걸린다.
  final double textScaler;

  /// 본문 글꼴에 실제로 적용되는 합성 배율 (`scaling × textScaler`).
  double get compoundTextScale => scaling * textScaler;

  /// 실패 메시지·테스트 이름에 노출되는 조합 식별 라벨.
  String get label =>
      'scaling $scaling × textScaler $textScaler '
      '(글꼴 실효 ${compoundTextScale.toStringAsFixed(4)}×)';

  @override
  String toString() => 'ScaleVariant($label)';

  @override
  bool operator ==(Object other) =>
      other is ScaleVariant &&
      other.scaling == scaling &&
      other.textScaler == textScaler;

  @override
  int get hashCode => Object.hash(scaling, textScaler);
}

/// 동일한 위젯 테스트 본문을 [scaling] × [textScalers] 전 조합에서 실행한다.
///
/// 조합마다 독립된 `testWidgets` 가 등록되고, 테스트 이름과 실패 시 출력에
/// [ScaleVariant.label](`scaling`·`textScaler` 값)이 포함되어 어느 조합이
/// 깨졌는지 즉시 식별된다.
///
/// [scaling] 은 **필수**다 — 디자인 시스템마다 기본 크기 배율이 달라 co_bdd 가
/// 기본값을 정할 수 없고, 1.0 으로 조용히 떨어지면 실기기 축을 잃는다. 프로젝트
/// 어댑터가 자기 기본값(예: coui 모바일 1.25)을 채운 래퍼를 제공한다.
///
/// [surfaceSize] 를 주면 논리 픽셀 뷰포트를 그 크기로 고정하고
/// (`devicePixelRatio = 1.0`) 테스트 종료 시 자동 복원한다.
///
/// `@isTest` 는 호출부 관점의 선언이다 — 이 호출 하나가 테스트를 등록한다는 사실을
/// 분석기에 알린다. `@isTestGroup` 은 **이 호출 자체**를 그룹으로 보게 만들어
/// "빈 그룹" 오탐이 늘어난다.
@isTest
void testScaleVariants(
  String description,
  Future<void> Function(WidgetTester tester, ScaleVariant variant) body, {
  required double scaling,
  List<double> textScalers = kDefaultScaleInvariantTextScalers,
  Size? surfaceSize,
  bool? skip,
  Timeout? timeout,
  Object? tags,
}) {
  for (final textScaler in textScalers) {
    final variant = ScaleVariant(scaling: scaling, textScaler: textScaler);

    testWidgets(
      '$description [${variant.label}]',
      (tester) async {
        printOnFailure('스케일 조합: ${variant.label}');

        if (surfaceSize != null) {
          tester.view
            ..physicalSize = surfaceSize
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
        }

        await body(tester, variant);
      },
      skip: skip,
      timeout: timeout,
      tags: tags,
    );
  }
}

/// 레이아웃 예외(`RenderFlex overflowed` 등)가 없음을 단정한다.
///
/// Flutter 는 오버플로를 `FlutterError.reportError` 로 보고하고 위젯 테스트는
/// 이를 보류 예외로 모아두므로, `tester.takeException()` 이 그 유무를 알려준다.
/// 실패 메시지에 [variant] 라벨을 실어 어느 배율 조합에서 터졌는지 남긴다.
void expectNoLayoutOverflow(WidgetTester tester, ScaleVariant variant) {
  expect(
    tester.takeException(),
    isNull,
    reason:
        '${variant.label} 조합에서 레이아웃 예외가 발생했습니다. '
        '고정 픽셀 높이 예산 합산을 콘텐츠 주도 레이아웃으로 전환하세요.',
  );
}

/// 부동소수 오차 허용치. 라인박스 높이는 폰트 메트릭에서 나오므로 정확히
/// 일치하지 않는다.
const double _kClipTolerance = 0.01;

/// 실패 메시지에 실을 텍스트 길이 상한.
const int _kSnippetLength = 24;

/// 텍스트가 고정 높이에 **조용히 잘리는지** 단정한다.
///
/// [expectNoLayoutOverflow] 만으로는 부족하다. 그 검사는 `RenderFlex` 의 **주축**
/// 초과만 잡는데, `Row` 의 교차축(세로)이나 고정 `height` 컨테이너가 라인박스를
/// 클램프하는 경우는 **예외를 던지지 않는다** — 글자 아랫부분이 잘릴 뿐이라
/// 테스트는 green 이고 사용자만 깨진 화면을 본다 (coco-de/unibook#9558 전수 조사:
/// 레이아웃 위반 13건 중 6건이 그 검사를 통과했다).
///
/// 판정은 라인박스의 **본질 높이**(`getMaxIntrinsicHeight`)와 **실제 배정 높이**를
/// 비교한다. 배정이 더 작으면 클램프된 것이다. 예외를 두어야 하면 [allowClipped]
/// 에 해당 텍스트를 넣되 **사유를 주석으로 남길 것** — 이 목록이 늘면 가드가
/// 무의미해진다.
///
/// [scope] 를 주지 않으면 pump 된 트리 **전체**를 훑는다. 검사 지점을 일일이
/// 지정하게 하면 결국 빠뜨리므로 전체 순회가 기본이다.
void expectNoTextClipping(
  WidgetTester tester,
  ScaleVariant variant, {
  Finder? scope,
  Iterable<String> allowClipped = const [],
}) {
  final root = scope == null
      ? tester.binding.rootElement?.renderObject
      : tester.renderObject<RenderObject>(scope);
  if (root == null) return;

  final allowed = allowClipped.toSet();
  final clipped = <String>[];

  void visit(RenderObject node) {
    if (node is RenderParagraph && node.hasSize) {
      final report = _clipReportOf(node, allowed);
      if (report != null) clipped.add(report);
    }
    node.visitChildren(visit);
  }

  visit(root);

  expect(
    clipped,
    isEmpty,
    reason:
        '${variant.label} 조합에서 텍스트가 고정 높이에 클램프돼 잘렸습니다.\n'
        '${clipped.join('\n')}\n'
        '이 형태는 `RenderFlex overflowed` 예외를 던지지 않아 '
        'expectNoLayoutOverflow 로는 잡히지 않습니다. 고정 height 를 '
        '`minHeight` 하한으로 바꾸거나 콘텐츠 주도로 전환하세요.',
  );
}

/// 라인박스가 배정 높이를 넘었으면 실패 메시지를, 아니면 `null` 을 돌려준다.
///
/// ⚠️ **`didExceedMaxLines` 로 거르지 말 것.** 이 플래그는 "`maxLines` 로 의도적
/// 축약"만이 아니라 **높이 제약으로 잘린 경우에도 true** 다. 필터로 쓰면 정작
/// 잡아야 할 무음 클리핑을 전부 놓친다.
///
/// 가로 `ellipsis` 축약은 높이에 영향이 없어 여기서 오탐이 되지 않는다.
/// `maxLines` 가 있으면 intrinsic 이 그 줄 수까지만 계산되므로, 배정이 그보다
/// 작을 때만(= 실제로 잘릴 때만) 걸린다.
String? _clipReportOf(RenderParagraph paragraph, Set<String> allowed) {
  final label = paragraph.text.toPlainText();
  if (allowed.contains(label)) return null;

  // 높이 상한이 없으면 **클램프가 물리적으로 불가능하다** — 라인박스는 필요한
  // 만큼 늘어나므로 검사할 것이 없다.
  //
  // ⚠️ 이 조기 반환이 없으면 정상 레이아웃이 오탐된다. 아래 `needed` 는
  // `size.width` 로 intrinsic 을 묻는데, 느슨한 폭 제약(`0<=w<=N`)에서 한 줄로
  // 들어간 텍스트의 `size.width` 는 **배정 폭이 아니라 글자가 실제로 쓴 폭**이다.
  // 그 폭을 되물으면 "이 폭이면 한 줄에 안 들어간다(=2줄 필요)" 는 답이 돌아온다
  // (coco-de/unibook#11157).
  if (paragraph.constraints.maxHeight == double.infinity) return null;

  final size = paragraph.size;
  final needed = paragraph.getMaxIntrinsicHeight(size.width);
  if (size.height + _kClipTolerance >= needed) return null;

  return '"${_snippet(label)}" — '
      '배정 ${size.height.toStringAsFixed(1)}dp '
      '< 필요 ${needed.toStringAsFixed(1)}dp';
}

/// 실패 메시지용 텍스트 축약. 본문이 길면 앞부분만 남긴다.
String _snippet(String text) {
  final flat = text.replaceAll('\n', ' ').trim();

  return flat.length <= _kSnippetLength
      ? flat
      : '${flat.substring(0, _kSnippetLength)}…';
}
