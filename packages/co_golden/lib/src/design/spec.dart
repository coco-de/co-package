import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'color.dart';
import 'geometry.dart';

/// Schema name of the neutral design specification.
const String goldenDesignSpecSchema = 'co_golden.design_spec';

/// Highest neutral design specification version this package reads.
const int goldenDesignSpecSchemaVersion = 1;

/// Where a design specification came from.
@immutable
final class GoldenDesignSource {
  /// Creates source metadata.
  const GoldenDesignSource({
    required this.format,
    this.tool = 'figma',
    this.fileKey,
    this.fileName,
    this.nodeId,
    this.version,
    this.lastModified,
    this.url,
  });

  /// Input format: `co_golden.design_spec`, `figma-rest`, or
  /// `compare-frames`.
  final String format;

  /// Design tool, usually `figma`.
  final String tool;

  /// Figma file key, when known.
  final String? fileKey;

  /// Figma file name, when known.
  final String? fileName;

  /// Frame node id.
  final String? nodeId;

  /// File version that was exported, when known.
  final String? version;

  /// Last modification time of the file, when known.
  final String? lastModified;

  /// Link to the original frame, when known.
  final String? url;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'format': format,
    'tool': tool,
    'fileKey': fileKey,
    'fileName': fileName,
    'nodeId': nodeId,
    'version': version,
    'lastModified': lastModified,
    'url': url,
  };
}

/// A solid, gradient, or image paint of a design node.
@immutable
final class GoldenDesignPaint {
  /// Creates a paint.
  const GoldenDesignPaint({
    required this.type,
    this.color,
    this.variable,
    this.style,
  });

  /// Figma paint type, such as `SOLID`, `GRADIENT_LINEAR`, or `IMAGE`.
  final String type;

  /// `0xAARRGGBB` with the paint opacity folded into alpha; solid paints only.
  final int? color;

  /// Bound variable (design token) name or id, when known.
  final String? variable;

  /// Paint style name, when known.
  final String? style;

  /// Whether this is a solid color.
  bool get isSolid => type == 'SOLID' && color != null;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'type': type,
    if (color != null) 'color': GoldenColorMath.hexArgb(color!),
    if (variable != null) 'variable': variable,
    if (style != null) 'style': style,
  };
}

/// A drop shadow of a design node.
@immutable
final class GoldenDesignShadow {
  /// Creates a shadow description.
  const GoldenDesignShadow({
    required this.color,
    this.offsetX = 0,
    this.offsetY = 0,
    this.radius = 0,
    this.spread = 0,
    this.inner = false,
  });

  /// `0xAARRGGBB`.
  final int color;

  /// Horizontal offset.
  final double offsetX;

  /// Vertical offset.
  final double offsetY;

  /// Blur radius.
  final double radius;

  /// Spread.
  final double spread;

  /// Whether the shadow is an inner shadow.
  final bool inner;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'color': GoldenColorMath.hexArgb(color),
    'offset': [goldenRound(offsetX), goldenRound(offsetY)],
    'radius': goldenRound(radius),
    'spread': goldenRound(spread),
    if (inner) 'inner': true,
  };
}

/// Typography of a whole text node or of a run inside it.
@immutable
final class GoldenDesignTypography {
  /// Creates typography. `null` means unspecified (inherit the node's value).
  const GoldenDesignTypography({
    this.fontFamily,
    this.fontStyle,
    this.fontWeight,
    this.fontSize,
    this.lineHeight,
    this.lineHeightAuto = false,
    this.letterSpacing,
    this.italic,
    this.textCase,
    this.textDecoration,
    this.color,
    this.colorVariable,
    this.styleName,
    this.variables = const {},
  });

  /// Font family, such as `Pretendard`.
  final String? fontFamily;

  /// Font style name, such as `SemiBold`.
  final String? fontStyle;

  /// Numeric weight from 100 to 900.
  final int? fontWeight;

  /// Font size in logical pixels.
  final double? fontSize;

  /// Line height in logical pixels; `null` with [lineHeightAuto] for "auto".
  final double? lineHeight;

  /// Whether the line height is the font's natural ("auto") line height.
  final bool lineHeightAuto;

  /// Letter spacing in logical pixels.
  final double? letterSpacing;

  /// Whether the font is italic.
  final bool? italic;

  /// `ORIGINAL`, `UPPER`, `LOWER`, `TITLE`, `SMALL_CAPS`, ...
  final String? textCase;

  /// `NONE`, `UNDERLINE`, or `STRIKETHROUGH`.
  final String? textDecoration;

  /// Text color, `0xAARRGGBB`.
  final int? color;

  /// Bound color variable (token) name or id.
  final String? colorVariable;

  /// Text style name, such as `Title/Medium`.
  final String? styleName;

  /// Variables bound to typography fields, such as
  /// `{fontSize: font-size/body-small}`.
  final Map<String, String> variables;

  /// Values of [run] where set, otherwise this typography's values.
  GoldenDesignTypography merge(GoldenDesignTypography run) =>
      GoldenDesignTypography(
        fontFamily: run.fontFamily ?? fontFamily,
        fontStyle: run.fontStyle ?? fontStyle,
        fontWeight: run.fontWeight ?? fontWeight,
        fontSize: run.fontSize ?? fontSize,
        lineHeight: run.lineHeight ?? (run.lineHeightAuto ? null : lineHeight),
        lineHeightAuto:
            run.lineHeight == null && (run.lineHeightAuto || lineHeightAuto),
        letterSpacing: run.letterSpacing ?? letterSpacing,
        italic: run.italic ?? italic,
        textCase: run.textCase ?? textCase,
        textDecoration: run.textDecoration ?? textDecoration,
        color: run.color ?? color,
        colorVariable: run.colorVariable ?? colorVariable,
        styleName: run.styleName ?? styleName,
        variables: {...variables, ...run.variables},
      );

