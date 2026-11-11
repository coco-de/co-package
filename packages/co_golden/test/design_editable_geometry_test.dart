import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenStructuralResult compare({double top = 0, double scroll = 0}) =>
    compareDesignStructure(
      GoldenDesignSpec.parse({
        'schema': 'co_golden.design_spec',
        'schemaVersion': 1,
        'frame': {'id': 'f', 'width': 200, 'height': 100},
        'nodes': [
          {
            'id': 't',
            'type': 'TEXT',
            'rect': [0, 0, 100, 20],
            'text': {
              'characters': 'Value',
              'fontSize': 16,
              'fontWeight': 400,
              'lineHeight': {'unit': 'PIXELS', 'value': 20},
              'autoResize': 'NONE',
              'verticalAlign': 'TOP',
            },
          },
        ],
      }),
      GoldenRenderSnapshot(
        width: 200,
        height: 100,
        nodes: [
          GoldenRenderNode(
            id: 0,
            kind: GoldenRenderKind.text,
            widget: 'EditableText',
            rect: GoldenRect(0, top, 100, 20),
            visibleRect: GoldenRect(0, top, 100, 20),
            text: GoldenRenderText(
              text: 'Value',
              editable: true,
              style: const GoldenRenderTextStyle(
                fontSize: 16,
                fontWeight: 400,
                height: 1.25,
              ),
              contentRect: GoldenRect(0, top + 2.15 - scroll, 100, 15.7),
            ),
          ),
        ],
      ),
      const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
    );

void main() {
  test('selection-cell leading is not an editable text position error', () {
    expect(compare().findings.where((f) => f.category == 'layout'), isEmpty);
  });
  test('an actual editable text offset remains an error', () {
    expect(
      compare(top: 8).findings.where((f) => f.category == 'layout'),
      isNotEmpty,
    );
  });
  test('scrolling is not discarded by line-box normalization', () {
    expect(
      compare(scroll: 10).findings.where((f) => f.category == 'layout'),
      isNotEmpty,
    );
  });
}
