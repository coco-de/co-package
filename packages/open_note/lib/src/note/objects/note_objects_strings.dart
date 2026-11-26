import 'package:flutter/foundation.dart';

/// User-visible text of the `objects` module: accessibility labels, hints and
/// the labels of undo steps. English by default; pass a translated instance.
@immutable
class NoteObjectsStrings {
  /// Names of the kinds this module ships.
  static const Map<String, String> defaultKindNames = {
    'sticky': 'Sticky note',
    'arrow': 'Arrow',
    'link': 'Link',
    'sticker': 'Sticker',
  };

  /// Spoken names by object `kind`. A host that registers more kinds (tables,
  /// masks, …) adds their names here.
  final Map<String, String> kindNames;

  /// Name used for a kind that [kindNames] does not know.
  final String unknownObjectName;

  /// Accessibility label of the mark on a locked object.
  final String lockedLabel;

  /// Accessibility label of the eight resize handles.
  final String resizeHandleLabel;

  /// Accessibility label of the rotation handle.
  final String rotateHandleLabel;

  /// Hint shown in an empty sticky note while it is edited.
  final String stickyHint;

  /// Name given to a sticker collection created with a blank name.
  final String untitledCollectionName;

  /// Undo label of adding an object.
  final String addLabel;

  /// Undo label of changing an object (including committed inline edits).
  final String editLabel;

  /// Undo label of moving objects.
  final String moveLabel;

  /// Undo label of resizing an object.
  final String resizeLabel;

  /// Undo label of rotating an object.
  final String rotateLabel;

  /// Undo label of removing objects.
  final String deleteLabel;

  /// Undo label of duplicating objects.
  final String duplicateLabel;

  /// Undo label of changing the stacking order.
  final String reorderLabel;

  /// Undo label of locking objects.
  final String lockLabel;

  /// Undo label of unlocking objects.
  final String unlockLabel;

  /// Undo label of changing opacity.
  final String opacityLabel;

  /// The filter showing every collection's stickers.
  final String allStickers;

  /// Starts and ends changing the collections.
  final String manageStickers;
  final String doneManagingStickers;

  final String newCollection;
  final String collectionName;
  final String deleteCollection;

  /// The delete button after its first tap.
  final String confirmDeleteCollection;

  final String addStickerPictures;
  final String removeSticker;
  final String moveStickerEarlier;
  final String moveStickerLater;
  final String noStickers;

  const NoteObjectsStrings({
    this.kindNames = defaultKindNames,
    this.unknownObjectName = 'Object',
    this.lockedLabel = 'Locked',
    this.resizeHandleLabel = 'Resize handle',
    this.rotateHandleLabel = 'Rotate handle',
    this.stickyHint = 'Write a note',
    this.untitledCollectionName = 'Untitled',
    this.addLabel = 'Add',
    this.editLabel = 'Edit',
    this.moveLabel = 'Move',
    this.resizeLabel = 'Resize',
    this.rotateLabel = 'Rotate',
    this.deleteLabel = 'Delete',
    this.duplicateLabel = 'Duplicate',
    this.reorderLabel = 'Reorder',
    this.lockLabel = 'Lock',
    this.unlockLabel = 'Unlock',
    this.opacityLabel = 'Change opacity',
    this.allStickers = 'All',
    this.manageStickers = 'Edit collections',
    this.doneManagingStickers = 'Done',
    this.newCollection = 'New collection',
    this.collectionName = 'Collection name',
    this.deleteCollection = 'Delete collection',
    this.confirmDeleteCollection = 'Tap again to delete',
    this.addStickerPictures = 'Add pictures',
    this.removeSticker = 'Remove sticker',
    this.moveStickerEarlier = 'Move earlier',
    this.moveStickerLater = 'Move later',
    this.noStickers = 'No stickers yet',
  });

  /// The spoken name of the object kind [kind].
  String nameOf(String kind) => kindNames[kind] ?? '$unknownObjectName ($kind)';
}
