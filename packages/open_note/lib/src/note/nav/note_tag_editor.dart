import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/nav/internal/note_nav_chip.dart';
import 'package:open_note/src/note/nav/internal/note_nav_text.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';
import 'package:open_note/src/note/nav/note_tag_ref.dart';
import 'package:open_note/src/note/nav/note_tags.dart';

/// Edits the tags of one note or page: a chip per tag (with a remove button), an
/// input (submit adds the whole text as one tag) and suggestions.
///
/// Suggestions are the other tags in use that contain the typed text (all of
/// them while nothing is typed), most used first. Changes go straight to
/// [tags]. The editor is as tall as its content.
class NoteTagEditor extends StatefulWidget {
  /// Creates the editor of [target].
  const NoteTagEditor({
    required this.tags,
    required this.target,
    super.key,
    this.onTagSelected,
    this.maxSuggestions = 8,
    this.autofocus = false,
    this.strings = const NoteNavStrings(),
    this.style = const NoteNavStyle(),
  }) : assert(maxSuggestions >= 0, 'maxSuggestions must not be negative');

  /// The tags shown and edited.
  final NoteTags tags;

  /// What is being tagged.
  final NoteTagRef target;

  /// A tag chip of [target] was tapped (for example to search for it).
  final ValueChanged<String>? onTagSelected;

  /// The most suggestions shown; `0` shows none.
  final int maxSuggestions;

  /// Whether the input takes the focus when it appears.
  final bool autofocus;

  /// User-visible text.
  final NoteNavStrings strings;

  /// Colours and sizes.
  final NoteNavStyle style;

  @override
  State<NoteTagEditor> createState() => _NoteTagEditorState();
}

class _NoteTagEditorState extends State<NoteTagEditor> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// A keyboard submit keeps the input focused for the next tag.
  void _submit(String text) {
    if (_add(text)) _focusNode.requestFocus();
  }

  bool _add(String tag) {
    if (NoteTags.normalize(tag) == null) return false;
    widget.tags.add(tag, widget.target);
    _input.clear();

    return true;
  }

  List<String> _suggestions(List<String> applied) {
    final typed = noteNavKey(_input.text);
    final taken = applied.map(noteNavKey).toSet();
    final candidates = [
      for (final entry in widget.tags.allTags.entries)
        if (!taken.contains(noteNavKey(entry.key)) &&
            noteNavKey(entry.key).contains(typed))
          entry,
    ];
    mergeSort<MapEntry<String, int>>(
      candidates,
      compare: (a, b) => b.value.compareTo(a.value),
    );

    return [
      for (final entry in candidates.take(widget.maxSuggestions)) entry.key,
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.tags, _input]),
    builder: (context, _) {
      final applied = widget.tags.tagsOf(widget.target);
      final suggestions = _suggestions(applied);
      final onTagSelected = widget.onTagSelected;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (applied.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in applied)
                  NoteNavChip(
                    key: ValueKey('note-tag-chip-$tag'),
                    label: tag,
                    style: widget.style,
                    onTap: onTagSelected == null
                        ? null
                        : () => onTagSelected(tag),
                    onRemove: () => widget.tags.remove(tag, widget.target),
                    removeLabel: widget.strings.removeTag(tag),
                    removeKey: ValueKey('note-tag-remove-$tag'),
                  ),
              ],
            ),
          NoteTextField(
            key: const ValueKey('note-tag-input'),
            controller: _input,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            hintText: widget.strings.addTagHint,
            onSubmitted: _submit,
            style: widget.style.textStyle,
            hintStyle: widget.style.secondaryTextStyle,
            cursorColor: widget.style.accentColor,
          ),
          if (suggestions.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in suggestions)
                  NoteNavChip(
                    key: ValueKey('note-tag-suggestion-$tag'),
                    label: '+ $tag',
                    style: widget.style,
                    onTap: () => _add(tag),
                  ),
              ],
            ),
        ],
      );
    },
  );
}
