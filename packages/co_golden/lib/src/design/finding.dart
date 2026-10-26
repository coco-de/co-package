import 'package:meta/meta.dart';

import 'geometry.dart';
import 'mask.dart';
import 'render_node.dart';
import 'spec.dart';

/// How much a finding matters.
enum GoldenFindingSeverity {
  /// Visible to users and designers; fails the design verdict.
  error,

  /// A small deviation; worth fixing, does not fail the verdict.
  warning,

  /// Context that helps a reviewer; never fails.
  info;

  /// The more severe of two severities.
  GoldenFindingSeverity max(GoldenFindingSeverity other) =>
      index <= other.index ? this : other;
}

/// Who decides a differing value.
abstract final class GoldenFindingOwner {
  /// The app's code drew or configured it.
  static const String app = 'app';

  /// A design-system component drew it internally.
  static const String designSystem = 'designSystem';

  /// Owner of a finding about [widget] inside [component]: the design system
  /// when the nearest app source of the widget is the component itself (the
  /// app only created the component), else the app when the widget comes from
  /// project code.
  static String? of(
    GoldenRenderNode? widget,
    GoldenRenderComponent? component,
  ) {
    final source = widget?.source;
    if (widget != null &&
        component != null &&
        source != null &&
        source == component.source) {
      return designSystem;
    }
    if (source != null && source.project) return app;
    if (widget == null && component != null) return app;
    return null;
  }
}

/// Finding categories, written as plain strings to reports.
abstract final class GoldenFindingCategory {
  /// Font family, size, weight, line height, letter spacing, text role.
  static const String typography = 'typography';

  /// Text, fill, border, and icon colors.
  static const String color = 'color';

  /// Position and size of matched elements.
  static const String layout = 'layout';

  /// Corner radius, border width, shadows.
  static const String shape = 'shape';

  /// Design-system component type and variant properties.
  static const String component = 'component';

  /// Text content, line count, truncation.
  static const String content = 'content';

  /// Elements missing from the implementation or not in the design.
  static const String presence = 'presence';

  /// Fonts that were not loaded for real in the test.
  static const String font = 'font';

  /// Pixel regions that no structural finding explains.
  static const String visual = 'visual';

  /// Frame geometry and comparison setup.
  static const String frame = 'frame';

  /// Categories in display order.
  static const List<String> values = [
    font,
    frame,
    presence,
    component,
    typography,
    content,
    color,
    layout,
    shape,
    visual,
  ];
}

/// One property that differs inside a finding.
@immutable
final class GoldenFindingDiff {
  /// Creates a property difference.
  const GoldenFindingDiff({
    required this.property,
    required this.expected,
    required this.actual,
    required this.severity,
    this.unit,
    this.delta,
    this.scope,
  });

  /// Property name, such as `fontWeight` or `y`.
  final String property;

  /// Design value (JSON-encodable).
  final Object? expected;

  /// Implementation value (JSON-encodable).
  final Object? actual;

  /// Severity of this difference alone.
  final GoldenFindingSeverity severity;

  /// Unit, such as `px` or `ΔE`.
  final String? unit;

  /// Signed numeric difference (actual − expected), or the color distance.
  final double? delta;

  /// Part of the element the difference applies to, such as a run of text
  /// (`‘굵게’`) or the sibling a gap is measured from.
  final String? scope;

  /// JSON form.
  Map<String, Object?> toJson() => {
    'property': property,
    'expected': expected,
    'actual': actual,
    'unit': ?unit,
    if (delta != null) 'delta': goldenRound(delta!),
    'scope': ?scope,
    'severity': severity.name,
  };
}

/// A precise statement of how the implementation deviates from the design:
/// which element, which properties, by how much, and where to fix it.
@immutable
final class GoldenDesignFinding {
  /// Creates a finding.
  const GoldenDesignFinding({
    required this.id,
    required this.category,
    required this.severity,
    required this.message,
    this.diffs = const [],
    this.design,
    this.designPath,
    this.designRole,
    this.widget,
    this.component,
    this.widgetRole,
    this.rect,
    this.hint,
    this.known,
    this.owner,
  });

  /// Stable id: `<category>@<design node id>` or `<category>@<widget>`.
  final String id;

  /// One of [GoldenFindingCategory].
  final String category;

  /// Most severe difference.
  final GoldenFindingSeverity severity;

  /// One sentence in Korean for reviewers.
  final String message;

  /// The property differences.
  final List<GoldenFindingDiff> diffs;

  /// Design node, when the finding concerns one.
  final GoldenDesignNode? design;

  /// Layer path of [design].
  final String? designPath;

  /// Design-system text role of [design], such as `titleMedium`.
  final String? designRole;

  /// Rendered node, when the finding concerns one.
  final GoldenRenderNode? widget;

  /// Design-system component that contains or is [widget].
  final GoldenRenderComponent? component;

  /// Design-system text role the rendered style matches.
  final String? widgetRole;

  /// Area to highlight, in logical pixels.
  final GoldenRect? rect;

  /// What to change, when it can be said precisely.
  final String? hint;

  /// The known difference that accepts this finding, if any.
  final GoldenKnownDifference? known;

  /// Who decides the differing value: `app` when the app's code drew or
  /// configured it, `designSystem` when a design-system component drew it
  /// internally (fix or track it in the design system, not in the app).
  final String? owner;

  /// Whether the finding counts toward the verdict.
  bool get counts => known == null;

  /// Copy accepted by [difference].
  GoldenDesignFinding accept(GoldenKnownDifference difference) =>
      GoldenDesignFinding(
        id: id,
        category: category,
        severity: severity,
        message: message,
        diffs: diffs,
        design: design,
        designPath: designPath,
        designRole: designRole,
        widget: widget,
        component: component,
        widgetRole: widgetRole,
        rect: rect,
        hint: hint,
        known: difference,
        owner: owner,
      );

  /// Whether [difference] matches this finding.
  bool matches(GoldenKnownDifference difference) {
    if (difference.designNode != null && difference.designNode != design?.id) {
      return false;
    }
    if (difference.widget != null &&
        difference.widget != widget?.widget &&
        difference.widget != component?.name) {
      return false;
    }
    if (difference.category != null && difference.category != category) {
      return false;
    }
    if (difference.property != null &&
        !diffs.any((d) => d.property == difference.property)) {
      return false;
    }
    return true;
  }

  /// JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'category': category,
    'severity': severity.name,
    'message': message,
    if (diffs.isNotEmpty) 'diffs': [for (final d in diffs) d.toJson()],
    if (design != null)
      'design': {
        ...design!.toRef(),
        if (designPath != null) 'path': designPath,
        if (designRole != null) 'role': designRole,
      },
    if (widget != null)
      'widget': {
        'id': widget!.id,
        'kind': widget!.kind,
        'type': widget!.widget,
        if (widget!.key != null) 'key': widget!.key,
        if (widget!.text != null) 'text': widget!.text!.text,
        'rect': widget!.rect.toJson(),
        if (widget!.source != null) 'source': widget!.source!.label,
        if (widget!.path.isNotEmpty) 'path': widget!.path.join(' › '),
        if (widgetRole != null) 'role': widgetRole,
      },
    if (component != null) 'component': component!.toJson(),
    if (rect != null) 'rect': rect!.toJson(),
    'owner': ?owner,
    if (hint != null) 'hint': hint,
    if (known != null) 'known': known!.toJson(),
  };
}
