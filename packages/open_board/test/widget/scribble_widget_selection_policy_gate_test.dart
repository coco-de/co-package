import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_board/src/module/models/scribble_selectable.dart';
import 'package:open_board/src/module/scribble.notifier.dart';
import 'package:open_board/src/module/scribble_mode.notifier.dart';
import 'package:open_board/src/module/state/drawing_state.dart';
import 'package:open_board/src/module/widgets/scribble_widget.dart';
import 'package:open_board/src/module/widgets/simple_scribble_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/protobuf_factories.dart';

/// [ScribbleWidget.canSelectItem] 텍스트박스 탭 **신규 진입** 게이트 테스트
/// (kobic unibook#12445, UB-639).
///
/// 계약 3가지를 고정한다:
/// 1. 미주입(null) 시 기존 동작(kobic#12374 — 다른 도구 모드에서 손가락
///    탭으로 기존 텍스트 선택 가능)과 완전히 동일하다.
/// 2. 정책이 거부한 텍스트박스는 탭에 '투명'하다 — 신규 선택이 되지 않는다.
/// 3. 게이트는 **신규 진입에만** 적용된다 — 이미 선택된 텍스트박스는 정책이
///    거부로 바뀌어도 계속 조작(드래그 이동) 가능하다 (#270~#272 보존).
void main() {
  group('ScribbleWidget canSelectItem — 텍스트박스 탭 진입 게이트', () {
    late ScribbleNotifier scribbleNotifier;
    late ScribbleModeNotifier modeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      scribbleNotifier = ScribbleNotifier(
        scribble: Scribble(strokes: [], width: 300, height: 400),
      );
      // 처음부터 다른 도구(pencil) — 텍스트 모드를 거치지 않는다.
      modeNotifier = ScribbleModeNotifier()..setPencil();
      DrawingState().hasSelectedTextBox.value = false;
    });

    tearDown(() {
      scribbleNotifier.dispose();
      modeNotifier.dispose();
      DrawingState().hasSelectedTextBox.value = false;
    });

    Widget buildTestWidget({CanSelectScribbleItem? canSelectItem}) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: ScribbleWidget(
                notifier: scribbleNotifier,
                modeNotifier: modeNotifier,
                canSelectItem: canSelectItem,
                child: const SizedBox(width: 300, height: 400),
              ),
            ),
          ),
        );

    void addText() {
      scribbleNotifier.addTextDrawable(
        createTextDrawable(
          id: 't1',
          text: 'Hello World Testing',
          x: 100,
          y: 100,
          fontSize: 24,
        ),
      );
    }

    /// touch 탭 — down 은 kTouchDelay(30ms) 지연 처리되므로 50ms pump 필요.
    Future<void> fingerTapAt(WidgetTester tester, Offset position) async {
      final gesture = await tester.startGesture(position); // kind = touch
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();
    }

    testWidgets(
      'canSelectItem 미주입이면 pencil 모드 손가락 탭으로 기존 텍스트가 '
      '선택된다 (kobic#12374 기존 동작 패리티)',
      (tester) async {
        addText();
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await fingerTapAt(tester, const Offset(100, 100));

        expect(
          DrawingState().hasSelectedTextBox.value,
          isTrue,
          reason: '정책 미주입 시 기존 동작(탭 선택 가능)이 그대로여야 한다',
        );
      },
    );

    testWidgets('정책이 텍스트를 거부하면 손가락 탭으로 선택되지 않는다', (tester) async {
      addText();
      await tester.pumpWidget(
        buildTestWidget(
          canSelectItem: (item) => switch (item) {
            ScribbleSelectableText() => false,
            ScribbleSelectableStroke() => true,
          },
        ),
      );
      await tester.pumpAndSettle();

      await fingerTapAt(tester, const Offset(100, 100));

      expect(
        DrawingState().hasSelectedTextBox.value,
        isFalse,
        reason: '거부된 텍스트박스는 탭에 투명해야 한다 — 신규 선택 진입 차단',
      );
    });

    testWidgets(
      '이미 선택된 텍스트박스는 정책이 거부로 바뀌어도 계속 드래그 이동된다 '
      '(신규 진입만 게이팅 — #270~#272 보존)',
      (tester) async {
        addText();
        // 가변 정책: 처음엔 허용해 선택을 만들고, 이후 거부로 뒤집는다.
        var allowText = true;
        await tester.pumpWidget(
          buildTestWidget(
            canSelectItem: (item) => switch (item) {
              ScribbleSelectableText() => allowText,
              ScribbleSelectableStroke() => true,
            },
          ),
        );
        await tester.pumpAndSettle();

        await fingerTapAt(tester, const Offset(100, 100));
        expect(DrawingState().hasSelectedTextBox.value, isTrue);

        // 더블탭 판정(실제 벽시계 800ms)에 걸리지 않도록 실제 시간을 흘린다.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 900)),
        );

        // 정책을 거부로 전환 — 이미 성립한 선택의 조작은 막히면 안 된다.
        allowText = false;

        final originalPosition = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1');
        final originalOffset = Offset(originalPosition.x, originalPosition.y);

        final dragGesture = await tester.startGesture(const Offset(100, 100));
        await tester.pump(const Duration(milliseconds: 50));
        await dragGesture.moveBy(const Offset(30, 20));
        await tester.pump();
        await dragGesture.up();
        await tester.pump();

        final after = scribbleNotifier
            .getCurrentTextDrawables()
            .firstWhere((t) => t.id == 't1');
        expect(
          Offset(after.x, after.y),
          isNot(equals(originalOffset)),
          reason: '기선택 조작은 정책과 무관하게 유지돼야 한다 (진입만 게이팅)',
        );
      },
    );
  });

  group('SimpleScribbleWidget — canSelectItem 전달 사슬', () {
    testWidgets('주입한 콜백이 내부 ScribbleWidget 까지 그대로 전달된다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      bool policy(ScribbleSelectable item) => false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: SimpleScribbleWidget(
                canSelectItem: policy,
                child: const SizedBox(width: 300, height: 400),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 전달 누락은 컴파일이 잡지 못하는 조용한 no-op 이므로 여기서 고정한다.
      final inner = tester.widget<ScribbleWidget>(find.byType(ScribbleWidget));
      expect(inner.canSelectItem, same(policy));
    });
  });
}
