import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/core/utils/stroke_id.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/document/note_page_numbering.dart';
import 'package:open_note/src/note/document/note_page_ops.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/study/utilities/note_attachment_list.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// A notebook: its pages in order (and recently deleted ones), page numbering,
/// bookmarks, outline, excerpts, page tags, attachments, recordings and the
/// objects that appear on every page.
///
/// Page operations are reversible rather than undoable: turn a page back,
/// set the margins back, or restore a removed page from [trashedPages] (its
/// bookmarks and other entries are kept until the page is purged). Ink and
/// object undo belongs to the page being edited (`NotePageSession`).
///
/// A document has at least one page. It notifies on every change, including
/// changes to its bookmarks, outline, excerpts, tags and attachments;
/// [dirtyPageIds] tells a repository which pages to write again.
class NoteDocument extends ChangeNotifier {
  NoteDocument({
    required this.id,
    required this.registry,
    String title = '',
    Iterable<NotePage> pages = const [],
    Iterable<NoteTrashedPage> trash = const [],
    NotePageNumbering numbering = const NotePageNumbering(),
    NoteBookmarks? bookmarks,
    NoteOutline? outline,
    NoteExcerpts? excerpts,
    NoteTags? tags,
    NoteAttachmentList? attachments,
    JsonMap recordings = const {},
    Map<String, String> recordingPageIds = const {},
    Iterable<NoteObject> documentObjects = const [],
    NotePaperTemplate? defaultTemplate,
    NoteIdFactory idFactory = generateNoteId,
    String Function() strokeIdFactory = generateStrokeId,
    NoteClock clock = systemNoteClock,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : _title = title,
       _numbering = numbering,
       _recordings = recordings,
       _documentObjects = List.unmodifiable(documentObjects),
       _defaultTemplate = defaultTemplate ?? NotePaperTemplate.lined(),
       _idFactory = idFactory,
       _strokeIdFactory = strokeIdFactory,
       _clock = clock,
       createdAt = createdAt ?? clock(),
       bookmarks = bookmarks ?? NoteBookmarks(),
       outline = outline ?? NoteOutline(),
       excerpts = excerpts ?? NoteExcerpts(),
       tags = tags ?? NoteTags(),
       attachments = attachments ?? NoteAttachmentList() {
    _modifiedAt = modifiedAt ?? this.createdAt;
    for (final page in pages) {
      if (_pages.containsKey(page.id)) continue;
      _pages[page.id] = page;
      _order.add(page.id);
    }
    for (final entry in trash) {
      if (_pages.containsKey(entry.page.id)) continue;
      _pages[entry.page.id] = entry.page;
      _trash.add(entry);
    }
    if (_order.isEmpty) {
      final page = _blankPage(_defaultTemplate, null);
      _pages[page.id] = page;
      _order.add(page.id);
      _dirty.add(page.id);
    }
    if (recordingPageIds.isEmpty) {
      _attachRecordings(recordings);
    } else {
      _recordingPages.addAll({
        for (final entry in recordingPageIds.entries)
          if (_pages.containsKey(entry.value)) entry.key: entry.value,
      });
    }
    for (final listenable in _navListenables) {
      listenable.addListener(_onEntriesChanged);
    }
  }

  final String id;

  /// Decodes (and copies) page objects.
  final NoteObjectRegistry registry;

  final NoteBookmarks bookmarks;
  final NoteOutline outline;
  final NoteExcerpts excerpts;

  /// Page tags (refs carry this note's [id]). Tags on the note itself live in
  /// the library's `NoteSummary.tags`.
  final NoteTags tags;
  final NoteAttachmentList attachments;

  final DateTime createdAt;

  final NotePaperTemplate _defaultTemplate;
  final NoteIdFactory _idFactory;
  final String Function() _strokeIdFactory;
  final NoteClock _clock;

  final Map<String, NotePage> _pages = {};
  final Map<String, String> _recordingPages = {};
  final List<String> _order = [];
  final List<NoteTrashedPage> _trash = [];
  final Set<String> _dirty = {};
  String _title;
  NotePageNumbering _numbering;
  JsonMap _recordings;
  List<NoteObject> _documentObjects;
  late DateTime _modifiedAt;
  int _revision = 0;
  bool _isDisposed = false;

  String get title => _title;

  set title(String value) {
    if (value == _title) return;
    _title = value;
    _touch();
  }

  NotePageNumbering get numbering => _numbering;

  set numbering(NotePageNumbering value) {
    if (value == _numbering) return;
    _numbering = value;
    _touch();
  }

  /// The recording list as `NoteRecordingController.toJson`, for a host that
  /// owns the controller (it needs the host's audio player).
  ///
  /// Each recording stays on its page: reading gives the page numbers for the
  /// current order, and a recording of a removed page reads as detached until
  /// the page is restored. Assigning takes the numbers as they are now, so
  /// after page operations bring a live controller up to date with
  /// [recordingPageNumber] (`attachToPage`) before saving its JSON back.
  JsonMap get recordings => {
    ..._recordings,
    if (_recordings['recordings'] != null)
      'recordings': [
        for (final entry in NoteJson.mapList(_recordings, 'recordings'))
          {
            for (final field in entry.entries)
              if (field.key != 'pageNumber') field.key: field.value,
            'pageNumber': ?recordingPageNumber(NoteJson.string(entry, 'id')),
          },
      ],
  };

  set recordings(JsonMap value) {
    _recordings = value;
    _attachRecordings(value);
    _touch();
  }

  /// The stable page id of each attached recording.
  Map<String, String> get recordingPageIds => Map.unmodifiable(_recordingPages);

  /// The current 1-based page number of a recording; null when it has no page
  /// or its page is removed.
  int? recordingPageNumber(String recordingId) {
    final pageId = _recordingPages[recordingId];
    final index = pageId == null ? -1 : indexOf(pageId);

    return index < 0 ? null : index + 1;
  }

  /// Objects shown on every page, such as a cover board that stays while pages
  /// turn.
  List<NoteObject> get documentObjects => _documentObjects;

  set documentObjects(List<NoteObject> value) {
    if (listEquals(value, _documentObjects)) return;
    _documentObjects = List.unmodifiable(value);
    _touch();
  }

  DateTime get modifiedAt => _modifiedAt;

  /// Increases with every change.
  int get revision => _revision;

  /// Pages whose content changed since the last [markSaved].
  Set<String> get dirtyPageIds => Set.unmodifiable(_dirty);

  List<String> get pageIds => List.unmodifiable(_order);

  List<NotePage> get pages =>
      List.unmodifiable([for (final id in _order) _pages[id]!]);

  int get pageCount => _order.length;

  /// Removed pages, most recently removed last.
  List<NoteTrashedPage> get trashedPages => List.unmodifiable(_trash);

  /// The page [pageId], including a removed one; null when unknown.
  NotePage? page(String pageId) => _pages[pageId];

  NotePage pageAt(int index) => _pages[_order[index]]!;

  /// The position of a page, or -1 for unknown and removed pages.
  int indexOf(String pageId) => _order.indexOf(pageId);

  /// The number printed for a page (see [numbering]).
  String labelOf(String pageId) {
    final index = indexOf(pageId);

    return index < 0 ? '' : _numbering.labelOf(_order, index);
  }

  /// Pages with ink on them, in order.
  List<NotePage> get pagesWithInk => [
    for (final page in pages)
      if (page.hasInk) page,
  ];

  /// Inserts a blank page and returns it.
  ///
  /// It goes after [after], else before [before], else at [index], else at the
  /// end. The paper defaults to that of the neighbouring page; [size] defaults
  /// to the template's size when [template] is given, else the neighbour's
  /// paper size, and [orientation] turns it if needed.
  NotePage addPage({
    int? index,
    String? after,
    String? before,
    NotePaperTemplate? template,
    NotePageSize? size,
    NotePageOrientation? orientation,
  }) {
    final anchor = after ?? before;
    final anchorIndex = anchor == null ? -1 : indexOf(anchor);
    final position = switch ((after, before)) {
      (final String _, _) when anchorIndex >= 0 => anchorIndex + 1,
      (_, final String _) when anchorIndex >= 0 => anchorIndex,
      _ => (index ?? _order.length).clamp(0, _order.length),
    };
    final neighbour = anchorIndex >= 0
        ? pageAt(anchorIndex)
        : pageAt((position - 1).clamp(0, _order.length - 1));
    final paper = template ?? neighbour.template;
    var pageSize =
        size ?? (template != null ? template.size : neighbour.paperSize);
    if (orientation != null) pageSize = pageSize.withOrientation(orientation);
    final page = _blankPage(paper, pageSize);
    _insert(page, position);

    return page;
  }

  /// Copies a page right after itself; null for an unknown page.
  NotePage? duplicatePage(String pageId) {
    final index = indexOf(pageId);
    if (index < 0) return null;
    final copy = _copy(_pages[pageId]!);
    _insert(copy, index + 1);

    return copy;
  }

  /// Copies pages of [source] (with new ids) into this note at [index] (the
  /// end by default), keeping their order. Unknown ids are skipped.
  List<NotePage> importPages(
    NoteDocument source,
    Iterable<String> sourcePageIds, {
    int? index,
  }) {
    var position = (index ?? _order.length).clamp(0, _order.length);
    final imported = <NotePage>[];
    final copied = <String, String>{};
    for (final sourceId in sourcePageIds) {
      final original = source.page(sourceId);
      if (original == null || source.indexOf(sourceId) < 0) continue;
      final copy = _copy(original);
      copied[original.id] = copy.id;
      imported.add(copy);
    }
    // Links between the imported pages follow the copies.
    for (var i = 0; i < imported.length; i++) {
      imported[i] = NotePageOps.remapLinks(
        imported[i],
        copied,
        registry: registry,
      );
      final page = imported[i];
      _pages[page.id] = page;
      _order.insert(position++, page.id);
      _dirty.add(page.id);
    }
    if (imported.isNotEmpty) _touch();

    return imported;
  }

  /// Appends pages built elsewhere (for example from an imported PDF).
  void appendPages(Iterable<NotePage> pages, {int? index}) {
    var position = (index ?? _order.length).clamp(0, _order.length);
    var added = false;
    for (final page in pages) {
      if (_pages.containsKey(page.id)) continue;
      _pages[page.id] = page;
      _order.insert(position++, page.id);
      _dirty.add(page.id);
      added = true;
    }
    if (added) _touch();
  }

  /// Moves a page to the trash. The last page cannot be removed.
  bool removePage(String pageId) {
    final index = indexOf(pageId);
    if (index < 0 || _order.length == 1) return false;
    _order.removeAt(index);
    _trash.add(NoteTrashedPage(page: _pages[pageId]!, index: index));
    _touch();

    return true;
  }

  /// Brings a removed page back to where it was.
  bool restorePage(String pageId) {
    final entry = _trashEntry(pageId);
    if (entry == null) return false;
    _trash.remove(entry);
    _order.insert(entry.index.clamp(0, _order.length), pageId);
    _touch();

    return true;
  }

  /// Deletes a removed page for good, with its bookmarks, outline entries,
  /// excerpts and tags.
  bool purgePage(String pageId) {
    final entry = _trashEntry(pageId);
    if (entry == null) return false;
    _trash.remove(entry);
    _pages.remove(pageId);
    _dirty.remove(pageId);
    bookmarks.removePage(pageId);
    outline.removePage(pageId);
    excerpts.removePage(pageId);
    tags.removePage(id, pageId);
    _recordingPages.removeWhere((_, attached) => attached == pageId);
    _touch();

    return true;
  }

  void emptyPageTrash() {
    for (final entry in List.of(_trash)) {
      purgePage(entry.page.id);
    }
  }

  /// Moves a page to [newIndex] (clamped).
  bool movePage(String pageId, int newIndex) {
    final index = indexOf(pageId);
    if (index < 0) return false;
    final target = newIndex.clamp(0, _order.length - 1);
    if (target == index) return false;
    _order
      ..removeAt(index)
      ..insert(target, pageId);
    _touch();

    return true;
  }

  /// Stores a new snapshot of an existing page (what an editing session saves
  /// back). Unknown pages are ignored.
  void replacePage(NotePage page) {
    final current = _pages[page.id];
    if (current == null || identical(current, page)) return;
    _pages[page.id] = page;
    _dirty.add(page.id);
    _touch();
  }

  /// Turns a page clockwise by [quarterTurns] × 90°. Not for the page open in
  /// an editing session — rotate through the session there.
  void rotatePage(String pageId, [int quarterTurns = 1]) =>
      _edit(pageId, (page) => NotePageOps.rotate(page, quarterTurns));

  /// Sets the extended margins of a page, and optionally the paper that fills
  /// them.
  void setPageMargins(
    String pageId,
    EdgeInsets margins, {
    NotePaperTemplate? marginTemplate,
  }) => _edit(pageId, (page) {
    final resized = NotePageOps.setMargins(page, margins);

    return marginTemplate == null
        ? resized
        : resized.copyWith(marginTemplate: () => marginTemplate);
  });

  /// Gives pages a new paper, keeping their size and content.
  void setTemplate(Iterable<String> pageIds, NotePaperTemplate template) {
    for (final pageId in pageIds) {
      _edit(
        pageId,
        (page) => page.copyWith(template: template.fitted(page.paperSize)),
      );
    }
  }

  /// Marks pages as written (every page when [written] is null). A page that
  /// changed since [written] was taken stays dirty. Repositories call this
  /// after saving.
  void markSaved([Iterable<NotePage>? written]) {
    if (written == null) {
      _dirty.clear();

      return;
    }
    for (final page in written) {
      if (identical(_pages[page.id], page)) _dirty.remove(page.id);
    }
  }

  /// The persisted metadata (pages are written separately). JSON: `{v: 1, id,
  /// title, pageOrder, trash: [{id, index}], numbering, bookmarks, outline,
  /// excerpts, tags, attachments, recordings, recordingPages,
  /// documentObjects, createdAt, modifiedAt}`.
  JsonMap metadataToJson() => {
    'v': 1,
    'id': id,
    'title': _title,
    'pageOrder': _order,
    'trash': [
      for (final entry in _trash) {'id': entry.page.id, 'index': entry.index},
    ],
    'numbering': _numbering.toJson(),
    'bookmarks': bookmarks.toJson(),
    'outline': outline.toJson(),
    'excerpts': excerpts.toJson(),
    'tags': tags.toJson(),
    'attachments': attachments.toJson(),
    'recordings': recordings,
    'recordingPages': _recordingPages,
    'documentObjects': [for (final o in _documentObjects) o.toJson()],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'modifiedAt': _modifiedAt.toUtc().toIso8601String(),
  };

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final listenable in _navListenables) {
      listenable.removeListener(_onEntriesChanged);
    }
    bookmarks.dispose();
    outline.dispose();
    excerpts.dispose();
    tags.dispose();
    attachments.dispose();
    super.dispose();
  }

