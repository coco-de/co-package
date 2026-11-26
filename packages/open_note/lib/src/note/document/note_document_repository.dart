import 'dart:typed_data';

import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/internal/note_page_link_remap.dart';
import 'package:open_note/src/note/document/note_document.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/document/note_page_numbering.dart';
import 'package:open_note/src/note/document/note_page_ops.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/study/utilities/note_attachment_list.dart';
import 'package:protobuf/protobuf.dart';

/// A loaded note and what could not be read.
class NoteDocumentLoadResult {
  const NoteDocumentLoadResult(this.document, this.damagedKeys);

  final NoteDocument document;

  /// Store keys that were missing or unreadable. Unreadable files were copied
  /// to `<key>.corrupt` so that saving again cannot destroy them.
  final List<String> damagedKeys;
}

/// Saves notes into a [NoteStore]:
///
/// - `notes/<note>/note.json` — [NoteDocument.metadataToJson];
/// - `notes/<note>/pages/<page>/page.json` — [NotePage.toJson];
/// - `notes/<note>/pages/<page>/layer-<layer>.pb` — one engine [Scribble]
///   (protobuf) per layer.
///
/// Ids are percent-encoded into path segments. Only changed pages are
/// rewritten; `note.json` is written last, and files of purged pages and
/// removed layers are deleted. With the library, delete [notePrefix] when a
/// note is removed for good.
class NoteDocumentRepository {
  NoteDocumentRepository(
    this.store, {
    required this.registry,
    this.idFactory = generateNoteId,
    this.clock = systemNoteClock,
  });

  final NoteStore store;
  final NoteObjectRegistry registry;
  final NoteIdFactory idFactory;
  final NoteClock clock;

  static const String _root = 'notes/';

  Future<void> _queue = Future.value();

  /// The store prefix of a note: every key of the note starts with it.
  static String notePrefix(String noteId) => '$_root${_segment(noteId)}/';

  Future<bool> exists(String noteId) =>
      store.exists('${notePrefix(noteId)}note.json');

  /// Ids of the stored notes.
  Future<List<String>> noteIds() async {
    final ids = <String>{};
    for (final key in await store.list(_root)) {
      final parts = key.substring(_root.length).split('/');
      if (parts.length == 2 && parts[1] == 'note.json') {
        ids.add(Uri.decodeComponent(parts[0]));
      }
    }

    return ids.toList()..sort();
  }

  /// Writes the note. Pages that changed (all of them with [everything], and any
  /// page not yet stored) are rewritten. Saves run one after another; each
  /// stores the note as it was when it began, and pages changed since then stay
  /// dirty for the next save.
  Future<void> save(NoteDocument document, {bool everything = false}) {
    final run = _queue.then((_) => _save(document, everything: everything));
    // A failed save is reported to its caller and does not block later ones.
    _queue = run.then((_) {}, onError: (Object _) {});

    return run;
  }

  Future<void> _save(NoteDocument document, {required bool everything}) async {
    final prefix = notePrefix(document.id);
    final dirty = document.dirtyPageIds;
    final kept = [
      ...document.pages,
      for (final entry in document.trashedPages) entry.page,
    ];
    final metadata = NoteJson.encode(document.metadataToJson());
    final existing = (await store.list(prefix)).toSet();
    for (final page in kept) {
      final pagePrefix = '$prefix${_pageDir(page.id)}';
      if (!everything &&
          !dirty.contains(page.id) &&
          existing.contains('${pagePrefix}page.json')) {
        continue;
      }
      await _savePage(pagePrefix, page);
    }
    await store.writeString('${prefix}note.json', metadata);
    await _deleteOrphans(prefix, kept);
    document.markSaved(kept);
  }

