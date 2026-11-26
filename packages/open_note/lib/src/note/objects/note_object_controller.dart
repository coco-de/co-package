import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_object.dart';
import 'package:open_note/src/note/core/note_undo_stack.dart';
import 'package:open_note/src/note/objects/internal/note_object_order.dart';
import 'package:open_note/src/note/objects/note_object_geometry.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';
import 'package:open_note/src/note/objects/note_reidentifiable_object.dart';

/// Computes the unsaved input of an inline editor: the edited copy of
/// [current], or `null` when there is nothing to commit.
typedef NotePendingEdit = NoteObject? Function(NoteObject current);

/// Owns the objects of one page: their stacking order, the selection, the
/// inline editing session and every edit.
///
/// Index 0 of [objects] is the bottom of the stack. Ids are unique; objects
/// with an empty or repeated id are dropped (the first occurrence wins).
///
/// With a [history], every mutation pushes one [NoteUndoable] that restores
/// the previous object list *and* selection; between [beginGesture] and
/// [endGesture] all mutations merge into one step. Selecting and editing alone
/// are not recorded. Locked objects ignore [moveBy], [resize], [rotate] and
/// [remove]; every other operation (including [update]) applies to them.
///
/// After [dispose] every method is a no-op that returns `false`, an empty list
/// or `null`.
class NoteObjectController extends ChangeNotifier {
  /// Where [duplicate] puts a copy relative to its original by default.
  static const Offset defaultDuplicateOffset = Offset(16, 16);

  static const int _idAttempts = 100;

  /// The undo history edits are recorded in, or `null` to record nothing.
  /// It may be shared with other controllers (ink, pages, …).
  final NoteUndoStack? history;

  /// Used by [duplicate] to copy kinds that are not
  /// [NoteReidentifiableObject].
  final NoteObjectRegistry? registry;

  /// Labels of the undo steps.
  final NoteObjectsStrings strings;

  final NoteIdFactory _idFactory;

  final NoteClock _clock;

  // Both collections are unmodifiable and replaced as a whole, so an undo
  // snapshot may keep a reference to them.
  List<NoteObject> _objects;

  Set<String> _selectedIds = const {};
  String? _editingId;
  DateTime? _modifiedAt;
  final List<NotePendingEditRegistration> _pendingEdits = [];
  _Snapshot? _gestureStart;
  int _gestureDepth = 0;
  String _gestureLabel = '';

  /// Bumped by [replaceAll] so undo steps of older content do nothing.
  int _generation = 0;

  bool _disposed = false;

  /// Creates a controller. [idFactory] names the copies of [duplicate] (and
  /// [createId]); [clock] stamps [modifiedAt]; [registry] lets [duplicate] copy
  /// kinds that are not [NoteReidentifiableObject]; [strings] labels the undo
  /// steps.
  NoteObjectController({
    List<NoteObject> objects = const [],
    this.history,
    NoteIdFactory? idFactory,
    NoteClock? clock,
    this.registry,
    this.strings = const NoteObjectsStrings(),
  }) : _idFactory = idFactory ?? generateNoteId,
       _clock = clock ?? systemNoteClock,
       _objects = _uniqueById(objects);

  /// Every object, bottom first. The list cannot be modified.
  List<NoteObject> get objects => _objects;

  /// Ids of the selected objects. The set cannot be modified.
  Set<String> get selectedIds => _selectedIds;

  /// The selected objects, bottom first.
  List<NoteObject> get selection => List.unmodifiable([
    for (final object in _objects)
      if (_selectedIds.contains(object.id)) object,
  ]);

  /// The object being edited inline, or `null`. While it is not `null` it is
  /// the only selected object.
  String? get editingId => _editingId;

  /// When the objects last changed (through an edit, an undo or a redo), as
  /// reported by the clock; `null` after construction and after [replaceAll].
  DateTime? get modifiedAt => _modifiedAt;

  /// Whether a [beginGesture] is still waiting for its [endGesture].
  bool get isGestureActive => _gestureDepth > 0;

  /// The visual (rotated) bounding box of the selection in page coordinates, or
  /// `null` when nothing is selected.
  Rect? get selectionBounds {
    Rect? box;
    for (final object in selection) {
      final rotated = NoteObjectGeometry.boundingBox(
        object.bounds,
        object.rotation,
      );
      box = box?.expandToInclude(rotated) ?? rotated;
    }

    return box;
  }

