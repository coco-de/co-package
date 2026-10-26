// co_golden only runs inside flutter_test. InspectorSerializationDelegate is
// the one public route to the widget creation locations that `flutter test`
// tracks by default (--track-widget-creation).
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'design_system.dart';
import 'geometry.dart';
import 'package_map.dart';
import 'render_node.dart';

/// Widgets whose names add nothing to a node's path.
final RegExp _trivialWidget = RegExp(
  r'^(Padding|Align|Center|SizedBox|ConstrainedBox|Expanded|Flexible|'
  r'Container|DecoratedBox|ColoredBox|Builder|LayoutBuilder|KeyedSubtree|'
  r'Semantics|MergeSemantics|ExcludeSemantics|IgnorePointer|AbsorbPointer|'
  r'Listener|MouseRegion|GestureDetector|RepaintBoundary|DefaultTextStyle|'
  r'IconTheme|Directionality|MediaQuery|Opacity|Transform|ClipRect|'
  r'ClipRRect|Positioned|Stack|Row|Column|Flex|Wrap|ListView|'
  r'SingleChildScrollView|CustomScrollView|SafeArea|Spacer|Gap)$',
);

/// Full-screen widgets that frame an app rather than draw a component.
final RegExp _shellWidget = RegExp(
  r'(App|Scaffold|Theme|Scope|Provider|Router|Navigator|Material|Overlay)$',
);

/// Widget properties the generic reader tries on component widgets.
const List<String> _genericFields = [
  'variant',
  'size',
  'shape',
  'layout',
  'tone',
  'form',
  'emphasis',
  'selected',
  'enabled',
];

/// Collects what the app painted, from the element tree under a capture
/// boundary, with styles, bounds, design-system components, and the source
/// locations that created them.
final class GoldenRenderInspector {
  /// Creates an inspector.
  GoldenRenderInspector({
    required this.designSystem,
    required this.packages,
    this.catalog,
  }) : _dsPackages = {
         ...designSystem.packages,
         ?catalog?.library,
         'flutter/material',
         'flutter/cupertino',
       },
       _mappings = {
         for (final mapping in designSystem.components)
           goldenNormalizeName(mapping.widget): mapping,
       };

  /// The design system description.
  final GoldenDesignSystem designSystem;

  /// Catalog of the design system, when found.
  final GoldenComponentCatalog? catalog;

  /// Package resolution for source locations.
  final GoldenPackageMap packages;

  final Set<String> _dsPackages;
  final Map<String, GoldenComponentMapping> _mappings;
  final Map<Element, GoldenSourceLocation?> _locations = {};
  final Map<Element, String?> _packages = {};
  late final InspectorSerializationDelegate _delegate =
      InspectorSerializationDelegate(
        service: WidgetInspectorService.instance,
        subtreeDepth: 0,
        expandPropertyValues: false,
      );

