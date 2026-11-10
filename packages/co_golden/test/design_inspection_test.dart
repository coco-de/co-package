import 'dart:convert';
import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design/finding.dart';
import 'package:co_golden/src/design/inspection.dart';
import 'package:co_golden/src/design/package_map.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fixtures/fake_design_system/fake_design_system.dart';

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

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  RepaintBoundary(
    key: _boundary,
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  ),
);

GoldenRenderSnapshot _inspectPumped(
  WidgetTester tester, {
  GoldenDesignSystem system = _system,
  GoldenComponentCatalog? catalog,
  GoldenPackageMap? packages,
  Set<String> nestedComponents = const {},
}) =>
    GoldenRenderInspector(
      designSystem: system,
      packages: packages ?? GoldenPackageMap.discover(),
      catalog: catalog,
      nestedComponents: nestedComponents,
    ).inspect(
      tester.element(find.byKey(_boundary)),
      tester.renderObject<RenderBox>(find.byKey(_boundary)),
    );

Future<GoldenRenderSnapshot> _inspect(
  WidgetTester tester,
  Widget child, {
  GoldenDesignSystem system = _system,
}) async {
  await _pump(tester, child);
  return _inspectPumped(tester, system: system);
}

/// The workspace packages, and test/fixtures/fake_design_system as a
/// design-system package outside the project (a `file:` root, like a hosted
/// or git dependency).
GoldenPackageMap _withFakeDesignSystem() {
  var root = Directory.current;
  while (!File(
    p.join(root.path, '.dart_tool', 'package_config.json'),
  ).existsSync()) {
    root = root.parent;
  }
  final config = File(p.join(root.path, '.dart_tool', 'package_config.json'));
  final json = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
  final fake = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'fake_design_system'),
  ).absolute;
  (json['packages']! as List<Object?>).add({
    'name': 'fake_design_system',
    'rootUri': fake.uri.toString(),
    'packageUri': '',
  });
  return GoldenPackageMap.parse(
    jsonEncode(json),
    configDirectory: config.parent.path,
    workingDirectory: Directory.current.path,
  );
}

const _fakeSystem = GoldenDesignSystem(
  discoverCoui: false,
  packages: {'fake_design_system'},
);

/// Catalog of the fake design system: its components, as CoUI's
/// components.json lists CoUI's.
final _fakeCatalog = GoldenComponentCatalog(
  name: 'Fake',
  library: 'fake_design_system',
  components: const [
    GoldenCatalogComponent(name: 'FakeField'),
    GoldenCatalogComponent(name: 'FakeLabel'),
    GoldenCatalogComponent(name: 'FakeToolbar'),
    GoldenCatalogComponent(name: 'FakeButton'),
  ],
);

/// A field and a toolbar the app places; the fake design system composes a
/// label inside the field and buttons inside the toolbar.
const Widget _composedScreen = Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    FakeField(label: '버전', value: 'v1'),
    FakeToolbar(),
  ],
);

Map<String, Object?> _instance(
  String id,
  String component,
  Rect rect,
  Map<String, String> variant, {
  String? parent,
}) => {
  'id': id,
  'parent': ?parent,
  'name': component,
  'type': 'INSTANCE',
  'rect': [rect.left, rect.top, rect.width, rect.height],
  'instance': {'set': component, 'variant': variant},
};

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

  group('components that a design-system component composes', () {
    testWidgets('are listed when the design names them', (tester) async {
      final packages = _withFakeDesignSystem();
      await _pump(tester, _composedScreen);
      final snapshot = _inspectPumped(
        tester,
        system: _fakeSystem,
        catalog: _fakeCatalog,
        packages: packages,
        nestedComponents: {'fakelabel', 'fakebutton'},
      );
      expect(
        [for (final c in snapshot.components) (c.name, c.composed, c.parent)],
        [
          ('FakeField', false, null),
          ('FakeLabel', true, 0),
          ('FakeToolbar', false, null),
          ('FakeButton', true, 2),
          ('FakeButton', true, 2),
          ('FakeButton', true, 2),
        ],
      );
      final label = snapshot.components[1];
      expect(label.properties['size'], 'lg');
      expect(label.source?.package, 'fake_design_system');
      // Found past the Builder that DefaultTextStyle.merge creates.
      expect(label.library, 'fake_design_system');
      expect(label.toJson()['composed'], isTrue);
      // What the label draws still belongs to the field the app placed.
      final text = snapshot.nodes.singleWhere((n) => n.text?.text == '버전');
      expect(text.component, 0);

      final placed = _inspectPumped(
        tester,
        system: _fakeSystem,
        catalog: _fakeCatalog,
        packages: packages,
      );
      expect(placed.components.map((c) => c.name), [
        'FakeField',
        'FakeToolbar',
      ]);
    });

    testWidgets('answer nested design instances', (tester) async {
      final packages = _withFakeDesignSystem();
      await _pump(tester, _composedScreen);
      final buttons = find.byType(FakeButton);
      final spec = GoldenDesignSpec.parse({
        'schema': 'co_golden.design_spec',
        'schemaVersion': 1,
        'frame': {'id': '1:1', 'name': 'Screen', 'width': 800, 'height': 600},
        'nodes': [
          _instance(
            '1:2',
            'FakeField',
            tester.getRect(find.byType(FakeField)),
            {'Size': 'lg'},
          ),
          _instance(
            '1:3',
            'FakeLabel',
            tester.getRect(find.byType(FakeLabel)),
            {'Size': 'lg'},
            parent: '1:2',
          ),
          // Toolbar buttons placed one by one in the design.
          _instance('1:4', 'FakeButton', tester.getRect(buttons.at(0)), {
            'Variant': 'plain',
            'Size': 'sm',
          }),
          _instance('1:5', 'FakeButton', tester.getRect(buttons.at(1)), {
            'Variant': 'plain',
            'Size': 'md',
          }),
        ],
      });
      final names = goldenDesignComponentNames(spec, const []);
      expect(names, {'fakefield', 'fakelabel', 'fakebutton'});
      List<GoldenDesignFinding> components(Set<String> nested) =>
          compareDesignStructure(
                spec,
                _inspectPumped(
                  tester,
                  system: _fakeSystem,
                  catalog: _fakeCatalog,
                  packages: packages,
                  nestedComponents: nested,
                ),
                GoldenStructuralContext(
                  tolerance: const GoldenDesignTolerance(),
                  catalog: _fakeCatalog,
                ),
              ).findings
              .where((f) => f.category == GoldenFindingCategory.component)
              .toList();

      // Without them, the label and the buttons read as hand-built widgets.
      final before = components(const {});
      expect(before.map((f) => (f.id, f.severity)), [
        ('component@1:3', GoldenFindingSeverity.error),
        ('component@1:4', GoldenFindingSeverity.error),
        ('component@1:5', GoldenFindingSeverity.error),
      ]);
      expect(before.first.message, contains('직접 만든 위젯(FakeField)'));

      // With them, the label matches; a composed button whose variant
      // differs is context for the design system, not an app error.
      final after = components(names);
      final variant = after.single;
      expect(variant.id, 'component@1:4');
      expect(variant.severity, GoldenFindingSeverity.info);
      expect(variant.owner, GoldenFindingOwner.designSystem);
      expect(variant.component?.composed, isTrue);
      expect(variant.diffs.single.property, 'size');
      expect(
        variant.hint,
        contains('‘FakeToolbar’(fake_design_system)가 안에서 만든 FakeButton'),
      );
    });
  });
}
