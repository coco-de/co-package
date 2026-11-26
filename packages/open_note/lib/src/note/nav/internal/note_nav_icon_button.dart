import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// A glyph button with an accessibility label, disabled when [onPressed] is
/// `null`. Not exported by the barrel.
class NoteNavIconButton extends StatelessWidget {
  const NoteNavIconButton({
    required this.glyph,
    required this.label,
    required this.onPressed,
    required this.style,
    super.key,
  });

  final NoteNavGlyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final NoteNavStyle style;

  /// A disabled button still takes the tap, so that it does not reach the
  /// tappable row around it. Empty on purpose.
  // ignore: no-empty-block
  static void _swallow() {}

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled
        ? style.iconColor
        : style.iconColor.withValues(alpha: 0.3);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      tooltip: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed ?? _swallow,
          child: SizedBox.square(
            dimension: style.iconSize,
            child: CustomPaint(
              painter: NoteNavGlyphPainter(glyph: glyph, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
