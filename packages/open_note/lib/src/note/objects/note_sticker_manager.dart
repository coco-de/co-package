import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:open_note/src/module/image/image_source_resolver.dart';
import 'package:open_note/src/note/core/note_text_field.dart';
import 'package:open_note/src/note/objects/note_sticker_collection.dart';
import 'package:open_note/src/note/objects/note_sticker_item.dart';
import 'package:open_note/src/note/objects/note_sticker_manager_style.dart';
import 'package:open_note/src/note/objects/note_sticker_store.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';

/// The stickers of a [NoteStickerStore]: tap one to use it, or edit the
/// collections (make, rename and delete them, add pictures, reorder and remove
/// stickers). Saving the store stays with the app.
class NoteStickerManager extends StatefulWidget {
  const NoteStickerManager({
    required this.store,
    this.onSelected,
    this.onPickPictures,
    this.imageProviderResolver = resolveImageSource,
    this.strings = const NoteObjectsStrings(),
    this.style = const NoteStickerManagerStyle(),
    super.key,
  });

  final NoteStickerStore store;

  /// A tapped sticker, outside editing.
  final ValueChanged<NoteStickerItem>? onSelected;

  /// Lets the user choose pictures and returns their image sources; without it
  /// the manager offers no "add pictures".
  final Future<List<String>> Function()? onPickPictures;

  final ImageProvider Function(String source) imageProviderResolver;
  final NoteObjectsStrings strings;
  final NoteStickerManagerStyle style;

  @override
  State<NoteStickerManager> createState() => _NoteStickerManagerState();
}

class _NoteStickerManagerState extends State<NoteStickerManager> {
  /// The shown collection; null shows all of them.
  String? _collectionId;

  /// The sticker the editing buttons act on.
  String? _itemId;
  bool _isEditing = false;
  bool _isConfirmingDelete = false;
  bool _isPicking = false;

  /// Rebuilds the name field, to drop a name the store refused.
  int _nameRevision = 0;

  NoteStickerStore get _store => widget.store;

  NoteObjectsStrings get _strings => widget.strings;

