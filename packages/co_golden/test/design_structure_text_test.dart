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
  String? horizontalAnchor,
  double renderX = 0,
  double renderWidth = 120,
  bool loadedFont = false,
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
          'fontFamily': 'TestFont',
          'color': '#111111FF',
          'fontWeight': 400,
          'letterSpacing': 0,
          'lineHeight': {'unit': 'PIXELS', 'value': 20},
          'autoResize': autoResize,
          'horizontalAnchor': ?horizontalAnchor,
        },
      },
    ],
  }),
  GoldenRenderSnapshot(
    width: 200,
    height: 200,
    fonts: {'TestFont': loadedFont},
    nodes: [
      if (render)
        GoldenRenderNode(
          id: 0,
          kind: GoldenRenderKind.text,
          widget: 'Text',
          rect: GoldenRect(renderX, 0, renderWidth, 20),
          visibleRect: GoldenRect(renderX, 0, renderWidth, 20),
          text: GoldenRenderText(
            text: 'Title',
            style: const GoldenRenderTextStyle(
              fontSize: 16,
              fontFamily: 'TestFont',
              color: 0xff111111,
              fontWeight: 400,
              height: 1.25,
            ),
            contentRect: GoldenRect(renderX, 0, renderWidth, 20),
          ),
        ),
    ],
  ),
  const GoldenStructuralContext(tolerance: GoldenDesignTolerance()),
);

void main() {
  test(
    'verified identical text at a wrap boundary is renderer information',
    () {
      final finding = compare(
        autoResize: 'HEIGHT',
        renderWidth: 118,
        loadedFont: true,
      ).findings.singleWhere((f) => f.diffs.any((d) => d.property == 'lines'));
      expect(finding.severity.name, 'info');
      expect(finding.owner, isNull);
    },
  );
  test('a real line-width mismatch remains a warning', () {
    final finding = compare(
      autoResize: 'HEIGHT',
      renderWidth: 80,
      loadedFont: true,
    ).findings.singleWhere((f) => f.diffs.any((d) => d.property == 'lines'));
    expect(finding.severity.name, 'warning');
  });
  test('unverified fonts are not explained as a wrap boundary', () {
    final finding = compare(
      autoResize: 'HEIGHT',
      renderWidth: 118,
    ).findings.singleWhere((f) => f.diffs.any((d) => d.property == 'lines'));
    expect(finding.severity.name, 'warning');
  });
  test(
    'container-centred text compares its centre when glyph advances differ',
    () {
      expect(
        compare(
          horizontalAnchor: 'CENTER',
          renderX: 4,
          renderWidth: 112,
        ).findings.where((f) => f.category == 'layout'),
        isEmpty,
      );
    },
  );
  test('an actual centre offset is still reported', () {
    expect(
      compare(
        horizontalAnchor: 'CENTER',
        renderX: 9,
        renderWidth: 112,
      ).findings.where((f) => f.category == 'layout'),
      isNotEmpty,
    );
  });
  test('left-aligned text keeps its left edge as the anchor', () {
    expect(
      compare(
        renderX: 4,
        renderWidth: 112,
      ).findings.where((f) => f.category == 'layout'),
      isNotEmpty,
    );
  });
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