  /// Reads a note, or null when it has no readable `note.json`.
  Future<NoteDocumentLoadResult?> load(String noteId) async {
    final prefix = notePrefix(noteId);
    final damaged = <String>[];
    final metadata = await _readJson('${prefix}note.json', damaged);
    if (metadata == null) return null;
    final pages = <NotePage>[];
    for (final pageId in NoteJson.stringList(metadata, 'pageOrder')) {
      final page = await _loadPage(prefix, pageId, damaged);
      if (page != null) pages.add(page);
    }
    final trash = <NoteTrashedPage>[];
    for (final entry in NoteJson.mapList(metadata, 'trash')) {
      final page = await _loadPage(
        prefix,
        NoteJson.string(entry, 'id'),
        damaged,
      );
      if (page == null) continue;
      trash.add(
        NoteTrashedPage(page: page, index: NoteJson.integer(entry, 'index')),
      );
    }
    final document = NoteDocument(
      id: noteId,
      registry: registry,
      title: NoteJson.string(metadata, 'title'),
      pages: pages,
      trash: trash,
      numbering: NotePageNumbering.fromJson(metadata['numbering']),
      bookmarks: NoteBookmarks.fromJson(
        metadata['bookmarks'],
        idFactory: idFactory,
        clock: clock,
      ),
      outline: NoteOutline.fromJson(metadata['outline'], idFactory: idFactory),
      excerpts: NoteExcerpts.fromJson(
        metadata['excerpts'],
        idFactory: idFactory,
        clock: clock,
      ),
      tags: NoteTags.fromJson(metadata['tags']),
      attachments: NoteAttachmentList.fromJson(
        metadata['attachments'],
        idFactory: idFactory,
      ),
      recordings: NoteJson.map(metadata, 'recordings'),
      recordingPageIds: {
        for (final entry in NoteJson.map(metadata, 'recordingPages').entries)
          if (entry.value case final String pageId) entry.key: pageId,
      },
      documentObjects: registry.decodeAll(
        NoteJson.list(metadata, 'documentObjects'),
      ),
      idFactory: idFactory,
      clock: clock,
      createdAt: DateTime.tryParse(NoteJson.string(metadata, 'createdAt')),
      modifiedAt: DateTime.tryParse(NoteJson.string(metadata, 'modifiedAt')),
    );

    return NoteDocumentLoadResult(document, damaged);
  }

  Future<void> delete(String noteId) => store.deletePrefix(notePrefix(noteId));

  /// Copies a stored note under [newNoteId] with new page, layer, ink and object
  /// ids (what the library's duplicate calls for). Returns whether the source
  /// existed. Bookmarks, outline, excerpts, tags, recordings and `pageid:` links
  /// point at the copied pages; removed pages are not copied.
  Future<bool> duplicate(String noteId, String newNoteId) async {
    final loaded = await load(noteId);
    if (loaded == null) return false;
    final source = loaded.document;
    final pageIds = <String, String>{};
    final copies = <NotePage>[];
    for (final page in source.pages) {
      final copy = NotePageOps.duplicate(
        page,
        registry: registry,
        idFactory: idFactory,
        clock: clock,
      );
      pageIds[page.id] = copy.id;
      copies.add(copy);
    }
    final pages = [
      for (final page in copies)
        NotePageOps.remapLinks(page, pageIds, registry: registry),
    ];
    final metadata = _remapMetadata(source.metadataToJson(), pageIds, {
      noteId: newNoteId,
    });
    final copy = NoteDocument(
      id: newNoteId,
      registry: registry,
      title: source.title,
      pages: pages,
      numbering: NotePageNumbering.fromJson(metadata['numbering']),
      bookmarks: NoteBookmarks.fromJson(metadata['bookmarks']),
      outline: NoteOutline.fromJson(metadata['outline']),
      excerpts: NoteExcerpts.fromJson(metadata['excerpts']),
      tags: NoteTags.fromJson(metadata['tags']),
      attachments: NoteAttachmentList.fromJson(metadata['attachments']),
      recordings: NoteJson.map(metadata, 'recordings'),
      recordingPageIds: {
        for (final entry in source.recordingPageIds.entries)
          if (pageIds[entry.value] case final String pageId) entry.key: pageId,
      },
      documentObjects: [
        for (final object in source.documentObjects)
          NotePageLinkRemap.object(object, pageIds, registry: registry),
      ],
      idFactory: idFactory,
      clock: clock,
    );
    await save(copy, everything: true);
    copy.dispose();
    source.dispose();

    return true;
  }