  /// Inspects the subtree of [root], whose render object is [boundary].
  GoldenRenderSnapshot inspect(Element root, RenderBox boundary) {
    final tracked = WidgetInspectorService.instance.isWidgetCreationTracked();
    final nodes = <GoldenRenderNode>[];
    final components = <GoldenRenderComponent>[];
    final families = <String>{};
    final warnings = <String>[];
    final bounds = Offset.zero & boundary.size;
    final area = bounds.width * bounds.height;

    void visit(Element element, _Context context) {
      final widget = element.widget;
      var next = context;
      final location = tracked ? _location(element) : null;
      if (location != null && location.project) {
        final name = _typeName(widget);
        next = next.created(location, _keyOf(widget), name);
        if (!_trivialWidget.hasMatch(name)) next = next.named(name);
      }
      if (element is ComponentElement &&
          (location?.project ?? !tracked) &&
          widget is! Icon) {
        final identity = _component(element, widget, tracked);
        if (identity != null) {
          final rect = _rectOfElement(element, boundary);
          final shell =
              rect != null &&
              rect.area >= area * 0.95 &&
              _shellWidget.hasMatch(identity.name);
          if (rect != null && !shell) {
            components.add(
              GoldenRenderComponent(
                id: components.length,
                name: identity.name,
                library: identity.library,
                properties: identity.properties,
                rect: rect,
                source: location,
                parent: next.component,
              ),
            );
            next = next.inComponent(components.length - 1, identity.name);
          }
        }
      }
      if (widget is Icon) next = next.inIcon(widget);
      if (widget is Image) next = next.inImage(_describeImage(widget.image));
      if (widget is ColoredBox && (widget.color.a > 0)) {
        final render = element.renderObject;
        if (render is RenderBox && render.hasSize) {
          _add(
            nodes,
            render,
            boundary,
            bounds,
            next,
            GoldenRenderKind.box,
            next.sourceWidget ?? 'ColoredBox',
            box: GoldenRenderBox(color: widget.color.toARGB32()),
          );
        }
      }
      if (element is RenderObjectElement) {
        final render = element.renderObject;
        if (render is RenderOffstage && render.offstage) return;
        if (render is RenderOpacity) {
          if (render.opacity <= 0) return;
          next = next.faded(render.opacity);
        } else if (render is RenderAnimatedOpacity) {
          final value = render.opacity.value;
          if (value <= 0) return;
          next = next.faded(value);
        }
        if (render is RenderBox && render.hasSize && render.attached) {
          _collect(
            nodes,
            families,
            warnings,
            render,
            widget,
            boundary,
            bounds,
            next,
          );
          if (render is RenderParagraph && next.icon != null) {
            next = next.withoutIcon();
          }
        }
      }
      element.visitChildElements((child) => visit(child, next));
    }

    root.visitChildElements((child) => visit(child, const _Context()));
    final fonts = _checkFonts(families);
    return GoldenRenderSnapshot(
      width: boundary.size.width,
      height: boundary.size.height,
      nodes: nodes,
      components: components,
      sourceLocations: tracked,
      fonts: fonts,
      warnings: [
        if (!tracked)
          'Widget creation tracking is off: findings carry no source '
              'locations. Run flutter test without --no-track-widget-creation.',
        ...warnings,
      ],
    );
  }