  /// JSON form without unset values.
  Map<String, Object?> toJson() => {
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontStyle != null) 'fontStyle': fontStyle,
    if (fontWeight != null) 'fontWeight': fontWeight,
    if (fontSize != null) 'fontSize': goldenRound(fontSize!),
    if (lineHeight != null) 'lineHeight': goldenRound(lineHeight!),
    if (lineHeightAuto) 'lineHeight': 'auto',
    if (letterSpacing != null) 'letterSpacing': goldenRound(letterSpacing!),
    if (italic != null) 'italic': italic,
    if (textCase != null) 'textCase': textCase,
    if (textDecoration != null) 'textDecoration': textDecoration,
    if (color != null) 'color': GoldenColorMath.hexArgb(color!),
    if (colorVariable != null) 'colorVariable': colorVariable,
    if (styleName != null) 'style': styleName,
    if (variables.isNotEmpty) 'variables': variables,
  };
}

/// A run of characters with typography that differs from the node's.
@immutable
final class GoldenDesignTextRun {
  /// Creates a run over UTF-16 offsets [start] (inclusive) to [end].
  const GoldenDesignTextRun(this.start, this.end, this.typography);

  /// First UTF-16 offset.
  final int start;

  /// UTF-16 offset after the run.
  final int end;

  /// Values set by the run.
  final GoldenDesignTypography typography;
}

/// Text content and typography of a design text node.
@immutable
final class GoldenDesignText {
  /// Creates text data.
  const GoldenDesignText({
    required this.characters,
    required this.typography,
    this.align,
    this.verticalAlign,
    this.autoResize,
    this.maxLines,
    this.truncated = false,
    this.runs = const [],
  });

  /// Characters as stored in the design (before text case).
  final String? characters;

  /// Typography of the node.
  final GoldenDesignTypography typography;

  /// `LEFT`, `CENTER`, `RIGHT`, or `JUSTIFIED`.
  final String? align;

  /// `TOP`, `CENTER`, or `BOTTOM`.
  final String? verticalAlign;

  /// `NONE`, `HEIGHT`, `WIDTH_AND_HEIGHT`, or `TRUNCATE`.
  final String? autoResize;

  /// Maximum lines, when limited.
  final int? maxLines;

  /// Whether the text truncates with an ellipsis.
  final bool truncated;

  /// Runs whose typography differs from [typography].
  final List<GoldenDesignTextRun> runs;

  /// Characters as displayed, with [GoldenDesignTypography.textCase] applied.
  String? get displayed {
    final value = characters;
    if (value == null) return null;
    return switch (typography.textCase) {
      'UPPER' => value.toUpperCase(),
      'LOWER' => value.toLowerCase(),
      'TITLE' => value.replaceAllMapped(
        RegExp(r'(^|\s)(\S)'),
        (m) => '${m[1]}${m[2]!.toUpperCase()}',
      ),
      _ => value,
    };
  }

  /// JSON form.
  Map<String, Object?> toJson() => {
    'characters': characters,
    ...typography.toJson(),
    if (align != null) 'align': align,
    if (verticalAlign != null) 'verticalAlign': verticalAlign,
    if (autoResize != null) 'autoResize': autoResize,
    if (maxLines != null) 'maxLines': maxLines,
    if (truncated) 'truncated': true,
    if (runs.isNotEmpty)
      'runs': [
        for (final run in runs)
          {'start': run.start, 'end': run.end, ...run.typography.toJson()},
      ],
  };
}

/// Component instance data of a design node.
@immutable
final class GoldenDesignInstance {
  /// Creates instance data.
  const GoldenDesignInstance({
    this.component,
    this.componentSet,
    this.key,
    this.remote,
    this.properties = const {},
    this.variant = const {},
  });

  /// Main component name, such as `Variant=Primary, Size=md`.
  final String? component;

  /// Component set name, such as `Button`; the component name for components
  /// without variants.
  final String? componentSet;

  /// Published component key, when known.
  final String? key;

  /// Whether the component comes from a library.
  final bool? remote;

  /// Every component property (variant, text, boolean) by plain name.
  final Map<String, String> properties;

  /// Variant properties only, such as `{Variant: Primary, Size: md}`.
  final Map<String, String> variant;

  /// Name that identifies the component: the set, else the component.
  String? get name => componentSet ?? component;

  /// JSON form.
  Map<String, Object?> toJson() => {
    if (component != null) 'component': component,
    if (componentSet != null) 'set': componentSet,
    if (key != null) 'key': key,
    if (remote != null) 'remote': remote,
    if (properties.isNotEmpty) 'properties': properties,
    if (variant.isNotEmpty) 'variant': variant,
  };
}

/// Auto layout of a design frame.
@immutable
final class GoldenDesignLayout {
  /// Creates layout data.
  const GoldenDesignLayout({
    required this.mode,
    this.padding = const [0, 0, 0, 0],
    this.gap,
  });

  /// `HORIZONTAL`, `VERTICAL`, or `NONE`.
  final String mode;

  /// Padding as top, right, bottom, left.
  final List<double> padding;

  /// Spacing between children.
  final double? gap;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'mode': mode,
    'padding': [for (final value in padding) goldenRound(value)],
    if (gap != null) 'gap': goldenRound(gap!),
  };
}

