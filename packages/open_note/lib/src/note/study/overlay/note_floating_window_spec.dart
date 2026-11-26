import 'package:flutter/widgets.dart';

/// Describes a floating tool window: a browser, a chat, a reference sheet…
/// The package provides the window; [builder] provides the content.
@immutable
class NoteFloatingWindowSpec {
  /// Creates a spec. [id] must be unique among open windows and [minSize]
  /// positive.
  const NoteFloatingWindowSpec({
    required this.id,
    required this.title,
    required this.builder,
    this.initialRect = defaultRect,
    this.minSize = defaultMinSize,
    this.resizable = true,
    this.opacity = 1,
  }) : assert(id != '', 'id must not be empty');

  /// Default [initialRect].
  static const Rect defaultRect = Rect.fromLTWH(24, 24, 320, 400);

  /// Default [minSize].
  static const Size defaultMinSize = Size(200, 160);

  /// Identifies the window; opening the same id again reuses it.
  final String id;

  /// Shown in the title bar.
  final String title;

  /// Builds the body, below the title bar.
  final WidgetBuilder builder;

  /// Where the window first appears, in the host's coordinates (grown to
  /// [minSize] if smaller).
  final Rect initialRect;

  /// Smallest size, including the title bar. A smaller host limits it, and the
  /// host never draws a window narrower than its title bar buttons need.
  final Size minSize;

  /// Whether the user can resize it from its bottom-right corner.
  final bool resizable;

  /// Initial opacity (clamped like [NoteFloatingWindowController.setOpacity]).
  final double opacity;

  /// A copy with the given fields replaced; the [id] stays.
  NoteFloatingWindowSpec copyWith({
    String? title,
    WidgetBuilder? builder,
    Rect? initialRect,
    Size? minSize,
    bool? resizable,
    double? opacity,
  }) => NoteFloatingWindowSpec(
    id: id,
    title: title ?? this.title,
    builder: builder ?? this.builder,
    initialRect: initialRect ?? this.initialRect,
    minSize: minSize ?? this.minSize,
    resizable: resizable ?? this.resizable,
    opacity: opacity ?? this.opacity,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteFloatingWindowSpec &&
      other.id == id &&
      other.title == title &&
      other.builder == builder &&
      other.initialRect == initialRect &&
      other.minSize == minSize &&
      other.resizable == resizable &&
      other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(id, title, builder, initialRect, minSize, resizable, opacity);

  @override
  String toString() => 'NoteFloatingWindowSpec($id, $title)';
}
