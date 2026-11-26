import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/core/utils/extensions/scribble_extension.dart';
import 'package:open_note/src/core/utils/ink_group_info.dart';
import 'package:open_note/src/core/utils/stroke_id.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/module/scribble.notifier.dart';
import 'package:open_note/src/note/core/note_ids.dart';
import 'package:open_note/src/note/core/note_undo_stack.dart';
import 'package:open_note/src/note/layer/note_layer.dart';
import 'package:open_note/src/note/layer/note_layer_content.dart';

/// The ink layers of one page, each with its own [ScribbleNotifier], and one
/// chronological undo history across all of them.
///
/// Exactly one layer is *active*: it is the one the editor draws on (through
/// its notifier). Layers are listed bottom to top.
///
/// ## Undo
///
/// Every committed ink edit of any layer, and every layer operation, is one
/// command on [history]. Call [undo]/[redo] here (or on the shared [history])
/// — **not** on a layer notifier directly, or the layer's own history gets out
/// of step with the page history. Commands pushed by other controllers (objects)
/// on the same [history] are ordered with the ink edits.
///
/// Notifications are sent when the layer list, the active layer or committed
/// content changes — not for every intermediate pointer frame.
class NoteLayerStack extends ChangeNotifier {
  /// Creates a stack from [layers] (bottom to top). Without layers it starts
  /// with one empty layer. [activeLayerId] defaults to the top layer.
  NoteLayerStack({
    Iterable<NoteLayerContent> layers = const [],
    String? activeLayerId,
    NoteUndoStack? history,
    NoteIdFactory idFactory = generateNoteId,
    String Function()? strokeIdFactory,
    String Function(int number)? nameBuilder,
  }) : _idFactory = idFactory,
       _strokeIdFactory = strokeIdFactory ?? generateStrokeId,
       _nameBuilder = nameBuilder ?? _defaultName,
       _ownsHistory = history == null,
       history = history ?? NoteUndoStack(maxLength: historyDepth) {
    for (final content in layers) {
      if (_layers.containsKey(content.layer.id)) continue;
      _layers[content.layer.id] = content.layer;
      _notifiers[content.layer.id] = _newNotifier(content.scribble);
      _order.add(content.layer.id);
    }
    if (_order.isEmpty) {
      final layer = NoteLayer(id: _idFactory(), name: _nameBuilder(1));
      _layers[layer.id] = layer;
      _notifiers[layer.id] = _newNotifier(null);
      _order.add(layer.id);
    }
    _activeId = _order.contains(activeLayerId) ? activeLayerId! : _order.last;
  }

  /// How many edits each layer (and an owned history) can undo.
  static const int historyDepth = 200;

  /// The page-wide undo history.
  final NoteUndoStack history;

  final NoteIdFactory _idFactory;
  final String Function() _strokeIdFactory;
  final String Function(int number) _nameBuilder;
  final bool _ownsHistory;

  Offset Function(Offset position)? Function(Offset start)? _strokeConstraint;

  /// Includes layers that were removed, which undo may bring back.
  final Map<String, NoteLayer> _layers = {};
  final Map<String, ScribbleNotifier> _notifiers = {};
  final List<String> _order = [];

  late String _activeId;
  int _revision = 0;
  bool _applyingLayerEdit = false;
  bool _isDisposed = false;

  /// Constrains new strokes on every layer (see
  /// `ScribbleNotifier.strokeConstraintFor`).
  set strokeConstraintFor(
    Offset Function(Offset position)? Function(Offset start)? value,
  ) {
    _strokeConstraint = value;
    for (final notifier in _notifiers.values) {
      notifier.strokeConstraintFor = value;
    }
  }

  /// Layers bottom to top.
  List<NoteLayer> get layers =>
      List.unmodifiable([for (final id in _order) _layers[id]!]);

  int get length => _order.length;

  String get activeLayerId => _activeId;

  NoteLayer get activeLayer => _layers[_activeId]!;

  /// The notifier the editor draws on.
  ScribbleNotifier get activeNotifier => _notifiers[_activeId]!;

  /// False while the active layer is hidden or locked.
  bool get canDrawOnActive => activeLayer.visible && !activeLayer.locked;

  /// Increases with every committed change; compare to detect "needs saving".
  int get revision => _revision;

  bool get canUndo => history.canUndo;

  bool get canRedo => history.canRedo;

