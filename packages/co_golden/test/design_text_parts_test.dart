import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/structural_diff.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';

GoldenStructuralResult compareParts({
  List<String> labels = const ['Home', '/', 'Library'],
  int lastWeight = 400,
  double lastY = 0,
}) {
  const rects = [
    GoldenRect(0, 0, 32, 20),
    GoldenRect(40, 0, 4, 20),
    GoldenRect(52, 0, 48, 20),
  ];
  return compareDesignStructure(
    GoldenDesignSpec.parse({
      'schema': 'co_golden.design_spec',
      'schemaVersion': 1,
      'source': {'tool': 'figma'},
      'frame': {'id': 'f', 'width': 200, 'height': 100},
      'nodes': [
        {
          'id': 'breadcrumb',
          'parent': 'f',
          'type': 'TEXT',
          'name': 'Breadcrumb',
          'rect': [0, 0, 100, 20],
          'text': {
            'characters': 'Home / Library',
            'fontSize': 10,
            'fontWeight': 400,
            'lineHeight': {'unit': 'PIXELS', 'value': 20},
            'autoResize': 'NONE',
          },
        },
      ],
    }),
    GoldenRenderSnapshot(
      width: 200,
      height: 100,
      nodes: [
        for (var i = 0; i < labels.length; i++)
          GoldenRenderNode(
            id: i,
            kind: GoldenRenderKind.text,
            widget: 'Text',
            rect: rects[i],
            visibleRect: rects[i],
            text: GoldenRenderText(
              text: labels[i],
              contentRect: GoldenRect(
                rects[i].left,
                i == 2 ? lastY : 0,
                rects[i].width,
                20,
              ),
              style: GoldenRenderTextStyle(
                fontSize: 10,
                fontWeight: i == 2 ? lastWeight : 400,
                height: 2,
              ),
            ),
          ),
      ],
    ),
    const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
  );
}

void main() {
  test('one design line matches adjacent links and separators', () {
    expect(compareParts().findings, isEmpty);
  });

  test('a missing link is still reported', () {
    expect(compareParts(labels: ['Home', '/']).findings, isNotEmpty);
  });

  test('a changed label is still reported', () {
    expect(
      compareParts(labels: ['Home', '/', 'Settings']).findings,
      isNotEmpty,
    );
  });

  test('reordered links are still reported', () {
    expect(compareParts(labels: ['Library', '/', 'Home']).findings, isNotEmpty);
  });

  test('different lines are never combined as one breadcrumb', () {
    expect(compareParts(lastY: 10).findings, isNotEmpty);
  });

  test('a wrong weight in the last link is still reported', () {
    expect(
      compareParts(
        lastWeight: 700,
      ).findings.any((f) => f.diffs.any((d) => d.property == 'fontWeight')),
      isTrue,
    );
  });
}
