import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// A rounded chip: a tappable label, optionally with a remove button. Not
/// exported by the barrel.
class NoteNavChip extends StatelessWidget {
  const NoteNavChip({
    required this.label,
    required this.style,
    super.key,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.removeLabel,
    this.removeKey,
  });

  final String label;
  final NoteNavStyle style;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  /// Accessibility label of the remove button.
  final String? removeLabel;

  /// Key of the remove button.
  final Key? removeKey;

  @override
  Widget build(BuildContext context) {
    final text = selected
        ? style.textStyle.copyWith(color: const Color(0xFFFFFFFF))
        : style.textStyle;

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? style.accentColor : style.chipColor,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRemove != null)
                  _NoteNavChipRemove(
                    key: removeKey,
                    label: removeLabel ?? label,
                    color: text.color ?? style.iconColor,
                    onPressed: onRemove!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteNavChipRemove extends StatelessWidget {
  const _NoteNavChipRemove({
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    tooltip: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: SizedBox.square(
          dimension: 16,
          child: CustomPaint(
            painter: NoteNavGlyphPainter(
              glyph: NoteNavGlyph.close,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}