  void _collect(
    List<GoldenRenderNode> nodes,
    Set<String> families,
    List<String> warnings,
    RenderBox render,
    Widget widget,
    RenderBox boundary,
    Rect bounds,
    _Context context,
  ) {
    if (render is RenderParagraph) {
      final icon = context.icon;
      final text = render.text.toPlainText();
      if (icon != null || _isIconGlyph(text)) {
        final style = _styleRuns(render.text).dominant;
        _add(
          nodes,
          render,
          boundary,
          bounds,
          context,
          GoldenRenderKind.icon,
          icon == null ? _typeName(widget) : 'Icon',
          iconCodePoint: icon?.icon?.codePoint ?? text.runes.firstOrNull,
          iconSize: icon?.size ?? style?.fontSize,
          iconColor: (style?.color ?? style?.foreground?.color)?.toARGB32(),
        );
        return;
      }
      final data = _text(
        span: render.text,
        align: render.textAlign,
        direction: render.textDirection,
        maxLines: render.maxLines,
        scaler: render.textScaler,
        truncated: render.didExceedMaxLines,
        // Whole line boxes, like a Figma text box. Tight boxes only cover
        // the glyphs' ascent and descent, and the includeLineSpacing styles
        // leave out the first line's top leading.
        boxes: (length) => render.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
          boxHeightStyle: BoxHeightStyle.max,
        ),
        render: render,
        boundary: boundary,
        families: families,
      );
      if (data == null) return;
      _add(
        nodes,
        render,
        boundary,
        bounds,
        context,
        GoldenRenderKind.text,
        context.sourceWidget ?? _typeName(widget),
        text: data,
      );
      return;
    }
    if (render is RenderEditable) {
      final span = render.text;
      if (span == null) return;
      final data = _text(
        span: span,
        align: render.textAlign,
        direction: render.textDirection,
        maxLines: render.maxLines,
        scaler: render.textScaler,
        truncated: false,
        boxes: (length) => render.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: length),
        ),
        render: render,
        boundary: boundary,
        families: families,
        editable: true,
      );
      if (data == null) return;
      _add(
        nodes,
        render,
        boundary,
        bounds,
        context,
        GoldenRenderKind.text,
        context.sourceWidget ?? 'EditableText',
        text: data,
      );
      return;
    }
    if (render is RenderImage) {
      if (render.image == null) {
        warnings.add(
          'An image (${context.image ?? 'unknown'}) was not decoded at capture '
          'time; pump with GoldenPumps.withRealAsyncWork().',
        );
      }
      _add(
        nodes,
        render,
        boundary,
        bounds,
        context,
        GoldenRenderKind.image,
        'Image',
        imageDescription:
            '${context.image ?? 'image'}${render.image == null ? ' (not decoded)' : ''}',
      );
      return;
    }
    if (render is RenderDecoratedBox) {
      final box = _decoration(render.decoration, render.size);
      if (box != null) {
        _add(
          nodes,
          render,
          boundary,
          bounds,
          context,
          GoldenRenderKind.box,
          context.sourceWidget ?? _typeName(widget),
          box: box,
        );
      }
      return;
    }
    if (render is RenderPhysicalModel) {
      if (render.color.a > 0) {
        final radius = render.borderRadius;
        _add(
          nodes,
          render,
          boundary,
          bounds,
          context,
          GoldenRenderKind.box,
          context.sourceWidget ?? _typeName(widget),
          box: GoldenRenderBox(
            color: render.color.toARGB32(),
            circle: render.shape == BoxShape.circle,
            radii: radius == null ? null : _radii(radius),
            elevation: render.elevation,
          ),
        );
      }
      return;
    }
    if (render is RenderPhysicalShape) {
      if (render.color.a > 0) {
        final clipper = render.clipper;
        final shape = clipper is ShapeBorderClipper ? clipper.shape : null;
        _add(
          nodes,
          render,
          boundary,
          bounds,
          context,
          GoldenRenderKind.box,
          context.sourceWidget ?? _typeName(widget),
          box: _shapeBox(
            shape,
            render.size,
            color: render.color.toARGB32(),
            elevation: render.elevation,
          ),
        );
      }
      return;
    }
    if (render is RenderCustomPaint) {
      if (render.painter != null || render.foregroundPainter != null) {
        _add(
          nodes,
          render,
          boundary,
          bounds,
          context,
          GoldenRenderKind.graphic,
          _typeName(widget),
        );
      }
      return;
    }
    final type = render.runtimeType.toString();
    if (type.contains('VectorGraphic') ||
        type.contains('Svg') ||
        type.contains('Picture')) {
      _add(
        nodes,
        render,
        boundary,
        bounds,
        context,
        GoldenRenderKind.graphic,
        _typeName(widget),
      );
    }
  }

  void _add(
    List<GoldenRenderNode> nodes,
    RenderBox render,
    RenderBox boundary,
    Rect bounds,
    _Context context,
    String kind,
    String widget, {
    GoldenRenderText? text,
    GoldenRenderBox? box,
    int? iconCodePoint,
    double? iconSize,
    int? iconColor,
    String? imageDescription,
  }) {
    final rect = _globalRect(render, boundary, Offset.zero & render.size);
    if (rect == null) return;
    final visible = _visibleRect(render, boundary, rect, bounds);
    if (visible == null || visible.width < 0.5 || visible.height < 0.5) return;
    if (context.opacity <= 0.01) return;
    nodes.add(
      GoldenRenderNode(
        id: nodes.length,
        kind: kind,
        widget: widget,
        key: context.key,
        rect: _rect(rect),
        visibleRect: _rect(visible),
        opacity: context.opacity,
        text: text,
        box: box,
        iconCodePoint: iconCodePoint,
        iconSize: iconSize,
        iconColor: iconColor,
        imageDescription: imageDescription,
        source: context.source,
        component: context.component,
        path: context.path.length > 6
            ? context.path.sublist(context.path.length - 6)
            : context.path,
      ),
    );
  }

  GoldenRenderText? _text({
    required InlineSpan span,
    required TextAlign align,
    required TextDirection direction,
    required int? maxLines,
    required TextScaler scaler,
    required bool truncated,
    required List<TextBox> Function(int length) boxes,
    required RenderBox render,
    required RenderBox boundary,
    required Set<String> families,
    bool editable = false,
  }) {
    final runs = _styleRuns(span);
    final plain = runs.text.replaceAll('￼', '');
    if (plain.trim().isEmpty) return null;
    final dominant = runs.dominant ?? const TextStyle();
    for (final run in runs.runs) {
      final family = run.$3.fontFamily;
      if (family != null) families.add(family);
    }
    final lineBoxes = boxes(runs.text.length);
    Rect? content;
    final tops = <double>{};
    for (final box in lineBoxes) {
      final rect = box.toRect();
      content = content == null ? rect : content.expandToInclude(rect);
      tops.add((rect.top * 2).roundToDouble() / 2);
    }
    final global = content == null
        ? null
        : _globalRect(render, boundary, content);
    final contentRect =
        global ??
        _globalRect(render, boundary, Offset.zero & render.size) ??
        Rect.zero;
    return GoldenRenderText(
      text: plain,
      style: _renderStyle(dominant),
      runs: runs.runs.length > 1 && !runs.text.contains('￼')
          ? [
              for (final run in runs.runs)
                GoldenRenderTextRun(run.$1, run.$2, _renderStyle(run.$3)),
            ]
          : const [],
      align: _align(align, direction),
      lineCount: math.max(1, tops.length),
      truncated: truncated,
      maxLines: maxLines,
      textScale: scaler.scale(14) / 14,
      editable: editable,
      contentRect: _rect(contentRect),
    );
  }

  GoldenComponentIdentity? _component(
    ComponentElement element,
    Widget widget,
    bool tracked,
  ) {
    final custom = designSystem.resolver?.call(widget);
    if (custom != null) return custom;
    final name = _typeName(widget);
    final mapping = _mappings[goldenNormalizeName(name)];
    final listed = catalog?.component(name);
    final implementation = tracked ? _implementation(element) : null;
    // A component is a widget the app creates that a design-system package
    // implements, or one that a mapping names. Without creation locations,
    // a catalog name counts when the widget carries one of the catalog's
    // axis enums (this also tells CoUI's Card from Material's Card).
    final accepted =
        mapping != null ||
        (implementation != null && _dsPackages.contains(implementation)) ||
        (!tracked && listed != null && _hasCatalogAxis(widget, listed));
    if (!accepted) return null;
    return GoldenComponentIdentity(
      name,
      properties: _properties(widget, listed, mapping),
      library: implementation ?? (listed != null ? catalog?.library : null),
    );
  }

  bool _hasCatalogAxis(Widget widget, GoldenCatalogComponent component) {
    for (final axis in component.axes) {
      for (final field in goldenAxisFields(axis, component.name)) {
        final value = _read(widget, field);
        if (value is Enum && value.runtimeType.toString() == axis.enumName) {
          return true;
        }
      }
    }
    return component.axes.isEmpty;
  }

  Map<String, String> _properties(
    Widget widget,
    GoldenCatalogComponent? listed,
    GoldenComponentMapping? mapping,
  ) {
    final result = <String, String>{};
    void put(String field, Object? value) {
      final text = _scalar(value);
      if (text != null) result.putIfAbsent(field, () => text);
    }

    mapping?.readers.forEach((field, reader) {
      try {
        put(field, reader(widget));
      } on Object {
        // A reader that does not fit this widget is ignored.
      }
    });
    if (listed != null) {
      for (final axis in listed.axes) {
        for (final field in goldenAxisFields(axis, listed.name)) {
          if (result.containsKey(field)) break;
          final value = _read(widget, field);
          if (value is Enum && value.runtimeType.toString() == axis.enumName) {
            put(field, value);
            break;
          }
        }
      }
    }
    for (final field in _genericFields) {
      if (result.containsKey(field)) continue;
      final value = _read(widget, field);
      if (value is Enum || value is bool) put(field, value);
    }
    if (!result.containsKey('enabled')) {
      final enabled = _enabled(widget);
      if (enabled != null) result['enabled'] = '$enabled';
    }
    return result;
  }

  String? _implementation(ComponentElement element) {
    if (_packages.containsKey(element)) return _packages[element];
    Element? child;
    element.visitChildElements((c) => child ??= c);
    String? result;
    final location = child == null ? null : _rawLocation(child!);
    if (location != null) {
      final path = GoldenPackageMap.toPath(location.$1);
      final package = packages.packageOf(path);
      if (package != null) {
        result = package.name;
        if (package.name == 'flutter') {
          final posix = path.replaceAll(r'\', '/');
          if (posix.contains('/src/material/')) result = 'flutter/material';
          if (posix.contains('/src/cupertino/')) result = 'flutter/cupertino';
        }
      }
    }
    return _packages[element] = result;
  }

  (String, int, int)? _rawLocation(Element element) {
    try {
      final json = element.toDiagnosticsNode().toJsonMap(_delegate);
      final location = json['creationLocation'];
      if (location is Map) {
        final file = location['file'];
        final line = location['line'];
        final column = location['column'];
        if (file is String && line is int && column is int) {
          return (file, line, column);
        }
      }
    } on Object {
      // Defunct elements and exotic widgets have no location.
    }
    return null;
  }

  GoldenSourceLocation? _location(Element element) {
    if (_locations.containsKey(element)) return _locations[element];
    final raw = _rawLocation(element);
    GoldenSourceLocation? result;
    if (raw != null) {
      final path = GoldenPackageMap.toPath(raw.$1);
      final package = packages.packageOf(path);
      // co_golden's own widgets (the capture boundary, TickerMode) are not
      // app code, even when co_golden is a workspace member.
      final infrastructure =
          package?.name == 'co_golden' &&
          _isWithinPath(package!.libDirectory, path);
      result = GoldenSourceLocation(
        file: packages.display(path),
        line: raw.$2,
        column: raw.$3,
        package: package?.name,
        project:
            !infrastructure &&
            (package?.project ??
                _isWithinPath(packages.workingDirectory, path)),
      );
    }
    return _locations[element] = result;
  }

  Map<String, bool> _checkFonts(Set<String> families) {
    if (families.isEmpty) return const {};
    (double, double) measure(String family) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'Hamburgefonstiv 0123 ABC 가나다',
          style: TextStyle(fontFamily: family, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final size = (painter.width, painter.height);
      painter.dispose();
      return size;
    }

    final fallback = measure('__co_golden_missing_font__');
    return {
      for (final family in families)
        _family(family)!: (() {
          final size = measure(family);
          return (size.$1 - fallback.$1).abs() > 0.01 ||
              (size.$2 - fallback.$2).abs() > 0.01;
        })(),
    };
  }
}

