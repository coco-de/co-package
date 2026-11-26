import 'package:flutter/foundation.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/note_page.dart';
import 'package:open_note/src/note/layer/note_layer_stack.dart';
import 'package:open_note/src/note/objects/note_object_controller.dart';
import 'package:open_note/src/note/objects/note_objects_strings.dart';

/// The live editing state of one page: its ink layers, its objects and the
/// note's shared (every-page) objects, with one undo history that walks back
/// through all of them in order.
///
/// It notifies on every change, selection changes included. [snapshot] gives
/// the page to store; [isModified] says whether anything changed since the
/// last [markClean].
class NotePageSession extends ChangeNotifier {
  NotePageSession(
    NotePage page, {
    required NoteObjectRegistry registry,
    List<NoteObject> sharedObjects = const [],
    NoteIdFactory idFactory = generateNoteId,
    NoteClock clock = systemNoteClock,
    NoteObjectsStrings objectStrings = const NoteObjectsStrings(),
    String Function(int number)? layerName,
  }) : _base = page,
       _clock = clock,
       history = NoteUndoStack(maxLength: NoteLayerStack.historyDepth) {
    layers = NoteLayerStack(
      layers: page.layers,
      activeLayerId: page.activeLayerId,
      history: history,
      idFactory: idFactory,
      nameBuilder: layerName,
    );
    objects = NoteObjectController(
      objects: page.objects,
      history: history,
      idFactory: idFactory,
      clock: clock,
      registry: registry,
      strings: objectStrings,
    );
    shared = NoteObjectController(
      objects: sharedObjects,
      history: history,
      idFactory: idFactory,
      clock: clock,
      registry: registry,
      strings: objectStrings,
    );
    _cleanShared = shared.objects;
    _markPageClean();
    layers.addListener(notifyListeners);
    objects.addListener(notifyListeners);
    shared.addListener(notifyListeners);
  }

  /// Orders every ink, layer and object edit of this page.
  final NoteUndoStack history;

  late final NoteLayerStack layers;

  /// The page's objects.
  late final NoteObjectController objects;

  /// Objects shown on every page of the note.
  late final NoteObjectController shared;

  final NoteClock _clock;
  NotePage _base;
  late int _cleanRevision;
  late String _cleanActiveLayer;
  late List<NoteObject> _cleanObjects;
  late List<NoteObject> _cleanShared;
  bool _isPageChanged = false;

  String get pageId => _base.id;

  /// The page as it is now (text still being typed is not included).
  NotePage get page => _base.copyWith(
    layers: layers.contents,
    activeLayerId: layers.activeLayerId,
    objects: objects.objects,
  );

  bool get isModified =>
      _isPageChanged ||
      layers.revision != _cleanRevision ||
      layers.activeLayerId != _cleanActiveLayer ||
      !identical(objects.objects, _cleanObjects);

  bool get areSharedObjectsModified => !identical(shared.objects, _cleanShared);

  /// The page to store; the stored page itself when nothing changed.
  NotePage snapshot() =>
      isModified ? page.copyWith(modifiedAt: _clock()) : _base;

  /// Records that [stored] (a [snapshot]) and [shared] were stored.
  void markClean(NotePage stored) {
    _base = stored;
    _cleanShared = shared.objects;
    _markPageClean();
  }

  /// Turns the page into [changed] (the same page rotated, with other margins
  /// or another paper) as one undo step: [moveInk] moves the ink of every
  /// layer, page objects take their places in [changed], and the page takes its
  /// size, margins, paper turns and papers. Every-page objects stay.
  void rearrange(
    String label,
    NotePage changed, {
    Scribble Function(Scribble scribble)? moveInk,
  }) {
    assert(changed.id == pageId);
    history.group(label, () {
      if (moveInk != null) layers.transformAll(label, moveInk);
      _moveObjects(changed.objects);
      _changeSettings(label, changed);
    });
  }

  /// Takes the endless setting of [changed] (not an undo step).
  void setAutoGrows(bool autoGrows) {
    _base = _base.copyWith(autoGrows: autoGrows);
    _isPageChanged = true;
    notifyListeners();
  }

  void _moveObjects(List<NoteObject> moved) {
    objects.beginGesture();
    for (final object in moved) {
      final current = objects.find(object.id);
      if (current != null && current != object) objects.update(object);
    }
    objects.endGesture();
  }

  void _changeSettings(String label, NotePage changed) {
    final before = _base;
    if (before.size == changed.size &&
        before.margins == changed.margins &&
        before.paperTurns == changed.paperTurns &&
        before.template == changed.template &&
        before.marginTemplate == changed.marginTemplate) {
      return;
    }
    void apply(NotePage settings) {
      _base = _base.copyWith(
        size: settings.size,
        margins: settings.margins,
        paperTurns: settings.paperTurns,
        template: settings.template,
        marginTemplate: () => settings.marginTemplate,
      );
      _isPageChanged = true;
      notifyListeners();
    }

    history.push(
      NoteCallbackUndoable(
        label: label,
        onUndo: () => apply(before),
        onRedo: () => apply(changed),
      ),
    );
    apply(changed);
  }

  /// Uses [page] (the same content) as the stored page, after the document
  /// replaced it.
  void rebase(NotePage page) {
    assert(page.id == _base.id);
    _base = page;
  }

  @override
  void dispose() {
    layers
      ..removeListener(notifyListeners)
      ..dispose();
    objects
      ..removeListener(notifyListeners)
      ..dispose();
    shared
      ..removeListener(notifyListeners)
      ..dispose();
    history.dispose();
    super.dispose();
  }

  void _markPageClean() {
    _isPageChanged = false;
    _cleanRevision = layers.revision;
    _cleanActiveLayer = layers.activeLayerId;
    _cleanObjects = objects.objects;
  }
}
