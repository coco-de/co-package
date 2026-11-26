import 'package:open_note/src/note/core/note_link_target.dart';

/// Turns a [NoteLinkTarget] into a navigation callback.
///
/// Page numbers are 1-based positions in [pageOrder], read when [navigate] is
/// called. An external URL comes from a document, which may have been imported,
/// so [openUrl] is only called for the [allowedSchemes]
/// ([NoteUrlLink.safeSchemes] by default); anything else is unresolved.
class NoteLinkNavigator {
  /// Creates a navigator for one open note.
  const NoteLinkNavigator({
    required this.pageOrder,
    required this.goToPage,
    required this.openNote,
    required this.openUrl,
    this.onUnresolved,
    this.currentNoteId,
    this.pageIdOfOtherNote,
    this.openNoteAtPage,
    this.allowedSchemes = NoteUrlLink.safeSchemes,
  });

  /// The page ids of the open note, in order.
  final List<String> Function() pageOrder;

  /// Shows a page of the open note.
  final void Function(String pageId) goToPage;

  /// Opens another note, at a page when its id is known.
  final void Function(String noteId, String? pageId) openNote;

  /// Opens an external URL.
  final void Function(String url) openUrl;

  /// Lower-case URL schemes [openUrl] may receive. Add an app's own deep-link
  /// scheme here only when the host handles it safely for untrusted input.
  final Set<String> allowedSchemes;

  /// Told about a target that leads nowhere: a page number outside the note, an
  /// empty URL or a URL whose scheme is not allowed.
  final void Function(NoteLinkTarget target)? onUnresolved;

  /// Id of the open note; links to it are followed with [goToPage] (a link
  /// without a page goes to the first page).
  final String? currentNoteId;

  /// Looks up the id of the page number `page` (1-based) of another note, so
  /// that [openNote] can receive it.
  final String? Function(String noteId, int page)? pageIdOfOtherNote;

  /// Opens another note at a page **number** (1-based). Used for a link to a
  /// page of another note whose id [pageIdOfOtherNote] cannot give — for a host
  /// that loads notes asynchronously. Without it such a link calls [openNote]
  /// with no page id, and the page number is dropped.
  final void Function(String noteId, int page)? openNoteAtPage;

  /// Follows [target]. Returns `true` when [goToPage], [openUrl] or one of the
  /// note callbacks was called, and `false` when the target is unresolvable.
  bool navigate(NoteLinkTarget target) => switch (target) {
    NotePageLink(:final page) => _goTo(target, page),
    NotePageIdLink(:final pageId) => _goToId(target, pageId),
    NoteNoteLink(:final noteId, :final page) => _openOther(
      target,
      noteId,
      page,
    ),
    NoteUrlLink(:final url) => _openExternal(target, url),
  };

  bool _goTo(NoteLinkTarget target, int page) {
    final order = pageOrder();
    if (page < 1 || page > order.length) return _unresolved(target);
    goToPage(order[page - 1]);

    return true;
  }

  bool _goToId(NoteLinkTarget target, String pageId) {
    if (!pageOrder().contains(pageId)) return _unresolved(target);
    goToPage(pageId);

    return true;
  }

  bool _openOther(NoteLinkTarget target, String noteId, int? page) {
    if (noteId.isEmpty) return _unresolved(target);
    if (noteId == currentNoteId) return _goTo(target, page ?? 1);
    final pageId = page == null ? null : pageIdOfOtherNote?.call(noteId, page);
    final atPage = openNoteAtPage;
    if (page != null && pageId == null && atPage != null) {
      atPage(noteId, page);
    } else {
      openNote(noteId, pageId);
    }

    return true;
  }

  bool _openExternal(NoteLinkTarget target, String url) {
    if (url.trim().isEmpty ||
        !allowedSchemes.contains(NoteUrlLink(url).scheme)) {
      return _unresolved(target);
    }
    openUrl(url);

    return true;
  }

  bool _unresolved(NoteLinkTarget target) {
    onUnresolved?.call(target);

    return false;
  }
}
