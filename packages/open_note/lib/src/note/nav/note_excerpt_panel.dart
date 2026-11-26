import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/nav/internal/note_excerpt_listing.dart';
import 'package:open_note/src/note/nav/internal/note_excerpt_tile.dart';
import 'package:open_note/src/note/nav/internal/note_nav_chip.dart';
import 'package:open_note/src/note/nav/internal/note_nav_frame.dart';
import 'package:open_note/src/note/nav/internal/note_nav_message.dart';
import 'package:open_note/src/note/nav/note_excerpt.dart';
import 'package:open_note/src/note/nav/note_excerpts.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';

/// The excerpts of a note, grouped by label, with a search field and label
/// chips.
///
/// Tapping a row reports the excerpt: the host jumps to the page and usually
/// calls `NoteExcerptFlashController.flash`. A chip shows one label (tap it
/// again, or "All", to show everything); the search filters by label and note.
///
/// The panel fills its constraints, which must bound the height.
class NoteExcerptPanel extends StatefulWidget {
  /// Creates the panel.
  const NoteExcerptPanel({
    required this.excerpts,
    required this.pageOrder,
    required this.onExcerptSelected,
    super.key,
    this.editable = true,
    this.strings = const NoteNavStrings(),
    this.style = const NoteNavStyle(),
  });

  /// The excerpts shown.
  final NoteExcerpts excerpts;

  /// The page ids of the note, in order (used for sorting and page numbers).
  final List<String> pageOrder;

  /// An excerpt was tapped.
  final ValueChanged<NoteExcerpt> onExcerptSelected;

  /// Whether rows have a delete button.
  final bool editable;

  /// User-visible text.
  final NoteNavStrings strings;

  /// Colours and sizes.
  final NoteNavStyle style;

  @override
  State<NoteExcerptPanel> createState() => _NoteExcerptPanelState();
}

class _NoteExcerptPanelState extends State<NoteExcerptPanel> {
  String _query = '';
  String? _labelKey;

  void _search(String query) => setState(() => _query = query);

  void _filter(String? key) =>
      setState(() => _labelKey = _labelKey == key ? null : key);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.excerpts,
    builder: (context, _) {
      final listing = NoteExcerptListing.of(
        widget.excerpts,
        pageOrder: widget.pageOrder,
        query: _query,
        selectedKey: _labelKey,
      );

      return NoteNavFrame(
        title: widget.strings.excerptsTitle,
        style: widget.style,
        toolbar: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            NoteTextField(
              key: const ValueKey('note-excerpt-search'),
              hintText: widget.strings.searchExcerptsHint,
              onChanged: _search,
              style: widget.style.textStyle,
              hintStyle: widget.style.secondaryTextStyle,
              cursorColor: widget.style.accentColor,
            ),
            if (listing.chips.isNotEmpty)
              _NoteExcerptChips(
                listing: listing,
                strings: widget.strings,
                style: widget.style,
                onSelected: _filter,
              ),
          ],
        ),
        body: listing.groups.isEmpty
            ? NoteNavMessage(
                message: widget.excerpts.isEmpty
                    ? widget.strings.emptyExcerpts
                    : widget.strings.noResults,
                style: widget.style,
              )
            : _NoteExcerptList(groups: listing.groups, panel: widget),
      );
    },
  );
}

class _NoteExcerptChips extends StatelessWidget {
  const _NoteExcerptChips({
    required this.listing,
    required this.strings,
    required this.style,
    required this.onSelected,
  });

  final NoteExcerptListing listing;
  final NoteNavStrings strings;
  final NoteNavStyle style;
  final ValueChanged<String?> onSelected;

  String _text(NoteExcerptChip chip) {
    final key = chip.key;
    if (key == null) return strings.allLabels;
    final name = key.isEmpty ? strings.unlabeled : chip.label ?? key;

    return strings.countedName(name, chip.count);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 6,
      children: [
        for (final chip in listing.chips)
          NoteNavChip(
            // "All" has its own prefix: a label may contain any text.
            key: ValueKey(
              chip.key == null
                  ? 'note-excerpt-chips-all'
                  : 'note-excerpt-chip-${chip.key}',
            ),
            label: _text(chip),
            style: style,
            selected: listing.selectedKey == chip.key,
            onTap: () => onSelected(chip.key),
          ),
      ],
    ),
  );
}

class _NoteExcerptList extends StatelessWidget {
  const _NoteExcerptList({required this.groups, required this.panel});

  final List<NoteExcerptGroup> groups;
  final NoteExcerptPanel panel;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[
      for (final group in groups) ...[group, ...group.excerpts],
    ];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is NoteExcerptGroup) {
          return _NoteExcerptGroupHeader(
            label: item.label ?? panel.strings.unlabeled,
            style: panel.style,
          );
        }
        final excerpt = item as NoteExcerpt;

        return NoteExcerptTile(
          key: ValueKey('note-excerpt-row-${excerpt.id}'),
          excerpt: excerpt,
          pageLabel: panel.strings.pageLabel(excerpt.pageId, panel.pageOrder),
          strings: panel.strings,
          style: panel.style,
          onSelect: () => panel.onExcerptSelected(excerpt),
          onDelete: panel.editable
              ? () => panel.excerpts.remove(excerpt.id)
              : null,
        );
      },
    );
  }
}

class _NoteExcerptGroupHeader extends StatelessWidget {
  const _NoteExcerptGroupHeader({required this.label, required this.style});

  final String label;
  final NoteNavStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: style.padding.add(const EdgeInsets.only(top: 10, bottom: 2)),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: style.secondaryTextStyle.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
