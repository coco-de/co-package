import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/nav/internal/note_nav_glyph.dart';
import 'package:open_note/src/note/nav/internal/note_nav_icon_button.dart';
import 'package:open_note/src/note/nav/internal/note_nav_row.dart';
import 'package:open_note/src/note/nav/note_excerpt.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// One excerpt row: a colour swatch, the note (or the page) and the page label,
/// with an optional delete button. Not exported by the barrel.
class NoteExcerptTile extends StatelessWidget {
  const NoteExcerptTile({
    required this.excerpt,
    required this.pageLabel,
    required this.strings,
    required this.style,
    required this.onSelect,
    super.key,
    this.onDelete,
  });

  final NoteExcerpt excerpt;
  final String pageLabel;
  final NoteNavStrings strings;
  final NoteNavStyle style;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final note = excerpt.note;

    return NoteNavRow(
      style: style,
      onTap: onSelect,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: excerpt.color ?? style.highlightColor,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 10),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note ?? pageLabel,
                    style: style.textStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note != null)
                    Text(pageLabel, style: style.secondaryTextStyle),
                ],
              ),
            ),
          ),
          if (onDelete != null)
            NoteNavIconButton(
              key: ValueKey('note-excerpt-delete-${excerpt.id}'),
              glyph: NoteNavGlyph.close,
              label: strings.delete,
              onPressed: onDelete,
              style: style,
            ),
        ],
      ),
    );
  }
}