bool _isWithinPath(String parent, String child) {
  final prefix = parent.endsWith('/') ? parent : '$parent/';
  return child.startsWith(prefix);
}

final class _Context {
  const _Context({
    this.source,
    this.sourceWidget,
    this.key,
    this.component,
    this.opacity = 1,
    this.path = const [],
    this.icon,
    this.image,
  });

  final GoldenSourceLocation? source;
  final String? sourceWidget;
  final String? key;
  final int? component;
  final double opacity;
  final List<String> path;
  final Icon? icon;
  final String? image;

  _Context copy({
    GoldenSourceLocation? source,
    String? sourceWidget,
    String? key,
    bool resetKey = false,
    int? component,
    double? opacity,
    List<String>? path,
    Icon? icon,
    bool resetIcon = false,
    String? image,
  }) => _Context(
    source: source ?? this.source,
    sourceWidget: sourceWidget ?? this.sourceWidget,
    key: resetKey ? key : (key ?? this.key),
    component: component ?? this.component,
    opacity: opacity ?? this.opacity,
    path: path ?? this.path,
    icon: resetIcon ? null : (icon ?? this.icon),
    image: image ?? this.image,
  );

  _Context created(GoldenSourceLocation location, String? key, String name) =>
      copy(source: location, sourceWidget: name, key: key, resetKey: true);

