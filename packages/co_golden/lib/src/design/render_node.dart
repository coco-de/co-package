import 'package:meta/meta.dart';

import 'color.dart';
import 'geometry.dart';

/// Where a widget was created in source code.
@immutable
final class GoldenSourceLocation {
  /// Creates a location.
  const GoldenSourceLocation({
    required this.file,
    required this.line,
    required this.column,
    this.package,
    this.project = false,
  });

  /// Path relative to the tested package (`lib/src/login_page.dart`), or a
  /// `package:` URI for dependencies.
  final String file;

  /// 1-based line.
  final int line;

  /// 1-based column.
  final int column;

  /// Name of the package that contains the file, when known.
  final String? package;

  /// Whether the file belongs to the project (a path package such as the app
  /// or a workspace member) rather than to a hosted, git, or SDK package.
  final bool project;

  /// `file:line:column`.
  String get label => '$file:$line:$column';

  /// JSON form: the label string.
  String toJson() => label;

  @override
  bool operator ==(Object other) =>
      other is GoldenSourceLocation &&
      other.file == file &&
      other.line == line &&
      other.column == column;

  @override
  int get hashCode => Object.hash(file, line, column);

  @override
  String toString() => label;
}

/// Typography of rendered text, after inheritance and defaults.
@immutable
final class GoldenRenderTextStyle {
  /// Creates a style.
  const GoldenRenderTextStyle({
    required this.fontSize,
    required this.fontWeight,
    this.fontFamily,
    this.fontFamilyFallback = const [],
    this.italic = false,
    this.height,
    this.letterSpacing = 0,
    this.color,
    this.decoration,
  });

  /// Family as resolved for painting, without a `packages/<name>/` prefix.
  final String? fontFamily;

  /// Fallback families.
  final List<String> fontFamilyFallback;

  /// Font size in logical pixels, before the text scaler.
  final double fontSize;

  /// Numeric weight from 100 to 900.
  final int fontWeight;

  /// Whether the style is italic.
  final bool italic;

  /// Line height as a multiple of [fontSize]; `null` is the font's natural
  /// line height.
  final double? height;

  /// Letter spacing in logical pixels.
  final double letterSpacing;

  /// Text color `0xAARRGGBB`, when a plain color paints the text.
  final int? color;

  /// `underline`, `lineThrough`, `overline`, or `null` for none.
  final String? decoration;

  /// Line height in logical pixels when [height] is set.
  double? get lineHeight => height == null ? null : height! * fontSize;

  /// JSON form.
  Map<String, Object?> toJson() => {
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontFamilyFallback.isNotEmpty) 'fontFamilyFallback': fontFamilyFallback,
    'fontSize': goldenRound(fontSize),
    'fontWeight': fontWeight,
    if (italic) 'italic': true,
    'lineHeight': lineHeight == null ? 'auto' : goldenRound(lineHeight!),
    if (height != null) 'height': goldenRound(height!, 3),
    'letterSpacing': goldenRound(letterSpacing, 3),
    if (color != null) 'color': GoldenColorMath.hexArgb(color!),
    if (decoration != null) 'decoration': decoration,
  };
}

/// A character range of rendered text with its own style.
@immutable
final class GoldenRenderTextRun {
  /// Creates a run over UTF-16 offsets.
  const GoldenRenderTextRun(this.start, this.end, this.style);

  /// First UTF-16 offset.
  final int start;

  /// UTF-16 offset after the run.
  final int end;

  /// Style of the run.
  final GoldenRenderTextStyle style;
}

/// Rendered text and how it was laid out.
@immutable
final class GoldenRenderText {
  /// Creates text data.
  const GoldenRenderText({
    required this.text,
    required this.style,
    required this.contentRect,
    this.runs = const [],
    this.align = 'left',
    this.lineCount = 1,
    this.truncated = false,
    this.maxLines,
    this.textScale = 1,
    this.editable = false,
  });

  /// Plain text, placeholders removed.
  final String text;

  /// Style that covers most characters.
  final GoldenRenderTextStyle style;

  /// Runs, in order, when more than one style is used.
  final List<GoldenRenderTextRun> runs;

  /// `left`, `center`, `right`, or `justify`, resolved for the direction.
  final String align;

  /// Laid out line count.
  final int lineCount;