  /// Whether no layer holds any stroke, text or image.
  bool get isEmpty => contents.every((content) => content.isEmpty);

  /// Layers with their ink, bottom to top (a snapshot for saving/rendering).
  List<NoteLayerContent> get contents => [
    for (final id in _order)
      NoteLayerContent(
        layer: _layers[id]!,
        scribble: _notifiers[id]!.currentScribble,
      ),
  ];

  /// The position of layer [id] from the bottom, or -1.
  int indexOf(String id) => _order.indexOf(id);

  NoteLayer? layerById(String id) => _order.contains(id) ? _layers[id] : null;

  /// The notifier of a layer. Throws [ArgumentError] for an unknown id.
  ScribbleNotifier notifierOf(String id) => _notifiers[_requireId(id)]!;

  Scribble scribbleOf(String id) => notifierOf(id).currentScribble;

  bool undo() => history.undo();

  bool redo() => history.redo();

  /// Makes layer [id] the one being drawn on. A gesture in progress on the
  /// previous layer is finished first.
  void setActive(String id) {
    _requireId(id);
    if (id == _activeId) return;
    activeNotifier.releaseStalePointers();
    _activeId = id;
    notifyListeners();
  }

  /// Adds an empty layer above [aboveId] (top by default) and activates it.
  NoteLayer addLayer({String? name, String? aboveId, Scribble? scribble}) {
    final layer = NoteLayer(
      id: _idFactory(),
      name: name ?? _nameBuilder(_order.length + 1),
    );
    _insertLayer(layer, _indexAbove(aboveId), scribble, 'add layer');

    return layer;
  }

  /// Removes a layer. The last remaining layer cannot be removed.
  bool removeLayer(String id) {
    _requireId(id);
    if (_order.length == 1) return false;
    final index = _order.indexOf(id);
    final previousActive = _activeId;
    final nextActive = previousActive == id
        ? _order[index == 0 ? 1 : index - 1]
        : previousActive;
    void apply() {
      _order.remove(id);
      _activeId = nextActive;
    }

    apply();
    _record(
      'remove layer',
      undo: () {
        _order.insert(index, id);
        _activeId = previousActive;
      },
      redo: apply,
    );

    return true;
  }

  /// Renames a layer; a blank name is ignored.
  void renameLayer(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _replaceLayer(
      'rename layer',
      _layers[_requireId(id)]!.copyWith(name: trimmed),
    );
  }

  void setVisible(String id, bool visible) => _replaceLayer(
    'layer visibility',
    _layers[_requireId(id)]!.copyWith(visible: visible),
  );

  void setLocked(String id, bool locked) => _replaceLayer(
    'layer lock',
    _layers[_requireId(id)]!.copyWith(locked: locked),
  );

  /// Changes the opacity without recording it — for a slider being dragged.
  /// Finish the drag with [setOpacity] and `from:` the value before it.
  void previewOpacity(String id, double opacity) {
    final next = _layers[_requireId(id)]!.copyWith(opacity: opacity);
    if (next == _layers[id]) return;
    _layers[id] = next;
    notifyListeners();
  }

  /// Sets the opacity (clamped to 0..1) as one undo step. [from] is the value
  /// undo returns to; it defaults to the current one.
  void setOpacity(String id, double opacity, {double? from}) {
    final current = _layers[_requireId(id)]!;
    final before = current.copyWith(opacity: from ?? current.opacity);
    final after = current.copyWith(opacity: opacity);
    _layers[id] = after;
    if (before == after) return;
    _record(
      'layer opacity',
      undo: () => _layers[id] = before,
      redo: () => _layers[id] = after,
    );
  }

  /// Moves a layer to [newIndex] (0 is the bottom, clamped).
  void moveLayer(String id, int newIndex) {
    final from = _order.indexOf(_requireId(id));
    final to = newIndex.clamp(0, _order.length - 1);
    if (from == to) return;
    void move(int origin, int destination) {
      _order
        ..removeAt(origin)
        ..insert(destination, id);
    }

    move(from, to);
    _record(
      'move layer',
      undo: () => move(to, from),
      redo: () => move(from, to),
    );
  }

