import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/nav/note_search_hit_kind.dart';

/// All user-visible text of the nav panels, in English by default. Apps pass
/// their own instance to translate.
@immutable
class NoteNavStrings {
  /// Creates the strings; every argument has an English default.
  const NoteNavStrings({
    this.outlineTitle = 'Outline',
    this.bookmarksTitle = 'Bookmarks',
    this.excerptsTitle = 'Excerpts',
    this.emptyOutline = 'No outline entries',
    this.emptyBookmarks = 'No bookmarks yet',
    this.emptyExcerpts = 'No excerpts yet',
    this.noResults = 'No results',
    this.edit = 'Edit',
    this.done = 'Done',
    this.add = 'Add entry',
    this.addChild = 'Add sub-entry',
    this.rename = 'Rename',
    this.delete = 'Delete',
    this.indent = 'Indent',
    this.outdent = 'Outdent',
    this.expand = 'Expand',
    this.collapse = 'Collapse',
    this.newEntryTitle = 'New entry',
    this.titleHint = 'Title',
    this.addBookmark = 'Bookmark this page',
    this.removeBookmark = 'Remove bookmark',
    this.searchExcerptsHint = 'Search excerpts',
    this.allLabels = 'All',
    this.unlabeled = 'Unlabeled',
    this.addTagHint = 'Add a tag',
    this.searchHint = 'Search',
    this.searchPrompt = 'Type to search',
    this.allKinds = 'All',
    this.kindText = 'Text',
    this.kindExcerpt = 'Excerpt',
    this.kindBookmark = 'Bookmark',
    this.kindOutline = 'Outline',
    this.kindTag = 'Tag',
    this.kindHandwriting = 'Handwriting',
    this.unknownPage = 'Unknown page',
    this.pageNumber = _englishPageNumber,
    this.removeTag = _englishRemoveTag,
    this.countedName = _englishCountedName,
    this.monthName = _englishMonthName,
  });

  /// Header of the outline panel.
  final String outlineTitle;

  /// Header of the bookmark panel.
  final String bookmarksTitle;

  /// Header of the excerpt panel.
  final String excerptsTitle;

  /// Shown by an outline panel without entries.
  final String emptyOutline;

  /// Shown by a bookmark panel without bookmarks.
  final String emptyBookmarks;

  /// Shown by an excerpt panel without excerpts.
  final String emptyExcerpts;

  /// Shown when a search or filter matches nothing.
  final String noResults;

  /// Button that enters the edit mode.
  final String edit;

  /// Button that leaves the edit mode.
  final String done;

  /// Button that adds a root outline entry.
  final String add;

  /// Button that adds an entry below another.
  final String addChild;

  /// Rename button.
  final String rename;

  /// Delete button.
  final String delete;

  /// Indent button.
  final String indent;

  /// Outdent button.
  final String outdent;

  /// Button that shows sub-entries.
  final String expand;

  /// Button that hides sub-entries.
  final String collapse;

  /// Title of an entry added without a title.
  final String newEntryTitle;

  /// Hint of a title field.
  final String titleHint;

  /// Button that bookmarks the current page.
  final String addBookmark;

  /// Button that removes the bookmark of the current page.
  final String removeBookmark;

  /// Hint of the excerpt search field.
  final String searchExcerptsHint;

  /// Chip that shows excerpts of every label.
  final String allLabels;

  /// Group and chip of excerpts without a label.
  final String unlabeled;

  /// Hint of the tag input.
  final String addTagHint;

  /// Hint of the search field.
  final String searchHint;

  /// Shown by the search panel before anything is typed.
  final String searchPrompt;

  /// Search filter chip for every source.
  final String allKinds;

  /// Source name of [NoteSearchHitKind.text].
  final String kindText;

  /// Source name of [NoteSearchHitKind.excerpt].
  final String kindExcerpt;

  /// Source name of [NoteSearchHitKind.bookmark].
  final String kindBookmark;

  /// Source name of [NoteSearchHitKind.outline].
  final String kindOutline;

  /// Source name of [NoteSearchHitKind.tag].
  final String kindTag;

  /// Source name of [NoteSearchHitKind.handwriting].
  final String kindHandwriting;

  /// Shown for a page that is not in the page order.
  final String unknownPage;

  /// Label of the 1-based page number.
  final String Function(int number) pageNumber;

  /// Label of the button that removes the tag `tag`.
  final String Function(String tag) removeTag;

  /// Label of a filter chip: a name with the number of items behind it.
  final String Function(String name, int count) countedName;

  /// Name of the month `1`–`12` (used by `NoteOutlineBuilder.calendar`).
  final String Function(int month) monthName;

  /// The source name of [kind].
  String kindName(NoteSearchHitKind kind) => switch (kind) {
    NoteSearchHitKind.text => kindText,
    NoteSearchHitKind.excerpt => kindExcerpt,
    NoteSearchHitKind.bookmark => kindBookmark,
    NoteSearchHitKind.outline => kindOutline,
    NoteSearchHitKind.tag => kindTag,
    NoteSearchHitKind.handwriting => kindHandwriting,
  };

  /// The label of [pageId] given the [pageOrder]: its page number, or
  /// [unknownPage] when it is not listed.
  String pageLabel(String pageId, List<String> pageOrder) {
    final index = pageOrder.indexOf(pageId);

    return index < 0 ? unknownPage : pageNumber(index + 1);
  }

  static String _englishPageNumber(int number) => 'Page $number';

  static String _englishRemoveTag(String tag) => 'Remove tag $tag';

  static String _englishCountedName(String name, int count) => '$name ($count)';

  static String _englishMonthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][(month - 1).clamp(0, 11)];
}
