import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/study/overlay/note_floating_window_spec.dart';

/// The state of one open floating window.
@immutable
class NoteFloatingWindow {
  /// Creates a window state.
  const NoteFloatingWindow({
    required this.spec,
    required this.rect,
    this.opacity = 1,
    this.pinned = false,
    this.minimized = false,
  });

  /// What the window is.
  final NoteFloatingWindowSpec spec;

  /// Position and full size in host coordinates. A minimized window keeps its
  /// full size here. The host may draw it elsewhere to keep it on screen.
  final Rect rect;

  /// Opacity of the whole window.
  final double opacity;

  /// Whether the window stays above unpinned windows.
  final bool pinned;

  /// Whether only the title bar shows.
  final bool minimized;

  /// The spec's id.
  String get id => spec.id;

  /// A copy with the given fields replaced.
  NoteFloatingWindow copyWith({
    NoteFloatingWindowSpec? spec,
    Rect? rect,
    double? opacity,
    bool? pinned,
    bool? minimized,
  }) => NoteFloatingWindow(
    spec: spec ?? this.spec,
    rect: rect ?? this.rect,
    opacity: opacity ?? this.opacity,
    pinned: pinned ?? this.pinned,
    minimized: minimized ?? this.minimized,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteFloatingWindow &&
      other.spec == spec &&
      other.rect == rect &&
      other.opacity == opacity &&
      other.pinned == pinned &&
      other.minimized == minimized;

  @override
  int get hashCode => Object.hash(spec, rect, opacity, pinned, minimized);

  @override
  String toString() =>
      'NoteFloatingWindow($id, $rect, pinned: $pinned, '
      'minimized: $minimized)';
}
