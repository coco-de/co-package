import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'package_map.dart';

/// Reads a component property that the generic reader does not know.
typedef GoldenPropertyReader = Object? Function(Widget widget);

/// Identifies a design-system component that the catalog cannot describe.
typedef GoldenComponentResolver =
    GoldenComponentIdentity? Function(Widget widget);

/// Resolves named color tokens of the active theme, such as
/// `{'on-surface': Color(0xff14161a)}`.
typedef GoldenColorTokens = Map<String, Color> Function(BuildContext context);

/// A component instance as a custom [GoldenComponentResolver] reports it.
@immutable
final class GoldenComponentIdentity {
  /// Creates an identity.
  const GoldenComponentIdentity(
    this.name, {
    this.properties = const {},
    this.library,
  });

  /// Component name in code, such as `Button`. It is matched against the
  /// design's component set name directly or through a
  /// [GoldenComponentMapping].
  final String name;

  /// Identity properties, such as `{variant: primary}`.
  final Map<String, String> properties;

  /// Implementing package, when known.
  final String? library;
}

/// How one design-tool component maps onto a widget.
///
/// Most CoUI components need no mapping: the Figma component set is named
/// like the widget class and variant values are spelled like the enum
/// members. Add a mapping when a name or an axis differs, for example
/// Chip's Figma `Variant` axis that holds `chipColor` values:
///
/// ```dart
/// GoldenComponentMapping(
///   widget: 'Chip',
///   properties: {'Variant': 'chipColor'},
///   readers: {'chipColor': (widget) => (widget as Chip).chipColor},
/// )
/// ```
@immutable
final class GoldenComponentMapping {
  /// Creates a mapping. [figma] defaults to [widget].
  const GoldenComponentMapping({
    required this.widget,
    String? figma,
    this.properties = const {},
    this.readers = const {},
    this.values = const {},
    this.ignore = const {},
  }) : figma = figma ?? widget;

  /// Widget type name without type arguments, such as `Button`.
  final String widget;

  /// Component set (or component) name in the design tool.
  final String figma;

  /// Design property name → widget property name, such as
  /// `{'Variant': 'chipColor'}`. Unlisted properties map to the property
  /// whose name equals the design property in lower camel case.
  final Map<String, String> properties;

  /// Widget property name → reader, for properties the generic reader does
  /// not know.
  final Map<String, GoldenPropertyReader> readers;

  /// Design property name → design value → widget value, when spellings
  /// differ.
  final Map<String, Map<String, String>> values;

  /// Design properties that are not compared.
  final Set<String> ignore;
}

/// One axis of a catalog component, such as `variant` with its enum members.
@immutable
final class GoldenCatalogAxis {
  /// Creates an axis.
  const GoldenCatalogAxis({
    required this.role,
    required this.enumName,
    required this.members,
  });

  /// `variant`, `size`, `state`, or `other`.
  final String role;

  /// Dart enum type, such as `CoreButtonVariant`.
  final String enumName;

  /// Enum member names, which are also the design values.
  final List<String> members;
}

/// A component of a design-system catalog.
@immutable
final class GoldenCatalogComponent {
  /// Creates a catalog component.
  const GoldenCatalogComponent({required this.name, this.axes = const []});

  /// Component (and widget class) name, such as `Button`.
  final String name;

  /// Variant axes.
  final List<GoldenCatalogAxis> axes;

  /// Axis whose members contain [value] (case-insensitive), preferring the
  /// axis named like [designProperty].
  GoldenCatalogAxis? axisFor(String designProperty, String value) {
    final key = goldenNormalizeName(designProperty);
    final wanted = goldenNormalizeName(value);
    GoldenCatalogAxis? byName;
    final byValue = <GoldenCatalogAxis>[];
    for (final axis in axes) {
      final names = {
        goldenNormalizeName(axis.role),
        goldenNormalizeName(_axisSuffix(axis.enumName, name)),
      };
      final hasValue = axis.members.any(
        (m) => goldenNormalizeName(m) == wanted,
      );
      if (names.contains(key) && hasValue) return axis;
      if (names.contains(key)) byName ??= axis;
      if (hasValue) byValue.add(axis);
    }
    return byValue.length == 1 ? byValue.single : byName;
  }
}

/// A named text style of a design system, such as CoUI's `titleMedium`.
@immutable
final class GoldenTextRole {
  /// Creates a role. [lineHeight] is a multiple of [fontSize] and
  /// [letterSpacing] is in em.
  const GoldenTextRole({
    required this.name,
    required this.fontSize,
    required this.fontWeight,
    this.lineHeight,
    this.letterSpacing = 0,
  });

  /// Role name, such as `titleMedium`.
  final String name;

  /// Font size in logical pixels.
  final double fontSize;

  /// Numeric weight.
  final int fontWeight;

