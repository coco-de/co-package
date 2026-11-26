import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:open_note/open_note.dart';

import '../i18n/strings.g.dart';
import '../light_surface.dart';
import 'note_demo_strings_ko.dart';
import 'note_demo_workspace.dart';
import 'note_editor_demo_page.dart';

/// 노트 라이브러리 데모 — 폴더 · 정렬 · 고정 · 여러 권 선택, 글 검색, 그리고
/// 노트를 열면 [NoteEditorDemoPage].
class NoteDemoPage extends StatefulWidget {
  const NoteDemoPage({super.key});

  @override
  State<NoteDemoPage> createState() => _NoteDemoPageState();
}

class _NoteDemoPageState extends State<NoteDemoPage> {
  final NoteDemoWorkspace _workspace = NoteDemoWorkspace.instance;
  late final Future<NoteLibrary> _library = _workspace.library();

  bool get _korean => context.t.$meta.locale == AppLocale.ko;

  @override
  Widget build(BuildContext context) => FutureBuilder<NoteLibrary>(
    future: _library,
    builder: (context, snapshot) {
      final library = snapshot.data;
      if (library == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return ListenableBuilder(
        listenable: library,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(context.t.home.note.title),
            actions: library.selectionMode
                ? _selectionActions(library)
                : _actions(library),
          ),
          body: LightSurface(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final strings = _korean
                    ? noteLibraryStringsKo
                    : const NoteLibraryStrings();
                final view = NoteLibraryView(
                  library: library,
                  strings: strings,
                  imageProviderResolver: _workspace.imageProvider,
                  onOpenNote: (note) => unawaited(_open(library, note)),
                );
                if (constraints.maxWidth < 720) return view;

                return Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: NoteFolderSidebar(
                        library: library,
                        strings: strings,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: view),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _actions(NoteLibrary library) => [
    _layoutButton(library),
    _sortMenu(library),
    IconButton(
      key: const ValueKey('note-demo-search'),
      tooltip: _korean ? '글 검색' : 'Search text',
      icon: const Icon(Icons.search),
      onPressed: () => unawaited(_search(library)),
    ),
    IconButton(
      key: const ValueKey('note-demo-new-folder'),
      tooltip: _korean ? '새 폴더' : 'New folder',
      icon: const Icon(Icons.create_new_folder_outlined),
      onPressed: () => library.createFolder(
        _korean ? '새 폴더' : 'New folder',
        parentId: library.viewState.folderId,
      ),
    ),
    IconButton(
      key: const ValueKey('note-demo-new-note'),
      tooltip: _korean ? '새 노트' : 'New note',
      icon: const Icon(Icons.note_add_outlined),
      onPressed: () {
        final note = library.createNote(
          title: _korean ? '새 노트' : 'New note',
          folderId: library.viewState.folderId,
        );
        unawaited(_open(library, note));
      },
    ),
  ];

  Widget _layoutButton(NoteLibrary library) {
    final drawer = library.viewState.layout == NoteLibraryLayout.drawer;

    return IconButton(
      tooltip: drawer
          ? (_korean ? '목록으로 보기' : 'List view')
          : (_korean ? '서랍으로 보기' : 'Drawer view'),
      icon: Icon(drawer ? Icons.view_list : Icons.grid_view),
      onPressed: () => library.viewState = library.viewState.copyWith(
        layout: drawer ? NoteLibraryLayout.list : NoteLibraryLayout.drawer,
      ),
    );
  }

  Widget _sortMenu(NoteLibrary library) {
    final state = library.viewState;
    final ascending = state.sortOrder == NoteSortOrder.ascending;

    return PopupMenuButton<Object>(
      tooltip: _korean ? '정렬' : 'Sort',
      icon: const Icon(Icons.sort),
      onSelected: (value) => library.viewState = switch (value) {
        final NoteSortField field => state.copyWith(sortField: field),
        _ => state.copyWith(
          sortOrder: ascending
              ? NoteSortOrder.descending
              : NoteSortOrder.ascending,
        ),
      },
      itemBuilder: (context) => [
        for (final (field, label) in [
          (NoteSortField.name, _korean ? '이름' : 'Name'),
          (NoteSortField.modified, _korean ? '수정한 날' : 'Last changed'),
          (NoteSortField.created, _korean ? '만든 날' : 'Created'),
        ])
          CheckedPopupMenuItem<Object>(
            value: field,
            checked: state.sortField == field,
            child: Text(label),
          ),
        PopupMenuItem<Object>(
          value: 'order',
          child: Text(
            ascending
                ? (_korean ? '거꾸로 정렬' : 'Reverse')
                : (_korean ? '바로 정렬' : 'Forward'),
          ),
        ),
      ],
    );
  }

  /// 고른 노트의 표지를 다음 기본 표지로 바꾼다.
  void _nextCover(NoteLibrary library, Iterable<String> ids) {
    for (final id in ids) {
      final cover = library.noteById(id)?.cover;
      if (cover == null) continue;
      final current = NoteCoverCatalog.builtIn.indexOf(cover.builtinId ?? '');
      library.setCover(
        id,
        NoteCover(
          kind: NoteCoverKind.builtin,
          builtinId: NoteCoverCatalog
              .builtIn[(current + 1) % NoteCoverCatalog.builtIn.length],
          size: cover.size,
          orientation: cover.orientation,
        ),
      );
    }
  }

  Future<void> _tag(NoteLibrary library, Set<String> ids) async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_korean ? '태그 달기' : 'Add a tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    controller.dispose();
    if (tag == null) return;
    for (final id in ids) {
      library.addTag(id, tag);
    }
    library.selectionMode = false;
  }

  List<Widget> _selectionActions(NoteLibrary library) {
    final selected = library.selection;

    return [
      IconButton(
        tooltip: _korean ? '고정' : 'Pin',
        icon: const Icon(Icons.push_pin_outlined),
        onPressed: () => library
          ..pin(selected)
          ..selectionMode = false,
      ),
      IconButton(
        tooltip: _korean ? '표지 바꾸기' : 'Change cover',
        icon: const Icon(Icons.photo_album_outlined),
        onPressed: () => _nextCover(library, selected),
      ),
      IconButton(
        tooltip: _korean ? '태그' : 'Tag',
        icon: const Icon(Icons.sell_outlined),
        onPressed: () => unawaited(_tag(library, selected)),
      ),
      IconButton(
        tooltip: _korean ? '복제' : 'Duplicate',
        icon: const Icon(Icons.copy_outlined),
        onPressed: () => library
          ..duplicateNotes(selected)
          ..selectionMode = false,
      ),
      IconButton(
        tooltip: _korean ? '휴지통으로' : 'Move to trash',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => library
          ..deleteNotes(selected)
          ..selectionMode = false,
      ),
      IconButton(
        tooltip: _korean ? '선택 끝내기' : 'Done',
        icon: const Icon(Icons.close),
        onPressed: () => library.selectionMode = false,
      ),
    ];
  }

  Future<void> _open(
    NoteLibrary library,
    NoteSummary note, {
    String? pageId,
  }) async {
    final document = await _workspace.open(note);
    if (!mounted) {
      document.dispose();

      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NoteEditorDemoPage(
          library: library,
          document: document,
          initialPageId: pageId,
        ),
      ),
    );
  }

  Future<void> _search(NoteLibrary library) async {
    final hit = await showModalBottomSheet<NoteSearchHit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: LightSurface(
            child: NoteSearchPanel(
              index: _workspace.searchIndex,
              strings: _korean
                  ? noteEditorStringsKo.nav
                  : const NoteNavStrings(),
              autofocus: true,
              describeHit: (hit) => library.noteById(hit.noteId)?.title ?? '',
              onHitSelected: (hit) => Navigator.of(context).pop(hit),
            ),
          ),
        ),
      ),
    );
    if (hit == null || !mounted) return;
    final note = library.noteById(hit.noteId);
    if (note != null) await _open(library, note, pageId: hit.pageId);
  }
}