/// One node of a design frame, flattened in document order.
@immutable
final class GoldenDesignNode {
  /// Creates a node. [rect] is relative to the frame.
  const GoldenDesignNode({
    required this.id,
    required this.name,
    required this.type,
    required this.rect,
    this.parentId,
    this.depth = 0,
    this.inkRect,
    this.opacity = 1,
    this.fills = const [],
    this.strokes = const [],
    this.strokeWeight,
    this.cornerRadii,
    this.shadows = const [],
    this.text,
    this.instance,
    this.layout,
    this.instanceSet,
    this.clipsContent = false,
  });

  /// Node id, such as `12:345`.
  final String id;

  /// Id of the parent node, or `null` for the frame.
  final String? parentId;

  /// Depth below the frame (the frame is 0).
  final int depth;

  /// Layer name.
  final String name;

  /// Figma node type, such as `TEXT`, `INSTANCE`, or `RECTANGLE`.
  final String type;

  /// Bounding box relative to the frame, in logical pixels.
  final GoldenRect rect;

  /// Rendered (ink) bounds relative to the frame, when known.
  final GoldenRect? inkRect;

  /// Layer opacity.
  final double opacity;

  /// Visible fills.
  final List<GoldenDesignPaint> fills;

  /// Visible strokes.
  final List<GoldenDesignPaint> strokes;

  /// Stroke width.
  final double? strokeWeight;

  /// Corner radii as top-left, top-right, bottom-right, bottom-left.
  final List<double>? cornerRadii;

  /// Visible drop and inner shadows.
  final List<GoldenDesignShadow> shadows;

  /// Text data for `TEXT` nodes.
  final GoldenDesignText? text;

  /// Component data for `INSTANCE` nodes.
  final GoldenDesignInstance? instance;

  /// Auto layout for frames that use it.
  final GoldenDesignLayout? layout;

  /// Component set of the outermost library instance containing this node
  /// (compare-frames rows only).
  final String? instanceSet;

  /// Whether the node clips its children.
  final bool clipsContent;

  /// Whether the node is a text node.
  bool get isText => type == 'TEXT';

  /// Whether the node is a component instance.
  bool get isInstance => type == 'INSTANCE';

  /// Whether the node paints a visible fill, stroke, or shadow.
  bool get paints =>
      fills.isNotEmpty ||
      (strokes.isNotEmpty && (strokeWeight ?? 1) > 0) ||
      shadows.isNotEmpty;

  /// First visible solid fill color.
  GoldenDesignPaint? get solidFill {
    for (final paint in fills) {
      if (paint.isSolid) return paint;
    }
    return null;
  }

  /// First visible solid stroke color.
  GoldenDesignPaint? get solidStroke {
    for (final paint in strokes) {
      if (paint.isSolid) return paint;
    }
    return null;
  }

  /// Whether the node paints an image fill.
  bool get hasImageFill => fills.any((paint) => paint.type == 'IMAGE');

  /// Short JSON reference used by findings and regions.
  Map<String, Object?> toRef() => {
    'id': id,
    'name': name,
    'type': type,
    'rect': rect.toJson(),
    if (instance?.name != null) 'component': instance!.name,
    if (instanceSet != null) 'instance': instanceSet,
    if (text?.typography.styleName != null)
      'textStyle': text!.typography.styleName,
  };

  /// Full JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'parent': parentId,
    'name': name,
    'type': type,
    'rect': rect.toJson(),
    if (inkRect != null) 'ink': inkRect!.toJson(),
    if (opacity != 1) 'opacity': goldenRound(opacity, 3),
    if (fills.isNotEmpty) 'fills': [for (final f in fills) f.toJson()],
    if (strokes.isNotEmpty) 'strokes': [for (final s in strokes) s.toJson()],
    if (strokeWeight != null) 'strokeWeight': goldenRound(strokeWeight!),
    if (cornerRadii != null)
      'radius': [for (final r in cornerRadii!) goldenRound(r)],
    if (shadows.isNotEmpty) 'shadows': [for (final s in shadows) s.toJson()],
    if (text != null) 'text': text!.toJson(),
    if (instance != null) 'instance': instance!.toJson(),
    if (layout != null) 'layout': layout!.toJson(),
    if (instanceSet != null) 'instanceSet': instanceSet,
  };
}

/// A design frame flattened into comparable nodes.
@immutable
final class GoldenDesignSpec {
  /// Creates a specification. [nodes] are in document order and exclude the
  /// frame itself.
  GoldenDesignSpec({
    required this.source,
    required this.frame,
    required List<GoldenDesignNode> nodes,
    this.insetTop = 0,
    this.insetBottom = 0,
    this.hasStyles = true,
    List<String> warnings = const [],
  }) : nodes = List.unmodifiable(nodes),
       warnings = List.unmodifiable(warnings),
       _byId = {for (final node in nodes) node.id: node};

  /// Where the specification came from.
  final GoldenDesignSource source;

  /// The frame: its size is the logical size of the design.
  final GoldenDesignNode frame;

  /// Visible nodes below the frame, in document order.
  final List<GoldenDesignNode> nodes;

  /// Height of a status bar band at the top, when the source reports it.
  final double insetTop;

  /// Height of a home indicator band at the bottom, when the source reports
  /// it.
  final double insetBottom;

  /// Whether nodes carry fonts, colors, and component data. compare-frames
  /// rows carry geometry only.
  final bool hasStyles;

  /// Conversion warnings.
  final List<String> warnings;

  final Map<String, GoldenDesignNode> _byId;

  /// Node by id, including the frame.
  GoldenDesignNode? operator [](String id) =>
      id == frame.id ? frame : _byId[id];

