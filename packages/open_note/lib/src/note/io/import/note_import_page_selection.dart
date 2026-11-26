/// The page selection rule every importer follows.
abstract final class NoteImportPageSelection {
  /// Which of [pageCount] pages to import: all of them when [requested] is
  /// null, otherwise the requested 0-based indices in order, without repeats
  /// and without indices outside the document.
  static List<int> select(int pageCount, List<int>? requested) {
    if (requested == null) {
      return [for (var index = 0; index < pageCount; index++) index];
    }
    final seen = <int>{};

    return [
      for (final index in requested)
        if (index >= 0 && index < pageCount && seen.add(index)) index,
    ];
  }
}
