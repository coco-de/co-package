import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// A tappable list row with a bottom divider and a selected background. Not
/// exported by the barrel.
class NoteNavRow extends StatelessWidget {
  const NoteNavRow({
    required this.child,
    required this.style,
    super.key,
    this.onTap,
    this.selected = false,
    this.indent = 0,
  });

  final Widget child;
  final NoteNavStyle style;
  final VoidCallback? onTap;
  final bool selected;

  /// Extra left padding in logical pixels.
  final double indent;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    selected: selected,
    child: MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? style.selectedColor : null,
            border: Border(bottom: BorderSide(color: style.dividerColor)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: style.rowHeight),
            child: Padding(
              padding: style.padding.add(EdgeInsets.only(left: indent)),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
