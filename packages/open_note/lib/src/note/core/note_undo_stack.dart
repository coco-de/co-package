import 'package:flutter/foundation.dart';

/// One reversible edit performed by a note-level controller (objects, page
/// operations, layer operations…). The engine's per-layer ink history is wrapped
/// in a command too, so one [NoteUndoStack] orders every edit chronologically.
abstract interface class NoteUndoable {
  /// Short human-readable description (for an "Undo <label>" affordance).
  String get label;

  /// Reverts the edit.
  void undo();

  /// Re-applies the edit after an [undo].
  void redo();
}

/// A [NoteUndoable] built from two callbacks.
class NoteCallbackUndoable implements NoteUndoable {
  const NoteCallbackUndoable({
    required this.label,
    required VoidCallback onUndo,
    required VoidCallback onRedo,
  }) : _onUndo = onUndo,
       _onRedo = onRedo;

  @override
  final String label;

  final VoidCallback _onUndo;
  final VoidCallback _onRedo;

  @override
  void undo() => _onUndo();

  @override
  void redo() => _onRedo();
}

/// A linear undo/redo history of [NoteUndoable] commands.
///
/// Commands pushed while [isApplying] (an undo/redo is running) are ignored.
/// That is what lets a controller register a listener that pushes a command on
/// every change without recording the change that the undo itself produces.
class NoteUndoStack extends ChangeNotifier {
  NoteUndoStack({this.maxLength = 200}) : assert(maxLength > 0);

  /// Oldest commands are dropped beyond this many.
  final int maxLength;

  final List<NoteUndoable> _undoable = [];
  final List<NoteUndoable> _redoable = [];
  List<NoteUndoable>? _grouped;
  int _pushCount = 0;
  bool _applying = false;

  bool get canUndo => _undoable.isNotEmpty;

  bool get canRedo => _redoable.isNotEmpty;

  int get undoLength => _undoable.length;

  int get redoLength => _redoable.length;

  /// How many commands were ever recorded. Undo and redo leave it alone, so a
  /// change means something new was done.
  int get pushCount => _pushCount;

  /// Whether [group] or [amend] is collecting commands.
  bool get isGrouping => _grouped != null;

  /// Label of the command [undo] would revert.
  String? get undoLabel => _undoable.isEmpty ? null : _undoable.last.label;

  /// Label of the command [redo] would re-apply.
  String? get redoLabel => _redoable.isEmpty ? null : _redoable.last.label;

  /// Whether an undo or redo is currently running.
  bool get isApplying => _applying;

  /// Records [command] as the newest edit and clears the redo history.
  void push(NoteUndoable command) {
    if (_applying) return;
    final grouped = _grouped;
    if (grouped != null) {
      grouped.add(command);

      return;
    }
    _pushCount++;
    _undoable.add(command);
    _redoable.clear();
    if (_undoable.length > maxLength) {
      _undoable.removeRange(0, _undoable.length - maxLength);
    }
    notifyListeners();
  }

  /// Runs [body] and records everything it pushes as one command named
  /// [label]. Inside another group, the commands join that group.
  T group<T>(String label, T Function() body) =>
      _collect(body, (commands) => push(_NoteUndoGroup(label, commands)));

  /// Runs [body] and joins what it pushes to the newest command, so one undo
  /// reverts both (a page growing under the stroke that made it grow). Without
  /// a command to join, what [body] pushes is recorded as one.
  T amend<T>(T Function() body) => _collect(body, (commands) {
    if (_undoable.isEmpty) {
      push(_NoteUndoGroup(commands.first.label, commands));

      return;
    }
    final newest = _undoable.removeLast();
    push(_NoteUndoGroup(newest.label, [newest, ...commands]));
  });

  /// Reverts the newest edit. Returns whether anything was undone.
  bool undo() {
    if (_undoable.isEmpty || _applying) return false;
    final command = _undoable.removeLast();
    _run(command.undo);
    _redoable.add(command);
    notifyListeners();

    return true;
  }

  /// Re-applies the most recently undone edit. Returns whether anything ran.
  bool redo() {
    if (_redoable.isEmpty || _applying) return false;
    final command = _redoable.removeLast();
    _run(command.redo);
    _undoable.add(command);
    notifyListeners();

    return true;
  }

  /// Forgets all history.
  void clear() {
    if (_undoable.isEmpty && _redoable.isEmpty) return;
    _undoable.clear();
    _redoable.clear();
    notifyListeners();
  }

  T _collect<T>(
    T Function() body,
    void Function(List<NoteUndoable> commands) record,
  ) {
    if (_grouped != null || _applying) return body();
    final commands = <NoteUndoable>[];
    _grouped = commands;
    try {
      return body();
    } finally {
      // What was applied stays recorded even if [body] threw part way.
      _grouped = null;
      if (commands.isNotEmpty) record(commands);
    }
  }

  void _run(VoidCallback body) {
    _applying = true;
    try {
      body();
    } finally {
      _applying = false;
    }
  }
}

class _NoteUndoGroup implements NoteUndoable {
  _NoteUndoGroup(this.label, this._commands);

  @override
  final String label;

  final List<NoteUndoable> _commands;

  @override
  void undo() {
    for (final command in _commands.reversed) {
      command.undo();
    }
  }

  @override
  void redo() {
    for (final command in _commands) {
      command.redo();
    }
  }
}
