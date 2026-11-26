import 'dart:math' as math;
import 'dart:ui';

/// The pure placement rules of floating windows inside their host, whose
/// top-left corner is the origin.
abstract final class NoteFloatingWindowGeometry {
  /// [rect] made to fit a [host]: its size is limited to the host (but not
  /// shrunk below [minSize] while the host is large enough), then it is shifted
  /// inside.
  static Rect clamp(Rect rect, Size host, {Size minSize = Size.zero}) {
    final width = math.max(
      math.min(rect.width, host.width),
      math.min(minSize.width, host.width),
    );
    final height = math.max(
      math.min(rect.height, host.height),
      math.min(minSize.height, host.height),
    );

    return Rect.fromLTWH(
      rect.left.clamp(0.0, math.max(0.0, host.width - width)),
      rect.top.clamp(0.0, math.max(0.0, host.height - height)),
      width,
      height,
    );
  }

  /// [start] (already inside the [host]) with its bottom-right corner dragged
  /// by [delta]: it keeps its top-left corner, stays inside the host and does
  /// not shrink below [minSize].
  static Rect resize(
    Rect start,
    Offset delta,
    Size host, {
    Size minSize = Size.zero,
  }) {
    final maxWidth = math.max(0.0, host.width - start.left);
    final maxHeight = math.max(0.0, host.height - start.top);

    return start.topLeft &
        Size(
          (start.width + delta.dx).clamp(
            math.min(minSize.width, maxWidth),
            maxWidth,
          ),
          (start.height + delta.dy).clamp(
            math.min(minSize.height, maxHeight),
            maxHeight,
          ),
        );
  }
}
