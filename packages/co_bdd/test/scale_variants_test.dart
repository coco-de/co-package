// 스케일 불변성 코어 자체 검증 (coco-de/unibook#9231 에서 이관).
//
// 디자인 시스템 크기 배율은 프로젝트 어댑터가 적용하므로, 여기서는 두 배율의
// 합성값(`scaling × textScaler`)을 `MediaQuery.textScaler` 로 얹는 최소 앱으로
// 같은 실패 모드를 재현한다 — 판정 함수가 잡는지가 관심사다.
import 'package:co_bdd/co_bdd.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 고정 픽셀 높이 예산 안티패턴 재현용 상수.
///
/// 기본 배율(글꼴 14px · 줄 높이 ≈20px)에서 2줄 ≈ 40px 이므로 44 는 여유가
/// 있지만, 글꼴 배율이 오르면 2줄이 예산을 넘겨 `RenderFlex` 가 오버플로를
/// 보고한다 — 스케일 불변 규약이 금지하는 패턴.
const double _kFixedHeightBudget = 44;

/// 높이를 고정 예산으로 못박은 2줄 레이아웃.
const Widget _kFixedBudgetLayout = SizedBox(
  height: _kFixedHeightBudget,
  child: Column(children: [Text('첫째 줄'), Text('둘째 줄')]),
);

/// 라인박스보다 작은 고정 높이 — **예외 없이 조용히 잘리는** 안티패턴.
///
/// 기본 배율에서도 한 줄 라인박스(≈20px)가 12px 예산을 넘지만, 이 형태는
/// `RenderFlex` 를 거치지 않아 오버플로가 **보고되지 않는다**. coco-de/unibook#9558 이 확정한
/// 무음 클리핑 6건이 전부 이 구조다.
const Widget _kSilentClipLayout = SizedBox(height: 12, child: Text('잘리는 본문'));

/// `maxLines` + `ellipsis` 로 **의도적으로** 축약한 레이아웃 — 위반이 아니다.
const Widget _kEllipsizedLayout = SizedBox(
  height: 60,
  width: 60,
  child: Text(
    '아주 긴 문장이 들어와서 한 줄에 절대 담기지 않는다',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
);

/// 합성 글꼴 배율을 적용한 최소 앱.
Widget _app({required ScaleVariant variant, required Widget child}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(variant.compoundTextScale)),
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  group('testScaleVariants 조합 매트릭스', () {
    final observed = <ScaleVariant>[];

    testScaleVariants('본문이 조합마다 실행된다', scaling: 1.25, (tester, variant) async {
      observed.add(variant);
      await tester.pumpWidget(
        _app(variant: variant, child: const SizedBox.shrink()),
      );
    });

    // 위 4개 조합이 모두 끝난 뒤 실행된다(선언 순서 = 실행 순서).
    test('scaling 은 호출부가 준 값 하나, textScaler 는 기본 4단계다', () {
      expect(observed, hasLength(kDefaultScaleInvariantTextScalers.length));
      expect(
        observed.map((item) => item.textScaler).toList(),
        kDefaultScaleInvariantTextScalers,
      );
      expect(observed.map((item) => item.scaling).toSet(), {1.25});
    });

    test('textScalers 축은 WCAG AA 상한 200% 와 실기기 재현값 1.15 를 포함한다', () {
      expect(kDefaultScaleInvariantTextScalers, contains(2.0));
      expect(kDefaultScaleInvariantTextScalers, contains(1.15));
    });
  });

  group('테스트 이름·실패 리포트에 조합이 노출된다', () {
    test('label 에 scaling·textScaler 와 합성 배율이 모두 담긴다', () {
      const variant = ScaleVariant(scaling: 1.25, textScaler: 1.15);

      expect(variant.label, contains('scaling 1.25'));
      expect(variant.label, contains('textScaler 1.15'));
      expect(variant.compoundTextScale, closeTo(1.4375, 1e-9));
      expect(variant.label, contains('1.4375'));
    });
  });

  group('expectNoLayoutOverflow — 고정 예산 실패 모드 재현', () {
    testWidgets('배율 1.0 단일 조건에서는 고정 예산이 통과한다', (tester) async {
      await tester.pumpWidget(
        _app(
          variant: const ScaleVariant(scaling: 1, textScaler: 1),
          child: _kFixedBudgetLayout,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('글꼴 배율이 오르면 같은 레이아웃에서 오버플로가 감지된다', (tester) async {
      const variant = ScaleVariant(scaling: 1.25, textScaler: 2);
      await tester.pumpWidget(
        _app(variant: variant, child: _kFixedBudgetLayout),
      );

      final exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(exception.toString(), contains('overflowed'));
    });
  });

  group('surfaceSize', () {
    testScaleVariants(
      '지정한 논리 픽셀 뷰포트가 적용된다',
      scaling: 1.25,
      (tester, variant) async {
        Size? actualSize;

        await tester.pumpWidget(
          _app(
            variant: variant,
            child: Builder(
              builder: (context) {
                actualSize = MediaQuery.sizeOf(context);

                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(actualSize, const Size(800, 1200));
      },
      surfaceSize: const Size(800, 1200),
      textScalers: const [1],
    );
  });

  group('expectNoTextClipping — 무음 클리핑', () {
    testScaleVariants('무음 클리핑을 검출한다 (레이아웃 예외 단정은 통과)', scaling: 1.25, (
      tester,
      variant,
    ) async {
      await tester.pumpWidget(
        _app(variant: variant, child: _kSilentClipLayout),
      );
      await tester.pump();

      // 교차축 클램프는 `RenderFlex overflowed` 를 보고하지 않는다.
      expectNoLayoutOverflow(tester, variant);

      expect(
        () => expectNoTextClipping(tester, variant),
        throwsA(isA<TestFailure>()),
        reason: '고정 높이에 클램프된 라인박스를 검출하지 못했습니다',
      );
    });

    testScaleVariants('여유가 있으면 통과한다', scaling: 1.25, (tester, variant) async {
      await tester.pumpWidget(
        _app(variant: variant, child: const Text('짧은 본문')),
      );
      await tester.pump();

      expectNoTextClipping(tester, variant);
    });

    testScaleVariants('maxLines + ellipsis 축약은 위반이 아니다', scaling: 1.25, (
      tester,
      variant,
    ) async {
      await tester.pumpWidget(
        _app(variant: variant, child: _kEllipsizedLayout),
      );
      await tester.pump();

      expectNoTextClipping(tester, variant);
    });

    testWidgets('allowClipped 에 넣은 텍스트는 건너뛴다', (tester) async {
      const variant = ScaleVariant(scaling: 1.25, textScaler: 1);
      await tester.pumpWidget(
        _app(variant: variant, child: _kSilentClipLayout),
      );
      await tester.pump();

      expectNoTextClipping(tester, variant, allowClipped: const ['잘리는 본문']);
    });

    testWidgets('scope 밖의 클리핑은 보지 않는다', (tester) async {
      const variant = ScaleVariant(scaling: 1.25, textScaler: 1);
      await tester.pumpWidget(
        _app(
          variant: variant,
          child: const Column(
            children: [
              KeyedSubtree(key: Key('safe'), child: Text('짧은 본문')),
              _kSilentClipLayout,
            ],
          ),
        ),
      );
      await tester.pump();

      expectNoTextClipping(
        tester,
        variant,
        scope: find.byKey(const Key('safe')),
      );
    });
  });
}
