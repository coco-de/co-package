import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenStructuralResult compare({
  String text = 'Title',
  String autoResize = 'NONE',
  bool render = true,
}) => compareDesignStructure(
  GoldenDesignSpec.parse({
    'schema': 'co_golden.design_spec',
    'schemaVersion': 1,
    'source': {'tool': 'figma'},
    'frame': {
      'id': 'frame',
      'name': 'frame',
      'type': 'FRAME',
      'width': 200,
      'height': 200,
    },
    'nodes': [
      {
        'id': 'title',
        'parent': 'frame',
        'name': 'Title',
        'type': 'TEXT',
        'rect': [0, 0, 120, 40],
        'text': {
          'characters': text,
          'fontSize': 16,
          'fontWeight': 400,
          'lineHeight': {'unit': 'PIXELS', 'value': 20},
          'autoResize': autoResize,
        },
      },
    ],
  }),
  GoldenRenderSnapshot(
    width: 200,
    height: 200,
    nodes: [
      if (render)
        const GoldenRenderNode(
          id: 0,
          kind: GoldenRenderKind.text,
          widget: 'Text',
          rect: GoldenRect(0, 0, 120, 20),
          visibleRect: GoldenRect(0, 0, 120, 20),
          text: GoldenRenderText(
            text: 'Title',
            style: GoldenRenderTextStyle(
              fontSize: 16,
              fontWeight: 400,
              height: 1.25,
            ),
            contentRect: GoldenRect(0, 0, 120, 20),
          ),
        ),
    ],
  ),
  const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
);

void main() {
  test('fixed text boxes do not invent a second line from empty space', () {
    expect(
      compare().findings.where(
        (f) => f.diffs.any((d) => d.property == 'lines'),
      ),
      isEmpty,
    );
  });
  test('content-sized text still reports an actual line-count mismatch', () {
    expect(
      compare(
        autoResize: 'HEIGHT',
      ).findings.where((f) => f.diffs.any((d) => d.property == 'lines')),
      hasLength(1),
    );
  });
  for (final text in ['', '   ', '\n']) {
    test('empty design text is not reported as missing: ${text.codeUnits}', () {
      expect(compare(text: text, render: false).findings, isEmpty);
    });
  }
  test('real missing text is still an error', () {
    expect(
      compare(
        render: false,
      ).findings.where((f) => f.id.startsWith('presence.missing')),
      hasLength(1),
    );
  });
}
