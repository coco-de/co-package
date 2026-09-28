import 'dart:async';

import 'package:co_bdd/co_bdd.dart';
import 'package:co_bdd/shared_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공유 step 의 동작 테스트.
///
/// 판정 step 은 **통과해야 하는 경우와 실패해야 하는 경우를 함께** 고정한다 —
/// 항상 통과하는 step 은 어떤 화면에서도 green 이라 아무것도 검증하지 않는다.
void main() {
  Future<WidgetTestDriver> pump(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
    return WidgetTestDriver(tester);
  }

  // `expectLater(step(), throwsA(...))` 를 쓰지 않는다 — step 이 인자 평가 시점에
  // 이미 `tester.pump()` 를 부르면 expectLater 의 가드와 겹쳐 'Guarded function
  // conflict' 로 죽는다. 클로저로 받아 순서대로 실행한다.
  Future<void> expectFails(Future<void> Function() step) async {
    try {
      await step();
    } on TestFailure {
      return;
    }
    fail('실패해야 하는 판정이 통과했다');
  }

  group('동작 step', () {
    testWidgets('iTapTheWidget should tap the keyed widget', (tester) async {
      var taps = 0;
      final driver = await pump(
        tester,
        TextButton(
          key: const Key('save_button'),
          onPressed: () => taps++,
          child: const Text('저장'),
        ),
      );

      await iTapTheWidget(driver, 'save_button');

      expect(taps, 1);
    });

    testWidgets('iTapTheText should tap the widget with the text', (
      tester,
    ) async {
      var taps = 0;
      final driver = await pump(
        tester,
        TextButton(onPressed: () => taps++, child: const Text('로그인')),
      );

      await iTapTheText(driver, '로그인');

      expect(taps, 1);
    });

    testWidgets('iEnterInTheWidget / iClearTheWidget should edit the field', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final driver = await pump(
        tester,
        TextField(key: const Key('search_field'), controller: controller),
      );

      await iEnterInTheWidget(driver, '검색어', 'search_field');
      expect(controller.text, '검색어');

      await iClearTheWidget(driver, 'search_field');
      expect(controller.text, isEmpty);
    });

    testWidgets('iLongPressTheWidget should long press', (tester) async {
      var longPresses = 0;
      final driver = await pump(
        tester,
        GestureDetector(
          key: const Key('book_item'),
          behavior: HitTestBehavior.opaque,
          onLongPress: () => longPresses++,
          child: const SizedBox(width: 100, height: 100),
        ),
      );

      await iLongPressTheWidget(driver, 'book_item');

      expect(longPresses, 1);
    });

    testWidgets('iTapTheWidgetAtIndex should tap the N-th match (0-based)', (
      tester,
    ) async {
      final tapped = <int>[];
      final driver = await pump(
        tester,
        Column(
          children: [
            // 같은 Key 는 형제끼리 겹칠 수 없다(Duplicate keys) — 실제 목록처럼
            // 항목마다 부모를 따로 둔다.
            for (var i = 0; i < 3; i++)
              KeyedSubtree(
                key: ValueKey(i),
                child: TextButton(
                  key: const Key('book_item'),
                  onPressed: () => tapped.add(i),
                  child: Text('$i'),
                ),
              ),
          ],
        ),
      );

      await iTapTheWidgetAtIndex(driver, 'book_item', '1');

      expect(tapped, [1]);
    });

    testWidgets('iScrollUntilTheWidgetIsVisible should bring it on screen', (
      tester,
    ) async {
      final driver = await pump(
        tester,
        ListView.builder(
          itemCount: 100,
          itemBuilder: (_, i) => SizedBox(
            key: i == 20 ? const Key('target') : null,
            height: 50,
            child: Text('$i'),
          ),
        ),
      );
      expect(find.byKey(const Key('target')), findsNothing);

      await iScrollUntilTheWidgetIsVisible(driver, 'target');

      expect(find.byKey(const Key('target')).hitTestable(), findsOneWidget);
    });

    testWidgets('iWaitForSeconds should advance time', (tester) async {
      final driver = await pump(tester, const _DelayedLabel());
      expect(find.text('done'), findsNothing);

      await iWaitForSeconds(driver, '2');

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('iConfirmDeletion / iTapTheNextPageButton use CommonKeys', (
      tester,
    ) async {
      final tapped = <String>[];
      final driver = await pump(
        tester,
        Column(
          children: [
            TextButton(
              key: CommonKeys.confirmButton,
              onPressed: () => tapped.add('confirm'),
              child: const Text('확인'),
            ),
            TextButton(
              key: CommonKeys.nextPageButton,
              onPressed: () => tapped.add('next'),
              child: const Text('다음'),
            ),
          ],
        ),
      );

      await iConfirmDeletion(driver);
      await iTapTheNextPageButton(driver);

      expect(tapped, ['confirm', 'next']);
    });
  });

  group('표시 판정 step', () {
    testWidgets('theWidgetShouldBeDisplayed', (tester) async {
      final driver = await pump(tester, const SizedBox(key: Key('book_list')));

      await theWidgetShouldBeDisplayed(driver, 'book_list');
      await expectFails(() => theWidgetShouldBeDisplayed(driver, 'nope'));
    });

    testWidgets('theWidgetShouldNotBeDisplayed', (tester) async {
      final driver = await pump(tester, const SizedBox(key: Key('book_list')));

      await theWidgetShouldNotBeDisplayed(driver, 'error_banner');
      await expectFails(
        () => theWidgetShouldNotBeDisplayed(driver, 'book_list'),
      );
    });

    testWidgets('theTextShouldBeDisplayed', (tester) async {
      final driver = await pump(tester, const Text('로그인 성공'));

      await theTextShouldBeDisplayed(driver, '로그인 성공');
      await expectFails(() => theTextShouldBeDisplayed(driver, '실패'));
    });

    testWidgets('iShouldSeeWidgets counts exactly', (tester) async {
      final driver = await pump(
        tester,
        Column(
          children: [
            for (var i = 0; i < 3; i++)
              KeyedSubtree(
                key: ValueKey(i),
                child: const SizedBox(key: Key('row')),
              ),
          ],
        ),
      );

      await iShouldSeeWidgets(driver, '3', 'row');
      await expectFails(() => iShouldSeeWidgets(driver, '2', 'row'));
    });

    testWidgets('theWidgetShouldContainText looks in the subtree', (
      tester,
    ) async {
      final driver = await pump(
        tester,
        const Column(
          children: [
            Card(key: Key('total_card'), child: Text('42')),
            Text('7'),
          ],
        ),
      );

      await theWidgetShouldContainText(driver, 'total_card', '42');
      // 서브트리 밖의 텍스트로는 통과하지 않는다.
      await expectFails(
        () => theWidgetShouldContainText(driver, 'total_card', '7'),
      );
    });

    testWidgets('고정 문구 step 4종은 CommonKeys 를 본다', (tester) async {
      final driver = await pump(
        tester,
        Column(
          children: [
            SizedBox(key: CommonKeys.errorMessage),
            SizedBox(key: CommonKeys.loadingIndicator),
            SizedBox(key: CommonKeys.successMessage),
            SizedBox(key: CommonKeys.totalCount),
          ],
        ),
      );

      await theErrorMessageShouldBeDisplayed(driver);
      await theLoadingIndicatorShouldBeDisplayed(driver);
      await theSuccessMessageShouldBeDisplayed(driver);
      await theTotalCountShouldBeDisplayed(driver);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await expectFails(() => theErrorMessageShouldBeDisplayed(driver));
      await expectFails(() => theLoadingIndicatorShouldBeDisplayed(driver));
      await expectFails(() => theSuccessMessageShouldBeDisplayed(driver));
      await expectFails(() => theTotalCountShouldBeDisplayed(driver));
    });
  });

  group('theCurrentPageShouldBe', () {
    Widget pagination(String current) => Row(
      children: [
        TextButton(
          key: const Key('current_page_indicator'),
          onPressed: () {},
          child: Text(current),
        ),
      ],
    );

    testWidgets('should match the label exactly', (tester) async {
      final driver = await pump(tester, pagination('1'));

      await theCurrentPageShouldBe(driver, '1');
    });

    testWidgets('should not pass on a partial match (11 is not 1)', (
      tester,
    ) async {
      final driver = await pump(tester, pagination('11'));

      await expectFails(() => theCurrentPageShouldBe(driver, '1'));
    });
  });

  group('theWidgetShouldBeAnchoredTo', () {
    Widget layout({required double anchorTop, required double panelRight}) =>
        Stack(
          children: [
            Positioned(
              top: anchorTop,
              right: 20,
              width: 80,
              height: 40,
              child: const SizedBox(key: Key('filter_button')),
            ),
            Positioned(
              top: anchorTop + 40,
              right: panelRight,
              width: 200,
              height: 100,
              child: const SizedBox(key: Key('filter_dialog')),
            ),
          ],
        );

    testWidgets('should pass when the panel hangs under the anchor', (
      tester,
    ) async {
      final driver = await pump(tester, layout(anchorTop: 100, panelRight: 20));

      await theWidgetShouldBeAnchoredTo(
        driver,
        'filter_dialog',
        'filter_button',
      );
    });

    testWidgets('should fail when the panel ignores the anchor', (
      tester,
    ) async {
      final driver = await pump(
        tester,
        layout(anchorTop: 100, panelRight: 120),
      );

      await expectFails(
        () => theWidgetShouldBeAnchoredTo(
          driver,
          'filter_dialog',
          'filter_button',
        ),
      );
    });

    testWidgets('should fail when the anchor sits at the top edge (공허성 가드)', (
      tester,
    ) async {
      final driver = await pump(tester, layout(anchorTop: 0, panelRight: 20));

      await expectFails(
        () => theWidgetShouldBeAnchoredTo(
          driver,
          'filter_dialog',
          'filter_button',
        ),
      );
    });
  });

  group('활성 step 은 Key 하위의 Semantics(enabled:) 선언을 본다', () {
    Widget control({required bool enabled}) => Semantics(
      key: const Key('submit'),
      button: true,
      enabled: enabled,
      child: const SizedBox(width: 40, height: 40),
    );

    testWidgets('enabled: true', (tester) async {
      final driver = await pump(tester, control(enabled: true));

      await theWidgetShouldBeEnabled(driver, 'submit');
      await expectFails(() => theWidgetShouldBeDisabled(driver, 'submit'));
    });

    testWidgets('enabled: false', (tester) async {
      final driver = await pump(tester, control(enabled: false));

      await theWidgetShouldBeDisabled(driver, 'submit');
      await expectFails(() => theWidgetShouldBeEnabled(driver, 'submit'));
    });

    testWidgets('Material 버튼은 onPressed 가 없으면 비활성으로 판정된다', (tester) async {
      final driver = await pump(
        tester,
        Column(
          children: [
            const ElevatedButton(
              key: Key('off'),
              onPressed: null,
              child: Text('끔'),
            ),
            ElevatedButton(
              key: const Key('on'),
              onPressed: () {},
              child: const Text('켬'),
            ),
          ],
        ),
      );

      await theWidgetShouldBeDisabled(driver, 'off');
      await theWidgetShouldBeEnabled(driver, 'on');
    });

    testWidgets('식별용 래퍼에 Key 가 있어도 자손 컨트롤의 선언을 읽는다', (tester) async {
      final driver = await pump(
        tester,
        Semantics(
          key: const Key('login_button'),
          container: true,
          identifier: 'login_button',
          child: Semantics(
            enabled: false,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await theWidgetShouldBeDisabled(driver, 'login_button');
    });

    testWidgets('선언이 없거나 여럿이면 실패한다 — 엉뚱한 컨트롤을 조용히 고르지 않는다', (tester) async {
      final driver = await pump(
        tester,
        Column(
          children: [
            const SizedBox(key: Key('plain'), width: 10, height: 10),
            Column(
              key: const Key('two'),
              children: [
                Semantics(enabled: true, child: const SizedBox(height: 10)),
                Semantics(enabled: true, child: const SizedBox(height: 10)),
              ],
            ),
          ],
        ),
      );

      await expectFails(() => theWidgetShouldBeEnabled(driver, 'plain'));
      await expectFails(() => theWidgetShouldBeEnabled(driver, 'two'));
    });
  });

  group('토글 step 은 Key 하위의 Semantics(toggled:) 선언을 본다', () {
    Widget toggle({required bool value}) => Semantics(
      key: const Key('push_toggle'),
      toggled: value,
      child: Semantics(
        enabled: true,
        child: const SizedBox(width: 40, height: 24),
      ),
    );

    testWidgets('toggled: true', (tester) async {
      final driver = await pump(tester, toggle(value: true));

      await theToggleShouldBeOn(driver, 'push_toggle');
      await expectFails(() => theToggleShouldBeOff(driver, 'push_toggle'));
    });

    testWidgets('toggled: false — 꺼진 토글도 활성이다', (tester) async {
      final driver = await pump(tester, toggle(value: false));

      await theToggleShouldBeOff(driver, 'push_toggle');
      await expectFails(() => theToggleShouldBeOn(driver, 'push_toggle'));
      // 토글 값과 활성 여부는 다른 관심사다.
      await theWidgetShouldBeEnabled(driver, 'push_toggle');
    });
  });

  group('selected step 은 Semantics isSelected 로 판정한다', () {
    Widget chip({bool? selected}) => Semantics(
      key: const Key('chip'),
      container: true,
      selected: selected,
      child: const SizedBox(width: 40, height: 40),
    );

    testWidgets('selected: true', (tester) async {
      final driver = await pump(tester, chip(selected: true));

      await theWidgetShouldBeSelected(driver, 'chip');
      await expectFails(() => theWidgetShouldNotBeSelected(driver, 'chip'));
    });

    testWidgets('selected: false', (tester) async {
      final driver = await pump(tester, chip(selected: false));

      await theWidgetShouldNotBeSelected(driver, 'chip');
      await expectFails(() => theWidgetShouldBeSelected(driver, 'chip'));
    });

    testWidgets('선택 상태가 없는 위젯은 양쪽 모두 실패한다', (tester) async {
      final driver = await pump(tester, chip());

      await expectFails(() => theWidgetShouldBeSelected(driver, 'chip'));
      await expectFails(() => theWidgetShouldNotBeSelected(driver, 'chip'));
    });
  });
}

class _DelayedLabel extends StatefulWidget {
  const _DelayedLabel();

  @override
  State<_DelayedLabel> createState() => _DelayedLabelState();
}

class _DelayedLabelState extends State<_DelayedLabel> {
  late final Timer _timer;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: 1),
      () => setState(() => _done = true),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_done ? 'done' : 'waiting');
}