  _Context named(String name) =>
      path.isNotEmpty && path.last == name ? this : copy(path: [...path, name]);

  _Context inComponent(int index, String name) => copy(
    component: index,
    path: path.isNotEmpty && path.last == name ? path : [...path, name],
  );

  _Context faded(double value) => copy(opacity: opacity * value);

  _Context inIcon(Icon widget) => copy(icon: widget);

  _Context withoutIcon() => copy(resetIcon: true);

  _Context inImage(String description) => copy(image: description);
}

typedef _Runs = ({
  String text,
  List<(int, int, TextStyle)> runs,
  TextStyle? dominant,
});

_Runs _styleRuns(InlineSpan root) {
  final buffer = StringBuffer();
  final runs = <(int, int, TextStyle)>[];
  void walk(InlineSpan span, TextStyle? inherited) {
    final own = span.style;
    final style = inherited == null
        ? own
        : (own == null ? inherited : inherited.merge(own));
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        final start = buffer.length;
        buffer.write(text);
        runs.add((start, buffer.length, style ?? const TextStyle()));
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, style);
      }
    } else if (span is PlaceholderSpan) {
      buffer.write('￼');
    }
  }

  walk(root, null);
  final text = buffer.toString();
  TextStyle? dominant;
  var best = -1;
  for (final run in runs) {
    final count = text
        .substring(run.$1, run.$2)
        .replaceAll(RegExp(r'\s'), '')
        .length;
    if (count > best) {
      best = count;
      dominant = run.$3;
    }
  }
  return (text: text, runs: runs, dominant: dominant);
}

