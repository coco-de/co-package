import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/region_attribution.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = GoldenRect(10, 10, 20, 20);
  const design = GoldenDesignNode(
    id: 'text',
    name: 'text',
    type: 'TEXT',
    rect: rect,
  );
  const matched = GoldenRenderNode(
    id: 1,
    kind: GoldenRenderKind.text,
    widget: 'Text',
    rect: rect,
    visibleRect: rect,
    text: GoldenRenderText(
      text: 'A',
      contentRect: rect,
      style: GoldenRenderTextStyle(fontSize: 14, fontWeight: 400),
    ),
  );
  GoldenRenderNode selected(String kind) => GoldenRenderNode(
    id: 2,
    kind: kind,
    widget: 'Selected',
    rect: rect,
    visibleRect: rect,
  );
  GoldenRenderNode? owner(GoldenRenderNode candidate, double x) =>
      goldenPreferMatchedText(
        design: design,
        selected: candidate,
        matched: matched,
        x: x,
        y: 15,
        tolerance: const GoldenDesignTolerance(),
      );
  test('attributes a matched glyph bearing to text over its backing box', () {
    expect(owner(selected(GoldenRenderKind.box), 9), matched);
  });
  test('keeps foreground images and other text as their own pixel owners', () {
    for (final kind in [GoldenRenderKind.image, GoldenRenderKind.text]) {
      final candidate = selected(kind);
      expect(owner(candidate, 15), candidate);
    }
  });
  test('does not extend the text owner beyond the existing text tolerance', () {
    final candidate = selected(GoldenRenderKind.box);
    expect(owner(candidate, 5), candidate);
  });
}