  /// The object with [id], or `null`.
  NoteObject? find(String id) {
    final index = _indexOf(id);

    return index < 0 ? null : _objects[index];
  }

  /// A new id from the id factory, for building an object to [add].
  String createId() => _idFactory();

  /// The topmost object whose rotated bounds contain [pagePoint], or `null`.
  /// Nothing is skipped: locked and fully transparent objects count too.
  NoteObject? objectAt(Offset pagePoint) {
    for (final object in _objects.reversed) {
      if (NoteObjectGeometry.contains(
        object.bounds,
        object.rotation,
        pagePoint,
      )) {
        return object;
      }
    }

    return null;
  }

  /// Selects [id] only, or adds it to the selection when [additive]. Unknown
  /// ids are ignored.
  void select(String id, {bool additive = false}) {
    if (_disposed || find(id) == null) return;
    _applySelection(additive ? {..._selectedIds, id} : {id});
  }

  /// Adds [id] to the selection, or removes it when it is already selected.
  void toggleSelection(String id) {
    if (_disposed || find(id) == null) return;
    final next = {..._selectedIds};
    if (!next.remove(id)) next.add(id);
    _applySelection(next);
  }

  /// Selects every object.
  void selectAll() {
    if (_disposed) return;
    _applySelection({for (final object in _objects) object.id});
  }

  /// Deselects everything (which also ends editing).
  void clearSelection() {
    if (_disposed) return;
    _applySelection(const {});
  }

  /// Starts editing [id] inline and makes it the only selected object. Returns
  /// `false` for an unknown id.
  bool beginEditing(String id) {
    if (_disposed || find(id) == null) return false;
    if (_editingId == id) return true;
    flushPendingEdits();
    if (_disposed || find(id) == null) return false;
    _selectedIds = Set.unmodifiable({id});
    _editingId = id;
    notifyListeners();

    return true;
  }

  /// Ends the editing session, committing any pending input first. The object
  /// stays selected.
  void endEditing() {
    if (_disposed || _editingId == null) return;
    flushPendingEdits();
    if (_disposed || _editingId == null) return;
    _editingId = null;
    notifyListeners();
  }

  /// Lets an inline editor of the object [objectId] keep unsaved input here.
  ///
  /// The controller commits it with [flushPendingEdits] — which it calls itself
  /// before it ends an editing session, starts a gesture, removes the edited
  /// object or duplicates — so typed input becomes its own undo step instead of
  /// being lost or merged into a drag. Call
  /// [NotePendingEditRegistration.cancel] when the editor goes away.
  NotePendingEditRegistration registerPendingEdit(
    String objectId,
    NotePendingEdit apply,
  ) {
    final registration = NotePendingEditRegistration._(this, objectId, apply);
    if (!_disposed) _pendingEdits.add(registration);

    return registration;
  }

  /// Commits the unsaved input of every inline editor now. Call it before
  /// saving a page or undoing while a text field is open. Does nothing while an
  /// undo or redo is running.
  void flushPendingEdits() {
    if (_disposed || (history?.isApplying ?? false)) return;
    for (final registration in List.of(_pendingEdits)) {
      registration.commit();
    }
  }

  /// Puts [object] on top and, when [select] is `true`, selects it. Returns
  /// `false` (and changes nothing) when its id is empty or already used.
  bool add(NoteObject object, {bool select = true}) {
    // ignore: prefer-moving-to-variable
    if (_disposed || object.id.isEmpty || find(object.id) != null) {
      return false;
    }
    if (select) flushPendingEdits();
    // Checked again: committing pending input notifies listeners.
    // ignore: prefer-moving-to-variable
    if (_disposed || find(object.id) != null) return false;

    return _commit(strings.addLabel, [
      ..._objects,
      object,
    ], selection: select ? {object.id} : null);
  }

  /// Replaces the object that has the id of [object]. Returns `false` when
  /// there is none or it is already equal. Applies to locked objects too.
  bool update(NoteObject object) {
    if (_disposed) return false;
    final index = _indexOf(object.id);
    if (index < 0 || _objects[index] == object) return false;

    return _commit(strings.editLabel, [..._objects]..[index] = object);
  }