  NoteStickerManagerStyle get _style => widget.style;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final collections = _store.collections;
      var current = _collectionId == null ? null : _store.find(_collectionId!);
      // Editing always works on one collection.
      if (_isEditing) current ??= collections.firstOrNull;
      final items = [
        for (final collection in current == null ? collections : [current])
          for (final item in collection.items) (collection, item),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filters(collections, current),
          if (_isEditing && current != null) ..._editingRows(current),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(
              _strings.noStickers,
              style: _style.textStyle.copyWith(color: _style.mutedColor),
            )
          else
            _wrap([
              for (final (collection, item) in items) _tile(collection, item),
            ]),
        ],
      );
    },
  );

  Widget _wrap(List<Widget> children) => Wrap(
    spacing: _style.spacing,
    runSpacing: _style.spacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );

  Widget _filters(
    List<NoteStickerCollection> collections,
    NoteStickerCollection? current,
  ) => _wrap([
    if (!_isEditing)
      _button(
        'all',
        _strings.allStickers,
        selected: current == null,
        onPressed: () => _show(null),
      ),
    for (final collection in collections)
      _button(
        'collection-${collection.id}',
        collection.name,
        selected: current?.id == collection.id,
        onPressed: () => _show(collection.id),
      ),
    if (_isEditing)
      _button(
        'new-collection',
        _strings.newCollection,
        onPressed: () => _show(_store.createCollection('').id),
      ),
    _button(
      'manage',
      _isEditing ? _strings.doneManagingStickers : _strings.manageStickers,
      selected: _isEditing,
      onPressed: () => setState(() {
        _isEditing = !_isEditing;
        _itemId = null;
        _isConfirmingDelete = false;
      }),
    ),
  ]);

  List<Widget> _editingRows(NoteStickerCollection collection) {
    final index = collection.items.indexWhere((item) => item.id == _itemId);
    final pick = widget.onPickPictures;

    return [
      const SizedBox(height: 6),
      _wrap([
        SizedBox(
          width: _style.nameFieldWidth,
          child: NoteTextField(
            key: ValueKey('note-sticker-name-${collection.id}-$_nameRevision'),
            initialText: collection.name,
            hintText: _strings.collectionName,
            submitOnBlur: true,
            style: _style.textStyle,
            onSubmitted: (name) => _rename(collection, name),
          ),
        ),
        _button(
          'delete-collection',
          _isConfirmingDelete
              ? _strings.confirmDeleteCollection
              : _strings.deleteCollection,
          color: _style.dangerColor,
          onPressed: () => _delete(collection),
        ),
        if (pick != null)
          _button(
            'add-pictures',
            _strings.addStickerPictures,
            onPressed: _isPicking
                ? null
                : () => unawaited(_addPictures(collection.id, pick)),
          ),
        if (index >= 0) ...[
          _button(
            'move-earlier',
            _strings.moveStickerEarlier,
            onPressed: index > 0
                ? () => _store.moveItem(collection.id, index, index - 1)
                : null,
          ),
          _button(
            'move-later',
            _strings.moveStickerLater,
            onPressed: index < collection.items.length - 1
                ? () => _store.moveItem(collection.id, index, index + 1)
                : null,
          ),
          _button(
            'remove',
            _strings.removeSticker,
            color: _style.dangerColor,
            onPressed: () {
              _store.removeItem(collection.id, collection.items[index].id);
              setState(() => _itemId = null);
            },
          ),
        ],
      ]),
    ];
  }

  Widget _tile(NoteStickerCollection collection, NoteStickerItem item) {
    final selected = _isEditing && item.id == _itemId;

    return Semantics(
      button: true,
      selected: selected,
      label: item.name ?? collection.name,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('note-sticker-${item.id}'),
        onTap: () {
          if (!_isEditing) {
            widget.onSelected?.call(item);

            return;
          }
          setState(() {
            _itemId = selected ? null : item.id;
            _isConfirmingDelete = false;
          });
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: selected
                ? Border.all(color: _style.accentColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(_style.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image(
              image: widget.imageProviderResolver(item.source),
              width: _style.stickerExtent,
              height: _style.stickerExtent,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => SizedBox.square(
                dimension: _style.stickerExtent,
                child: Center(
                  child: Text(item.name ?? '?', style: _style.textStyle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(
    String key,
    String label, {
    VoidCallback? onPressed,
    bool selected = false,
    Color? color,
  }) => Semantics(
    button: true,
    enabled: onPressed != null,
    selected: selected,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: onPressed == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('note-sticker-$key'),
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? _style.selectedColor : null,
            borderRadius: BorderRadius.circular(_style.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              label,
              style: _style.textStyle.copyWith(
                color: onPressed == null
                    ? _style.mutedColor
                    : selected
                    ? _style.accentColor
                    : color,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _show(String? collectionId) => setState(() {
    _collectionId = collectionId;
    _itemId = null;
    _isConfirmingDelete = false;
  });

  void _rename(NoteStickerCollection collection, String name) {
    if (name.trim() == collection.name) return;
    if (!_store.rename(collection.id, name)) setState(() => _nameRevision++);
  }

  /// Deletes after a second tap, so one slip does not lose a collection.
  void _delete(NoteStickerCollection collection) {
    if (!_isConfirmingDelete) {
      setState(() {
        _collectionId = collection.id;
        _isConfirmingDelete = true;
      });

      return;
    }
    _store.delete(collection.id);
    _show(null);
  }

  Future<void> _addPictures(
    String collectionId,
    Future<List<String>> Function() pick,
  ) async {
    setState(() {
      _isPicking = true;
      _isConfirmingDelete = false;
    });
    try {
      final sources = await pick();
      if (mounted) _store.importAll(collectionId, sources);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'open_note',
          context: ErrorDescription('while adding sticker pictures'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }
}
