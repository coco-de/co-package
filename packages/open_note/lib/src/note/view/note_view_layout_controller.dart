import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/view/note_drag_data.dart';
import 'package:open_note/src/note/view/note_view_notifier.dart';
import 'package:open_note/src/note/view/note_view_pane.dart';

/// How a note screen is divided.
enum NoteViewMode {
  /// One pane.
  single,

  /// A book spread: two panes of the same note showing consecutive pages
  /// (the second pane is always one page after the first).
  twoPage,

  /// Two panes of the same note, each on its own page.
  doubleReading,

  /// Two panes showing two documents; the second starts empty.
  dualDocument,

  /// A free split: any notes, and more than two panes if allowed.
  split,
}

/// The panes of a note screen, their arrangement and the divider position.
///
/// Invariants: there is always at least one pane; [NoteViewMode.single] has
/// exactly one; every other mode has at least two, at most two except in
/// [NoteViewMode.split] (up to [maxPanes]); [NoteViewMode.twoPage] panes share
/// a note and show consecutive pages; [NoteViewMode.doubleReading] panes share
/// a note; [ratio] stays within [minRatio]–[maxRatio].
///
/// JSON: `{mode, axis (horizontal|vertical), ratio, panes: [{id, noteId?,
/// pageIndex}]}`.
class NoteViewLayoutController extends NoteViewNotifier {
  /// Creates a layout; the given state is repaired to satisfy the invariants
  /// (a multi-pane [mode] given fewer than two panes becomes
  /// [NoteViewMode.single]). Without [panes] there is one pane with no note.
  NoteViewLayoutController({
    NoteViewMode mode = NoteViewMode.single,
    List<NoteViewPane> panes = const [],
    double ratio = defaultRatio,
    Axis axis = Axis.horizontal,
    NoteIdFactory idFactory = generateNoteId,
    int maxPanes = 2,
  }) : _idFactory = idFactory,
       maxPanes = maxPanes.clamp(2, paneLimit),
       _axis = axis,
       _ratio = _clampRatio(ratio, defaultRatio) {
    final state = _normalize(mode, panes);
    _mode = state.$1;
    _panes = state.$2;
  }

  /// Restores [toJson] output. Never throws: unknown mode or axis names fall
  /// back to single and horizontal, the ratio is clamped, unreadable panes are
  /// skipped, duplicate ids are replaced and the invariants are restored.
  factory NoteViewLayoutController.fromJson(
    Object? value, {
    NoteIdFactory idFactory = generateNoteId,
    int maxPanes = 2,
  }) {
    final map = NoteJson.asMap(value) ?? <String, Object?>{};
    final panes = [
      for (final entry in NoteJson.list(map, 'panes'))
        if (NoteViewPane.fromJson(entry) case final NoteViewPane pane) pane,
    ];

    return NoteViewLayoutController(
      mode: NoteJson.enumByName(
        NoteViewMode.values,
        map['mode'],
        NoteViewMode.single,
      ),
      axis: NoteJson.enumByName(Axis.values, map['axis'], Axis.horizontal),
      ratio: NoteJson.number(map, 'ratio', defaultRatio),
      panes: panes,
      idFactory: idFactory,
      maxPanes: maxPanes,
    );
  }

  /// Smallest share of the first pane.
  static const double minRatio = 0.2;

  /// Largest share of the first pane.
  static const double maxRatio = 0.8;

  /// Share of the first pane of a new layout.
  static const double defaultRatio = 0.5;

  /// Hard upper bound of [maxPanes].
  static const int paneLimit = 4;

  final NoteIdFactory _idFactory;

  /// Most panes this layout accepts, 2–[paneLimit] (default 2). More than two
  /// are possible only in [NoteViewMode.split].
  final int maxPanes;

  late NoteViewMode _mode;
  late List<NoteViewPane> _panes;
  Axis _axis;
  double _ratio;

  /// Current mode.
  NoteViewMode get mode => _mode;

  /// The panes in screen order (left to right, or top to bottom).
  List<NoteViewPane> get panes => List.unmodifiable(_panes);

  /// Share of the first pane along [axis]. With more than two panes the others
  /// split the rest equally.
  double get ratio => _ratio;

  /// [Axis.horizontal]: panes side by side; [Axis.vertical]: stacked.
  Axis get axis => _axis;

  /// The size share of every pane, in order; sums to 1.
  List<double> get fractions {
    final count = _panes.length;
    if (count < 2) return const [1];
    final rest = (1 - _ratio) / (count - 1);

    return [_ratio, for (var i = 1; i < count; i++) rest];
  }

