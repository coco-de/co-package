import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/library/note_cover_view.dart';
import 'package:open_note/src/note/library/note_library_strings.dart';
import 'package:open_note/src/note/library/note_library_style.dart';
import 'package:open_note/src/note/library/note_library_view_state.dart';
import 'package:open_note/src/note/library/note_summary.dart';
import 'package:open_note/src/note/library/note_thumbnail_provider.dart';

part 'note_tile_marks.dart';

/// One note in the library.
///
/// In [NoteLibraryLayout.drawer] it is a cover above the title and date, filling
/// the height it is given (it needs a bounded height). In
/// [NoteLibraryLayout.list] it is a row with a small cover, the title and a
/// line of details. In [selectionMode] it carries a check mark.
class NoteTile extends StatelessWidget {
  /// Creates a tile for [note].
  const NoteTile({
    required this.note,
    super.key,
    this.layout = NoteLibraryLayout.drawer,
    this.selectionMode = false,
    this.selected = false,
    this.date,
    this.onTap,
    this.onLongPress,
    this.thumbnailProvider,
    this.imageProviderResolver = resolveImageSource,
    this.strings = const NoteLibraryStrings(),
    this.style = const NoteLibraryStyle(),
  });

  /// The note to show.
  final NoteSummary note;

  /// A cover in a grid or a row in a list.
  final NoteLibraryLayout layout;

  /// Whether to show a check mark.
  final bool selectionMode;

  /// Whether the check mark is ticked.
  final bool selected;

  /// The date shown; the note's modification time by default.
  final DateTime? date;

  /// Called on a tap.
  final VoidCallback? onTap;

  /// Called on a long press.
  final VoidCallback? onLongPress;

  /// Draws previews instead of covers where it returns one.
  final NoteThumbnailProvider? thumbnailProvider;

  /// Resolves the pictures of image covers.
  final NoteCoverImageResolver imageProviderResolver;

  /// The texts.
  final NoteLibraryStrings strings;

  /// The colours and sizes.
  final NoteLibraryStyle style;

  /// The key of the check mark of the note [noteId].
  static Key checkMarkKey(String noteId) => ValueKey('noteCheck:$noteId');

  /// The key of the pin badge of the note [noteId].
  static Key pinKey(String noteId) => ValueKey('notePin:$noteId');

  String get _title => note.title.isEmpty ? strings.untitled : note.title;

  String get _date => strings.formatDate(date ?? note.modifiedAt);

  @override
  Widget build(BuildContext context) {
    final label = [
      _title,
      strings.pageCount(note.pageCount),
      if (note.pinned) strings.pinned,
    ].join(', ');

    return Semantics(
      container: true,
      button: true,
      selected: selectionMode ? selected : null,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        onLongPress: onLongPress,
        child: layout == NoteLibraryLayout.drawer
            ? _NoteDrawerTile(this)
            : _NoteListRow(this),
      ),
    );
  }
}

/// The cover of a tile, or the host's preview, in the cover's proportions.
class _NoteArtwork extends StatelessWidget {
  const _NoteArtwork(this.tile);

  final NoteTile tile;

  @override
  Widget build(BuildContext context) {
    final preview = tile.thumbnailProvider?.thumbnailFor(context, tile.note);
    final radius = tile.style.coverCornerRadius;

    return AspectRatio(
      aspectRatio: tile.note.cover.aspectRatio,
      child: preview == null
          ? NoteCoverView(
              cover: tile.note.cover,
              imageProviderResolver: tile.imageProviderResolver,
              cornerRadius: radius,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: preview,
            ),
    );
  }
}

class _NoteDrawerTile extends StatelessWidget {
  const _NoteDrawerTile(this.tile);

  final NoteTile tile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _NoteDrawerCover(tile),
        ),
      ),
      const SizedBox(height: NoteLibraryStyle.captionGap),
      Text(
        tile._title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: tile.style.titleStyle,
      ),
      Text(
        tile._date,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: tile.style.captionStyle,
      ),
    ],
  );
}

class _NoteDrawerCover extends StatelessWidget {
  const _NoteDrawerCover(this.tile);

  final NoteTile tile;

  @override
  Widget build(BuildContext context) {
    final id = tile.note.id;

    return Stack(
      children: [
        _NoteArtwork(tile),
        if (tile.selected)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  tile.style.coverCornerRadius,
                ),
                border: Border.all(color: tile.style.accentColor, width: 2.5),
              ),
            ),
          ),
        if (tile.note.pinned)
          Positioned(
            top: 4,
            right: 4,
            child: _NotePinMark(
              key: NoteTile.pinKey(id),
              color: tile.style.accentColor,
            ),
          ),
        if (tile.selectionMode)
          Positioned(
            top: 4,
            left: 4,
            child: _NoteCheckMark(
              key: NoteTile.checkMarkKey(id),
              checked: tile.selected,
              color: tile.style.accentColor,
            ),
          ),
      ],
    );
  }
}

class _NoteListRow extends StatelessWidget {
  const _NoteListRow(this.tile);

  final NoteTile tile;

  @override
  Widget build(BuildContext context) {
    final style = tile.style;
    final id = tile.note.id;

    return ColoredBox(
      color: tile.selected ? style.selectionColor : const Color(0x00000000),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: style.listRowHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: style.spacing, vertical: 6),
          child: Row(
            children: [
              if (tile.selectionMode)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: _NoteCheckMark(
                    key: NoteTile.checkMarkKey(id),
                    checked: tile.selected,
                    color: style.accentColor,
                  ),
                ),
              SizedBox(
                width: 40,
                height: 52,
                child: Center(child: _NoteArtwork(tile)),
              ),
              const SizedBox(width: 12),
              Expanded(child: _NoteListCaption(tile)),
              if (tile.note.pinned)
                _NotePinMark(
                  key: NoteTile.pinKey(id),
                  color: style.accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteListCaption extends StatelessWidget {
  const _NoteListCaption(this.tile);

  final NoteTile tile;

  @override
  Widget build(BuildContext context) {
    final note = tile.note;
    final details = [
      tile._date,
      tile.strings.pageCount(note.pageCount),
      if (note.tags.isNotEmpty) note.tags.map((tag) => '#$tag').join(' '),
    ].join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tile._title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tile.style.titleStyle,
        ),
        Text(
          details,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tile.style.captionStyle,
        ),
      ],
    );
  }
}
