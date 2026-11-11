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
  (GoldenDesignNode, GoldenRenderNode)? hit(
    GoldenRenderNode? selected, {
    double x = 9,
    GoldenRenderNode target = matched,
  }) => goldenMatchedTextAt(
    candidates: [design],
    matches: {'text': target.id},
    rendered: {target.id: target},
    selected: selected,
    x: x,
    y: 15,
    tolerance: const GoldenDesignTolerance(),
  );
  test('recovers a matched text pair outside both layout hit boxes', () {
    final pair = hit(selected(GoldenRenderKind.box));
    expect(pair?.$1, design);
    expect(pair?.$2, matched);
  });
  test(
    'does not assign image, vector icon or another text pixels to a glyph',
    () {
      for (final kind in [
        GoldenRenderKind.image,
        GoldenRenderKind.graphic,
        GoldenRenderKind.text,
      ]) {
        expect(hit(selected(kind)), isNull);
      }
    },
  );
  test(
    'requires both source and target near the pixel within existing radii',
    () {
      expect(hit(null, x: 5), isNull);
      const moved = GoldenRenderNode(
        id: 1,
        kind: GoldenRenderKind.text,
        widget: 'Text',
        rect: GoldenRect(40, 10, 20, 20),
        visibleRect: GoldenRect(40, 10, 20, 20),
        text: GoldenRenderText(
          text: 'A',
          contentRect: GoldenRect(40, 10, 20, 20),
          style: GoldenRenderTextStyle(fontSize: 14, fontWeight: 400),
        ),
      );
      expect(hit(null, target: moved), isNull);
    },
  );
  test('an existing vector icon owner is preserved by the text preference', () {
    final candidate = selected(GoldenRenderKind.graphic);
    expect(owner(candidate, 15), candidate);
  });
}
