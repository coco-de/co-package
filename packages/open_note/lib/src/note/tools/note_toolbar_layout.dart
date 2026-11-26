import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_toolbar_dock_edge.dart';
import 'package:open_note/src/note/tools/note_toolbar_item.dart';
import 'package:open_note/src/note/tools/note_toolbar_item_ids.dart';
import 'package:open_note/src/note/tools/note_toolbar_placement.dart';

/// Which toolbar items are shown, in which order, and where the toolbar is.
///
/// Immutable: every change returns a new layout (or this one when nothing
/// changes). Item ids are unique and non-empty; extra ids beyond
/// `NoteToolbarItemIds` are allowed.
///
/// JSON: `{"items": [{"id": String, "visible": bool}, ...],
/// "placement": "docked" | "floating",
/// "dockEdge": "top" | "bottom" | "left" | "right",
/// "floatingOffset": {"x": number, "y": number}}`.
@immutable
class NoteToolbarLayout {
  /// Default [floatingOffset].
  static const Offset defaultFloatingOffset = Offset(16, 80);

  /// Every standard item, visible, in the default order.
  static const List<NoteToolbarItem> standardItems = [
    NoteToolbarItem(id: NoteToolbarItemIds.pen),
    NoteToolbarItem(id: NoteToolbarItemIds.pencil),
    NoteToolbarItem(id: NoteToolbarItemIds.marker),
    NoteToolbarItem(id: NoteToolbarItemIds.eraser),
    NoteToolbarItem(id: NoteToolbarItemIds.lasso),
    NoteToolbarItem(id: NoteToolbarItemIds.shape),
    NoteToolbarItem(id: NoteToolbarItemIds.text),
    NoteToolbarItem(id: NoteToolbarItemIds.image),
    NoteToolbarItem(id: NoteToolbarItemIds.undo),
    NoteToolbarItem(id: NoteToolbarItemIds.redo),
    NoteToolbarItem(id: NoteToolbarItemIds.layers),
    NoteToolbarItem(id: NoteToolbarItemIds.presets),
  ];

  /// Items in display order, hidden ones included. Unmodifiable.
  final List<NoteToolbarItem> items;

  /// Docked or floating.
  final NoteToolbarPlacement placement;

  /// The edge used while docked (kept while floating).
  final NoteToolbarDockEdge dockEdge;

  /// Top-left of a floating toolbar in logical pixels from the top-left of the
  /// editor area (kept while docked).
  final Offset floatingOffset;

  /// Creates a layout. [items] default to [standardItems]; entries with an
  /// empty or repeated id are dropped. A non-finite [floatingOffset] becomes
  /// [defaultFloatingOffset] and negative coordinates become 0.
  NoteToolbarLayout({
    List<NoteToolbarItem>? items,
    this.placement = NoteToolbarPlacement.docked,
    this.dockEdge = NoteToolbarDockEdge.top,
    Offset floatingOffset = defaultFloatingOffset,
  }) : items = _unique(items ?? standardItems),
       floatingOffset = _sanitizeOffset(floatingOffset);

  /// Reads the JSON form; never throws. When `items` is not a list the
  /// standard items are used; bad entries are skipped, so an empty list stays
  /// empty. Call [ensureItems] to add the items a newer version introduced.
  factory NoteToolbarLayout.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};
    final items = map['items'] is List
        ? [
            for (final entry in NoteJson.mapList(map, 'items'))
              NoteToolbarItem.fromJson(entry),
          ]
        : null;

    return NoteToolbarLayout(
      items: items,
      placement: NoteJson.enumByName(
        NoteToolbarPlacement.values,
        map['placement'],
        NoteToolbarPlacement.docked,
      ),
      dockEdge: NoteJson.enumByName(
        NoteToolbarDockEdge.values,
        map['dockEdge'],
        NoteToolbarDockEdge.top,
      ),
      floatingOffset: NoteJson.offset(
        map,
        'floatingOffset',
        defaultFloatingOffset,
      ),
    );
  }

  /// The shown items in display order.
  List<NoteToolbarItem> get visibleItems => [
    for (final item in items)
      if (item.visible) item,
  ];

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), placement, dockEdge, floatingOffset);

  /// The item with [id], or `null`.
  NoteToolbarItem? item(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }

    return null;
  }

  /// Whether the item [id] exists and is shown.
  bool isVisible(String id) => item(id)?.visible ?? false;

  /// Moves the item at [oldIndex] (counting hidden items) so that it ends up at
  /// [newIndex], clamped to the list. Not the `ReorderableListView`
  /// convention (there a downward move reports one more than the final
  /// position). An out of range [oldIndex] changes nothing.
  NoteToolbarLayout moveItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= items.length) return this;
    final target = newIndex.clamp(0, items.length - 1);
    if (target == oldIndex) return this;
    final next = [...items];
    next.insert(target, next.removeAt(oldIndex));

    return copyWith(items: next);
  }

  /// Shows or hides the item [id]; an unknown id changes nothing.
  NoteToolbarLayout setVisible(String id, bool visible) {
    final current = item(id);
    if (current == null || current.visible == visible) return this;

    return copyWith(
      items: [
        for (final item in items)
          item.id == id ? item.copyWith(visible: visible) : item,
      ],
    );
  }

  /// Appends, shown, every id of [ids] that has no item yet. Use it after
  /// loading a saved layout so items introduced later still appear.
  NoteToolbarLayout ensureItems([
    Iterable<String> ids = NoteToolbarItemIds.standard,
  ]) {
    final missing = [
      for (final id in ids.toSet())
        if (id.isNotEmpty && item(id) == null) NoteToolbarItem(id: id),
    ];

    return missing.isEmpty ? this : copyWith(items: [...items, ...missing]);
  }

  /// The factory layout: standard items, docked at the top. Custom items are
  /// dropped; add them again with [ensureItems].
  NoteToolbarLayout reset() => NoteToolbarLayout();

  /// A copy with the given values replaced.
  NoteToolbarLayout copyWith({
    List<NoteToolbarItem>? items,
    NoteToolbarPlacement? placement,
    NoteToolbarDockEdge? dockEdge,
    Offset? floatingOffset,
  }) => NoteToolbarLayout(
    items: items ?? this.items,
    placement: placement ?? this.placement,
    dockEdge: dockEdge ?? this.dockEdge,
    floatingOffset: floatingOffset ?? this.floatingOffset,
  );

  /// The JSON form described on the class.
  JsonMap toJson() => {
    'items': [for (final item in items) item.toJson()],
    'placement': placement.name,
    'dockEdge': dockEdge.name,
    'floatingOffset': NoteJson.offsetToJson(floatingOffset),
  };

  @override
  bool operator ==(Object other) =>
      other is NoteToolbarLayout &&
      listEquals(other.items, items) &&
      other.placement == placement &&
      other.dockEdge == dockEdge &&
      other.floatingOffset == floatingOffset;

  @override
  String toString() => 'NoteToolbarLayout(${toJson()})';

  static List<NoteToolbarItem> _unique(List<NoteToolbarItem> source) {
    final ids = <String>{};

    return List<NoteToolbarItem>.unmodifiable([
      for (final item in source)
        if (item.id.isNotEmpty && ids.add(item.id)) item,
    ]);
  }

  static Offset _sanitizeOffset(Offset offset) {
    if (!offset.isFinite) return defaultFloatingOffset;

    return Offset(offset.dx < 0 ? 0 : offset.dx, offset.dy < 0 ? 0 : offset.dy);
  }
}