  /// Whether the text exceeded its maximum lines (ellipsis or clipping).
  final bool truncated;

  /// Maximum lines, when limited.
  final int? maxLines;

  /// Text scale factor applied to [style] font sizes.
  final double textScale;

  /// Whether the text is the content of an editable field.
  final bool editable;

  /// Union of the line boxes in logical pixels — the text itself, without the
  /// paragraph's free space.
  final GoldenRect contentRect;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'text': text,
    ...style.toJson(),
    'align': align,
    'lines': lineCount,
    if (truncated) 'truncated': true,
    if (maxLines != null) 'maxLines': maxLines,
    if (textScale != 1) 'textScale': goldenRound(textScale, 3),
    if (editable) 'editable': true,
    'content': contentRect.toJson(),
    if (runs.length > 1)
      'runs': [
        for (final run in runs)
          {'start': run.start, 'end': run.end, ...run.style.toJson()},
      ],
  };
}

/// Paint of a rendered box: fill, border, radius, shadow.
@immutable
final class GoldenRenderBox {
  /// Creates box data.
  const GoldenRenderBox({
    this.color,
    this.gradient = false,
    this.image = false,
    this.radii,
    this.circle = false,
    this.borderWidth,
    this.borderColor,
    this.shadows = 0,
    this.elevation,
  });

  /// Fill color `0xAARRGGBB`.
  final int? color;

  /// Whether a gradient fills the box.
  final bool gradient;

  /// Whether an image fills the box.
  final bool image;

  /// Corner radii as top-left, top-right, bottom-right, bottom-left.
  final List<double>? radii;

  /// Whether the box is a circle.
  final bool circle;

  /// Uniform border width, when there is a border.
  final double? borderWidth;

  /// Border color `0xAARRGGBB`.
  final int? borderColor;

  /// Number of box shadows.
  final int shadows;

  /// Material elevation, when the box is a physical model.
  final double? elevation;

  /// JSON form.
  Map<String, Object?> toJson() => {
    if (color != null) 'color': GoldenColorMath.hexArgb(color!),
    if (gradient) 'gradient': true,
    if (image) 'image': true,
    if (radii != null) 'radius': [for (final r in radii!) goldenRound(r)],
    if (circle) 'circle': true,
    if (borderWidth != null) 'borderWidth': goldenRound(borderWidth!),
    if (borderColor != null)
      'borderColor': GoldenColorMath.hexArgb(borderColor!),
    if (shadows > 0) 'shadows': shadows,
    if (elevation != null) 'elevation': goldenRound(elevation!),
  };
}

/// A design-system component instance found in the widget tree.
@immutable
final class GoldenRenderComponent {
  /// Creates a component instance.
  const GoldenRenderComponent({
    required this.id,
    required this.name,
    required this.rect,
    this.library,
    this.properties = const {},
    this.source,
    this.parent,
  });

  /// Index in [GoldenRenderSnapshot.components].
  final int id;

  /// Widget type without type arguments, such as `Button`.
  final String name;

  /// Package that implements the component, such as `coui_flutter`.
  final String? library;

  /// Identity properties, such as `{variant: primary, size: md}`.
  final Map<String, String> properties;

  /// Rendered bounds in logical pixels.
  final GoldenRect rect;

  /// Where the app created the component.
  final GoldenSourceLocation? source;

  /// Index of the enclosing component, if any.
  final int? parent;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    if (library != null) 'library': library,
    if (properties.isNotEmpty) 'properties': properties,
    'rect': rect.toJson(),
    if (source != null) 'source': source!.label,
    if (parent != null) 'parent': parent,
  };
}

/// Kinds of rendered nodes.
abstract final class GoldenRenderKind {
  /// Laid out text.
  static const String text = 'text';

  /// A painted box: fill, border, or shadow.
  static const String box = 'box';

  /// A raster image.
  static const String image = 'image';

  /// A font icon.
  static const String icon = 'icon';

  /// Custom painting, SVG, or other vector graphics.
  static const String graphic = 'graphic';
}

/// One visible thing the app painted.
@immutable
final class GoldenRenderNode {
  /// Creates a node.
  const GoldenRenderNode({
    required this.id,
    required this.kind,
    required this.widget,
    required this.rect,
    required this.visibleRect,
    this.key,
    this.opacity = 1,
    this.text,
    this.box,
    this.iconCodePoint,
    this.iconSize,
    this.iconColor,
    this.imageDescription,
    this.source,
    this.component,
    this.path = const [],
  });