  /// Ancestors of [node] from its parent up to the frame.
  Iterable<GoldenDesignNode> ancestors(GoldenDesignNode node) sync* {
    var parent = node.parentId == null ? null : this[node.parentId!];
    while (parent != null) {
      yield parent;
      parent = parent.parentId == null ? null : this[parent.parentId!];
    }
  }

  /// Layer path such as `Login/Header/Title`.
  String pathOf(GoldenDesignNode node) => [
    ...ancestors(node).toList().reversed.map((n) => n.name),
    node.name,
  ].join(' / ');

  /// Reads a specification file. See [GoldenDesignSpec.parse].
  static GoldenDesignSpec read(String path, {String? nodeId}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FormatException('Design specification not found: $path');
    }
    return parse(jsonDecode(file.readAsStringSync()), nodeId: nodeId);
  }

  /// Parses a neutral `co_golden.design_spec`, a Figma REST API response
  /// (`GET /v1/files/:key/nodes` or a file or node document), or the output
  /// of the `compare-frames` Figma recipe. [nodeId] selects the frame when the
  /// input holds more than one. Throws a [FormatException] for anything else.
  static GoldenDesignSpec parse(Object? json, {String? nodeId}) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('A design specification must be an object.');
    }
    if (json['schema'] == goldenDesignSpecSchema) {
      return _NeutralParser(json).parse();
    }
    final nodes = json['nodes'];
    if (nodes is Map<String, Object?>) {
      return _FigmaRestParser.fromNodesResponse(json, nodeId).parse();
    }
    if (json['frames'] is List<Object?>) {
      return _CompareFramesParser.fromRecipe(json, nodeId).parse();
    }
    if (nodes is List<Object?> && json['width'] is num) {
      return _CompareFramesParser(json, json).parse();
    }
    if (json['document'] is Map<String, Object?>) {
      return _FigmaRestParser.fromDocument(json, nodeId).parse();
    }
    if (json['type'] is String && json['absoluteBoundingBox'] != null) {
      return _FigmaRestParser(json, const {}, const {}, const {}, json).parse();
    }
    throw const FormatException(
      'Unknown design specification: expected co_golden.design_spec, a Figma '
      'REST nodes response, or compare-frames output.',
    );
  }
}

// ───────────────────────── neutral co_golden.design_spec ─────────────────────

final class _NeutralParser {
  _NeutralParser(this.json);

  final Map<String, Object?> json;

  GoldenDesignSpec parse() {
    final version = json['schemaVersion'];
    if (version is! int || version > goldenDesignSpecSchemaVersion) {
      throw FormatException(
        '$goldenDesignSpecSchema version $version is newer than '
        '$goldenDesignSpecSchemaVersion.',
      );
    }
    final source = _map(json['source']) ?? const {};
    final frameJson = _map(json['frame']);
    if (frameJson == null) {
      throw const FormatException('design_spec lacks "frame".');
    }
    final width = _num(frameJson['width']);
    final height = _num(frameJson['height']);
    if (width == null || height == null || width <= 0 || height <= 0) {
      throw const FormatException('design_spec frame lacks a usable size.');
    }
    final frameId = '${frameJson['id'] ?? source['nodeId'] ?? 'frame'}';
    final frame = GoldenDesignNode(
      id: frameId,
      name: '${frameJson['name'] ?? frameId}',
      type: '${frameJson['type'] ?? 'FRAME'}',
      rect: GoldenRect(0, 0, width, height),
      fills: _paints(frameJson['fills']),
      cornerRadii: _radii(frameJson['radius']),
      layout: _layout(frameJson['layout']),
    );
    final nodes = <GoldenDesignNode>[];
    final depth = <String, int>{frameId: 0};
    final hidden = <String>{};
    final warnings = <String>[];
    for (final raw in _list(json['nodes'])) {
      final node = _map(raw);
      if (node == null) continue;
      final id = node['id'];
      var rect = GoldenRect.tryParse(node['rect']);
      if (id is! String || rect == null) {
        warnings.add('Skipped a node without id or rect.');
        continue;
      }
      final parent = node['parent'] is String
          ? node['parent']! as String
          : frameId;
      if (node['visible'] == false || hidden.contains(parent)) {
        hidden.add(id);
        continue;
      }
      if (node['type'] == 'LINE') {
        rect = _lineRect(rect, _num(node['strokeWeight']));
      }
      final d = (depth[parent] ?? 0) + 1;
      depth[id] = d;
      nodes.add(
        GoldenDesignNode(
          id: id,
          parentId: parent,
          depth: d,
          name: '${node['name'] ?? id}',
          type: '${node['type'] ?? 'FRAME'}',
          rect: rect,
          inkRect: GoldenRect.tryParse(node['ink']),
          opacity: _num(node['opacity']) ?? 1,
          fills: _paints(node['fills']),
          strokes: _paints(node['strokes']),
          strokeWeight: _num(node['strokeWeight']),
          cornerRadii: _radii(node['radius']),
          shadows: _shadows(node['shadows']),
          text: _text(node['text']),
          instance: _instance(node['instance']),
          layout: _layout(node['layout']),
          clipsContent: node['clipsContent'] == true,
        ),
      );
    }
    final insets = _map(frameJson['insets']) ?? const {};
    return GoldenDesignSpec(
      source: GoldenDesignSource(
        format: goldenDesignSpecSchema,
        tool: '${source['tool'] ?? 'figma'}',
        fileKey: source['fileKey'] as String?,
        fileName: source['fileName'] as String?,
        nodeId: (source['nodeId'] as String?) ?? frameId,
        version: source['version']?.toString(),
        lastModified: source['lastModified']?.toString(),
        url: source['url'] as String?,
      ),
      frame: frame,
      nodes: nodes,
      insetTop: _num(insets['top']) ?? 0,
      insetBottom: _num(insets['bottom']) ?? 0,
      warnings: warnings,
    );
  }

