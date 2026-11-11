import 'package:co_golden/src/design/design_system.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inspects the painted candidate, not every laid-out candidate', (
    tester,
  ) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundary,
          child: ValueListenableBuilder(
            valueListenable: selected,
            builder: (_, index, _) => IndexedStack(
              index: index,
              children: const [Text('wide pagination'), Text('compact 1 / 3')],
            ),
          ),
        ),
      ),
    );
    List<String> texts() =>
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
    expect(texts(), ['wide pagination']);
    selected.value = 1;
    await tester.pump();
    expect(texts(), ['compact 1 / 3']);
  });

  for (final opaque in [true, false]) {
    testWidgets(
      'opaque Stack cover hides only fully covered underlay: $opaque',
      (tester) async {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundary,
              child: Stack(
                children: [
                  const Positioned(left: 10, top: 10, child: Text('covered')),
                  const Positioned(left: 10, top: 100, child: Text('visible')),
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 200,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(opaque ? 0xffffffff : 0x80ffffff),
                      ),
                      child: const Text('front'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final nodes =
            GoldenRenderInspector(
                  designSystem: const GoldenDesignSystem(),
                  packages: GoldenPackageMap.discover(),
                )
                .inspect(
                  boundary.currentContext! as Element,
                  boundary.currentContext!.findRenderObject()! as RenderBox,
                )
                .nodes;
        expect(
          nodes.where((n) => n.text != null).map((n) => n.text!.text),
          opaque ? ['visible', 'front'] : ['covered', 'visible', 'front'],
        );
      },
    );
  }

  for (final rounded in [false, true]) {
    testWidgets('opaque Overlay covers its underlay, rounded=$rounded', (
      tester,
    ) async {
      final boundary = GlobalKey();
      final entries = [
        OverlayEntry(
          builder: (_) =>
              const Positioned(left: 50, top: 50, child: Text('covered')),
        ),
        OverlayEntry(
          builder: (_) => Positioned(
            left: 0,
            top: 0,
            width: 300,
            height: 200,
            child: PhysicalModel(
              color: const Color(0xffffffff),
              elevation: 4,
              borderRadius: BorderRadius.circular(rounded ? 24 : 0),
              child: const Text('front'),
            ),
          ),
        ),
      ];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundary,
            child: Overlay(initialEntries: entries),
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
        ['front'],
      );
    });
  }

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
