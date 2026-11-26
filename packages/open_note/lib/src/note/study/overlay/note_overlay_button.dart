import 'package:flutter/widgets.dart';

/// A plain tappable button for the overlay widgets (the package depends on no
/// design system). Internal to `study/overlay`.
///
/// [label] is the only thing announced to assistive technology; [child] is
/// what is drawn (a glyph or a short text).
class NoteOverlayButton extends StatelessWidget {
  /// Creates a button.
  const NoteOverlayButton({
    required this.label,
    required this.onPressed,
    required this.child,
    this.minWidth = 32,
    this.height = 32,
    this.background,
    this.radius = 6,
    this.padding = EdgeInsets.zero,
    this.selected,
    super.key,
  });

  /// Accessibility label.
  final String label;

  /// Called on tap.
  final VoidCallback onPressed;

  /// Content, centred.
  final Widget child;

  /// Smallest width.
  final double minWidth;

  /// Height.
  final double height;

  /// Fill behind the content, if any.
  final Color? background;

  /// Corner radius of [background].
  final double radius;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  /// Announces a toggle or tab state when not `null`.
  final bool? selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    selected: selected,
    onTap: onPressed,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onPressed,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    ),
  );
}
