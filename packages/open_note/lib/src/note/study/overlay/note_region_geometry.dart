import 'dart:math' as math;
import 'dart:ui';

/// The eight grab points of a region selection.
enum NoteRegionHandle {
  /// Top-left corner.
  topLeft(-1, -1),

  /// Middle of the top edge.
  top(0, -1),

  /// Top-right corner.
  topRight(1, -1),

  /// Middle of the right edge.
  right(1, 0),

  /// Bottom-right corner.
  bottomRight(1, 1),

  /// Middle of the bottom edge.
  bottom(0, 1),

  /// Bottom-left corner.
  bottomLeft(-1, 1),

  /// Middle of the left edge.
  left(-1, 0);

  const NoteRegionHandle(this.horizontal, this.vertical);

  /// -1 when the handle moves the left edge, 1 the right edge, 0 neither.
  final int horizontal;

  /// -1 when the handle moves the top edge, 1 the bottom edge, 0 neither.
  final int vertical;

  /// Where the handle sits on [rect].
  Offset positionOn(Rect rect) => Offset(
    rect.center.dx + horizontal * rect.width / 2,
    rect.center.dy + vertical * rect.height / 2,
  );
}

/// The pure geometry of `NoteRegionSelector`, in page coordinates with the
/// page's top-left corner at the origin.
abstract final class NoteRegionGeometry {
  /// [point] moved onto the page.
  static Offset clampPoint(Offset point, Size page) =>
      Offset(point.dx.clamp(0.0, page.width), point.dy.clamp(0.0, page.height));

  /// The rectangle spanned by two corners of a drag, clamped to the page.
  static Rect fromDrag(Offset anchor, Offset current, Size page) =>
      Rect.fromPoints(clampPoint(anchor, page), clampPoint(current, page));

  /// [rect] shifted (and shrunk only if it is larger than the page) so that it
  /// lies on the page.
  static Rect fit(Rect rect, Size page) {
    final width = math.min(rect.width, page.width);
    final height = math.min(rect.height, page.height);

    return Rect.fromLTWH(
      rect.left.clamp(0.0, math.max(0.0, page.width - width)),
      rect.top.clamp(0.0, math.max(0.0, page.height - height)),
      width,
      height,
    );
  }

  /// [rect] moved by [delta], keeping its size and staying on the page.
  static Rect move(Rect rect, Offset delta, Size page) =>
      fit(rect.shift(delta), page);

  /// [rect] with the edges of [handle] dragged by [delta]. The dragged edges
  /// stay on the page and never come closer than [minSize] to the opposite
  /// edge (no flipping).
  static Rect resize(
    Rect rect,
    NoteRegionHandle handle,
    Offset delta,
    Size page, {
    double minSize = 0,
  }) {
    final (left, right) = _resizeSpan(
      (rect.left, rect.right),
      handle.horizontal,
      delta.dx,
      page.width,
      minSize,
    );
    final (top, bottom) = _resizeSpan(
      (rect.top, rect.bottom),
      handle.vertical,
      delta.dy,
      page.height,
      minSize,
    );

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// The handle nearest to [point] among those within [radius] of it.
  static NoteRegionHandle? handleAt(Rect rect, Offset point, double radius) {
    NoteRegionHandle? nearest;
    var best = radius;
    for (final handle in NoteRegionHandle.values) {
      final distance = (handle.positionOn(rect) - point).distance;
      if (distance > best) continue;
      best = distance;
      nearest = handle;
    }

    return nearest;
  }

  /// The finished selection of a drag: `null` when [rect] is shorter than
  /// [minSize] in both directions (an accidental tap); otherwise [rect] with
  /// each shorter side grown to [minSize] around its centre, on the page. A
  /// minimum larger than the page is limited to the page.
  static Rect? atLeast(Rect rect, Size page, double minSize) {
    final minWidth = math.min(minSize, page.width);
    final minHeight = math.min(minSize, page.height);
    if (rect.width < minWidth && rect.height < minHeight) return null;
    if (rect.width >= minWidth && rect.height >= minHeight) {
      return fit(rect, page);
    }
    final grown = Rect.fromCenter(
      center: rect.center,
      width: math.max(rect.width, minWidth),
      height: math.max(rect.height, minHeight),
    );

    return grown.isEmpty ? null : fit(grown, page);
  }

  static (double, double) _resizeSpan(
    (double, double) span,
    int side,
    double delta,
    double extent,
    double minSize,
  ) {
    final (low, high) = span;
    final shortest = math.min(minSize, extent);
    if (side < 0) {
      final limit = math.max(0.0, high - shortest);

      return ((low + delta).clamp(0.0, limit), high);
    }
    if (side > 0) {
      final limit = math.min(extent, low + shortest);

      return (low, (high + delta).clamp(limit, extent));
    }

    return span;
  }
}
