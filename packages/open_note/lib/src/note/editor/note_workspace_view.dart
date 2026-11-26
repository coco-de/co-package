import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/editor/internal/note_editor_button.dart';
import 'package:open_note/src/note/editor/note_editor_controller.dart';
import 'package:open_note/src/note/editor/note_editor_style.dart';
import 'package:open_note/src/note/editor/note_editor_view.dart';
import 'package:open_note/src/note/editor/note_workspace_controller.dart';
import 'package:open_note/src/note/editor/note_workspace_strings.dart';
import 'package:open_note/src/note/view/note_resizable_panes.dart';
import 'package:open_note/src/note/view/note_tab.dart';
import 'package:open_note/src/note/view/note_tab_bar.dart';
import 'package:open_note/src/note/view/note_view_layout_controller.dart';
import 'package:open_note/src/note/view/note_view_pane.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// A [NoteWorkspaceController] on screen: the tabs of open notes, a layout
/// menu and the panes, each an editor.
class NoteWorkspaceView extends StatefulWidget {
  const NoteWorkspaceView({
    required this.controller,
    this.paneBuilder,
    this.onPickNote,
    this.strings = const NoteWorkspaceStrings(),
    this.style = const NoteEditorStyle(),
    this.viewStrings = const NoteViewStrings(),
    this.viewStyle = const NoteViewStyle(),
    super.key,
  });

  final NoteWorkspaceController controller;

  /// Builds a pane's editor; a plain [NoteEditorView] when null. Use it to
  /// pass your services (stickers, pictures, export…) to every pane.
  final Widget Function(
    BuildContext context,
    NoteEditorController editor,
    String paneId,
  )?
  paneBuilder;

  /// Lets the user choose a note (its id and tab title). Without it only open
  /// tabs can be put on a pane.
  final Future<NoteTab?> Function()? onPickNote;

  final NoteWorkspaceStrings strings;
  final NoteEditorStyle style;
  final NoteViewStrings viewStrings;
  final NoteViewStyle viewStyle;

  @override
  State<NoteWorkspaceView> createState() => _NoteWorkspaceViewState();
}

class _NoteWorkspaceViewState extends State<NoteWorkspaceView> {
  /// Keeps a pane's editor view while the panes around it change.
  final Map<(String, String?), GlobalKey> _paneKeys = {};
  final Map<String, FocusScopeNode> _scopes = {};
  bool _isLayoutMenuOpen = false;

  NoteWorkspaceController get _workspace => widget.controller;

  NoteViewLayoutController get _layout => _workspace.layout;

  NoteWorkspaceStrings get _strings => widget.strings;