  Future<void> _savePage(String pagePrefix, NotePage page) async {
    for (final content in page.layers) {
      await store.writeBytes(
        '$pagePrefix${_layerFile(content.layer.id)}',
        content.scribble.writeToBuffer(),
      );
    }
    await store.writeString(
      '${pagePrefix}page.json',
      NoteJson.encode(page.toJson()),
    );
  }

  Future<NotePage?> _loadPage(
    String prefix,
    String pageId,
    List<String> damaged,
  ) async {
    if (pageId.isEmpty) return null;
    final pagePrefix = '$prefix${_pageDir(pageId)}';
    final json = await _readJson('${pagePrefix}page.json', damaged);
    if (json == null) return null;
    final ink = <String, Scribble>{};
    for (final layer in NoteJson.mapList(json, 'layers')) {
      final layerId = NoteJson.string(layer, 'id');
      if (layerId.isEmpty) continue;
      final key = '$pagePrefix${_layerFile(layerId)}';
      final bytes = await store.readBytes(key);
      if (bytes == null) {
        damaged.add(key);
        continue;
      }
      try {
        ink[layerId] = Scribble.fromBuffer(bytes);
      } on InvalidProtocolBufferException {
        damaged.add(key);
        await _keepCorrupt(key, bytes);
      }
    }

    return NotePage.fromJson(json, registry: registry, ink: ink, clock: clock);
  }

  Future<JsonMap?> _readJson(String key, List<String> damaged) async {
    final bytes = await store.readBytes(key);
    if (bytes == null) {
      damaged.add(key);

      return null;
    }
    final json = NoteJson.decodeMap(NoteStoreKeys.decode(bytes));
    if (json == null) {
      damaged.add(key);
      await _keepCorrupt(key, bytes);
    }

    return json;
  }

  Future<void> _keepCorrupt(String key, Uint8List bytes) async {
    final backup = '$key.corrupt';
    if (!await store.exists(backup)) await store.writeBytes(backup, bytes);
  }

  Future<void> _deleteOrphans(String prefix, List<NotePage> kept) async {
    final wanted = <String>{};
    for (final page in kept) {
      final pagePrefix = '$prefix${_pageDir(page.id)}';
      wanted.add('${pagePrefix}page.json');
      for (final content in page.layers) {
        wanted.add('$pagePrefix${_layerFile(content.layer.id)}');
      }
    }
    for (final key in await store.list('${prefix}pages/')) {
      if (!wanted.contains(key) && !key.endsWith('.corrupt')) {
        await store.delete(key);
      }
    }
  }

  /// Rewrites every `pageId` and `startsAtPageId` with [pageIds] and every
  /// `noteId` with [noteIds].
  JsonMap _remapMetadata(
    JsonMap value,
    Map<String, String> pageIds,
    Map<String, String> noteIds,
  ) {
    Object? walk(Object? node) {
      if (node is List) return [for (final item in node) walk(item)];
      if (node is! Map) return node;

      return {
        for (final entry in node.entries)
          '${entry.key}': switch (entry.key) {
            'pageId' || 'startsAtPageId' => pageIds[entry.value] ?? entry.value,
            'noteId' => noteIds[entry.value] ?? entry.value,
            _ => walk(entry.value),
          },
      };
    }

    return NoteJson.asMap(walk(value))!;
  }

  static String _pageDir(String pageId) => 'pages/${_segment(pageId)}/';

  static String _layerFile(String layerId) => 'layer-${_segment(layerId)}.pb';

  /// A store path segment for an id (`.` and `..` cannot escape the root).
  static String _segment(String id) {
    final encoded = Uri.encodeComponent(id);

    return encoded == '.' || encoded == '..'
        ? encoded.replaceAll('.', '%2E')
        : encoded;
  }
}