GoldenRenderTextStyle _renderStyle(TextStyle style) => GoldenRenderTextStyle(
  fontFamily: _family(style.fontFamily),
  fontFamilyFallback: [
    for (final family in style.fontFamilyFallback ?? const <String>[])
      _family(family)!,
  ],
  fontSize: style.fontSize ?? 14,
  fontWeight: (style.fontWeight ?? FontWeight.w400).value,
  italic: style.fontStyle == FontStyle.italic,
  height: style.height,
  letterSpacing: style.letterSpacing ?? 0,
  color: (style.color ?? style.foreground?.color)?.toARGB32(),
  decoration: _decorationName(style.decoration),
);

String? _family(String? family) =>
    family?.replaceFirst(RegExp(r'^packages/[^/]+/'), '');

String? _decorationName(TextDecoration? decoration) {
  if (decoration == null || decoration == TextDecoration.none) return null;
  if (decoration.contains(TextDecoration.underline)) return 'underline';
  if (decoration.contains(TextDecoration.lineThrough)) return 'lineThrough';
  if (decoration.contains(TextDecoration.overline)) return 'overline';
  return null;
}

String _align(TextAlign align, TextDirection direction) => switch (align) {
  TextAlign.left => 'left',
  TextAlign.right => 'right',
  TextAlign.center => 'center',
  TextAlign.justify => 'justify',
  TextAlign.start => direction == TextDirection.ltr ? 'left' : 'right',
  TextAlign.end => direction == TextDirection.ltr ? 'right' : 'left',
};

