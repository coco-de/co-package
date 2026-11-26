import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_kind.dart';
import 'package:open_note/src/note/study/overlay/note_ai_pen_panel_style.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_button.dart';
import 'package:open_note/src/note/study/overlay/note_overlay_glyph.dart';
import 'package:open_note/src/note/study/overlay/note_study_overlay_strings.dart';

/// The tab strip and close button of the AI pen panel. Internal to
/// `study/overlay`.
class NoteAiPenPanelHeader extends StatelessWidget {
  /// Creates the header with [selected] marked.
  const NoteAiPenPanelHeader({
    required this.selected,
    required this.onSelect,
    required this.strings,
    required this.style,
    this.onClose,
    super.key,
  });

  /// The tab shown.
  final NoteAiPenKind selected;

  /// Called when another tab is tapped.
  final ValueChanged<NoteAiPenKind> onSelect;

  /// Tab titles and labels.
  final NoteStudyOverlayStrings strings;

  /// Colours and metrics.
  final NoteAiPenPanelStyle style;

  /// Closes the panel; `null` hides the button.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: style.borderColor)),
    ),
    child: Row(
      children: [
        // A narrow panel scrolls its tabs instead of overflowing.
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [for (final kind in NoteAiPenKind.values) _tab(kind)],
            ),
          ),
        ),
        if (onClose != null) _closeButton(onClose!),
      ],
    ),
  );

  Widget _closeButton(VoidCallback close) => NoteOverlayButton(
    key: const ValueKey('note-ai-pen-close'),
    label: strings.aiClose,
    onPressed: close,
    height: 40,
    minWidth: 40,
    child: NoteOverlayGlyph(
      NoteOverlayGlyphKind.close,
      color: style.mutedTextColor,
    ),
  );

  Widget _tab(NoteAiPenKind kind) {
    final active = kind == selected;

    return NoteOverlayButton(
      key: ValueKey('note-ai-pen-tab-${kind.name}'),
      label: strings.kindLabel(kind),
      onPressed: () => onSelect(kind),
      selected: active,
      height: 40,
      radius: 0,
      padding: EdgeInsets.symmetric(horizontal: style.padding),
      child: Text(
        strings.kindLabel(kind),
        maxLines: 1,
        style: TextStyle(
          color: active ? style.accentColor : style.mutedTextColor,
          fontSize: style.fontSize,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