  static List<GoldenDesignPaint> _paints(Object? raw) => [
    for (final item in _list(raw))
      if (_map(item) case final paint?)
        if (paint['visible'] != false)
          GoldenDesignPaint(
            type: '${paint['type'] ?? 'SOLID'}',
            color: paint['color'] is String
                ? GoldenColorMath.parseHex(paint['color']! as String)
                : null,
            variable: paint['variable'] as String?,
            style: paint['style'] as String?,
          ),
  ];

  static List<GoldenDesignShadow> _shadows(Object? raw) => [
    for (final item in _list(raw))
      if (_map(item) case final shadow?)
        if (shadow['color'] is String)
          GoldenDesignShadow(
            color: GoldenColorMath.parseHex(shadow['color']! as String) ?? 0,
            offsetX: _num(_list(shadow['offset']).firstOrNull) ?? 0,
            offsetY: _num(_list(shadow['offset']).elementAtOrNull(1)) ?? 0,
            radius: _num(shadow['radius']) ?? 0,
            spread: _num(shadow['spread']) ?? 0,
            inner: shadow['inner'] == true,
          ),
  ];

  static GoldenDesignTypography _typography(Map<String, Object?> json) {
    final size = _num(json['fontSize']);
    final (lineHeight, auto) = _lineHeight(json['lineHeight'], size);
    final fill = _paints(json['fills']).where((p) => p.isSolid).firstOrNull;
    return GoldenDesignTypography(
      fontFamily: json['fontFamily'] as String?,
      fontStyle: json['fontStyle'] as String?,
      fontWeight: _num(json['fontWeight'])?.round(),
      fontSize: size,
      lineHeight: lineHeight,
      lineHeightAuto: auto,
      letterSpacing: _letterSpacing(json['letterSpacing'], size),
      italic: json['italic'] as bool?,
      textCase: json['textCase'] as String?,
      textDecoration: json['textDecoration'] as String?,
      color: json['color'] is String
          ? GoldenColorMath.parseHex(json['color']! as String)
          : fill?.color,
      colorVariable: (json['colorVariable'] as String?) ?? fill?.variable,
      styleName: json['style'] as String?,
      variables: {
        for (final MapEntry(:key, :value)
            in (_map(json['variables']) ?? const {}).entries)
          if (value is String) key: value,
      },
    );
  }

  static GoldenDesignText? _text(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    return GoldenDesignText(
      characters: json['characters'] as String?,
      typography: _typography(json),
      align: json['align'] as String?,
      verticalAlign: json['verticalAlign'] as String?,
      autoResize: json['autoResize'] as String?,
      maxLines: _num(json['maxLines'])?.toInt(),
      truncated:
          json['truncated'] == true ||
          json['truncation'] == 'ENDING' ||
          json['autoResize'] == 'TRUNCATE',
      runs: [
        for (final item in _list(json['runs']))
          if (_map(item) case final run?)
            if (_num(run['start']) case final start?)
              if (_num(run['end']) case final end?)
                GoldenDesignTextRun(
                  start.toInt(),
                  end.toInt(),
                  _typography(run),
                ),
      ],
    );
  }

  static GoldenDesignInstance? _instance(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    Map<String, String> strings(Object? value) => {
      for (final MapEntry(:key, :value) in (_map(value) ?? const {}).entries)
        _propertyName(key): '$value',
    };
    return GoldenDesignInstance(
      component: json['component'] as String?,
      componentSet: json['set'] as String?,
      key: json['key'] as String?,
      remote: json['remote'] as bool?,
      properties: strings(json['properties']),
      variant: strings(json['variant']),
    );
  }

  static GoldenDesignLayout? _layout(Object? raw) {
    final json = _map(raw);
    if (json == null) return null;
    final padding = _list(json['padding']).map(_num).toList();
    return GoldenDesignLayout(
      mode: '${json['mode'] ?? 'NONE'}',
      padding: padding.length == 4 && padding.every((v) => v != null)
          ? padding.cast<double>()
          : const [0, 0, 0, 0],
      gap: _num(json['gap']),
    );
  }

  static List<double>? _radii(Object? raw) {
    if (raw is num) return List.filled(4, raw.toDouble());
    final values = _list(raw).map(_num).toList();
    if (values.length == 4 && values.every((v) => v != null)) {
      return values.cast<double>();
    }
    return null;
  }
}

// ───────────────────────────── Figma REST API ────────────────────────────────

final class _FigmaRestParser {
  _FigmaRestParser(
    this.root,
    this.components,
    this.componentSets,
    this.styles,
    this.meta,
  );

  factory _FigmaRestParser.fromNodesResponse(
    Map<String, Object?> json,
    String? nodeId,
  ) {
    final nodes = json['nodes']! as Map<String, Object?>;
    final wanted = nodeId?.replaceAll('-', ':');
    final entry = wanted != null
        ? (nodes[wanted] ?? nodes[nodeId])
        : (nodes.length == 1 ? nodes.values.single : null);
    if (entry == null) {
      throw FormatException(
        wanted == null
            ? 'The Figma response holds ${nodes.length} nodes; pass nodeId.'
            : 'Node $wanted is not in the Figma response.',
      );
    }
    final body = _map(entry);
    final document = _map(body?['document']);
    if (body == null || document == null) {
      throw const FormatException('The Figma node entry lacks "document".');
    }
    return _FigmaRestParser(
      document,
      _map(body['components']) ?? const {},
      _map(body['componentSets']) ?? const {},
      _map(body['styles']) ?? const {},
      json,
    );
  }