  /// Moves the unlocked objects of [ids] by [delta] page units. A zero or
  /// non-finite delta does nothing.
  void moveBy(Iterable<String> ids, Offset delta) {
    if (_disposed || !delta.isFinite || delta == Offset.zero) return;
    _mapUnlocked(
      strings.moveLabel,
      ids,
      (object) => object.withBase(bounds: object.bounds.shift(delta)),
    );
  }

  /// Sets the unrotated bounds of [id] (unless locked). A negative size is
  /// mirrored and each side is at least [NoteObjectGeometry.minimumSize]
  /// (growing about the center); non-finite rects are ignored.
  void resize(String id, Rect bounds) {
    if (_disposed || !bounds.isFinite) return;
    final next = NoteObjectGeometry.normalizeRect(
      bounds,
      minimum: NoteObjectGeometry.minimumSize,
    );
    _mapUnlocked(
      strings.resizeLabel,
      [id],
      (object) =>
          object.bounds == next ? object : object.withBase(bounds: next),
    );
  }

  /// Sets (does not add to) the rotation of [id] (unless locked), in clockwise
  /// radians, wrapped into `(-π, π]`. Non-finite values are ignored.
  void rotate(String id, double radians) {
    if (_disposed || !radians.isFinite) return;
    final next = NoteObjectGeometry.normalizeAngle(radians);
    _mapUnlocked(
      strings.rotateLabel,
      [id],
      (object) =>
          object.rotation == next ? object : object.withBase(rotation: next),
    );
  }

  /// Removes the unlocked objects of [ids].
  void remove(Iterable<String> ids) {
    if (_disposed) return;
    final targets = ids.toSet();
    final doomed = {
      for (final object in _objects)
        if (targets.contains(object.id) && !object.locked) object.id,
    };
    if (doomed.isEmpty) return;
    // Input typed into a removed editor belongs to its own undo step.
    if (doomed.contains(_editingId)) flushPendingEdits();
    _commit(strings.deleteLabel, [
      for (final object in _objects)
        if (!doomed.contains(object.id)) object,
    ]);
  }

  /// Puts copies of the objects of [ids] on top, in their current order, moved
  /// by [offset] and unlocked, and selects the copies. Returns their ids,
  /// bottom first.
  ///
  /// A kind that is neither [NoteReidentifiableObject] nor known to
  /// [registry] cannot be given a new id and is skipped.
  List<String> duplicate(
    Iterable<String> ids, {
    Offset offset = defaultDuplicateOffset,
  }) {
    if (_disposed || !offset.isFinite) return const [];
    final targets = ids.toSet();
    flushPendingEdits();
    final copies = _copiesOf(targets, offset);
    if (copies.isEmpty) return const [];
    final copyIds = [for (final copy in copies) copy.id];
    _commit(strings.duplicateLabel, [
      ..._objects,
      ...copies,
    ], selection: copyIds.toSet());

    return List.unmodifiable(copyIds);
  }

  /// Moves the objects of [ids] above all others, keeping their order.
  void bringToFront(Iterable<String> ids) =>
      _restack(ids, NoteObjectOrder.toFront);

  /// Moves the objects of [ids] below all others, keeping their order.
  void sendToBack(Iterable<String> ids) =>
      _restack(ids, NoteObjectOrder.toBack);

  /// Moves each object of [ids] one step up the stack.
  void moveForward(Iterable<String> ids) =>
      _restack(ids, NoteObjectOrder.forward);

  /// Moves each object of [ids] one step down the stack.
  void moveBackward(Iterable<String> ids) =>
      _restack(ids, NoteObjectOrder.backward);

  /// Locks or unlocks the objects of [ids].
  void setLocked(Iterable<String> ids, bool locked) {
    if (_disposed) return;
    _mapObjects(
      locked ? strings.lockLabel : strings.unlockLabel,
      ids,
      (object) =>
          object.locked == locked ? object : object.withBase(locked: locked),
    );
  }

  /// Sets the opacity (clamped to 0–1) of the objects of [ids]. A NaN is
  /// ignored.
  void setOpacity(Iterable<String> ids, double opacity) {
    if (_disposed || opacity.isNaN) return;
    final next = opacity.clamp(0.0, 1.0);
    _mapObjects(
      strings.opacityLabel,
      ids,
      (object) =>
          object.opacity == next ? object : object.withBase(opacity: next),
    );
  }