bool _isIconGlyph(String text) {
  final runes = text.trim().runes.toList();
  if (runes.length != 1) return false;
  final rune = runes.single;
  return (rune >= 0xE000 && rune <= 0xF8FF) || rune >= 0xF0000;
}

GoldenRenderBox? _decoration(Decoration decoration, Size size) {
  if (decoration is BoxDecoration) {
    final color = decoration.color;
    final border = decoration.border;
    double? borderWidth;
    int? borderColor;
    if (border is Border) {
      final sides = [
        border.top,
        border.right,
        border.bottom,
        border.left,
      ].where((s) => s.style != BorderStyle.none && s.width > 0).toList();
      if (sides.isNotEmpty) {
        final widest = sides.reduce((a, b) => a.width >= b.width ? a : b);
        borderWidth = widest.width;
        borderColor = widest.color.toARGB32();
      }
    } else if (border is BorderDirectional) {
      final sides = [
        border.top,
        border.end,
        border.bottom,
        border.start,
      ].where((s) => s.style != BorderStyle.none && s.width > 0).toList();
      if (sides.isNotEmpty) {
        final widest = sides.reduce((a, b) => a.width >= b.width ? a : b);
        borderWidth = widest.width;
        borderColor = widest.color.toARGB32();
      }
    }
    final visible =
        (color != null && color.a > 0) ||
        decoration.gradient != null ||
        decoration.image != null ||
        (borderWidth != null && (borderColor! >> 24) > 0) ||
        (decoration.boxShadow?.isNotEmpty ?? false);
    if (!visible) return null;
    final radius = decoration.borderRadius?.resolve(TextDirection.ltr);
    return GoldenRenderBox(
      color: color?.toARGB32(),
      gradient: decoration.gradient != null,
      image: decoration.image != null,
      radii: radius == null ? null : _radii(radius),
      circle: decoration.shape == BoxShape.circle,
      borderWidth: borderWidth,
      borderColor: borderColor,
      shadows: decoration.boxShadow?.length ?? 0,
    );
  }
  if (decoration is ShapeDecoration) {
    final color = decoration.color;
    final visible =
        (color != null && color.a > 0) ||
        decoration.gradient != null ||
        decoration.image != null ||
        (decoration.shadows?.isNotEmpty ?? false) ||
        _shapeSide(decoration.shape) != null;
    if (!visible) return null;
    return _shapeBox(
      decoration.shape,
      size,
      color: color?.toARGB32(),
      gradient: decoration.gradient != null,
      shadows: decoration.shadows?.length ?? 0,
    );
  }
  return null;
}

BorderSide? _shapeSide(ShapeBorder shape) {
  if (shape is OutlinedBorder) {
    final side = shape.side;
    if (side.style != BorderStyle.none && side.width > 0) return side;
  }
  return null;
}

GoldenRenderBox _shapeBox(
  ShapeBorder? shape,
  Size size, {
  int? color,
  bool gradient = false,
  int shadows = 0,
  double? elevation,
}) {
  List<double>? radii;
  var circle = false;
  if (shape is RoundedRectangleBorder) {
    radii = _radii(shape.borderRadius.resolve(TextDirection.ltr));
  } else if (shape is ContinuousRectangleBorder) {
    radii = _radii(shape.borderRadius.resolve(TextDirection.ltr));
  } else if (shape is StadiumBorder) {
    radii = List.filled(4, size.shortestSide / 2);
  } else if (shape is CircleBorder) {
    circle = true;
  }
  final side = shape == null ? null : _shapeSide(shape);
  return GoldenRenderBox(
    color: color,
    gradient: gradient,
    radii: radii,
    circle: circle,
    borderWidth: side?.width,
    borderColor: side?.color.toARGB32(),
    shadows: shadows,
    elevation: elevation,
  );
}

List<double> _radii(BorderRadius radius) => [
  radius.topLeft.x,
  radius.topRight.x,
  radius.bottomRight.x,
  radius.bottomLeft.x,
];