  /// Index in [GoldenRenderSnapshot.nodes] (paint order).
  final int id;

  /// One of [GoldenRenderKind].
  final String kind;

  /// Widget type that produced the node, such as `Text`.
  final String widget;

  /// Key of the widget, when it has a readable one.
  final String? key;

  /// Bounds in logical pixels relative to the captured boundary.
  final GoldenRect rect;

  /// Part of [rect] that is not clipped away.
  final GoldenRect visibleRect;

  /// Product of the ancestor opacities.
  final double opacity;

  /// Text data for text nodes.
  final GoldenRenderText? text;

  /// Paint data for box nodes.
  final GoldenRenderBox? box;

  /// Code point of an icon glyph.
  final int? iconCodePoint;

  /// Icon size in logical pixels.
  final double? iconSize;

  /// Icon color `0xAARRGGBB`.
  final int? iconColor;

  /// Image provider description, such as an asset name.
  final String? imageDescription;

  /// Nearest project source location that created the node's widget or an
  /// ancestor of it.
  final GoldenSourceLocation? source;

  /// Index of the nearest enclosing design-system component.
  final int? component;

  /// Ancestor widgets worth naming, outermost first.
  final List<String> path;

  /// Short label for messages: the text, or the widget type.
  String get label {
    final content = text?.text.trim();
    if (content != null && content.isNotEmpty) {
      return content.length > 40 ? '${content.substring(0, 39)}…' : content;
    }
    return widget;
  }

  /// JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'widget': widget,
    if (key != null) 'key': key,
    'rect': rect.toJson(),
    if (visibleRect != rect) 'visible': visibleRect.toJson(),
    if (opacity != 1) 'opacity': goldenRound(opacity, 3),
    if (text != null) 'text': text!.toJson(),
    if (box != null) 'box': box!.toJson(),
    if (iconCodePoint != null)
      'icon': {
        'codePoint': 'U+${iconCodePoint!.toRadixString(16).toUpperCase()}',
        if (iconSize != null) 'size': goldenRound(iconSize!),
        if (iconColor != null) 'color': GoldenColorMath.hexArgb(iconColor!),
      },
    if (imageDescription != null) 'image': imageDescription,
    if (source != null) 'source': source!.label,
    if (component != null) 'component': component,
    if (path.isNotEmpty) 'path': path.join(' › '),
  };
}

/// Everything the inspector found in one capture.
@immutable
final class GoldenRenderSnapshot {
  /// Creates a snapshot.
  GoldenRenderSnapshot({
    required this.width,
    required this.height,
    required List<GoldenRenderNode> nodes,
    List<GoldenRenderComponent> components = const [],
    this.sourceLocations = false,
    Map<String, bool> fonts = const {},
    List<String> warnings = const [],
  }) : nodes = List.unmodifiable(nodes),
       components = List.unmodifiable(components),
       fonts = Map.unmodifiable(fonts),
       warnings = List.unmodifiable(warnings);

  /// Logical width of the capture.
  final double width;

  /// Logical height of the capture.
  final double height;

  /// Visible nodes in paint order.
  final List<GoldenRenderNode> nodes;

  /// Design-system components in tree order.
  final List<GoldenRenderComponent> components;

  /// Whether widget creation locations were available.
  final bool sourceLocations;

  /// Font families used by text, and whether each was loaded for real (a
  /// family that is not loaded falls back to the test font).
  final Map<String, bool> fonts;

  /// Inspection warnings.
  final List<String> warnings;

  /// Component that contains [node], if any.
  GoldenRenderComponent? componentOf(GoldenRenderNode? node) {
    final index = node?.component;
    return index == null ? null : components[index];
  }

  /// JSON form.
  Map<String, Object?> toJson({int limit = 800}) => {
    'width': goldenRound(width),
    'height': goldenRound(height),
    'sourceLocations': sourceLocations,
    if (fonts.isNotEmpty) 'fonts': fonts,
    if (warnings.isNotEmpty) 'warnings': warnings,
    'components': [for (final c in components) c.toJson()],
    'nodes': [for (final n in nodes.take(limit)) n.toJson()],
    if (nodes.length > limit) 'nodesTruncated': nodes.length - limit,
  };
}
