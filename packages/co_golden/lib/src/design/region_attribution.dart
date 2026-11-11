import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Glyph bearings can extend just outside a paragraph's layout rectangle.
/// Prefer its structural match over a backing box/caret painter, while keeping
/// actual foreground images and other text as the owners of their pixels.
GoldenRenderNode? goldenPreferMatchedText({
  required GoldenDesignNode? design,
  required GoldenRenderNode? selected,
  required GoldenRenderNode? matched,
  required double x,
  required double y,
  required GoldenDesignTolerance tolerance,
}) {
  if (design?.isText != true ||
      matched?.text == null ||
      selected != null &&
          selected.kind != GoldenRenderKind.box &&
          selected.kind != GoldenRenderKind.graphic) {
    return selected;
  }
  return matched!.text!.contentRect
          .inflate(tolerance.textPixel, tolerance.pixel)
          .contains(x, y)
      ? matched
      : selected;
}
