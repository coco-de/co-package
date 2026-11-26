import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_mask_cover_painter.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill.dart';
import 'package:open_note/src/note/study/overlay/note_mask_fill_image.dart';
import 'package:open_note/src/note/study/overlay/note_mask_geometry.dart';
import 'package:open_note/src/note/study/overlay/note_mask_style.dart';

/// The widget behind `NoteMaskView` and `NoteTapeView`: paints one cover to
/// fill its constraints and reports taps on it. Internal to `study/overlay`.
///
/// Pointers outside the painted shape (plus the style's slop) fall through to
/// whatever is beneath.
class NoteMaskCoverView extends StatelessWidget {
  /// Creates the cover.
  const NoteMaskCoverView({
    required this.geometryFor,
    required this.fill,
    required this.fillOpacity,
    required this.revealed,
    required this.fallbackSize,
    required this.semanticLabel,
    this.onToggle,
    this.style = const NoteMaskStyle(),
    this.imageResolver,
    super.key,
  });

  /// The shape inside a rectangle of the widget's size.
  final NoteMaskGeometry Function(Rect area) geometryFor;

  /// How the hidden cover looks.
  final NoteMaskFill fill;

  /// Opacity of the fill.
  final double fillOpacity;

  /// Whether the cover is lifted.
  final bool revealed;

  /// Size used if the constraints are unbounded (the object's bounds).
  final Size fallbackSize;

  /// Accessibility label of the tap action.
  final String semanticLabel;

  /// Lifts or lays back the cover; `null` makes the widget display-only.
  final VoidCallback? onToggle;

  /// Outline, pattern and hit-test metrics.
  final NoteMaskStyle style;

  /// Resolves image fills.
  final NoteMaskImageResolver? imageResolver;

  @override
  Widget build(BuildContext context) => NoteMaskFillImage(
    source: fill.imageSource,
    resolver: imageResolver,
    builder: (context, image) => LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? constraints.biggest
            : fallbackSize;
        final paint = CustomPaint(
          size: size,
          painter: NoteMaskCoverPainter(
            geometry: geometryFor(Offset.zero & size),
            fill: fill,
            fillOpacity: fillOpacity,
            revealed: revealed,
            image: image,
            style: style,
          ),
        );

        return onToggle == null ? paint : _tappable(paint, onToggle!);
      },
    ),
  );

  Widget _tappable(Widget child, VoidCallback toggle) => Semantics(
    button: true,
    label: semanticLabel,
    onTap: toggle,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      hitTestBehavior: HitTestBehavior.deferToChild,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        excludeFromSemantics: true,
        onTap: toggle,
        child: child,
      ),
    ),
  );
}