  factory _FigmaRestParser.fromDocument(
    Map<String, Object?> json,
    String? nodeId,
  ) {
    final document = json['document']! as Map<String, Object?>;
    final wanted = nodeId?.replaceAll('-', ':');
    Map<String, Object?>? find(Map<String, Object?> node) {
      if (wanted == null) return null;
      if (node['id'] == wanted) return node;
      for (final child in _list(node['children'])) {
        if (_map(child) case final map?) {
          if (find(map) case final found?) return found;
        }
      }
      return null;
    }

    final root = document['absoluteBoundingBox'] != null && wanted == null
        ? document
        : find(document);
    if (root == null) {
      throw FormatException(
        wanted == null
            ? 'A Figma file document needs nodeId to select a frame.'
            : 'Node $wanted is not in the Figma document.',
      );
    }
    return _FigmaRestParser(
      root,
      _map(json['components']) ?? const {},
      _map(json['componentSets']) ?? const {},
      _map(json['styles']) ?? const {},
      json,
    );
  }

  final Map<String, Object?> root;
  final Map<String, Object?> components;
  final Map<String, Object?> componentSets;
  final Map<String, Object?> styles;
  final Map<String, Object?> meta;
  final List<String> warnings = [];

  GoldenDesignSpec parse() {
    final box = GoldenRect.tryParse(root['absoluteBoundingBox']);
    if (box == null || box.isEmpty) {
      throw const FormatException('The Figma frame lacks absoluteBoundingBox.');
    }
    final frameId = '${root['id'] ?? 'frame'}';
    final frame = GoldenDesignNode(
      id: frameId,
      name: '${root['name'] ?? frameId}',
      type: '${root['type'] ?? 'FRAME'}',
      rect: GoldenRect(0, 0, box.width, box.height),
      fills: _paints(root['fills'], root),
      cornerRadii: _radii(root),
      layout: _layout(root),
      clipsContent: root['clipsContent'] != false,
    );
    final nodes = <GoldenDesignNode>[];
    void walk(Map<String, Object?> node, String parentId, int depth) {
      for (final child in _list(node['children'])) {
        final json = _map(child);
        if (json == null || json['visible'] == false) continue;
        final absolute = GoldenRect.tryParse(json['absoluteBoundingBox']);
        if (absolute == null) continue;
        final rect = absolute.shift(-box.left, -box.top);
        final id = '${json['id']}';
        final opacity = _num(json['opacity']) ?? 1;
        if (opacity <= 0) continue;
        if (frame.clipsContent && rect.intersect(frame.rect) == null) continue;
        nodes.add(_node(json, id, parentId, depth, rect, box));
        walk(json, id, depth + 1);
      }
    }

    walk(root, frameId, 1);
    final url = meta['url'];
    return GoldenDesignSpec(
      source: GoldenDesignSource(
        format: 'figma-rest',
        fileKey: meta['key'] as String?,
        fileName: meta['name'] as String?,
        nodeId: frameId,
        version: meta['version']?.toString(),
        lastModified: meta['lastModified']?.toString(),
        url: url is String ? url : null,
      ),
      frame: frame,
      nodes: nodes,
      warnings: warnings,
    );
  }

  GoldenDesignNode _node(
    Map<String, Object?> json,
    String id,
    String parentId,
    int depth,
    GoldenRect rect,
    GoldenRect frameBox,
  ) {
    final type = '${json['type'] ?? 'FRAME'}';
    final ink = GoldenRect.tryParse(
      json['absoluteRenderBounds'],
    )?.shift(-frameBox.left, -frameBox.top);
    return GoldenDesignNode(
      id: id,
      parentId: parentId,
      depth: depth,
      name: '${json['name'] ?? id}',
      type: type,
      rect: type == 'LINE' ? _lineRect(rect, _num(json['strokeWeight'])) : rect,
      inkRect: ink,
      opacity: _num(json['opacity']) ?? 1,
      fills: type == 'TEXT' ? const [] : _paints(json['fills'], json),
      strokes: _paints(json['strokes'], json, stroke: true),
      strokeWeight: _num(json['strokeWeight']),
      cornerRadii: _radii(json),
      shadows: _shadows(json['effects']),
      text: type == 'TEXT' ? _text(json) : null,
      instance: type == 'INSTANCE' ? _instance(json) : null,
      layout: _layout(json),
      clipsContent: json['clipsContent'] == true,
    );
  }

  String? _styleName(Map<String, Object?> node, String kind) {
    final id = _map(node['styles'])?[kind];
    if (id is! String) return null;
    return _map(styles[id])?['name'] as String?;
  }

  List<GoldenDesignPaint> _paints(
    Object? raw,
    Map<String, Object?> node, {
    bool stroke = false,
  }) {
    final style = _styleName(node, stroke ? 'stroke' : 'fill');
    return [
      for (final item in _list(raw))
        if (_map(item) case final paint?)
          if (paint['visible'] != false && (_num(paint['opacity']) ?? 1) > 0)
            GoldenDesignPaint(
              type: '${paint['type'] ?? 'SOLID'}',
              color: paint['type'] == 'SOLID'
                  ? _color(paint['color'], _num(paint['opacity']) ?? 1)
                  : null,
              variable: _variable(paint),
              style: style,
            ),
    ];
  }

  static String? _variable(Map<String, Object?> paint) {
    final bound = _map(_map(paint['boundVariables'])?['color']);
    final id = bound?['id'];
    return id is String ? id : null;
  }

