import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;
import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/library/note_cover_view.dart';
import 'package:open_note/src/note/library/note_library.dart';
import 'package:open_note/src/note/library/note_library_strings.dart';
import 'package:open_note/src/note/library/note_library_style.dart';
import 'package:open_note/src/note/library/note_library_view_state.dart';
import 'package:open_note/src/note/library/note_summary.dart';
import 'package:open_note/src/note/library/note_thumbnail_provider.dart';
import 'package:open_note/src/note/library/note_tile.dart';

part 'note_library_pinch.dart';

/// The notes of a [NoteLibrary] as it is currently viewed: a drawer (a grid of
/// covers) or a list, with the pinned notes in their own section first.
///
/// A tap opens a note ([onOpenNote]), or toggles it while the library is in
/// selection mode. A long press calls [onLongPressNote]; without one it starts
/// selection mode with the note selected. In the drawer a two-finger pinch
/// changes the library's drawer zoom; one finger still scrolls.
///
/// The view needs bounded constraints (for example inside an `Expanded`).
class NoteLibraryView extends StatelessWidget {
  /// Creates a view of [library].
  const NoteLibraryView({
    required this.library,
    super.key,
    this.onOpenNote,
    this.onLongPressNote,
    this.thumbnailProvider,
    this.imageProviderResolver = resolveImageSource,
    this.scrollController,
    this.strings = const NoteLibraryStrings(),
    this.style = const NoteLibraryStyle(),
  });

  /// What is shown; the view rebuilds when it changes.
  final NoteLibrary library;

  /// Called when a note is tapped outside selection mode.
  final ValueChanged<NoteSummary>? onOpenNote;

  /// Called on a long press instead of starting selection mode.
  final ValueChanged<NoteSummary>? onLongPressNote;

  /// Draws page previews instead of covers where it returns one.
  final NoteThumbnailProvider? thumbnailProvider;

  /// Resolves the pictures of image covers.
  final NoteCoverImageResolver imageProviderResolver;

  /// Controls the scrolling.
  final ScrollController? scrollController;

  /// The texts.
  final NoteLibraryStrings strings;

  /// The colours and sizes.
  final NoteLibraryStyle style;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: library,
    builder: (context, _) => ColoredBox(
      color: style.backgroundColor,
      child: _NoteLibraryContent(this),
    ),
  );

  void _tap(NoteSummary note) {
    if (library.selectionMode) {
      library.toggleSelect(note.id);

      return;
    }
    onOpenNote?.call(note);
  }

  void _longPress(NoteSummary note) {
    final handler = onLongPressNote;
    if (handler != null) {
      handler(note);

      return;
    }
    library.toggleSelect(note.id);
  }
}

class _NoteLibraryContent extends StatelessWidget {
  const _NoteLibraryContent(this.view);

  final NoteLibraryView view;

  @override
  Widget build(BuildContext context) {
    final notes = view.library.visibleNotes();
    if (notes.isEmpty) {
      return Center(
        child: Text(
          view.library.notes.isEmpty
              ? view.strings.emptyLibrary
              : view.strings.noMatches,
          textAlign: TextAlign.center,
          style: view.style.captionStyle.copyWith(fontSize: 14),
        ),
      );
    }
    final pinned = [
      for (final note in notes)
        if (note.pinned) note,
    ];
    final others = [
      for (final note in notes)
        if (!note.pinned) note,
    ];

    return _NoteDrawerPinch(
      enabled: view.library.viewState.layout == NoteLibraryLayout.drawer,
      onZoom: view.library.zoomDrawer,
      child: CustomScrollView(
        controller: view.scrollController,
        slivers: [
          SliverPadding(padding: EdgeInsets.only(top: view.style.spacing / 2)),
          if (pinned.isNotEmpty) ...[
            _NoteSectionHeader(view, view.strings.pinnedSection),
            _NoteSection(view, pinned),
          ],
          if (pinned.isNotEmpty && others.isNotEmpty)
            _NoteSectionHeader(view, view.strings.notesSection),
          if (others.isNotEmpty) _NoteSection(view, others),
          SliverPadding(
            padding: EdgeInsets.only(bottom: view.style.spacing / 2),
          ),
        ],
      ),
    );
  }
}

class _NoteSectionHeader extends StatelessWidget {
  const _NoteSectionHeader(this.view, this.title);

  final NoteLibraryView view;
  final String title;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: view.style.spacing,
          vertical: view.style.spacing / 2,
        ),
        child: Text(
          title,
          style: view.style.captionStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

/// One section of notes, as a grid or as rows.
class _NoteSection extends StatelessWidget {
  const _NoteSection(this.view, this.notes);

  final NoteLibraryView view;
  final List<NoteSummary> notes;

  @override
  Widget build(BuildContext context) =>
      view.library.viewState.layout == NoteLibraryLayout.drawer
      ? SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: view.style.spacing,
            vertical: view.style.spacing / 2,
          ),
          sliver: SliverLayoutBuilder(builder: _buildGrid),
        )
      : SliverList.separated(
          itemCount: notes.length,
          itemBuilder: (context, index) => _NoteEntry(view, notes[index]),
          separatorBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(left: view.style.spacing),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: view.style.dividerColor),
            ),
          ),
        );

  Widget _buildGrid(BuildContext context, SliverConstraints constraints) {
    final style = view.style;
    final width = constraints.crossAxisExtent;
    final target = style.drawerTileWidth * view.library.viewState.drawerZoom;
    final columns = math.max(
      1,
      ((width + style.spacing) / (target + style.spacing)).floor(),
    );
    final tileWidth = math.max(
      0,
      (width - (columns - 1) * style.spacing) / columns,
    );
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent:
            tileWidth / style.drawerCoverAspectRatio +
            style.drawerCaptionHeight(textScaler),
        crossAxisSpacing: style.spacing,
        mainAxisSpacing: style.spacing,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteEntry(view, notes[index]),
    );
  }
}

/// A [NoteTile] wired to the library.
class _NoteEntry extends StatelessWidget {
  _NoteEntry(this.view, this.note) : super(key: ValueKey(note.id));

  final NoteLibraryView view;
  final NoteSummary note;

  @override
  Widget build(BuildContext context) {
    final state = view.library.viewState;

    return NoteTile(
      note: note,
      layout: state.layout,
      selectionMode: view.library.selectionMode,
      selected: view.library.isSelected(note.id),
      date: state.sortField == NoteSortField.created
          ? note.createdAt
          : note.modifiedAt,
      onTap: () => view._tap(note),
      onLongPress: () => view._longPress(note),
      thumbnailProvider: view.thumbnailProvider,
      imageProviderResolver: view.imageProviderResolver,
      strings: view.strings,
      style: view.style,
    );
  }
}