  /// Copies a layer (with new stroke, text and image ids) directly above it and
  /// activates the copy.
  NoteLayer duplicateLayer(String id) {
    final source = _layers[_requireId(id)]!;
    final copy = scribbleOf(id).deepCopy();
    for (final stroke in copy.strokes) {
      stroke.id = _strokeIdFactory();
    }
    for (final text in copy.textDrawables) {
      text.id = _idFactory();
    }
    for (final image in copy.imageDrawables) {
      image.id = _idFactory();
    }
    final layer = NoteLayer(
      id: _idFactory(),
      name: '${source.name} copy',
      visible: source.visible,
      locked: source.locked,
      opacity: source.opacity,
    );
    _insertLayer(layer, _order.indexOf(id) + 1, copy, 'duplicate layer');

    return layer;
  }

  /// Merges layer [id] into the one below it. The merged ink keeps the lower
  /// layer's opacity. Returns false for the bottom layer.
  bool mergeDown(String id) {
    final index = _order.indexOf(_requireId(id));
    if (index == 0) return false;

    return _merge([id], into: _order[index - 1], label: 'merge layer down');
  }

  /// Merges every visible layer into the lowest visible one. Hidden layers stay.
  bool mergeVisible() {
    final visible = [
      for (final id in _order)
        if (_layers[id]!.visible) id,
    ];
    if (visible.length < 2) return false;

    return _merge(
      visible.sublist(1),
      into: visible.first,
      label: 'merge visible layers',
    );
  }

  /// Removes all ink of a layer.
  void clearLayer(String id) => notifierOf(id).clear();

  /// Moves strokes (by index in the source layer), texts and images (by id)
  /// from one layer to another, appended on top, as one undo step.
  bool moveToLayer({
    required String fromId,
    required String toId,
    Set<int> strokeIndexes = const {},
    Set<String> textIds = const {},
    Set<String> imageIds = const {},
  }) {
    final source = notifierOf(fromId);
    final target = notifierOf(toId);
    if (fromId == toId) return false;
    final from = source.currentScribble;
    final movedStrokes = <Stroke>[];
    final keptStrokes = <Stroke>[];
    for (final (index, stroke) in from.strokes.indexed) {
      final moves =
          strokeIndexes.contains(index) && stroke.ink != InkModes.lasso;
      (moves ? movedStrokes : keptStrokes).add(stroke);
    }
    final movedTexts = [
      for (final text in from.textDrawables)
        if (textIds.contains(text.id)) text,
    ];
    final movedImages = [
      for (final image in from.imageDrawables)
        if (imageIds.contains(image.id)) image,
    ];
    if (movedStrokes.isEmpty && movedTexts.isEmpty && movedImages.isEmpty) {
      return false;
    }
    _quietly(() {
      source.setScribble(
        scribble: from.copyWithContents(
          strokes: keptStrokes,
          textDrawables: [
            for (final text in from.textDrawables)
              if (!textIds.contains(text.id)) text,
          ],
          imageDrawables: [
            for (final image in from.imageDrawables)
              if (!imageIds.contains(image.id)) image,
          ],
        ),
      );
      target.setScribble(
        scribble: _append(
          target.currentScribble,
          strokes: movedStrokes,
          texts: movedTexts,
          images: movedImages,
        ),
      );
    });
    _record(
      'move to layer',
      undo: () => _quietly(() {
        target.undo();
        source.undo();
      }),
      redo: () => _quietly(() {
        source.redo();
        target.redo();
      }),
    );

    return true;
  }

