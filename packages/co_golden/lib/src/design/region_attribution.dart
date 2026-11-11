import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Finds a verified text pair when glyph bearings miss both layout hit boxes.
/// Both source ink and rendered content must be within the existing pixel
/// radii; foreground images and a different text owner remain untouched.
(GoldenDesignNode, GoldenRenderNode)? goldenMatchedTextAt({
  required List<GoldenDesignNode> candidates,
  required Map<String, int> matches,
  required Map<int, GoldenRenderNode> rendered,
  required GoldenRenderNode? selected,
  required double x,
  required double y,
  required GoldenDesignTolerance tolerance,
}) {
  if (!_isTextBacking(selected) && selected?.kind != GoldenRenderKind.text) {
    return null;
  }
  (GoldenDesignNode, GoldenRenderNode)? result;
  for (final source in candidates) {
    if (!source.isText) continue;
    final target = rendered[matches[source.id]];
    if (target?.text == null ||
        selected?.kind == GoldenRenderKind.text && selected!.id != target!.id) {
      continue;
    }
    final sourceInk = (source.inkRect ?? source.rect).inflate(
      tolerance.textPixel,
      tolerance.pixel,
    );
    final targetInk = target!.text!.contentRect.inflate(
      tolerance.textPixel,
      tolerance.pixel,
    );
    if (sourceInk.contains(x, y) &&
        targetInk.contains(x, y) &&
        (result == null || source.rect.area < result.$1.rect.area)) {
      result = (source, target);
    }
  }
  return result;
}

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
      !_isTextBacking(selected)) {
    return selected;
  }
  return matched!.text!.contentRect
          .inflate(tolerance.textPixel, tolerance.pixel)
          .contains(x, y)
      ? matched
      : selected;
}

bool _isTextBacking(GoldenRenderNode? node) =>
    node == null ||
    node.kind == GoldenRenderKind.box ||
    node.kind == GoldenRenderKind.graphic &&
        node.widget.endsWith('CustomPaint');
