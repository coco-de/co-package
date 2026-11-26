import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/nav/internal/note_nav_chip.dart';
import 'package:open_note/src/note/nav/internal/note_nav_message.dart';
import 'package:open_note/src/note/nav/internal/note_nav_row.dart';
import 'package:open_note/src/note/nav/note_nav_strings.dart';
import 'package:open_note/src/note/nav/note_nav_style.dart';
import 'package:open_note/src/note/nav/note_search_hit.dart';
import 'package:open_note/src/note/nav/note_search_hit_kind.dart';
import 'package:open_note/src/note/nav/note_search_index.dart';

/// A search field with source filter chips and the ranked results, the match
/// highlighted. Results update as the user types and when the [index] changes.
///
/// The panel fills its constraints, which must bound the height.
class NoteSearchPanel extends StatefulWidget {
  /// Creates the panel.
  const NoteSearchPanel({
    required this.index,
    required this.onHitSelected,
    super.key,
    this.noteId,
    this.describeHit,
    this.limit = 50,
    this.showKindFilters = true,
    this.autofocus = false,
    this.strings = const NoteNavStrings(),
    this.style = const NoteNavStyle(),
  });

  /// What is searched.
  final NoteSearchIndex index;

  /// A result was tapped: jump to it.
  final ValueChanged<NoteSearchHit> onHitSelected;

  /// Searches this note only when set.
  final String? noteId;

  /// Says where a hit is, for example "Calculus · Page 3"; it follows the
  /// source name under the snippet.
  final String Function(NoteSearchHit hit)? describeHit;

  /// The most results shown.
  final int limit;

  /// Whether the source filter chips are shown.
  final bool showKindFilters;

  /// Whether the search field takes the focus when it appears.
  final bool autofocus;

  /// User-visible text.
  final NoteNavStrings strings;

  /// Colours and sizes.
  final NoteNavStyle style;

  @override
  State<NoteSearchPanel> createState() => _NoteSearchPanelState();
}

class _NoteSearchPanelState extends State<NoteSearchPanel> {
  String _query = '';
  NoteSearchHitKind? _kind;

  void _search(String query) => setState(() => _query = query);

  void _filter(NoteSearchHitKind? kind) =>
      setState(() => _kind = _kind == kind ? null : kind);

  List<NoteSearchHit> _hits() {
    final kind = widget.showKindFilters ? _kind : null;

    return widget.index.search(
      _query,
      limit: widget.limit,
      kinds: kind == null ? null : {kind},
      noteId: widget.noteId,
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.style.backgroundColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widget.style.padding.add(
            const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              NoteTextField(
                key: const ValueKey('note-search-field'),
                autofocus: widget.autofocus,
                hintText: widget.strings.searchHint,
                onChanged: _search,
                style: widget.style.textStyle,
                hintStyle: widget.style.secondaryTextStyle,
                cursorColor: widget.style.accentColor,
              ),
              if (widget.showKindFilters)
                _NoteSearchKindChips(
                  selected: _kind,
                  strings: widget.strings,
                  style: widget.style,
                  onSelected: _filter,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.index,
            builder: (context, _) {
              final hits = _hits();
              if (hits.isEmpty) {
                return NoteNavMessage(
                  message: _query.trim().isEmpty
                      ? widget.strings.searchPrompt
                      : widget.strings.noResults,
                  style: widget.style,
                );
              }

              return _NoteSearchResults(hits: hits, panel: widget);
            },
          ),
        ),
      ],
    ),
  );
}

class _NoteSearchKindChips extends StatelessWidget {
  const _NoteSearchKindChips({
    required this.selected,
    required this.strings,
    required this.style,
    required this.onSelected,
  });

  final NoteSearchHitKind? selected;
  final NoteNavStrings strings;
  final NoteNavStyle style;
  final ValueChanged<NoteSearchHitKind?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 6,
      children: [
        for (final kind in [null, ...NoteSearchHitKind.values])
          NoteNavChip(
            key: ValueKey('note-search-kind-${kind?.name ?? 'all'}'),
            label: kind == null ? strings.allKinds : strings.kindName(kind),
            style: style,
            selected: selected == kind,
            onTap: () => onSelected(kind),
          ),
      ],
    ),
  );
}

class _NoteSearchResults extends StatelessWidget {
  const _NoteSearchResults({required this.hits, required this.panel});

  final List<NoteSearchHit> hits;
  final NoteSearchPanel panel;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: hits.length,
    itemBuilder: (context, index) {
      final hit = hits[index];

      return _NoteSearchResultTile(
        key: ValueKey('note-search-hit-$index'),
        hit: hit,
        panel: panel,
      );
    },
  );
}

class _NoteSearchResultTile extends StatelessWidget {
  const _NoteSearchResultTile({
    required this.hit,
    required this.panel,
    super.key,
  });

  final NoteSearchHit hit;
  final NoteSearchPanel panel;

  @override
  Widget build(BuildContext context) {
    final style = panel.style;
    final place = panel.describeHit?.call(hit);
    final source = panel.strings.kindName(hit.kind);

    return NoteNavRow(
      style: style,
      onTap: () => panel.onHitSelected(hit),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: style.textStyle,
                children: [
                  TextSpan(text: hit.snippet.substring(0, hit.matchStart)),
                  TextSpan(
                    text: hit.matchedText,
                    style: TextStyle(
                      backgroundColor: style.highlightColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: hit.snippet.substring(hit.matchEnd)),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              place == null ? source : '$source · $place',
              style: style.secondaryTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