  /// Applies [transform] to the ink of every layer as one undo step (page
  /// rotation, margin extension). A layer whose transform returns the same
  /// instance is left alone.
  void transformAll(String label, Scribble Function(Scribble) transform) {
    final changed = <ScribbleNotifier>[];
    _quietly(() {
      for (final id in _order) {
        final notifier = _notifiers[id]!;
        final before = notifier.currentScribble;
        final after = transform(before);
        if (identical(after, before)) continue;
        notifier.setScribble(scribble: after);
        changed.add(notifier);
      }
    });
    if (changed.isEmpty) return;
    _record(
      label,
      undo: () => _quietly(() {
        for (final notifier in changed) {
          notifier.undo();
        }
      }),
      redo: () => _quietly(() {
        for (final notifier in changed) {
          notifier.redo();
        }
      }),
    );
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final notifier in _notifiers.values) {
      notifier
        ..onHistoryCommit = null
        ..dispose();
    }
    if (_ownsHistory) history.dispose();
    super.dispose();
  }

  static String _defaultName(int number) => 'Layer $number';

  ScribbleNotifier _newNotifier(Scribble? scribble) {
    final notifier = ScribbleNotifier(
      scribble: scribble,
      strokeIdFactory: _strokeIdFactory,
    )..maxHistoryLength = historyDepth;
    notifier
      ..onHistoryCommit = (() => _onInkCommit(notifier))
      ..strokeConstraintFor = _strokeConstraint;

    return notifier;
  }

  void _onInkCommit(ScribbleNotifier notifier) {
    if (_isDisposed) return;
    if (!_applyingLayerEdit) {
      history.push(
        NoteCallbackUndoable(
          label: 'ink',
          onUndo: () => _replayInk(notifier.canUndo, notifier.undo),
          onRedo: () => _replayInk(notifier.canRedo, notifier.redo),
        ),
      );
    }
    _changed();
  }

  void _replayInk(bool possible, VoidCallback apply) {
    if (_isDisposed || !possible) return;
    apply();
    _changed();
  }

  void _changed() {
    _revision++;
    notifyListeners();
  }

  /// Records a layer operation whose effect is already applied.
  void _record(
    String label, {
    required VoidCallback undo,
    required VoidCallback redo,
  }) {
    history.push(
      NoteCallbackUndoable(
        label: label,
        onUndo: () => _replayLayerEdit(undo),
        onRedo: () => _replayLayerEdit(redo),
      ),
    );
    _changed();
  }

  void _replayLayerEdit(VoidCallback apply) {
    if (_isDisposed) return;
    apply();
    _changed();
  }

  /// Runs [body] without mirroring its ink commits: the caller records one
  /// command that covers them.
  void _quietly(VoidCallback body) {
    final wasApplying = _applyingLayerEdit;
    _applyingLayerEdit = true;
    try {
      body();
    } finally {
      _applyingLayerEdit = wasApplying;
    }
  }

  String _requireId(String id) {
    if (!_order.contains(id)) {
      throw ArgumentError.value(id, 'id', 'no such layer');
    }

    return id;
  }

  int _indexAbove(String? aboveId) =>
      aboveId == null ? _order.length : _order.indexOf(_requireId(aboveId)) + 1;

  void _insertLayer(
    NoteLayer layer,
    int index,
    Scribble? scribble,
    String label,
  ) {
    final previousActive = _activeId;
    _layers[layer.id] = layer;
    _notifiers[layer.id] = _newNotifier(scribble);
    void apply() {
      _order.insert(index, layer.id);
      _activeId = layer.id;
    }

    activeNotifier.releaseStalePointers();
    apply();
    _record(
      label,
      undo: () {
        _order.remove(layer.id);
        _activeId = previousActive;
      },
      redo: apply,
    );
  }

  void _replaceLayer(String label, NoteLayer next) {
    final previous = _layers[next.id]!;
    if (previous == next) return;
    _layers[next.id] = next;
    _record(
      label,
      undo: () => _layers[next.id] = previous,
      redo: () => _layers[next.id] = next,
    );
  }

  bool _merge(
    List<String> sources, {
    required String into,
    required String label,
  }) {
    final target = _notifiers[into]!;
    var merged = target.currentScribble;
    for (final id in sources) {
      final extra = _notifiers[id]!.currentScribble;
      merged = _append(
        merged,
        strokes: extra.strokes.where((s) => s.ink != InkModes.lasso),
        texts: extra.textDrawables,
        images: extra.imageDrawables,
      );
    }
    final positions = {for (final id in sources) id: _order.indexOf(id)};
    final previousActive = _activeId;
    void removeSources() {
      _order.removeWhere(sources.contains);
      if (sources.contains(previousActive)) _activeId = into;
    }

    _quietly(() => target.setScribble(scribble: merged));
    removeSources();
    _record(
      label,
      undo: () {
        _quietly(target.undo);
        final restore = positions.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        for (final entry in restore) {
          _order.insert(entry.value, entry.key);
        }
        _activeId = previousActive;
      },
      redo: () {
        _quietly(target.redo);
        removeSources();
      },
    );

    return true;
  }

  Scribble _append(
    Scribble base, {
    required Iterable<Stroke> strokes,
    required Iterable<TextDrawable> texts,
    required Iterable<ImageDrawable> images,
  }) => base.copyWithContents(
    strokes: [...base.strokes, ...strokes],
    textDrawables: [...base.textDrawables, ...texts],
    imageDrawables: [...base.imageDrawables, ...images],
  );
}
