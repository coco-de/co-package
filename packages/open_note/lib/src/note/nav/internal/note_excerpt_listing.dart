import 'package:open_note/src/note/nav/internal/note_nav_text.dart';
import 'package:open_note/src/note/nav/note_excerpt.dart';
import 'package:open_note/src/note/nav/note_excerpts.dart';

/// The content of the excerpt panel for a search query and a label filter. Not
/// exported by the barrel.
class NoteExcerptListing {
  const NoteExcerptListing._({
    required this.chips,
    required this.selectedKey,
    required this.groups,
  });

  /// Computes the listing.
  ///
  /// [selectedKey] falls back to "every excerpt" when no excerpt has that label
  /// any more. Groups follow the label order, the unlabeled one last.
  factory NoteExcerptListing.of(
    NoteExcerpts excerpts, {
    required List<String> pageOrder,
    required String query,
    required String? selectedKey,
  }) {
    final labels = excerpts.labels;
    final unlabeled = excerpts.byLabel(null).length;
    final chips = [
      const NoteExcerptChip(key: null),
      for (final entry in labels.entries)
        NoteExcerptChip(
          key: noteNavKey(entry.key),
          label: entry.key,
          count: entry.value,
        ),
      if (unlabeled > 0) NoteExcerptChip(key: '', count: unlabeled),
    ];
    final selected = chips.any((chip) => chip.key == selectedKey)
        ? selectedKey
        : null;
    final found = excerpts.search(query).map((excerpt) => excerpt.id).toSet();
    final shown = excerpts
        .ordered(pageOrder)
        .where((excerpt) => found.contains(excerpt.id));

    return NoteExcerptListing._(
      chips: labels.isEmpty ? const [] : chips,
      selectedKey: selected,
      groups: _group(shown, labels.keys, selected),
    );
  }

  final List<NoteExcerptChip> chips;
  final String? selectedKey;
  final List<NoteExcerptGroup> groups;

  static List<NoteExcerptGroup> _group(
    Iterable<NoteExcerpt> excerpts,
    Iterable<String> labels,
    String? selectedKey,
  ) {
    final byKey = <String, List<NoteExcerpt>>{};
    for (final excerpt in excerpts) {
      final key = noteNavKey(excerpt.label ?? '');
      if (selectedKey != null && key != selectedKey) continue;
      byKey.putIfAbsent(key, () => []).add(excerpt);
    }

    return [
      for (final label in labels)
        if (byKey[noteNavKey(label)] case final members?)
          NoteExcerptGroup(label: label, excerpts: members),
      if (byKey[''] case final members?)
        NoteExcerptGroup(label: null, excerpts: members),
    ];
  }
}

/// One chip of the excerpt panel's label filter. Not exported by the barrel.
class NoteExcerptChip {
  const NoteExcerptChip({required this.key, this.label, this.count = 0});

  /// `null` = every excerpt, `''` = unlabeled, otherwise a label key.
  final String? key;

  /// Display spelling of a label chip.
  final String? label;

  /// Excerpts carrying the label.
  final int count;
}

/// One group of the excerpt panel. Not exported by the barrel.
class NoteExcerptGroup {
  const NoteExcerptGroup({required this.label, required this.excerpts});

  /// Display spelling, or `null` for the unlabeled group.
  final String? label;

  /// The excerpts, in reading order.
  final List<NoteExcerpt> excerpts;
}
