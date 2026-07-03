// Story: S8.3 (E8) — FixedLayoutPage 공유 TransformationController 주입

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/presentation/engine/fixed_layout/fixed_layout_page.dart';

void main() {
  testWidgets('주입한 TransformationController를 공유하고 dispose하지 않는다', (
    tester,
  ) async {
    final shared = TransformationController();
    addTearDown(shared.dispose);
    final key = GlobalKey<FixedLayoutPageState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FixedLayoutPage(
            key: key,
            logicalSize: const Size(600, 800),
            content: const SizedBox(width: 600, height: 800),
            transformationController: shared,
          ),
        ),
      ),
    );

    // 같은 컨트롤러를 본문 변환에 사용한다.
    expect(key.currentState!.controller, same(shared));

    // 위젯을 제거해도 주입 컨트롤러는 호스트 소유 → dispose되지 않는다.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(() => shared.addListener(() {}), returnsNormally);
  });

  testWidgets('주입하지 않으면 내부 컨트롤러를 생성한다', (tester) async {
    final key = GlobalKey<FixedLayoutPageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FixedLayoutPage(
            key: key,
            logicalSize: const Size(600, 800),
            content: const SizedBox(width: 600, height: 800),
          ),
        ),
      ),
    );
    expect(key.currentState!.controller, isA<TransformationController>());
  });
}
