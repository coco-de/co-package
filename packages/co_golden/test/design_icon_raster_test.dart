import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/icon_raster_evidence.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'design_text_raster_test.dart' show glyph;

GoldenDesignSpec spec() => GoldenDesignSpec.parse({
  'schema': 'co_golden.design_spec',
  'schemaVersion': 1,
  'frame': {'id': 'f', 'width': 24, 'height': 28},
  'nodes': [
    {
      'id': 'icon',
      'type': 'INSTANCE',
      'name': 'lucide/test',
      'rect': [0, 0, 24, 28],
      'instance': {
        'component': 'lucide/test',
        'properties': {'glyphName': 'lucide:test'},
      },
      'strokes': [
        {'type': 'SOLID', 'color': '#000000FF'},
      ],
      'strokeWeight': 1.25,
    },
  ],
});
GoldenRenderSnapshot snapshot({
  String name = 'lucide:test',
  int color = 0xff000000,
  double stroke = 1.25,
  double opacity = 1,
}) => GoldenRenderSnapshot(
  width: 24,
  height: 28,
  components: [
    GoldenRenderComponent(
      id: 0,
      name: 'Icon',
      rect: const GoldenRect(0, 0, 24, 28),
      properties: {
        'glyphName': name,
        'colorArgb': '$color',
        'strokeWidth': '$stroke',
      },
    ),
  ],
  nodes: [
    GoldenRenderNode(
      id: 0,
      kind: GoldenRenderKind.graphic,
      widget: 'Svg',
      component: 0,
      opacity: opacity,
      rect: const GoldenRect(0, 0, 24, 28),
      visibleRect: const GoldenRect(0, 0, 24, 28),
    ),
  ],
);
void main() {
  test('same resolved named icon with different faint edges has evidence', () {
    final s = snapshot();
    expect(
      goldenIconRasterEvidence(
        design: spec().nodes.single,
        render: s.nodes.single,
        snapshot: s,
        reference: GoldenRgbImage.fromImage(glyph()),
        actual: GoldenRgbImage.fromImage(glyph(edge: 150)),
        logicalWidth: 24,
        tolerance: const GoldenDesignTolerance(),
      ),
      isNotNull,
    );
  });
  for (final s in [
    snapshot(name: 'lucide:other'),
    snapshot(color: 0xffff0000),
    snapshot(stroke: 1.5),
    snapshot(opacity: 0.5),
  ]) {
    test(
      'a different glyph, color, stroke or opacity is not raster evidence: ${s.components.single.properties} ${s.nodes.single.opacity}',
      () {
        expect(
          goldenIconRasterEvidence(
            design: spec().nodes.single,
            render: s.nodes.single,
            snapshot: s,
            reference: GoldenRgbImage.fromImage(glyph()),
            actual: GoldenRgbImage.fromImage(glyph()),
            logicalWidth: 24,
            tolerance: const GoldenDesignTolerance(),
          ),
          isNull,
        );
      },
    );
  }
  test('wrong icon name and inherited color remain structural errors', () {
    final result = compareDesignStructure(
      spec(),
      snapshot(name: 'lucide:other', color: 0xffff0000),
      const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
    );
    expect(
      result.findings.any((f) => f.diffs.any((d) => d.property == 'glyphName')),
      isTrue,
    );
    expect(result.findings.any((f) => f.category == 'color'), isTrue);
  });
}