  /// The pane with [id], or `null`.
  NoteViewPane? pane(String id) {
    final index = _indexOf(id);

    return index < 0 ? null : _panes[index];
  }

  /// Switches the mode. Leaving [NoteViewMode.single] adds a second pane: the
  /// same note one page later (twoPage), the same note and page
  /// (doubleReading, split) or an empty pane (dualDocument). Going back to
  /// single keeps [keepPaneId], else the first pane. Entering twoPage also
  /// lays the panes side by side; panes beyond what the mode allows are
  /// dropped.
  void setMode(NoteViewMode mode, {String? keepPaneId}) {
    if (isDisposed || mode == _mode) return;
    final List<NoteViewPane> next;
    if (mode == NoteViewMode.single) {
      final keep = keepPaneId == null ? null : pane(keepPaneId);
      next = [keep ?? _panes.first];
    } else {
      next = [..._panes, if (_panes.length < 2) _companion(mode, _panes.first)];
    }
    final state = _normalize(mode, next);
    _commit(
      mode: state.$1,
      panes: state.$2,
      axis: mode == NoteViewMode.twoPage ? Axis.horizontal : _axis,
    );
  }

  /// Adds a pane at [index] (default: the end) and returns it. Adding turns the
  /// layout into [NoteViewMode.split]. Returns `null` (nothing changes) when
  /// [maxPanes] panes exist. A pane without [noteId] is empty.
  NoteViewPane? addPane({String? noteId, int pageIndex = 0, int? index}) {
    if (isDisposed || _panes.length >= maxPanes) return null;
    final added = _newPane(noteId, pageIndex);
    final next = [..._panes];
    next.insert((index ?? next.length).clamp(0, next.length), added);
    _commit(mode: NoteViewMode.split, panes: next);

    return added;
  }

  /// Removes the pane [paneId]; when one pane is left the mode becomes single.
  /// Returns `false` for an unknown id or the last remaining pane.
  bool removePane(String paneId) {
    final index = _indexOf(paneId);
    if (isDisposed || index < 0 || _panes.length < 2) return false;
    final next = [..._panes]..removeAt(index);
    _commit(mode: next.length < 2 ? NoteViewMode.single : _mode, panes: next);

    return true;
  }

  /// Shows page [pageIndex] (negative becomes 0) in pane [paneId]. In twoPage
  /// mode the other pane follows so the two stay consecutive (turning the
  /// second pane to page 0 shows pages 0 and 1).
  void setPage(String paneId, int pageIndex) {
    final index = _indexOf(paneId);
    if (isDisposed || index < 0) return;
    final page = math.max(pageIndex, 0);
    if (_mode == NoteViewMode.twoPage) {
      final first = index == 0 ? page : math.max(page - 1, 0);

      _commit(
        panes: [
          _panes[0].copyWith(pageIndex: first),
          _panes[1].copyWith(pageIndex: first + 1),
        ],
      );

      return;
    }
    final next = [..._panes];
    next[index] = next[index].copyWith(pageIndex: page);
    _commit(panes: next);
  }

  /// Puts [noteId] (`null`: none) on pane [paneId] at [pageIndex]. In twoPage
  /// and doubleReading both panes show one note, so both change.
  void setNote(String paneId, String? noteId, {int pageIndex = 0}) {
    final index = _indexOf(paneId);
    if (isDisposed || index < 0) return;
    final page = math.max(pageIndex, 0);
    NoteViewPane assign(NoteViewPane pane, int page) =>
        NoteViewPane(id: pane.id, noteId: noteId, pageIndex: page);
    final next = [..._panes];
    if (_mode == NoteViewMode.twoPage) {
      final first = index == 0 ? page : math.max(page - 1, 0);
      next[0] = assign(next[0], first);
      next[1] = assign(next[1], first + 1);
    } else if (_mode == NoteViewMode.doubleReading) {
      next[0] = assign(next[0], page);
      next[1] = assign(next[1], page);
    } else {
      next[index] = assign(next[index], page);
    }
    _commit(panes: next);
  }

  /// Exchanges two panes (by default the first two). Does nothing in twoPage,
  /// where the page order fixes the sides.
  void swapPanes([String? firstId, String? secondId]) {
    if (isDisposed || _panes.length < 2 || _mode == NoteViewMode.twoPage) {
      return;
    }
    final first = firstId == null ? 0 : _indexOf(firstId);
    final second = secondId == null ? 1 : _indexOf(secondId);
    if (first < 0 || second < 0 || first == second) return;
    final next = [..._panes];
    next[first] = _panes[second];
    next[second] = _panes[first];
    _commit(panes: next);
  }