  static List<GoldenDesignShadow> _shadows(Object? raw) => [
    for (final item in _list(raw))
      if (_map(item) case final effect?)
        if (effect['visible'] != false &&
            (effect['type'] == 'DROP_SHADOW' ||
                effect['type'] == 'INNER_SHADOW'))
          GoldenDesignShadow(
            color: _color(effect['color'], 1) ?? 0,
            offsetX: _num(_map(effect['offset'])?['x']) ?? 0,
            offsetY: _num(_map(effect['offset'])?['y']) ?? 0,
            radius: _num(effect['radius']) ?? 0,
            spread: _num(effect['spread']) ?? 0,
            inner: effect['type'] == 'INNER_SHADOW',
          ),
  ];

  GoldenDesignTypography _typography(
    Map<String, Object?> style,
    Map<String, Object?> node, {
    bool run = false,
  }) {
    final size = _num(style['fontSize']);
    final unit = style['lineHeightUnit'];
    final auto = unit == 'INTRINSIC_%';
    final fills = _list(style['fills']).isNotEmpty
        ? _paints(style['fills'], node)
        : (run ? const <GoldenDesignPaint>[] : _paints(node['fills'], node));
    final fill = fills.where((p) => p.isSolid).firstOrNull;
    return GoldenDesignTypography(
      fontFamily: style['fontFamily'] as String?,
      fontStyle: style['fontStyle'] as String?,
      fontWeight: _num(style['fontWeight'])?.round(),
      fontSize: size,
      lineHeight: auto ? null : _num(style['lineHeightPx']),
      lineHeightAuto: auto,
      letterSpacing: _num(style['letterSpacing']),
      italic: style['italic'] as bool?,
      textCase: style['textCase'] as String?,
      textDecoration: style['textDecoration'] as String?,
      color: fill?.color,
      colorVariable: fill?.variable,
      styleName: run ? null : _styleName(node, 'text'),
    );
  }

  GoldenDesignText _text(Map<String, Object?> node) {
    final style = _map(node['style']) ?? const {};
    final base = _typography(style, node);
    final overrides = _list(node['characterStyleOverrides']);
    final table = _map(node['styleOverrideTable']) ?? const {};
    final runs = <GoldenDesignTextRun>[];
    var start = 0;
    for (var i = 0; i <= overrides.length; i++) {
      final current = i < overrides.length ? overrides[i] : null;
      final previous = i > 0 ? overrides[i - 1] : null;
      if (i > 0 && current != previous) {
        if (previous != null && previous != 0) {
          final runStyle = _map(table['$previous']);
          if (runStyle != null && runStyle.isNotEmpty) {
            runs.add(
              GoldenDesignTextRun(
                start,
                i,
                _typography(runStyle, node, run: true),
              ),
            );
          }
        }
        start = i;
      }
    }
    final truncation = style['textTruncation'];
    return GoldenDesignText(
      characters: node['characters'] as String?,
      typography: base,
      align: style['textAlignHorizontal'] as String?,
      verticalAlign: style['textAlignVertical'] as String?,
      autoResize: style['textAutoResize'] as String?,
      maxLines: _num(style['maxLines'])?.toInt(),
      truncated:
          truncation == 'ENDING' || style['textAutoResize'] == 'TRUNCATE',
      runs: runs,
    );
  }

  GoldenDesignInstance _instance(Map<String, Object?> node) {
    final componentId = node['componentId'];
    final component = componentId is String
        ? _map(components[componentId])
        : null;
    final setId = component?['componentSetId'];
    final set = setId is String ? _map(componentSets[setId]) : null;
    final properties = <String, String>{};
    final variant = <String, String>{};
    for (final MapEntry(:key, :value)
        in (_map(node['componentProperties']) ?? const {}).entries) {
      final property = _map(value);
      if (property == null) continue;
      final name = _propertyName(key);
      final text = '${property['value']}';
      properties[name] = text;
      if (property['type'] == 'VARIANT') variant[name] = text;
    }
    final componentName = component?['name'] as String?;
    if (variant.isEmpty && componentName != null && set != null) {
      variant.addAll(_variantFromName(componentName));
    }
    return GoldenDesignInstance(
      component: componentName,
      componentSet: (set?['name'] as String?) ?? componentName,
      key: component?['key'] as String?,
      remote: component?['remote'] as bool?,
      properties: properties,
      variant: variant,
    );
  }

  static GoldenDesignLayout? _layout(Map<String, Object?> node) {
    final mode = node['layoutMode'];
    if (mode is! String || mode == 'NONE') return null;
    return GoldenDesignLayout(
      mode: mode,
      padding: [
        _num(node['paddingTop']) ?? 0,
        _num(node['paddingRight']) ?? 0,
        _num(node['paddingBottom']) ?? 0,
        _num(node['paddingLeft']) ?? 0,
      ],
      gap: _num(node['itemSpacing']),
    );
  }

  static List<double>? _radii(Map<String, Object?> node) {
    final corners = _list(node['rectangleCornerRadii']).map(_num).toList();
    if (corners.length == 4 && corners.every((v) => v != null)) {
      return corners.cast<double>();
    }
    final radius = _num(node['cornerRadius']);
    return radius == null ? null : List.filled(4, radius);
  }

  static int? _color(Object? raw, double opacity) {
    final color = _map(raw);
    if (color == null) return null;
    int channel(String key) =>
        ((_num(color[key]) ?? 0) * 255).round().clamp(0, 255);
    final alpha = (((_num(color['a']) ?? 1) * opacity) * 255).round().clamp(
      0,
      255,
    );
    return (alpha << 24) |
        (channel('r') << 16) |
        (channel('g') << 8) |
        channel('b');
  }
}

