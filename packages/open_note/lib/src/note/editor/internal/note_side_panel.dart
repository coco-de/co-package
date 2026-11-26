import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_strings.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/editor/note_export.dart';
import 'package:open_note/src/note/editor/note_page_thumbnail.dart';
import 'package:open_note/src/note/layer/note_layer_panel.dart';
import 'package:open_note/src/note/nav/note_bookmark_panel.dart';
import 'package:open_note/src/note/nav/note_excerpt_panel.dart';
import 'package:open_note/src/note/nav/note_outline_panel.dart';
import 'package:open_note/src/note/view/note_thumbnail_grid.dart';
import 'package:open_note/src/note/view/note_thumbnail_grid_controller.dart';

/// What the side panel shows.
enum NoteSidePanelTab { layers, pages, bookmarks, outline, excerpts }

/// Layers, the page grid, bookmarks, the outline or excerpts.
class NoteSidePanel extends StatefulWidget {
  const NoteSidePanel({
    required this.controller,
    required this.strings,
    required this.style,
    required this.tab,
    required this.thumbnails,
    required this.imageProviderResolver,
    required this.onTab,
    required this.onClose,
    super.key,
  });

  final NoteEditorController controller;
  final NoteEditorStrings strings;
  final NoteEditorStyle style;
  final NoteSidePanelTab tab;
  final NoteThumbnailGridController thumbnails;
  final NoteImageProviderResolver imageProviderResolver;
  final ValueChanged<NoteSidePanelTab> onTab;
  final VoidCallback onClose;

  @override
  State<NoteSidePanel> createState() => _NoteSidePanelState();
}

class _NoteSidePanelState extends State<NoteSidePanel> {
  bool _inkOnly = false;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final style = widget.style;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.panelColor,
        border: Border(left: BorderSide(color: style.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoteEditorStrip(
            style: style,
            children: [
              for (final (tab, label) in [
                (NoteSidePanelTab.layers, strings.layersPanel),
                (NoteSidePanelTab.pages, strings.pagesPanel),
                (NoteSidePanelTab.bookmarks, strings.bookmarksPanel),
                (NoteSidePanelTab.outline, strings.outlinePanel),
                (NoteSidePanelTab.excerpts, strings.excerptsPanel),
              ])
                _button(
                  'tab-${tab.name}',
                  label,
                  () => widget.onTab(tab),
                  selected: widget.tab == tab,
                ),
              _button('close', strings.close, widget.onClose),
            ],
          ),
          Expanded(
            child: switch (widget.tab) {
              NoteSidePanelTab.layers => NoteLayerPanel(
                layers: widget.controller.layers,
                strings: strings.layers,
                accentColor: style.accentColor,
              ),
              NoteSidePanelTab.pages => _pages(),
              NoteSidePanelTab.bookmarks => _bookmarks(),
              NoteSidePanelTab.outline => _outline(),
              NoteSidePanelTab.excerpts => NoteExcerptPanel(
                excerpts: widget.controller.document.excerpts,
                pageOrder: widget.controller.document.pageIds,
                strings: strings.nav,
                onExcerptSelected: widget.controller.showExcerpt,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _pages() {
    final controller = widget.controller;
    final document = controller.document;
    final indexes = [
      for (var i = 0; i < document.pageCount; i++)
        if (!_inkOnly ||
            (i == controller.pageIndex
                ? controller.page.hasInk
                : document.pageAt(i).hasInk))
          i,
    ];
    final current = indexes.indexOf(controller.pageIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _button(
          'ink-only',
          widget.strings.onlyPagesWithInk,
          () => setState(() => _inkOnly = !_inkOnly),
          selected: _inkOnly,
        ),
        Expanded(
          child: NoteThumbnailGrid(
            controller: widget.thumbnails,
            pageCount: indexes.length,
            currentPage: current < 0 ? null : current,
            showPageNumbers: !_inkOnly,
            pageAspectRatio: controller.page.size.aspectRatio,
            onPageTap: (position) =>
                controller.goToPage(document.pageIds[indexes[position]]),
            itemBuilder: (context, position) {
              final index = indexes[position];

              return NotePageThumbnail(
                page: index == controller.pageIndex
                    ? controller.page
                    : document.pageAt(index),
                sharedObjects: document.documentObjects,
                imageProviderResolver: widget.imageProviderResolver,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookmarks() {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _button(
          'toggle-bookmark',
          controller.isBookmarked
              ? widget.strings.removeBookmark
              : widget.strings.bookmark,
          controller.toggleBookmark,
          selected: controller.isBookmarked,
        ),
        Expanded(
          child: NoteBookmarkPanel(
            bookmarks: controller.document.bookmarks,
            pageOrder: controller.document.pageIds,
            currentPageId: controller.pageId,
            strings: widget.strings.nav,
            onBookmarkSelected: (bookmark) =>
                controller.goToPage(bookmark.pageId),
          ),
        ),
      ],
    );
  }

  Widget _outline() {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _button(
          'add-to-outline',
          widget.strings.addToOutline,
          () => controller.document.outline.add(
            widget.strings.outlineTitle(controller.pageLabel),
            controller.pageId,
          ),
        ),
        Expanded(
          child: NoteOutlinePanel(
            outline: controller.document.outline,
            currentPageId: controller.pageId,
            pageLabelOf: controller.document.labelOf,
            strings: widget.strings.nav,
            onEntrySelected: (entry) => controller.goToPage(entry.pageId),
          ),
        ),
      ],
    );
  }

  Widget _button(
    String key,
    String label,
    VoidCallback onPressed, {
    bool selected = false,
  }) => NoteEditorButton(
    key: ValueKey('note-panel-$key'),
    label: label,
    style: widget.style,
    onPressed: onPressed,
    selected: selected,
  );
}
