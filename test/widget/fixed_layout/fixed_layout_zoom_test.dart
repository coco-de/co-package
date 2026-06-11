// Story: S1.8 (#14) — FixedLayoutPage 핀치 줌 + 더블 탭 tests
// BDD: F3.2 (핀치 줌 인 + 최대 4.0x + 더블 탭 원복)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  group('FixedLayoutPage — InteractiveViewer 줌 (BDD F3.2)', () {
    testWidgets('InteractiveViewer가 트리에 존재 (enableZoom default true)', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(width: 800, height: 600),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('enableZoom=false면 InteractiveViewer 없음', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
          enableZoom: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('default minZoom=1.0, maxZoom=4.0, doubleTapZoom=2.0', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(viewer.minScale, 1.0);
      expect(viewer.maxScale, 4.0);
    });

    testWidgets('초기 상태 currentScale=1.0, isZoomedIn=false', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
      expect(state.currentScale, closeTo(1.0, 0.0001));
      expect(state.isZoomedIn, isFalse);
    });

    testWidgets('onDoubleTapAt: 줌 인 → isZoomedIn=true, currentScale=doubleTapZoom',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));

      state.onDoubleTapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(state.currentScale, closeTo(2.0, 0.0001));
      expect(state.isZoomedIn, isTrue);
    });

    testWidgets('줌 인 상태에서 더블 탭 다시 → 1.0x로 원복 (BDD F3.2)', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));

      // 줌 인
      state.onDoubleTapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
      expect(state.isZoomedIn, isTrue);

      // 더블 탭으로 원복
      state.onDoubleTapAt(const Offset(50, 50));
      await tester.pumpAndSettle();
      expect(state.currentScale, closeTo(1.0, 0.0001));
      expect(state.isZoomedIn, isFalse);
    });

    testWidgets('custom maxZoom 5.0 적용', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(),
          maxZoom: 5.0,
          doubleTapZoom: 3.0,
        ),
      ));
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(viewer.maxScale, 5.0);

      final state = tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
      state.onDoubleTapAt(Offset.zero);
      await tester.pumpAndSettle();
      expect(state.currentScale, closeTo(3.0, 0.0001));
    });

    testWidgets('실제 더블 탭 제스처 동작 — TransformationController 변화', (tester) async {
      await tester.pumpWidget(_wrap(
        const FixedLayoutPage(
          logicalSize: Size(800, 600),
          content: SizedBox(width: 800, height: 600),
        ),
      ));
      await tester.pumpAndSettle();
      final state = tester.state<FixedLayoutPageState>(find.byType(FixedLayoutPage));
      expect(state.isZoomedIn, isFalse);

      // 더블 탭 제스처 트리거 (kDoubleTapMinTime은 flutter에 없으므로 직접 지정)
      final center = tester.getCenter(find.byType(InteractiveViewer));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();
      expect(state.isZoomedIn, isTrue);
    });

    testWidgets('assertion: minZoom <= 0이면 throw', (tester) async {
      expect(
        () => FixedLayoutPage(
          logicalSize: const Size(800, 600),
          content: const SizedBox(),
          minZoom: 0,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('assertion: maxZoom < minZoom이면 throw', (tester) async {
      expect(
        () => FixedLayoutPage(
          logicalSize: const Size(800, 600),
          content: const SizedBox(),
          minZoom: 2.0,
          maxZoom: 1.0,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('assertion: doubleTapZoom이 범위 밖이면 throw', (tester) async {
      expect(
        () => FixedLayoutPage(
          logicalSize: const Size(800, 600),
          content: const SizedBox(),
          doubleTapZoom: 5.0, // maxZoom default 4.0보다 큼
        ),
        throwsAssertionError,
      );
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 600, child: child),
      ),
    );