  @override
  void dispose() {
    for (final scope in _scopes.values) {
      scope.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: widget.style.textStyle,
    child: ListenableBuilder(
      listenable: Listenable.merge([_workspace, _layout, _workspace.tabs]),
      builder: (context, _) => ColoredBox(
        color: widget.style.barColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(),
            if (_isLayoutMenuOpen) _layoutMenu(),
            Expanded(child: _panes()),
          ],
        ),
      ),
    ),
  );

  Widget _button(
    String key,
    String label, {
    VoidCallback? onPressed,
    bool selected = false,
  }) => NoteEditorButton(
    key: ValueKey('note-workspace-$key'),
    label: label,
    style: widget.style,
    selected: selected,
    onPressed: onPressed,
  );

  Widget _bar() => Row(
    children: [
      Expanded(
        child: NoteTabBar(
          controller: _workspace.tabs,
          onSelected: _workspace.open,
          onCloseRequested: _workspace.closeTab,
          style: widget.viewStyle,
          strings: widget.viewStrings,
        ),
      ),
      if (widget.onPickNote != null)
        _button(
          'open',
          _strings.openNote,
          onPressed: () => unawaited(_pickNote()),
        ),
      _button(
        'layout',
        _strings.layout,
        selected: _isLayoutMenuOpen,
        onPressed: () => setState(() => _isLayoutMenuOpen = !_isLayoutMenuOpen),
      ),
    ],
  );

  Widget _layoutMenu() {
    final mode = _layout.mode;
    final several = _layout.panes.length > 1;
    final canTurn = several && mode != NoteViewMode.twoPage;

    return Padding(
      padding: EdgeInsets.all(widget.style.spacing),
      child: Wrap(
        spacing: widget.style.spacing,
        runSpacing: widget.style.spacing,
        children: [
          for (final option in NoteViewMode.values)
            _button(
              'mode-${option.name}',
              switch (option) {
                NoteViewMode.single => _strings.single,
                NoteViewMode.twoPage => _strings.twoPage,
                NoteViewMode.doubleReading => _strings.doubleReading,
                NoteViewMode.dualDocument => _strings.dualDocument,
                NoteViewMode.split => _strings.split,
              },
              selected: option == mode,
              onPressed: () => _workspace.setMode(option),
            ),
          for (final axis in Axis.values)
            _button(
              'axis-${axis.name}',
              axis == Axis.horizontal ? _strings.sideBySide : _strings.stacked,
              selected: several && _layout.axis == axis,
              onPressed: canTurn ? () => _layout.setAxis(axis) : null,
            ),
          _button(
            'swap',
            _strings.swapPanes,
            onPressed: canTurn ? _layout.swapPanes : null,
          ),
          _button(
            'close-pane',
            _strings.closePane,
            onPressed: several
                ? () => _workspace.closePane(_workspace.focusedPaneId)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _panes() {
    final panes = _layout.panes;
    final several = panes.length > 1;
    final children = [for (final pane in panes) _pane(pane, several: several)];
    if (!several) return children.single;

    return NoteResizablePanes(
      axis: _layout.axis,
      fractions: panes.length == 2 ? _layout.fractions : null,
      initialFractions: _layout.fractions,
      minFraction: NoteViewLayoutController.minRatio,
      onFractionsChanged: (fractions) => _layout.setRatio(fractions.first),
      style: widget.viewStyle,
      strings: widget.viewStrings,
      children: children,
    );
  }

  Widget _pane(NoteViewPane pane, {required bool several}) {
    final focused = pane.id == _workspace.focusedPaneId;

    return KeyedSubtree(
      key: _paneKeys.putIfAbsent((pane.id, pane.noteId), GlobalKey.new),
      child: FocusScope(
        node: _scopes.putIfAbsent(pane.id, FocusScopeNode.new),
        child: DecoratedBox(
          key: ValueKey('note-workspace-pane-${pane.id}'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: several && focused
                ? Border.all(color: widget.style.accentColor, width: 2)
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _content(pane),
              if (several && !focused)
                _workspace.needsFocusFirst(pane.id)
                    ? _followingCover(pane.id)
                    // Takes the focus and lets the input through.
                    : Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) => _focus(pane.id),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  /// Covers a pane that follows the focused one: the first tap only focuses.
  Widget _followingCover(String paneId) => Listener(
    key: ValueKey('note-workspace-follow-$paneId'),
    behavior: HitTestBehavior.opaque,
    onPointerDown: (_) => _focus(paneId),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.style.tooltipColor,
            borderRadius: BorderRadius.circular(widget.style.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              _strings.tapToEdit,
              style: widget.style.textStyle.copyWith(
                color: widget.style.tooltipTextColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _focus(String paneId) {
    _workspace.focus(paneId);
    // Leaves the other pane's text field; keys now go to this pane.
    _scopes[paneId]?.requestFocus();
  }

  Widget _content(NoteViewPane pane) {
    final status = _workspace.statusOf(pane.id);
    final editor = _workspace.editorOf(pane.id);

    return switch (status) {
      NoteWorkspacePaneStatus.ready when editor != null =>
        widget.paneBuilder?.call(context, editor, pane.id) ??
            NoteEditorView(controller: editor, style: widget.style),
      NoteWorkspacePaneStatus.ready ||
      NoteWorkspacePaneStatus.loading => _message(_strings.opening),
      NoteWorkspacePaneStatus.empty => _chooser(pane.id),
      NoteWorkspacePaneStatus.failed => _message(_strings.openFailed, [
        _button(
          'retry-${pane.id}',
          _strings.retry,
          onPressed: () => _workspace.retry(pane.id),
        ),
      ]),
      NoteWorkspacePaneStatus.missing => _message(_strings.missingNote, [
        _button(
          'close-note-${pane.id}',
          _strings.closeNote,
          onPressed: () => _workspace.closeTab(pane.noteId!),
        ),
      ]),
      NoteWorkspacePaneStatus.pastEnd => _message(_strings.noNextPage, [
        _button(
          'add-page',
          _strings.addPage,
          onPressed: () => _workspace.addPageTo(pane.id),
        ),
      ]),
    };
  }

  /// An empty pane: open tabs that no pane shows, or another note.
  Widget _chooser(String paneId) {
    final shown = {for (final pane in _layout.panes) pane.noteId};

    return _message(_strings.chooseNote, [
      for (final tab in _workspace.tabs.tabs)
        if (!shown.contains(tab.noteId))
          _button(
            'pick-${tab.noteId}',
            tab.title.isEmpty ? widget.viewStrings.untitled : tab.title,
            onPressed: () => _workspace.open(tab.noteId, paneId: paneId),
          ),
      if (widget.onPickNote != null)
        _button(
          'pick-other-$paneId',
          _strings.openNote,
          onPressed: () => unawaited(_pickNote(paneId)),
        ),
    ]);
  }

  Widget _message(String text, [List<Widget> actions = const []]) => ColoredBox(
    color: widget.style.canvasColor,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: widget.style.spacing,
                runSpacing: widget.style.spacing,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Future<void> _pickNote([String? paneId]) async {
    try {
      final note = await widget.onPickNote?.call();
      if (!mounted || note == null) return;
      _workspace.open(note.noteId, title: note.title, paneId: paneId);
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'open_note',
          context: ErrorDescription('while choosing a note'),
        ),
      );
    }
  }
}
