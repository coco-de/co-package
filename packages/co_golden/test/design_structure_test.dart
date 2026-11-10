import 'package:co_golden/co_golden.dart';
import 'package:co_golden/src/design/finding.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenDesignSpec _spec(List<Map<String, Object?>> nodes) =>
    GoldenDesignSpec.parse({
      'schema': 'co_golden.design_spec',
      'schemaVersion': 1,
      'frame': {'id': '1:1', 'name': 'Screen', 'width': 200, 'height': 100},
      'nodes': nodes,
    });

Map<String, Object?> _instance(
  String id,
  String component,
  List<num> rect, {
  String? parent,
  String? name,
  Map<String, String> variant = const {},
}) => {
  'id': id,
  'parent': ?parent,
  'name': name ?? component,
  'type': 'INSTANCE',
  'rect': rect,
  'instance': {'set': component, 'variant': variant},
};

GoldenRenderNode _graphic(int id, GoldenRect rect) => GoldenRenderNode(
  id: id,
  kind: GoldenRenderKind.graphic,
  widget: '_RawPictureVectorGraphicWidget',
  rect: rect,
  visibleRect: rect,
);

List<GoldenDesignFinding> _compare(
  GoldenDesignSpec spec,
  GoldenRenderSnapshot snapshot,
) => compareDesignStructure(
  spec,
  snapshot,
  const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
).findings;

void main() {
  group('icon-set instances', () {
    // A CoUI Button whose leading Icon component swaps in `lucide/bell`, a
    // bare `lucide/calendar`, and an Icon whose glyph has a custom name.
    final spec = _spec([
      _instance(
        '1:2',
        'Button',
        [10, 10, 40, 40],
        variant: {'Variant': 'ghost'},
      ),
      {
        'id': '1:3',
        'parent': '1:2',
        'name': 'leading',
        'type': 'FRAME',
        'rect': [21, 21, 18, 18],
      },
      _instance('1:4', 'Icon', [21, 21, 18, 18], parent: '1:3'),
      _instance('1:5', 'lucide/bell', [21, 21, 18, 18], parent: '1:4'),
      {
        'id': '1:6',
        'parent': '1:5',
        'name': 'Vector',
        'type': 'VECTOR',
        'rect': [22.5, 22.5, 15, 15],
        'strokes': [
          {'type': 'SOLID', 'color': '#14161AFF'},
        ],
      },
      _instance('1:7', 'lucide/calendar', [60, 21, 18, 18]),
      _instance('1:8', 'Icon', [120, 21, 18, 18]),
      _instance('1:9', 'custom/arrow', [120, 21, 18, 18], parent: '1:8'),
      // A small component that is not an icon.
      _instance('1:10', 'Badge', [160, 10, 20, 20]),
      _instance('1:11', 'mdi:home', [160, 60, 16, 16]),
    ]);
    final snapshot = GoldenRenderSnapshot(
      width: 200,
      height: 100,
      components: const [
        GoldenRenderComponent(
          id: 0,
          name: 'Button',
          rect: GoldenRect(10, 10, 40, 40),
          properties: {'variant': 'ghost'},
        ),
        GoldenRenderComponent(
          id: 1,
          name: 'Icon',
          rect: GoldenRect(21, 21, 18, 18),
          parent: 0,
        ),
        GoldenRenderComponent(
          id: 2,
          name: 'Icon',
          rect: GoldenRect(60, 21, 18, 18),
        ),
        GoldenRenderComponent(
          id: 3,
          name: 'Icon',
          rect: GoldenRect(120, 21, 18, 18),
        ),
      ],
      nodes: [
        _graphic(0, const GoldenRect(21, 21, 18, 18)),
        _graphic(1, const GoldenRect(60, 21, 18, 18)),
        _graphic(2, const GoldenRect(120, 21, 18, 18)),
        _graphic(3, const GoldenRect(160, 60, 16, 16)),
      ],
    );

    test('are compared as icons, not as components', () {
      final findings = _compare(spec, snapshot);
      final components = findings
          .where((f) => f.category == GoldenFindingCategory.component)
          .toList();
      // Only the badge is still a component (with no catalog, an info).
      expect(components.map((f) => f.id), ['component@1:10']);
      // Every icon found its rendered glyph.
      expect(
        findings.where((f) => f.category != GoldenFindingCategory.component),
        isEmpty,
        reason: findings.map((f) => f.message).join('\n'),
      );
      expect(goldenDesignComponentNames(spec, const []), {'button', 'badge'});
    });
  });
}