Rect? _globalRect(RenderObject render, RenderBox boundary, Rect local) {
  try {
    return MatrixUtils.transformRect(render.getTransformTo(boundary), local);
  } on Object {
    return null;
  }
}

Rect? _visibleRect(
  RenderObject render,
  RenderBox boundary,
  Rect rect,
  Rect bounds,
) {
  var visible = rect.intersect(bounds);
  if (visible.isEmpty) return null;
  RenderObject child = render;
  var parent = render.parent;
  while (parent != null && !identical(child, boundary)) {
    final clip = parent.describeApproximatePaintClip(child);
    if (clip != null) {
      final global = _globalRect(parent, boundary, clip);
      if (global != null) {
        visible = visible.intersect(global);
        if (visible.isEmpty) return null;
      }
    }
    if (identical(parent, boundary)) break;
    child = parent;
    parent = parent.parent;
  }
  return visible;
}

GoldenRect? _rectOfElement(Element element, RenderBox boundary) {
  final render = element.renderObject;
  if (render is! RenderBox || !render.hasSize || !render.attached) return null;
  final rect = _globalRect(render, boundary, Offset.zero & render.size);
  return rect == null ? null : _rect(rect);
}

GoldenRect _rect(Rect rect) =>
    GoldenRect(rect.left, rect.top, rect.width, rect.height);

String _typeName(Widget widget) {
  final name = widget.runtimeType.toString();
  final generic = name.indexOf('<');
  return generic > 0 ? name.substring(0, generic) : name;
}

String? _keyOf(Widget widget) {
  final key = widget.key;
  if (key is ValueKey<String>) return key.value;
  if (key is ValueKey) return '${key.value}';
  if (key is GlobalObjectKey) return '${key.value}';
  return null;
}

String _describeImage(ImageProvider provider) {
  if (provider is AssetImage) return 'asset:${provider.assetName}';
  if (provider is ExactAssetImage) return 'asset:${provider.assetName}';
  if (provider is NetworkImage) return 'network:${provider.url}';
  if (provider is MemoryImage) return 'memory';
  if (provider is FileImage) return 'file:${provider.file.path}';
  if (provider is ResizeImage) return _describeImage(provider.imageProvider);
  return provider.runtimeType.toString();
}

String? _scalar(Object? value) {
  if (value is Enum) return value.name;
  if (value is bool || value is num || value is String) return '$value';
  return null;
}

bool? _enabled(Widget widget) {
  final enabled = _read(widget, 'enabled');
  if (enabled is bool) return enabled;
  for (final field in const ['onPressed', 'onTap', 'onChanged']) {
    final callback = _read(widget, field, missing: _missing);
    if (identical(callback, _missing)) continue;
    return callback != null;
  }
  return null;
}

const Object _missing = Object();

/// Reads a conventional property without importing the widget's library.
/// `flutter test` runs unobfuscated JIT code, so dynamic getters work.
Object? _read(Object widget, String field, {Object? missing}) {
  final dynamic target = widget;
  try {
    // ignore: avoid_dynamic_calls — by design, see above.
    return switch (field) {
      'variant' => target.variant,
      'size' => target.size,
      'shape' => target.shape,
      'state' => target.state,
      'tone' => target.tone,
      'form' => target.form,
      'emphasis' => target.emphasis,
      'layout' => target.layout,
      'selected' => target.selected,
      'enabled' => target.enabled,
      'chipColor' => target.chipColor,
      'chipSize' => target.chipSize,
      'color' => target.color,
      'density' => target.density,
      'orientation' => target.orientation,
      'kind' => target.kind,
      'type' => target.type,
      'intent' => target.intent,
      'appearance' => target.appearance,
      'onPressed' => target.onPressed,
      'onTap' => target.onTap,
      'onChanged' => target.onChanged,
      _ => missing,
    };
  } on NoSuchMethodError {
    return missing;
  }
}