  /// Line height as a multiple of [fontSize].
  final double? lineHeight;

  /// Letter spacing in em.
  final double letterSpacing;

  /// Design-tool style name, such as `Title/Medium` for `titleMedium`.
  String get styleName {
    final words = name
        .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ')
        .split(' ');
    if (words.isEmpty) return name;
    String cap(String w) =>
        w.length <= 3 &&
            RegExp(r'^(xl|xl\d|xs|xxl)$', caseSensitive: false).hasMatch(w)
        ? w.toUpperCase()
        : '${w[0].toUpperCase()}${w.substring(1)}';
    return [cap(words.first), words.skip(1).map(cap).join()].join('/');
  }

  /// Whether a rendered style matches this role.
  bool matches({
    required double fontSize,
    required int fontWeight,
    double? height,
    double letterSpacing = 0,
  }) {
    if ((fontSize - this.fontSize).abs() > 0.01) return false;
    if (fontWeight != this.fontWeight) return false;
    final expectedHeight = lineHeight;
    if (expectedHeight != null &&
        (height == null || (height - expectedHeight).abs() > 0.01)) {
      return false;
    }
    final spacing = this.letterSpacing * this.fontSize;
    return (letterSpacing - spacing).abs() <= 0.01;
  }
}

/// Components and text roles a design system offers.
@immutable
final class GoldenComponentCatalog {
  /// Creates a catalog.
  GoldenComponentCatalog({
    required this.name,
    List<GoldenCatalogComponent> components = const [],
    List<GoldenTextRole> textRoles = const [],
    this.path,
    this.library,
  }) : components = {
         for (final c in components) goldenNormalizeName(c.name): c,
       },
       textRoles = List.unmodifiable(textRoles);

  /// Design system name, such as `CoUI`.
  final String name;

  /// Catalog file, when read from disk.
  final String? path;

  /// Package that implements the components, such as `coui_flutter`.
  final String? library;

  /// Components by normalized name.
  final Map<String, GoldenCatalogComponent> components;

  /// Text roles.
  final List<GoldenTextRole> textRoles;

  /// Component named [name] (case- and separator-insensitive).
  GoldenCatalogComponent? component(String name) =>
      components[goldenNormalizeName(name)];

  /// Role whose design style name or role name matches [styleName].
  GoldenTextRole? roleNamed(String styleName) {
    final key = goldenNormalizeName(styleName);
    for (final role in textRoles) {
      if (goldenNormalizeName(role.name) == key ||
          goldenNormalizeName(role.styleName) == key) {
        return role;
      }
    }
    return null;
  }

