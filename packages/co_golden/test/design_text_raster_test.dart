import 'package:co_golden/src/design/geometry.dart';
import 'package:co_golden/src/design/pixel_diff.dart';
import 'package:co_golden/src/design/render_node.dart';
import 'package:co_golden/src/design/spec.dart';
import 'package:co_golden/src/design/text_raster_evidence.dart';
import 'package:co_golden/src/design/tolerance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

image.Image glyph({
  int edge = 160,
  int shift = 0,
  int shiftY = 0,
  int background = 255,
  bool missing = false,
  bool wrongShape = false,
}) {
  final img = image.Image(width: 24, height: 28, numChannels: 4);
  image.fill(
    img,
    color: image.ColorRgba8(background, background, background, 255),
  );
  if (missing) return img;
  for (var y = 5; y < 21; y++) {
    for (var x = 4; x < 15; x++) {
      final stem = x == 5 || x == 6 || x == 11 || x == 12;
      final cross = y == 11 || y == 12;
      final value = stem || cross
          ? 0
          : (x == 4 || x == 7 || x == 10 || x == 13)
          ? edge
          : background;
      img.setPixelRgba(x + shift, y + shiftY, value, value, value, 255);
    }
  }
  if (wrongShape) {
    for (var y = 5; y < 21; y++) {
      for (var x = 17; x < 20; x++) {
        img.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }
  return img;
}

GoldenTextRasterEvidence? evidence(
  image.Image actual, {
  String text = 'H',
  int weight = 400,
  int color = 0xff000000,
  bool loaded = true,
  double designOpacity = 1,
  double renderOpacity = 1,
}) => GoldenTextRasterEvidence.compare(
  design: GoldenDesignSpec.parse({
    'schema': 'co_golden.design_spec',
    'schemaVersion': 1,
    'frame': {'id': 'f', 'width': 24, 'height': 28},
    'nodes': [
      {
        'id': 't',
        'type': 'TEXT',
        'opacity': designOpacity,
        'rect': [0, 0, 24, 28],
        'text': {
          'characters': 'H',
          'fontFamily': 'TestFont',
          'fontSize': 14,
          'fontWeight': 400,
          'lineHeight': {'unit': 'PIXELS', 'value': 21},
          'letterSpacing': {'unit': 'PIXELS', 'value': 0},
          'color': '#000000FF',
        },
      },
    ],
  }).nodes.single,
  render: GoldenRenderNode(
    id: 0,
    kind: GoldenRenderKind.text,
    widget: 'Text',
    opacity: renderOpacity,
    rect: const GoldenRect(0, 0, 24, 28),
    visibleRect: const GoldenRect(0, 0, 24, 28),
    text: GoldenRenderText(
      text: text,
      style: GoldenRenderTextStyle(
        fontFamily: 'TestFont',
        fontSize: 14,
        fontWeight: weight,
        height: 1.5,
        color: color,
      ),
      contentRect: const GoldenRect(0, 0, 24, 28),
    ),
  ),
  fonts: {'TestFont': loaded},
  reference: GoldenRgbImage.fromImage(glyph()),
  actual: GoldenRgbImage.fromImage(actual),
  logicalWidth: 24,
  tolerance: const GoldenDesignTolerance(),
);

void main() {
  test('same solid glyph with different edge coverage has evidence', () {
    expect(evidence(glyph(edge: 120)), isNotNull);
  });
  test('different characters are never explained as rasterization', () {
    expect(evidence(glyph(), text: 'B'), isNull);
  });
  test('uses the existing text pixel radius on both axes', () {
    expect(evidence(glyph(shiftY: 2)), isNotNull);
    expect(evidence(glyph(shiftY: 5)), isNull);
  });
  test(
    'normalizes only backgrounds within existing property color tolerance',
    () {
      expect(evidence(glyph(background: 254)), isNotNull);
      expect(evidence(glyph(background: 100)), isNull);
    },
  );
  test('different weight or color remains actionable', () {
    expect(evidence(glyph(), weight: 700), isNull);
    expect(evidence(glyph(), color: 0xffff0000), isNull);
  });
  test('an unloaded font is not certified', () {
    expect(evidence(glyph(), loaded: false), isNull);
  });
  test('translucent design or render text is not certified', () {
    expect(evidence(glyph(), designOpacity: 0.5), isNull);
    expect(evidence(glyph(), renderOpacity: 0.5), isNull);
  });
  test('missing or substantially changed ink remains actionable', () {
    expect(evidence(glyph(missing: true)), isNull);
    expect(evidence(glyph(wrongShape: true)), isNull);
  });
  test('movement beyond the existing positional radius is not certified', () {
    expect(evidence(glyph(shift: 5)), isNull);
  });
  test('raw pixel differences are preserved even with raster evidence', () {
    final ref = GoldenRgbImage.fromImage(glyph());
    final actual = GoldenRgbImage.fromImage(glyph(edge: 120));
    final raw = compareDesignPixels(
      reference: ref,
      render: actual,
      logicalWidth: 24,
      tolerance: const GoldenDesignTolerance(
        antialias: false,
        pixel: 0,
        textPixel: 0,
      ),
    );
    expect(raw.differentPixels, greaterThan(0));
    expect(evidence(glyph(edge: 120)), isNotNull);
  });
}
