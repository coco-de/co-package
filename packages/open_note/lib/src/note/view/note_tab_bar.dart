import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/view/note_drag_data.dart';
import 'package:open_note/src/note/view/note_tab.dart';
import 'package:open_note/src/note/view/note_tab_chip.dart';
import 'package:open_note/src/note/view/note_tabs_controller.dart';
import 'package:open_note/src/note/view/note_view_strings.dart';
import 'package:open_note/src/note/view/note_view_style.dart';

/// A horizontally scrolling strip of the open notes.
///
/// Tap selects, the × closes and a long press picks a tab up to reorder it.
/// The picked-up tab carries a [NoteDragData], so it can also be dropped on a
/// `NoteDropSplitTarget` to open the note beside. The active tab is scrolled
/// into view when it changes.
class NoteTabBar extends StatefulWidget {
  /// The tab strip of [controller].
  const NoteTabBar({
    required this.controller,
    super.key,
    this.onSelected,
    this.onCloseRequested,
    this.trailing,
    this.height = 40,
    this.maxTabWidth = 200,
    this.reorderable = true,
    this.dragDelay = const Duration(milliseconds: 300),
    this.style = const NoteViewStyle(),
    this.strings = const NoteViewStrings(),
  }) : assert(height > 0),
       assert(maxTabWidth >= 80);

  /// Key of the tab of [noteId].
  static Key tabKey(String noteId) => ValueKey<String>('note-tab-$noteId');

  /// Key of the close button of the tab of [noteId].
  static Key closeKey(String noteId) =>
      ValueKey<String>('note-tab-close-$noteId');

  /// The open notes and the active one.
  final NoteTabsController controller;

  /// A tab was tapped (the controller has already focused it).
  final ValueChanged<String>? onSelected;

  /// Replaces the default close: when given, the × only calls this (for
  /// example to save first) and the host calls `controller.close`.
  final ValueChanged<String>? onCloseRequested;

  /// Widget after the tabs, such as a "new tab" button.
  final Widget? trailing;

  /// Height of the strip.
  final double height;

  /// Widest a tab may grow; longer titles are cut off.
  final double maxTabWidth;

  /// Whether tabs can be picked up.
  final bool reorderable;

  /// How long a press picks a tab up.
  final Duration dragDelay;

  /// Colours; see [NoteViewStyle].
  final NoteViewStyle style;

  /// Visible and accessibility text.
  final NoteViewStrings strings;

  @override
  State<NoteTabBar> createState() => _NoteTabBarState();
}

class _NoteTabBarState extends State<NoteTabBar> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _revealKeys = {};
  String? _revealed;

  NoteTabsController get _tabs => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String noteId) {
    _tabs.activate(noteId);
    widget.onSelected?.call(noteId);
  }

  void _close(String noteId) {
    final request = widget.onCloseRequested;
    if (request == null) {
      _tabs.close(noteId);
    } else {
      request(noteId);
    }
  }

  /// Drops the tab of [movedId] on the one of [targetId], taking its place.
  void _reorder(String movedId, String targetId) {
    final from = _tabs.indexOf(movedId);
    final to = _tabs.indexOf(targetId);
    if (from >= 0 && to >= 0) _tabs.move(from, to);
  }

  void _scheduleReveal() {
    final active = _tabs.activeId;
    if (active == _revealed) return;
    _revealed = active;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(active));
  }

  void _reveal(String? noteId) {
    if (!mounted || noteId == null || !_scroll.hasClients) return;
    final target = _revealKeys[noteId]?.currentContext?.findRenderObject();
    if (target == null) return;
    _scroll.position
      ..ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      )
      ..ensureVisible(
        target,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tabs,
      builder: (context, _) {
        _scheduleReveal();
        _revealKeys.removeWhere((noteId, _) => !_tabs.contains(noteId));

        return SizedBox(
          height: widget.height,
          child: ColoredBox(
            color: widget.style.barColor,
            child: Row(
              children: [
                Expanded(child: _buildStrip()),
                ?widget.trailing,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStrip() {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (final tab in _tabs.tabs) _buildTab(tab)]),
    );
  }

  Widget _buildTab(NoteTab tab) {
    return KeyedSubtree(
      key: _revealKeys.putIfAbsent(tab.noteId, GlobalKey.new),
      child: KeyedSubtree(
        key: NoteTabBar.tabKey(tab.noteId),
        child: widget.reorderable ? _buildDraggable(tab) : _buildChip(tab),
      ),
    );
  }

  Widget _buildChip(NoteTab tab, {bool keyed = true}) {
    return NoteTabChip(
      title: tab.title,
      active: tab.noteId == _tabs.activeId,
      height: widget.height,
      maxWidth: widget.maxTabWidth,
      onTap: () => _select(tab.noteId),
      onClose: () => _close(tab.noteId),
      closeButtonKey: keyed ? NoteTabBar.closeKey(tab.noteId) : null,
      style: widget.style,
      strings: widget.strings,
    );
  }

  Widget _buildDraggable(NoteTab tab) {
    return DragTarget<NoteDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.noteId != tab.noteId &&
          _tabs.contains(details.data.noteId),
      onAcceptWithDetails: (details) =>
          _reorder(details.data.noteId, tab.noteId),
      builder: (context, candidates, rejected) {
        final chip = _buildChip(tab);

        return LongPressDraggable<NoteDragData>(
          data: NoteDragData(noteId: tab.noteId),
          delay: widget.dragDelay,
          feedback: Opacity(
            opacity: 0.85,
            child: _buildChip(tab, keyed: false),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: chip),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: candidates.isEmpty
                  ? null
                  : Border.all(color: widget.style.accentColor, width: 2),
            ),
            child: chip,
          ),
        );
      },
    );
  }
}