  /// Reads CoUI's generated `components.json` (schema 3).
  static GoldenComponentCatalog readCoui(String path, {String? library}) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! Map<String, Object?> ||
        decoded['components'] is! Map<String, Object?>) {
      throw FormatException('Not a CoUI components.json: $path');
    }
    final components = <GoldenCatalogComponent>[];
    for (final entry
        in (decoded['components']! as Map<String, Object?>).values) {
      if (entry is! Map<String, Object?>) continue;
      final docs = entry['docs'];
      final slugs = docs is Map<String, Object?> ? docs['slugs'] : null;
      final pascal = slugs is Map<String, Object?> ? slugs['pascal'] : null;
      if (pascal is! String) continue;
      final axes = <GoldenCatalogAxis>[];
      final rawAxes = entry['axes'];
      if (rawAxes is Map<String, Object?>) {
        for (final role in const ['variant', 'size', 'state']) {
          final axis = rawAxes[role];
          if (axis is Map<String, Object?>) {
            final parsed = _axis(role, axis);
            if (parsed != null) axes.add(parsed);
          }
        }
        final others = rawAxes['other'];
        if (others is List<Object?>) {
          for (final axis in others) {
            if (axis is Map<String, Object?>) {
              final parsed = _axis('other', axis);
              if (parsed != null) axes.add(parsed);
            }
          }
        }
      }
      components.add(GoldenCatalogComponent(name: pascal, axes: axes));
    }
    final roles = <GoldenTextRole>[];
    final typography = decoded['typography'];
    if (typography is Map<String, Object?>) {
      for (final MapEntry(:key, :value) in typography.entries) {
        if (value is! Map<String, Object?>) continue;
        final size = value['fontSize'];
        final weight = value['fontWeight'];
        if (size is! num || weight is! num) continue;
        final height = value['lineHeight'];
        final spacing = value['letterSpacing'];
        roles.add(
          GoldenTextRole(
            name: key,
            fontSize: size.toDouble(),
            fontWeight: weight.toInt(),
            lineHeight: height is num ? height.toDouble() : null,
            letterSpacing: spacing is num ? spacing.toDouble() : 0,
          ),
        );
      }
    }
    return GoldenComponentCatalog(
      name: 'CoUI',
      components: components,
      textRoles: roles,
      path: path,
      library: library ?? 'coui_flutter',
    );
  }

  static GoldenCatalogAxis? _axis(String role, Map<String, Object?> json) {
    final enumName = json['enum'];
    final members = json['members'];
    if (enumName is! String || members is! List<Object?>) return null;
    return GoldenCatalogAxis(
      role: role,
      enumName: enumName,
      members: [
        for (final m in members)
          if (m is String) m,
      ],
    );
  }

  /// Finds CoUI's `components.json` next to the resolved `coui_flutter` (or
  /// `coui_core`) package of the tested app — the catalog of exactly the
  /// CoUI version the app uses. Returns `null` when CoUI is not resolved.
  static GoldenComponentCatalog? discoverCoui(GoldenPackageMap packages) {
    for (final name in const ['coui_flutter', 'coui_core']) {
      final package = packages.byName(name);
      if (package == null) continue;
      final candidates = [
        p.join(
          package.root,
          '..',
          '..',
          'tools',
          'figma-token-sync',
          'src',
          'data',
          'components.json',
        ),
        p.join(
          package.root,
          'tools',
          'figma-token-sync',
          'src',
          'data',
          'components.json',
        ),
      ];
      for (final candidate in candidates) {
        final file = File(p.normalize(candidate));
        if (!file.existsSync()) continue;
        try {
          return readCoui(file.path, library: 'coui_flutter');
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }
}

/// The design system an app is built with: how components and text styles
/// are recognized and named in design reports.
///
/// The default [GoldenDesignSystem.new] discovers CoUI's catalog from the
/// app's resolved `coui_flutter` package, so CoUI apps get component and
/// text-role checks without configuration. Other design systems describe
/// their components with [components] and [packages]; any design system can
/// add a custom [resolver] and theme [colorTokens].
@immutable
final class GoldenDesignSystem {
  /// Creates a design-system description.
  const GoldenDesignSystem({
    this.name,
    this.catalogPath,
    this.discoverCoui = true,
    this.packages = const {},
    this.components = const [],
    this.resolver,
    this.colorTokens,
    this.textRoles = const [],
  });

  /// No design-system knowledge beyond the widget tree itself.
  static const GoldenDesignSystem none = GoldenDesignSystem(
    discoverCoui: false,
  );

  /// Name shown in reports; defaults to the catalog's name.
  final String? name;

  /// CoUI-format `components.json` to read instead of discovering one.
  final String? catalogPath;

  /// Whether to look for CoUI's catalog next to the resolved `coui_flutter`.
  final bool discoverCoui;

  /// Packages whose widgets count as design-system components when the app
  /// creates them, such as `{'my_design_system'}`. The catalog's package and
  /// Flutter's Material and Cupertino libraries are always included.
  final Set<String> packages;

  /// Explicit design ↔ widget mappings.
  final List<GoldenComponentMapping> components;

  /// Custom component identification, tried before anything else.
  final GoldenComponentResolver? resolver;

  /// Named color tokens of the active theme, used to name expected and
  /// actual colors in findings.
  final GoldenColorTokens? colorTokens;

  /// Extra text roles, for design systems without a catalog file.
  final List<GoldenTextRole> textRoles;
}

/// Lowercase letters and digits only: `Title/Medium` → `titlemedium`,
/// `on-surface` → `onsurface`.
String goldenNormalizeName(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// Token name without collection prefixes, in kebab case:
/// `Semantic/color/on-surface`, `--coui-on-surface`, and `onSurface` all
/// become `on-surface`.
String goldenTokenName(String value) {
  var name = value.trim();
  final slash = name.lastIndexOf('/');
  if (slash >= 0) name = name.substring(slash + 1);
  name = name.replaceFirst(RegExp(r'^--(coui-)?'), '');
  name = name.replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => '-');
  return name.toLowerCase().replaceAll(RegExp(r'[\s_.]+'), '-');
}

String _axisSuffix(String enumName, String component) {
  var name = enumName;
  if (name.startsWith('Core')) name = name.substring(4);
  if (name.startsWith(component) && name.length > component.length) {
    name = name.substring(component.length);
  }
  return name;
}

/// Widget property names to try for a catalog axis of [component]:
/// `CoreButtonShape` → `shape`, `buttonShape`; `CoreChipColor` → `color`,
/// `chipColor`.
List<String> goldenAxisFields(GoldenCatalogAxis axis, String component) {
  if (axis.role == 'variant' || axis.role == 'size' || axis.role == 'state') {
    return [axis.role];
  }
  final suffix = _axisSuffix(axis.enumName, component);
  String lower(String v) =>
      v.isEmpty ? v : '${v[0].toLowerCase()}${v.substring(1)}';
  var full = axis.enumName;
  if (full.startsWith('Core')) full = full.substring(4);
  return {lower(suffix), lower(full)}.toList();
}
