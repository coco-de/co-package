import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _boundary = ValueKey('boundary');

/// A component the app creates; [_system] maps it.
class FakeChip extends StatelessWidget {
  /// Creates the chip.
  const FakeChip({required this.label, super.key});

  /// Label.
  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}

const _system = GoldenDesignSystem(
  discoverCoui: false,
  components: [GoldenComponentMapping(widget: 'FakeChip')],
);

Future<GoldenRenderSnapshot> _inspect(
  WidgetTester tester,
  Widget child, {
  GoldenDesignSystem system = _system,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
  return GoldenRenderInspector(
    designSystem: system,
    packages: GoldenPackageMap.discover(),
  ).inspect(
    tester.element(find.byKey(_boundary)),
    tester.renderObject<RenderBox>(find.byKey(_boundary)),
  );
}

List<String> _texts(GoldenRenderSnapshot snapshot) => [
  for (final node in snapshot.nodes)
    if (node.text != null) node.text!.text,
];

void main() {
  group('hidden Visibility', () {
    testWidgets('a twin that only reserves space is not inspected', (
      tester,
    ) async {
      // CoUI ToggleGroup reserves the selected label width with an invisible
      // bold twin under the visible label.
      final snapshot = await _inspect(
        tester,
        const Stack(
          children: [
            Visibility(
              visible: false,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Text('전체', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('전체', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
      final labels = [
        for (final node in snapshot.nodes)
          if (node.text?.text == '전체') node,
      ];
      expect(labels, hasLength(1));
      expect(labels.single.text!.style.fontWeight, 500);
    });

    testWidgets('kept placeholders, offstage children, and components '
        'below them are left out', (tester) async {
      final snapshot = await _inspect(
        tester,
        const Column(
          children: [
            // A text field's placeholder while the field has a value.
            Visibility(
              visible: false,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Text('placeholder'),
            ),
            Visibility(
              visible: false,
              maintainState: true,
              child: Text('offstage'),
            ),
            Visibility(
              visible: false,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: FakeChip(label: 'hidden chip'),
            ),
            FakeChip(label: 'chip'),
          ],
        ),
      );
      expect(_texts(snapshot), ['chip']);
      expect(snapshot.components.map((c) => c.name), ['FakeChip']);
    });

    testWidgets('replacements and visible children are inspected', (
      tester,
    ) async {
      final snapshot = await _inspect(
        tester,
        const Column(
          children: [
            Visibility(
              visible: false,
              replacement: Text('replacement'),
              child: Text('not built'),
            ),
            Visibility(
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Text('shown'),
            ),
          ],
        ),
      );
      expect(_texts(snapshot), ['replacement', 'shown']);
    });

    testWidgets('a hidden SliverVisibility is left out', (tester) async {
      final snapshot = await _inspect(
        tester,
        const CustomScrollView(
          slivers: [
            SliverVisibility(
              visible: false,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              sliver: SliverToBoxAdapter(child: Text('hidden sliver')),
            ),
            SliverToBoxAdapter(child: Text('sliver')),
          ],
        ),
      );
      expect(_texts(snapshot), ['sliver']);
    });
  });
}
