import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenStructuralResult compare(
  List<GoldenPixelRegion>? regions,
) => compareDesignStructure(
  GoldenDesignSpec.parse({
    'schema': 'co_golden.design_spec',
    'schemaVersion': 1,
    'frame': {'id': 'f', 'width': 200, 'height': 100},
    'nodes': [
      {
        'id': 'known',
        'type': 'TEXT',
        'rect': [0, 0, 100, 20],
        'text': {'characters': 'Known'},
      },
    ],
  }),
  GoldenRenderSnapshot(
    width: 200,
    height: 100,
    nodes: [
      for (final (id, label, y) in [(0, 'Known', 0.0), (1, 'Underlay', 40.0)])
        GoldenRenderNode(
          id: id,
          kind: GoldenRenderKind.text,
          widget: 'Text',
          rect: GoldenRect(0, y, 100, 20),
          visibleRect: GoldenRect(0, y, 100, 20),
          text: GoldenRenderText(
            text: label,
            style: const GoldenRenderTextStyle(fontSize: 14, fontWeight: 400),
            contentRect: GoldenRect(0, y, 100, 20),
          ),
        ),
    ],
  ),
  GoldenStructuralContext(
    tolerance: const GoldenDesignTolerance(),
    regions: regions,
  ),
);

void main() {
  test('no visual pixel evidence means no visible extra text claim', () {
    expect(
      compare([]).findings.where((f) => f.id.startsWith('presence.extra')),
      isEmpty,
    );
  });
  test('visible extra text with differing pixels is still reported', () {
    expect(
      compare([
        const GoldenPixelRegion(
          bounds: GoldenRect(5, 45, 20, 10),
          pixels: 100,
          logicalPixels: 100,
          referenceColor: 0xffffff,
          renderColor: 0,
          meanDeltaE: 50,
        ),
      ]).findings.where((f) => f.id.startsWith('presence.extra')),
      hasLength(1),
    );
  });
  test('absence of a pixel comparison never hides extra text', () {
    expect(
      compare(null).findings.where((f) => f.id.startsWith('presence.extra')),
      hasLength(1),
    );
  });
}