// ─────────────────────── compare-frames recipe output ────────────────────────

final class _CompareFramesParser {
  _CompareFramesParser(this.frame, this.recipe);

  factory _CompareFramesParser.fromRecipe(
    Map<String, Object?> json,
    String? nodeId,
  ) {
    final frames = [for (final item in _list(json['frames'])) ?_map(item)];
    final wanted = nodeId?.replaceAll('-', ':');
    final frame = wanted != null
        ? frames.where((f) => f['id'] == wanted).firstOrNull
        : (frames.length == 1 ? frames.single : null);
    if (frame == null) {
      throw FormatException(
        wanted == null
            ? 'compare-frames output holds ${frames.length} frames; pass nodeId.'
            : 'Frame $wanted is not in the compare-frames output.',
      );
    }
    return _CompareFramesParser(frame, json);
  }

  final Map<String, Object?> frame;
  final Map<String, Object?> recipe;

  GoldenDesignSpec parse() {
    final width = _num(frame['width']);
    final height = _num(frame['height']);
    if (width == null || height == null || width <= 0 || height <= 0) {
      throw const FormatException('compare-frames frame lacks a usable size.');
    }
    final frameId = '${frame['id'] ?? 'frame'}';
    final root = GoldenDesignNode(
      id: frameId,
      name: '${frame['name'] ?? frameId}',
      type: 'FRAME',
      rect: GoldenRect(0, 0, width, height),
    );
    final nodes = <GoldenDesignNode>[];
    for (final raw in _list(frame['nodes'])) {
      if (raw is! List<Object?> || raw.length < 6) continue;
      final rect = GoldenRect.tryParse(raw.sublist(2, 6));
      if (rect == null) continue;
      final type = raw.length > 6 && raw[6] is String
          ? raw[6]! as String
          : 'FRAME';
      final set = raw.length > 7 && raw[7] is String ? raw[7]! as String : null;
      nodes.add(
        GoldenDesignNode(
          id: '${raw[0]}',
          parentId: frameId,
          depth: 1,
          name: '${raw[1]}',
          type: type,
          rect: rect,
          inkRect: type == 'TEXT' ? rect : null,
          instanceSet: set,
          instance: type == 'INSTANCE' && set != null
              ? GoldenDesignInstance(componentSet: set)
              : null,
        ),
      );
    }
    final insets = _map(frame['insets']) ?? const {};
    final section = _map(recipe['section']);
    return GoldenDesignSpec(
      source: GoldenDesignSource(
        format: 'compare-frames',
        nodeId: frameId,
        fileName: section?['name'] as String?,
      ),
      frame: root,
      nodes: nodes,
      insetTop: _num(insets['top']) ?? 0,
      insetBottom: _num(insets['bottom']) ?? 0,
      hasStyles: false,
      warnings: const [
        'compare-frames rows carry geometry only: fonts, colors, and '
            'component properties are not compared.',
      ],
    );
  }
}

// ───────────────────────────────── helpers ───────────────────────────────────

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

List<Object?> _list(Object? value) => value is List<Object?> ? value : const [];

double? _num(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;

/// `Label#12:3` → `Label`.
String _propertyName(String key) {
  final at = key.indexOf('#');
  return at > 0 ? key.substring(0, at) : key;
}

/// `Variant=Primary, Size=md` → `{Variant: Primary, Size: md}`.
Map<String, String> _variantFromName(String name) {
  final result = <String, String>{};
  for (final part in name.split(',')) {
    final at = part.indexOf('=');
    if (at <= 0) return const {};
    result[part.substring(0, at).trim()] = part.substring(at + 1).trim();
  }
  return result;
}

(double?, bool) _lineHeight(Object? raw, double? fontSize) {
  if (raw == 'auto' || raw == 'AUTO') return (null, true);
  if (raw is num) return (raw.toDouble(), false);
  final json = _map(raw);
  if (json == null) return (null, false);
  final unit = json['unit'];
  final value = _num(json['value']);
  if (unit == 'AUTO' || unit == 'INTRINSIC_%') return (null, true);
  if (value == null) return (null, false);
  if (unit == 'PERCENT' || unit == 'FONT_SIZE_%') {
    return (fontSize == null ? null : fontSize * value / 100, false);
  }
  return (value, false);
}

double? _letterSpacing(Object? raw, double? fontSize) {
  if (raw is num) return raw.toDouble();
  final json = _map(raw);
  if (json == null) return null;
  final value = _num(json['value']);
  if (value == null) return null;
  if (json['unit'] == 'PERCENT') {
    return fontSize == null ? null : fontSize * value / 100;
  }
  return value;
}

/// A divider line has no height (or width); give it its stroke's thickness.
GoldenRect _lineRect(GoldenRect rect, double? strokeWeight) {
  final weight = strokeWeight ?? 1;
  if (rect.height <= 0) {
    return GoldenRect(rect.left, rect.top - weight / 2, rect.width, weight);
  }
  if (rect.width <= 0) {
    return GoldenRect(rect.left - weight / 2, rect.top, weight, rect.height);
  }
  return rect;
}

/// Whether the node is a system bar drawn by the design but not by the app.
bool goldenIsSystemBarName(String name) => RegExp(
  r'status\s*bar|상태\s*바|home\s*indicator|홈\s*인디케이터|dynamic\s*island|notch',
  caseSensitive: false,
).hasMatch(name);

/// Largest of [values], or `0` when empty.
double goldenMax(Iterable<double> values) =>
    values.fold(0, (a, b) => math.max(a, b));
