import 'package:flutter/foundation.dart';
import 'package:open_note/src/module/text/text_span_builder.dart'
    show kPageLinkScheme, normalizeExternalLinkTarget, parsePageLinkTarget;

/// Where a hyperlink points. The wire form is one string so it fits any
/// `url`/`target` field, including the engine's `TextLinkSpan.url`:
///
/// - `page:N`            — page N (1-based) of the same note (the engine's
///   existing in-document grammar, parsed by the engine's own helper);
/// - `pageid:<page id>`  — a page of the same note by id, which keeps pointing
///   at it when pages are inserted, removed or reordered;
/// - `note:<id>`         — the first page of another note;
/// - `note:<id>#page:N`  — page N (1-based) of another note;
/// - anything else with a scheme (`https://…`, `mailto:…`) — an external link
///   the host opens.
sealed class NoteLinkTarget {
  const NoteLinkTarget();

  /// Parses [raw]; `null` when it is blank. Unrecognised text becomes a
  /// [NoteUrlLink] (a missing scheme defaults to `https://`).
  static NoteLinkTarget? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();
    final page = parsePageLinkTarget(text);
    if (page != null) return NotePageLink(page);
    if (text.startsWith(NotePageIdLink.scheme)) {
      final pageId = text.substring(NotePageIdLink.scheme.length);

      return pageId.isEmpty ? null : NotePageIdLink(pageId);
    }
    if (text.startsWith(_noteScheme)) {
      final body = text.substring(_noteScheme.length);
      final hash = body.indexOf('#');
      final noteId = hash < 0 ? body : body.substring(0, hash);
      if (noteId.isEmpty) return null;
      if (hash < 0) return NoteNoteLink(noteId);
      final linkedPage = parsePageLinkTarget(body.substring(hash + 1));

      return NoteNoteLink(noteId, page: linkedPage);
    }
    final url = normalizeExternalLinkTarget(text);

    return url == null ? null : NoteUrlLink(url);
  }

  /// The one-string wire form.
  String format();

  static const String _noteScheme = 'note:';
}

/// A page of the same note (1-based).
@immutable
final class NotePageLink extends NoteLinkTarget {
  const NotePageLink(this.page) : assert(page >= 1, 'pages are 1-based');

  final int page;

  @override
  String format() => '$kPageLinkScheme$page';

  @override
  bool operator ==(Object other) => other is NotePageLink && other.page == page;

  @override
  int get hashCode => Object.hash(NotePageLink, page);

  @override
  String toString() => 'NotePageLink($page)';
}

/// A page of the same note, by its stable id.
@immutable
final class NotePageIdLink extends NoteLinkTarget {
  const NotePageIdLink(this.pageId);

  /// The wire prefix.
  static const String scheme = 'pageid:';

  final String pageId;

  @override
  String format() => '$scheme$pageId';

  @override
  bool operator ==(Object other) =>
      other is NotePageIdLink && other.pageId == pageId;

  @override
  int get hashCode => Object.hash(NotePageIdLink, pageId);

  @override
  String toString() => 'NotePageIdLink($pageId)';
}

/// Another note, optionally at a page (1-based).
@immutable
final class NoteNoteLink extends NoteLinkTarget {
  const NoteNoteLink(this.noteId, {this.page})
    : assert(page == null || page >= 1, 'pages are 1-based');

  final String noteId;
  final int? page;

  @override
  String format() => page == null
      ? '${NoteLinkTarget._noteScheme}$noteId'
      : '${NoteLinkTarget._noteScheme}$noteId#$kPageLinkScheme$page';

  @override
  bool operator ==(Object other) =>
      other is NoteNoteLink && other.noteId == noteId && other.page == page;

  @override
  int get hashCode => Object.hash(NoteNoteLink, noteId, page);

  @override
  String toString() => 'NoteNoteLink($noteId, page: $page)';
}

/// An external URL the host opens.
@immutable
final class NoteUrlLink extends NoteLinkTarget {
  const NoteUrlLink(this.url);

  final String url;

  /// Schemes that are safe to hand to a browser, mail or phone app by default.
  ///
  /// A link comes from a document, which may have been imported from anyone, so
  /// every other scheme (`file:`, `intent:`, `javascript:`, app deep links…)
  /// has to be allowed explicitly by the host.
  static const Set<String> safeSchemes = {'http', 'https', 'mailto', 'tel'};

  /// The lower-cased URL scheme, or '' when [url] cannot be parsed.
  String get scheme => Uri.tryParse(url)?.scheme.toLowerCase() ?? '';

  /// Whether [scheme] is one of [safeSchemes].
  bool get hasSafeScheme => safeSchemes.contains(scheme);

  @override
  String format() => url;

  @override
  bool operator ==(Object other) => other is NoteUrlLink && other.url == url;

  @override
  int get hashCode => Object.hash(NoteUrlLink, url);

  @override
  String toString() => 'NoteUrlLink($url)';
}
