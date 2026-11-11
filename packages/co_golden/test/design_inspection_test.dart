import 'package:co_golden/src/design/design_system.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final maintainSize in [false, true]) {
    testWidgets('ignores hidden maintained text, maintainSize=$maintainSize', (
      tester,
    ) async {
      final visible = ValueNotifier(false);
      addTearDown(visible.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundary,
            child: Column(
              children: [
                const Text('painted'),
                ValueListenableBuilder(
                  valueListenable: visible,
                  builder: (_, value, _) => Visibility(
                    visible: value,
                    maintainState: true,
                    maintainAnimation: maintainSize,
                    maintainSize: maintainSize,
                    child: const Text('measurement copy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      List<String?> texts() =>
          GoldenRenderInspector(
                designSystem: const GoldenDesignSystem(),
                packages: GoldenPackageMap.discover(),
              )
              .inspect(
                boundary.currentContext! as Element,
                boundary.currentContext!.findRenderObject()! as RenderBox,
              )
              .nodes
              .where((n) => n.text != null)
              .map((n) => n.text!.text)
              .toList();
      expect(texts(), ['painted']);
      visible.value = true;
      await tester.pump();
      expect(texts(), ['painted', 'measurement copy']);
      visible.value = false;
      await tester.pump();
      expect(texts(), ['painted']);
    });
  }

  testWidgets('keeps a visible replacement when the child is hidden', (
    tester,
  ) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundary,
          child: const Visibility(
            visible: false,
            replacement: Text('replacement'),
            child: Text('hidden'),
          ),
        ),
      ),
    );
    final snapshot =
        GoldenRenderInspector(
          designSystem: const GoldenDesignSystem(),
          packages: GoldenPackageMap.discover(),
        ).inspect(
          boundary.currentContext! as Element,
          boundary.currentContext!.findRenderObject()! as RenderBox,
        );
    expect(
      snapshot.nodes.where((n) => n.text != null).map((n) => n.text!.text),
      ['replacement'],
    );
  });
}