  /// Replaces the whole content with freshly loaded [objects]: nothing is
  /// recorded, selection, editing, any open gesture and pending input are
  /// dropped, and undo steps of the earlier content become no-ops.
  void replaceAll(Iterable<NoteObject> objects) {
    if (_disposed) return;
    final next = _uniqueById(objects);
    final changed =
        !listEquals(next, _objects) ||
        _selectedIds.isNotEmpty ||
        _editingId != null;
    _generation++;
    _gestureDepth = 0;
    _gestureStart = null;
    _pendingEdits.clear();
    _objects = next;
    _selectedIds = const {};
    _editingId = null;
    _modifiedAt = null;
    if (changed) notifyListeners();
  }

  /// Starts a gesture: until the matching [endGesture], changes are merged into
  /// one undo step. Calls nest; only the outermost pair counts. Pending editor
  /// input is committed first, as its own step.
  void beginGesture() {
    if (_disposed) return;
    if (_gestureDepth == 0) {
      flushPendingEdits();
      _gestureStart = _capture();
      _gestureLabel = strings.editLabel;
    }
    _gestureDepth++;
  }

  /// Ends a gesture and records what it changed as one undo step (nothing when
  /// the objects are back to how they started).
  void endGesture() {
    if (_disposed || _gestureDepth == 0) return;
    _gestureDepth--;
    if (_gestureDepth > 0) return;
    final start = _gestureStart;
    _gestureStart = null;
    if (start == null || listEquals(start.objects, _objects)) return;
    _push(_gestureLabel, start);
  }

  /// Abandons the whole gesture (all nesting levels): objects and selection go
  /// back to how they were at [beginGesture] and nothing is recorded.
  void cancelGesture() {
    if (_disposed || _gestureDepth == 0) return;
    final start = _gestureStart;
    _gestureDepth = 0;
    _gestureStart = null;
    if (start != null) _restore(start);
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingEdits.clear();
    _gestureStart = null;
    _gestureDepth = 0;
    super.dispose();
  }

  static List<NoteObject> _uniqueById(Iterable<NoteObject> objects) {
    final seen = <String>{};

    return List.unmodifiable([
      for (final object in objects)
        if (object.id.isNotEmpty && seen.add(object.id)) object,
    ]);
  }

  int _indexOf(String id) => _objects.indexWhere((object) => object.id == id);

  _Snapshot _capture() => _Snapshot(_objects, _selectedIds);

  void _applySelection(Set<String> next) {
    final endsEditing = _editingId != null && !_isOnly(next, _editingId);
    if (endsEditing) flushPendingEdits();
    if (_disposed) return;
    final editing = _isOnly(next, _editingId) ? _editingId : null;
    if (editing == _editingId && setEquals(next, _selectedIds)) return;
    _selectedIds = Set.unmodifiable(next);
    _editingId = editing;
    notifyListeners();
  }

  static bool _isOnly(Set<String> selection, String? id) =>
      id != null && selection.length == 1 && selection.contains(id);

  /// Installs [next], records one step (outside a gesture) and notifies.
  /// Returns whether the objects changed.
  bool _commit(String label, List<NoteObject> next, {Set<String>? selection}) {
    if (listEquals(next, _objects)) return false;
    final before = _capture();
    _install(next, selection ?? _selectedIds);
    _modifiedAt = _clock();
    if (_gestureDepth > 0) {
      _gestureLabel = label;
    } else {
      _push(label, before);
    }
    notifyListeners();

    return true;
  }

  /// Sets the objects and selection, keeping only existing ids and ending an
  /// editing session whose object is no longer the only selected one.
  void _install(List<NoteObject> objects, Set<String> selection) {
    _objects = List.unmodifiable(objects);
    final present = {for (final object in _objects) object.id};
    _selectedIds = Set.unmodifiable(selection.where(present.contains));
    if (!_isOnly(_selectedIds, _editingId)) _editingId = null;
  }

  void _push(String label, _Snapshot before) => history?.push(
    _NoteObjectEdit(this, label, _generation, before, _capture()),
  );

  void _mapObjects(
    String label,
    Iterable<String> ids,
    NoteObject Function(NoteObject object) change,
  ) {
    final targets = ids.toSet();
    _commit(label, [
      for (final object in _objects)
        targets.contains(object.id) ? change(object) : object,
    ]);
  }

