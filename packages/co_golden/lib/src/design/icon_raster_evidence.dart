import 'ink_raster_evidence.dart';
import 'pixel_diff.dart';
import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Verifies the same named icon's resolved paint before comparing its edges.
GoldenInkRasterEvidence? goldenIconRasterEvidence({
  required GoldenDesignNode design,
  required GoldenRenderNode render,
  required GoldenRenderSnapshot snapshot,
  required GoldenRgbImage reference,
  required GoldenRgbImage actual,
  required double logicalWidth,
  required GoldenDesignTolerance tolerance,
}) {
  final expectedName = design.instance?.properties['glyphName'];
  final properties = snapshot.componentOf(render)?.properties;
  final color = design.solidStroke?.color;
  final actualColor = int.tryParse(properties?['colorArgb'] ?? '');
  final stroke = double.tryParse(properties?['strokeWidth'] ?? '');
  final weight = design.strokeWeight;
  if (expectedName == null ||
      expectedName != properties?['glyphName'] ||
      color == null ||
      color != actualColor ||
      weight == null ||
      stroke == null ||
      (weight - stroke).abs() > 0.001 ||
      design.opacity != 1 ||
      render.opacity != 1 ||
      render.kind != GoldenRenderKind.graphic ||
      (design.rect.width - render.rect.width).abs() > tolerance.size ||
      (design.rect.height - render.rect.height).abs() > tolerance.size ||
      (design.rect.left - render.rect.left).abs() > tolerance.position ||
      (design.rect.top - render.rect.top).abs() > tolerance.position) {
    return null;
  }
  return GoldenInkRasterEvidence.compare(
    rect: design.rect.union(render.rect),
    foregroundColor: color,
    reference: reference,
    actual: actual,
    logicalWidth: logicalWidth,
    horizontalRadius: tolerance.pixel,
    verticalRadius: tolerance.pixel,
    minMassRatio: 0.9,
    maxMassRatio: 1.1,
  );
}