  List<Listenable> get _navListenables => [
    bookmarks,
    outline,
    excerpts,
    tags,
    attachments,
  ];

  void _onEntriesChanged() => _touch();

  void _attachRecordings(JsonMap value) {
    final ids = <String>{};
    for (final entry in NoteJson.mapList(value, 'recordings')) {
      final recordingId = NoteJson.string(entry, 'id');
      if (recordingId.isEmpty) continue;
      ids.add(recordingId);
      final number = NoteJson.integer(entry, 'pageNumber');
      if (number >= 1 && number <= _order.length) {
        _recordingPages[recordingId] = _order[number - 1];
      } else if (_trashEntry(_recordingPages[recordingId] ?? '') == null) {
        _recordingPages.remove(recordingId);
      }
    }
    _recordingPages.removeWhere((recordingId, _) => !ids.contains(recordingId));
  }

  NotePage _blankPage(NotePaperTemplate template, NotePageSize? size) =>
      NotePage.blank(
        template: template,
        size: size,
        idFactory: _idFactory,
        clock: _clock,
      );

  NotePage _copy(NotePage page) => NotePageOps.duplicate(
    page,
    registry: registry,
    idFactory: _idFactory,
    strokeIdFactory: _strokeIdFactory,
    clock: _clock,
  );

  void _insert(NotePage page, int position) {
    _pages[page.id] = page;
    _order.insert(position.clamp(0, _order.length), page.id);
    _dirty.add(page.id);
    _touch();
  }

  void _edit(String pageId, NotePage Function(NotePage) change) {
    final current = _pages[pageId];
    if (current == null) return;
    final next = change(current);
    if (identical(next, current)) return;
    replacePage(next.copyWith(modifiedAt: _clock()));
  }

  NoteTrashedPage? _trashEntry(String pageId) {
    for (final entry in _trash) {
      if (entry.page.id == pageId) return entry;
    }

    return null;
  }

  void _touch() {
    if (_isDisposed) return;
    _modifiedAt = _clock();
    _revision++;
    notifyListeners();
  }
}

/// A removed page and the position it had.
class NoteTrashedPage {
  const NoteTrashedPage({required this.page, required this.index});

  final NotePage page;
  final int index;
}