  /// Opens [noteId] on the [side] of the view — what dropping a note on that
  /// edge does. The axis follows the side and a left or top drop puts the new
  /// pane first. While there is room the pane is added and the mode becomes
  /// split; at [maxPanes] the pane on that side is replaced instead (a
  /// dualDocument layout stays dualDocument). Returns the new pane, or `null`
  /// after dispose.
  NoteViewPane? openBeside(
    String noteId,
    int pageIndex, {
    NoteDropSide side = NoteDropSide.right,
  }) {
    if (isDisposed) return null;
    final added = _newPane(noteId, pageIndex);
    final next = [..._panes];
    final NoteViewMode mode;
    if (next.length < maxPanes) {
      next.insert(side.isLeading ? 0 : next.length, added);
      mode = NoteViewMode.split;
    } else {
      next[side.isLeading ? 0 : next.length - 1] = added;
      mode = _mode == NoteViewMode.dualDocument
          ? NoteViewMode.dualDocument
          : NoteViewMode.split;
    }
    _commit(mode: mode, panes: next, axis: side.axis);

    return added;
  }

  /// Moves the divider so the first pane takes [ratio], clamped to
  /// [minRatio]–[maxRatio]. Non-finite values are ignored.
  void setRatio(double ratio) {
    if (isDisposed) return;
    _commit(ratio: _clampRatio(ratio, _ratio));
  }

  /// Lays the panes side by side or stacked.
  void setAxis(Axis axis) {
    if (isDisposed) return;
    _commit(axis: axis);
  }

  /// The persisted form (see the class comment).
  JsonMap toJson() => {
    'mode': _mode.name,
    'axis': _axis.name,
    'ratio': _ratio,
    'panes': [for (final pane in _panes) pane.toJson()],
  };

  static double _clampRatio(double ratio, double fallback) =>
      ratio.isFinite ? ratio.clamp(minRatio, maxRatio) : fallback;

  int _indexOf(String id) => _panes.indexWhere((pane) => pane.id == id);

  NoteViewPane _newPane(String? noteId, int pageIndex) => NoteViewPane(
    id: _idFactory(),
    noteId: noteId,
    pageIndex: math.max(pageIndex, 0),
  );

  NoteViewPane _companion(NoteViewMode mode, NoteViewPane first) =>
      switch (mode) {
        NoteViewMode.twoPage => _newPane(first.noteId, first.pageIndex + 1),
        NoteViewMode.dualDocument => _newPane(null, 0),
        _ => _newPane(first.noteId, first.pageIndex),
      };

  (NoteViewMode, List<NoteViewPane>) _normalize(
    NoteViewMode mode,
    List<NoteViewPane> panes,
  ) {
    final unique = _withUniqueIds(panes);
    if (unique.isEmpty) unique.add(_newPane(null, 0));
    if (mode == NoteViewMode.single || unique.length < 2) {
      return (NoteViewMode.single, [unique.first]);
    }
    final limit = mode == NoteViewMode.split ? maxPanes : 2;
    final result = unique.take(limit).toList();
    if (mode == NoteViewMode.twoPage) {
      result[1] = NoteViewPane(
        id: result[1].id,
        noteId: result[0].noteId,
        pageIndex: result[0].pageIndex + 1,
      );
    } else if (mode == NoteViewMode.doubleReading) {
      result[1] = NoteViewPane(
        id: result[1].id,
        noteId: result[0].noteId,
        pageIndex: result[1].pageIndex,
      );
    }

    return (mode, result);
  }

  List<NoteViewPane> _withUniqueIds(List<NoteViewPane> panes) {
    final seen = <String>{};

    return [
      for (final pane in panes)
        seen.add(pane.id) ? pane : pane.copyWith(id: _idFactory()),
    ];
  }

  void _commit({
    NoteViewMode? mode,
    List<NoteViewPane>? panes,
    Axis? axis,
    double? ratio,
  }) {
    final changed =
        (mode != null && mode != _mode) ||
        (panes != null && !listEquals(panes, _panes)) ||
        (axis != null && axis != _axis) ||
        (ratio != null && ratio != _ratio);
    if (!changed) return;
    _mode = mode ?? _mode;
    _panes = panes ?? _panes;
    _axis = axis ?? _axis;
    _ratio = ratio ?? _ratio;
    notifyChanged();
  }
}
