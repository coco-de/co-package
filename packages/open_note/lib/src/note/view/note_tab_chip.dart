import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// One tab of a `NoteTabBar`: the title and a close button.
class NoteTabChip extends StatelessWidget {
  /// A tab labelled [title].
  const NoteTabChip({
    required this.title,
    required this.active,
    required this.height,
    required this.onTap,
    required this.onClose,
    super.key,
    this.closeButtonKey,
    this.maxWidth = 200,
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  });

  /// Printed title; [NoteViewStrings.untitled] when empty.
  final String title;

  /// Whether this is the focused tab.
  final bool active;

  /// Height of the tab.
  final double height;

  /// The tab was tapped.
  final VoidCallback onTap;

  /// The close button was tapped.
  final VoidCallback onClose;

  /// Key of the close button.
  final Key? closeButtonKey;

  /// Widest the tab may grow.
  final double maxWidth;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  Widget build(BuildContext context) {
    final label = title.isEmpty ? strings.untitled : title;

    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          constraints: BoxConstraints(minWidth: 80, maxWidth: maxWidth),
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: active ? style.surfaceColor : null,
            border: Border(
              right: BorderSide(color: style.borderColor),
              bottom: BorderSide(
                color: active ? style.accentColor : style.borderColor,
                width: active ? 3 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: active ? style.textColor : style.mutedTextColor,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildCloseButton(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(String label) {
    return Semantics(
      container: true,
      button: true,
      label: '${strings.closeTab}: $label',
      child: GestureDetector(
        key: closeButtonKey,
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: SizedBox.square(
          dimension: 28,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                '×',
                style: TextStyle(fontSize: 18, color: style.mutedTextColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