  void _mapUnlocked(
    String label,
    Iterable<String> ids,
    NoteObject Function(NoteObject object) change,
  ) => _mapObjects(
    label,
    ids,
    (object) => object.locked ? object : change(object),
  );

  void _restack(
    Iterable<String> ids,
    List<NoteObject> Function(List<NoteObject> objects, Set<String> ids) order,
  ) {
    if (_disposed) return;
    _commit(strings.reorderLabel, order(_objects, ids.toSet()));
  }

  List<NoteObject> _copiesOf(Set<String> targets, Offset offset) {
    final taken = {for (final object in _objects) object.id};
    final copies = <NoteObject>[];
    for (final object in _objects) {
      if (!targets.contains(object.id)) continue;
      final id = _freshId(taken);
      final copy = id == null ? null : _withId(object, id);
      if (copy == null) continue;
      taken.add(copy.id);
      copies.add(
        copy.withBase(bounds: copy.bounds.shift(offset), locked: false),
      );
    }

    return copies;
  }

  String? _freshId(Set<String> taken) {
    for (var attempt = 0; attempt < _idAttempts; attempt++) {
      final id = _idFactory();
      if (id.isNotEmpty && !taken.contains(id)) return id;
    }

    return null;
  }

  NoteObject? _withId(NoteObject object, String id) {
    // Subclasses can be both, which the rule does not see.
    // ignore: avoid-unrelated-type-assertions
    if (object case final NoteReidentifiableObject source) {
      return source.withId(id);
    }
    if (object is NoteUnknownObject) {
      return NoteUnknownObject(
        id: id,
        bounds: object.bounds,
        unknownKind: object.unknownKind,
        payload: object.payload,
        rotation: object.rotation,
        opacity: object.opacity,
        locked: object.locked,
      );
    }
    final source = registry;
    if (source == null || !source.isRegistered(object.kind)) return null;
    final copy = source.decode({...object.toJson(), 'id': id});

    return copy?.id == id ? copy : null;
  }

  /// Applies an undo or redo step recorded for the content [generation].
  void _applyStep(_Snapshot snapshot, int generation) {
    if (generation == _generation) _restore(snapshot);
  }

  void _restore(_Snapshot snapshot) {
    if (_disposed) return;
    // An undo during a gesture moves the gesture's starting point.
    if (_gestureDepth > 0) _gestureStart = snapshot;
    final unchanged =
        listEquals(snapshot.objects, _objects) &&
        setEquals(snapshot.selection, _selectedIds);
    if (unchanged) return;
    _install(snapshot.objects, snapshot.selection);
    _modifiedAt = _clock();
    notifyListeners();
  }
}

/// A live registration of unsaved inline-editor input; see
/// [NoteObjectController.registerPendingEdit].
class NotePendingEditRegistration {
  /// The object the input belongs to.
  final String objectId;

  final NoteObjectController _controller;

  final NotePendingEdit _apply;
  NotePendingEditRegistration._(this._controller, this.objectId, this._apply);

  /// Whether [NoteObjectController.flushPendingEdits] still commits this input.
  /// `false` after [cancel], and after the controller was disposed or loaded
  /// other content with [NoteObjectController.replaceAll].
  bool get isActive => _controller._pendingEdits.contains(this);

  /// Applies the input to the object now, as its own undo step. Does nothing
  /// when the registration is not active or the object is gone.
  void commit() {
    if (!isActive) return;
    final current = _controller.find(objectId);
    if (current == null) return;
    final next = _apply(current);
    if (next != null) _controller.update(next);
  }

  /// Withdraws the registration; later flushes ignore it.
  void cancel() => _controller._pendingEdits.remove(this);
}

@immutable
class _Snapshot {
  final List<NoteObject> objects;

  final Set<String> selection;
  const _Snapshot(this.objects, this.selection);
}

class _NoteObjectEdit implements NoteUndoable {
  @override
  final String label;

  final NoteObjectController _controller;

  final int _generation;
  final _Snapshot _before;
  final _Snapshot _after;
  _NoteObjectEdit(
    this._controller,
    this.label,
    this._generation,
    this._before,
    this._after,
  );

  @override
  void undo() => _controller._applyStep(_before, _generation);

  @override
  void redo() => _controller._applyStep(_after, _generation);
}
