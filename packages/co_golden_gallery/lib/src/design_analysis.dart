import 'dart:convert';

import 'package:meta/meta.dart';

/// Schema name of co_golden design analysis reports.
const String galleryDesignReportSchema = 'co_golden.design_report';

/// Highest design analysis report version this gallery reads.
const int supportedDesignReportSchemaVersion = 1;

/// Findings kept per report; the rest stay in the report JSON.
const int galleryFindingLimit = 200;

/// Pixel regions kept per report; the rest stay in the report JSON.
const int galleryRegionLimit = 100;

/// Korean labels of the analysis verdicts.
const Map<String, String> galleryVerdictLabels = {
  'pass': '일치',
  'fail': '불일치',
  'undetermined': '판정 불가',
};

/// Korean labels of the finding severities.
const Map<String, String> gallerySeverityLabels = {
  'error': '오류',
  'warning': '경고',
  'info': '정보',
};

/// Korean labels of the finding categories.
const Map<String, String> galleryCategoryLabels = {
  'font': '폰트 로딩',
  'frame': '프레임',
  'presence': '누락/추가',
  'component': '컴포넌트',
  'typography': '서체',
  'content': '내용',
  'color': '색상',
  'layout': '레이아웃',
  'shape': '모양',
  'visual': '픽셀',
};

/// Display order of the finding categories, as co_golden writes them.
const List<String> galleryCategoryOrder = [
  'font',
  'frame',
  'presence',
  'component',
  'typography',
  'content',
  'color',
  'layout',
  'shape',
  'visual',
];

const List<String> _severities = ['error', 'warning', 'info'];
const Set<String> _verdicts = {'pass', 'fail', 'undetermined'};

/// Tolerance-based design analysis recorded by co_golden for one variant.
///
/// The run manifest carries this short form; [details] holds the trimmed
/// content of the report file when the gallery could read it.
@immutable
final class GalleryDesignAnalysis {
  /// Creates the analysis summary of one variant.
  const GalleryDesignAnalysis({
    required this.report,
    required this.verdict,
    this.pixelStatus,
    this.errors = 0,
    this.warnings = 0,
    this.infos = 0,
    this.known = 0,
    this.byCategory = const {},
    this.ratio,
    this.largestRegion,
    this.regionCount,
    this.diff,
    this.details,
  });

  /// Report JSON path relative to the capture root.
  final String report;

  /// `pass`, `fail`, or `undetermined`.
  final String verdict;

  /// Pixel part of the verdict: `pass`, `fail`, or `undetermined`.
  final String? pixelStatus;

  /// Error findings that count toward the verdict.
  final int errors;

  /// Warning findings that count toward the verdict.
  final int warnings;

  /// Info findings.
  final int infos;

  /// Findings accepted as known differences.
  final int known;

  /// Counting findings by category.
  final Map<String, int> byCategory;

  /// Differing fraction of the comparable pixels, when compared.
  final double? ratio;

  /// Largest differing region in logical px², when compared.
  final double? largestRegion;

  /// Number of differing regions, when compared.
  final int? regionCount;

  /// Tolerant difference map path relative to the capture root.
  final String? diff;

  /// Trimmed report content, or `null` when the report file is missing.
  final GalleryDesignReport? details;

  /// Whether the variant needs a look: anything but `pass`.
  bool get hasDifference => verdict != 'pass';

  /// Short label for the capture thumbnail.
  String get summary {
    switch (verdict) {
      case 'pass':
        return warnings > 0 ? '디자인 일치 · 경고 $warnings' : '디자인 일치(허용 오차 안)';
      case 'fail':
        if (errors > 0) {
          return '디자인 불일치 · 오류 $errors'
              '${warnings > 0 ? ' · 경고 $warnings' : ''}';
        }
        return pixelStatus == 'fail' ? '디자인 불일치 · 픽셀 예산 초과' : '디자인 불일치';
      default:
        return '디자인 판정 불가';
    }
  }

  /// One line with the verdict, pixel budget, and finding counts.
  String get line {
    final parts = <String>['허용 오차 판정 ${galleryVerdictLabels[verdict]}'];
    final budgetRatio = details?.budgetRatio;
    final budgetRegion = details?.budgetRegion;
    if (ratio case final value?) {
      parts.add(
        '픽셀 차이 ${galleryPercent(value)}'
        '${budgetRatio == null ? '' : ' (예산 ${galleryPercent(budgetRatio)})'}',
      );
    }
    if (largestRegion case final value?) {
      parts.add(
        '최대 영역 ${galleryNumber(value)}px²'
        '${budgetRegion == null ? '' : ' (예산 ${galleryNumber(budgetRegion)}px²)'}',
      );
    }
    if (pixelStatus == 'undetermined') {
      final reason = details?.pixelReason;
      parts.add('픽셀 비교 불가${reason == null ? '' : ' ($reason)'}');
    }
    parts.add('오류 $errors · 경고 $warnings · 정보 $infos');
    if (known > 0) parts.add('알려진 차이 $known');
    return parts.join(' · ');
  }

  /// Copy with report content.
  GalleryDesignAnalysis withDetails(GalleryDesignReport? value) =>
      GalleryDesignAnalysis(
        report: report,
        verdict: verdict,
        pixelStatus: pixelStatus,
        errors: errors,
        warnings: warnings,
        infos: infos,
        known: known,
        byCategory: byCategory,
        ratio: ratio,
        largestRegion: largestRegion,
        regionCount: regionCount,
        diff: diff,
        details: value,
      );

  /// Parses the manifest's `designComparison.analysis`, with the paths
  /// already checked by the scanner. Throws a [FormatException] for a
  /// malformed value.
  static GalleryDesignAnalysis parse(
    Map<String, Object?> json, {
    required String report,
    required String? diff,
  }) {
    final verdict = json['verdict'];
    if (verdict is! String || !_verdicts.contains(verdict)) {
      throw const FormatException('analysis.verdict is invalid');
    }
    final pixelStatus = json['pixelStatus'];
    if (pixelStatus != null &&
        (pixelStatus is! String || !_verdicts.contains(pixelStatus))) {
      throw const FormatException('analysis.pixelStatus is invalid');
    }
    final findings = json['findings'] ?? const <String, Object?>{};
    if (findings is! Map<String, Object?>) {
      throw const FormatException('analysis.findings is invalid');
    }
    int count(String key) {
      final value = findings[key] ?? 0;
      if (value is! int || value < 0) {
        throw FormatException('analysis.findings.$key is invalid');
      }
      return value;
    }

    final categories = json['byCategory'] ?? const <String, Object?>{};
    if (categories is! Map<String, Object?> ||
        categories.values.any((value) => value is! int || value < 0)) {
      throw const FormatException('analysis.byCategory is invalid');
    }
    final ratio = json['ratio'];
    if (ratio != null && (ratio is! num || !_unit(ratio))) {
      throw const FormatException('analysis.ratio is invalid');
    }
    final largest = json['largestRegion'];
    if (largest != null &&
        (largest is! num || !largest.isFinite || largest < 0)) {
      throw const FormatException('analysis.largestRegion is invalid');
    }
    final regions = json['regionCount'];
    if (regions != null && (regions is! int || regions < 0)) {
      throw const FormatException('analysis.regionCount is invalid');
    }
    return GalleryDesignAnalysis(
      report: report,
      verdict: verdict,
      pixelStatus: pixelStatus as String?,
      errors: count('error'),
      warnings: count('warning'),
      infos: count('info'),
      known: count('known'),
      byCategory: Map.unmodifiable(categories.cast<String, int>()),
      ratio: (ratio as num?)?.toDouble(),
      largestRegion: (largest as num?)?.toDouble(),
      regionCount: regions as int?,
      diff: diff,
    );
  }
}

/// One property difference of a finding.
@immutable
final class GalleryFindingDiff {
  /// Creates a property difference.
  const GalleryFindingDiff({
    required this.property,
    required this.expected,
    required this.actual,
    this.unit,
    this.delta,
    this.scope,
    this.severity = 'info',
  });

  /// Property name, such as `fontWeight`.
  final String property;

  /// Design value.
  final Object? expected;

  /// Implementation value.
  final Object? actual;

  /// Unit, such as `px` or `ΔE`.
  final String? unit;

  /// Signed numeric difference or color distance.
  final double? delta;

  /// Part of the element the difference applies to, such as a text run.
  final String? scope;

  /// `error`, `warning`, or `info`.
  final String severity;

  /// `fontWeight 700 → 600`, `y 112 → 120px (+8)`, `color #14161A → #2A2D33
  /// (ΔE 12.3)`.
  String get text {
    final unitText = unit == null || unit == 'ΔE' ? '' : unit!;
    final buffer = StringBuffer(
      '$property${scope == null ? '' : ' ($scope)'} '
      '${galleryValue(expected)} → ${galleryValue(actual)}',
    );
    if (actual is num || expected is num) buffer.write(unitText);
    if (delta case final value?) {
      if (unit == 'ΔE') {
        buffer.write(' (ΔE ${galleryNumber(value)})');
      } else if (actual is num && expected is num) {
        final sign = value > 0 ? '+' : '';
        buffer.write(' ($sign${galleryNumber(value)})');
      }
    }
    return buffer.toString();
  }

  /// JSON form for `--summary`.
  Map<String, Object?> toJson() => {
    'property': property,
    'expected': expected,
    'actual': actual,
    if (unit != null) 'unit': unit,
    if (delta != null) 'delta': delta,
    if (scope != null) 'scope': scope,
    'severity': severity,
  };
}

/// A finding of a design analysis report, trimmed for display.
@immutable
final class GalleryDesignFinding {
  /// Creates a finding.
  const GalleryDesignFinding({
    required this.id,
    required this.category,
    required this.severity,
    required this.message,
    this.diffs = const [],
    this.designId,
    this.designName,
    this.designType,
    this.designPath,
    this.designRole,
    this.designTextStyle,
    this.designComponent,
    this.designRect,
    this.widgetType,
    this.widgetKind,
    this.widgetText,
    this.widgetKey,
    this.widgetSource,
    this.widgetPath,
    this.widgetRole,
    this.widgetRect,
    this.componentName,
    this.componentLibrary,
    this.componentSource,
    this.componentProperties = const {},
    this.componentRect,
    this.rect,
    this.hint,
    this.owner,
    this.knownReason,
    this.knownIssue,
  });

  /// Stable id, such as `typography@12:350`.
  final String id;

  /// Category, such as `typography`.
  final String category;

  /// `error`, `warning`, or `info`.
  final String severity;

  /// Korean sentence from co_golden.
  final String message;

  /// Property differences.
  final List<GalleryFindingDiff> diffs;

  /// Design node id.
  final String? designId;

  /// Design layer name.
  final String? designName;

  /// Design node type.
  final String? designType;

  /// Design layer path.
  final String? designPath;

  /// Design-system text role of the design node.
  final String? designRole;

  /// Design text style name.
  final String? designTextStyle;

  /// Design component name.
  final String? designComponent;

  /// Design bounds `[x, y, w, h]` in the frame's logical pixels.
  final List<double>? designRect;

  /// Widget type.
  final String? widgetType;

  /// Rendered node kind.
  final String? widgetKind;

  /// Rendered text.
  final String? widgetText;

  /// Widget key.
  final String? widgetKey;

  /// Source location `file:line:column`.
  final String? widgetSource;

  /// Ancestor widget path.
  final String? widgetPath;

  /// Design-system text role the rendered style matches.
  final String? widgetRole;

  /// Rendered bounds `[x, y, w, h]` in the capture's logical pixels.
  final List<double>? widgetRect;

  /// Design-system component name.
  final String? componentName;

  /// Package that implements the component.
  final String? componentLibrary;

  /// Where the app created the component.
  final String? componentSource;

  /// Component identity properties.
  final Map<String, String> componentProperties;

  /// Component bounds in the capture's logical pixels.
  final List<double>? componentRect;

  /// Area to highlight when no element bounds exist.
  final List<double>? rect;

  /// What to change.
  final String? hint;

  /// Who decides the value: `app` or `designSystem` (a design-system
  /// component drew it internally, so it is fixed or tracked there).
  final String? owner;

  /// Korean label of [owner], or `null`.
  String? get ownerLabel => switch (owner) {
    'app' => '앱 코드',
    'designSystem' =>
      componentLibrary == null ? '디자인 시스템' : '디자인 시스템($componentLibrary)',
    _ => null,
  };

  /// Why the difference is accepted, when it is a known difference.
  final String? knownReason;

  /// HTTP(S) link of the tracking issue.
  final String? knownIssue;

  /// Whether the finding is accepted as a known difference.
  bool get known => knownReason != null;

  /// Korean category label.
  String get categoryLabel => galleryCategoryLabels[category] ?? category;

  /// Korean severity label.
  String get severityLabel => gallerySeverityLabels[severity] ?? severity;

  /// `Figma 12:350 Title · Login / Header / Title · 텍스트 스타일 Title/Medium`.
  String? get designLabel {
    if (designId == null && designName == null) return null;
    final parts = <String>[
      ['Figma', ?designId, ?designName].join(' '),
      if (designPath != null && designPath != designName) designPath!,
      if (designTextStyle != null) '텍스트 스타일 $designTextStyle',
      if (designRole != null) '역할 .$designRole',
      if (designComponent != null) '컴포넌트 $designComponent',
    ];
    return parts.join(' · ');
  }

  /// `Text ‘로그인’ · 역할 .bodyMedium`.
  String? get widgetLabel {
    if (widgetType == null) return null;
    final text = widgetText?.trim();
    return [
      [
        widgetType!,
        if (text != null && text.isNotEmpty) '‘${_clip(text, 40)}’',
      ].join(' '),
      if (widgetKey != null) 'key $widgetKey',
      if (widgetRole != null) '역할 .$widgetRole',
    ].join(' · ');
  }

  /// `Button (coui_flutter) · variant=primary, size=md`.
  String? get componentLabel {
    if (componentName == null) return null;
    final properties = [
      for (final MapEntry(:key, :value) in componentProperties.entries)
        '$key=$value',
    ].join(', ');
    return [
      componentLibrary == null
          ? componentName!
          : '$componentName ($componentLibrary)',
      if (properties.isNotEmpty) properties,
    ].join(' · ');
  }

  /// Where to fix: the widget's source, else the component's.
  String? get where => widgetSource ?? componentSource;

  /// Element name for headings: the text, else the layer, else the widget.
  String get element {
    final text = widgetText?.trim();
    if (text != null && text.isNotEmpty) return '‘${_clip(text, 40)}’';
    return designName ?? widgetType ?? componentName ?? id;
  }

  /// Data embedded in the page for the viewer.
  Map<String, Object?> toViewJson() => {
    'id': id,
    'category': category,
    'severity': severity,
    'message': message,
    'diffs': [for (final diff in diffs) diff.text],
    'where': ?where,
    'design': designRect == null && designLabel == null
        ? null
        : {'rect': designRect, 'label': designLabel},
    'widget': widgetRect == null && widgetLabel == null
        ? null
        : {'rect': widgetRect, 'label': widgetLabel},
    'component': componentName == null
        ? null
        : {
            'rect': componentRect,
            'label': componentLabel,
            'source': componentSource,
          },
    'rect': rect,
    'hint': hint,
    'owner': ?ownerLabel,
    'known': known ? {'reason': knownReason, 'issue': knownIssue} : null,
  };

  /// Flattened form for `--summary`.
  Map<String, Object?> toSummaryJson() => {
    'id': id,
    'category': category,
    'severity': severity,
    'message': message,
    'known': known,
    if (knownReason != null) 'knownReason': knownReason,
    if (knownIssue != null) 'issue': knownIssue,
    if (designId != null || designName != null)
      'design': {
        'id': designId,
        'name': designName,
        'type': designType,
        'path': designPath,
        if (designTextStyle != null) 'textStyle': designTextStyle,
        if (designRole != null) 'role': designRole,
        if (designComponent != null) 'component': designComponent,
        'rect': designRect,
      },
    if (widgetType != null)
      'widget': {
        'type': widgetType,
        'kind': widgetKind,
        if (widgetText != null) 'text': widgetText,
        if (widgetKey != null) 'key': widgetKey,
        'source': widgetSource,
        if (widgetPath != null) 'path': widgetPath,
        if (widgetRole != null) 'role': widgetRole,
        'rect': widgetRect,
      },
    if (componentName != null)
      'component': {
        'name': componentName,
        'library': componentLibrary,
        'properties': componentProperties,
        'source': componentSource,
      },
    if (diffs.isNotEmpty) 'diffs': [for (final diff in diffs) diff.toJson()],
    'owner': ?owner,
    if (hint != null) 'hint': hint,
  };
}

/// A differing pixel region of a report.
@immutable
final class GalleryDesignRegion {
  /// Creates a region.
  const GalleryDesignRegion({
    required this.id,
    required this.rect,
    required this.logicalPixels,
    this.meanDeltaE,
    this.designColor,
    this.renderColor,
    this.designId,
    this.designName,
    this.widgetType,
    this.widgetText,
    this.widgetSource,
    this.findings = const [],
    this.knownReason,
    this.knownIssue,
  });

  /// `node:<id>` or `cell:<x>,<y>`.
  final String id;

  /// Bounds `[x, y, w, h]` in the compared logical pixels.
  final List<double> rect;

  /// Differing area in logical px².
  final double logicalPixels;

  /// Mean CIEDE2000.
  final double? meanDeltaE;

  /// Mean design color `#RRGGBB`.
  final String? designColor;

  /// Mean implementation color `#RRGGBB`.
  final String? renderColor;

  /// Design node id under the region.
  final String? designId;

  /// Design layer name under the region.
  final String? designName;

  /// Widget type under the region.
  final String? widgetType;

  /// Text of the widget under the region.
  final String? widgetText;

  /// Source location of the widget under the region.
  final String? widgetSource;

  /// Ids of findings about the same element.
  final List<String> findings;

  /// Why the region is accepted, when it is a known difference.
  final String? knownReason;

  /// HTTP(S) link of the tracking issue.
  final String? knownIssue;

  /// Whether the region is accepted as a known difference.
  bool get known => knownReason != null;

  /// Whether no finding explains the region and it is not known.
  bool get unexplained => findings.isEmpty && !known;

  /// `45.5px² · ΔE 18.2 · Figma Title 12:350 · 구현 Text ‘로그인’ lib/a.dart:3:1`.
  String get label {
    final [x, y, w, h] = rect;
    final widget = widgetType == null
        ? null
        : [
            '구현 $widgetType',
            if (widgetText case final text? when text.trim().isNotEmpty)
              '‘${_clip(text.trim(), 30)}’',
            ?widgetSource,
          ].join(' ');
    return [
      '${galleryNumber(w)}×${galleryNumber(h)} @ '
          '(${galleryNumber(x)}, ${galleryNumber(y)})',
      '${galleryNumber(logicalPixels)}px²',
      if (meanDeltaE case final value?) 'ΔE ${galleryNumber(value)}',
      if (designName != null || designId != null)
        ['Figma', ?designName, ?designId].join(' '),
      ?widget,
      if (designColor != null && renderColor != null)
        '$designColor → $renderColor',
    ].join(' · ');
  }

  /// Data embedded in the page for the viewer.
  Map<String, Object?> toViewJson() => {
    'id': id,
    'rect': rect,
    'label': label,
    'unexplained': unexplained,
    'known': known ? {'reason': knownReason, 'issue': knownIssue} : null,
  };
}

/// A masked area of a report.
@immutable
final class GalleryDesignMask {
  /// Creates a mask.
  const GalleryDesignMask({
    required this.rect,
    required this.reason,
    this.source,
  });

  /// Bounds `[x, y, w, h]` in logical pixels.
  final List<double> rect;

  /// Why the area was not compared.
  final String reason;

  /// `safeArea`, `rect`, `figmaNode:<id>`, or `finder:<description>`.
  final String? source;

  /// Data embedded in the page.
  Map<String, Object?> toViewJson() => {
    'rect': rect,
    'reason': reason,
    'source': source,
  };
}

/// Trimmed content of a co_golden design analysis report.
@immutable
final class GalleryDesignReport {
  /// Creates report content.
  const GalleryDesignReport({
    required this.verdict,
    this.reasons = const [],
    this.pixelStatus,
    this.pixelReason,
    this.pixelDetail,
    this.budgetRatio,
    this.budgetRegion,
    this.designSize,
    this.renderSize,
    this.comparedSize,
    this.frameId,
    this.frameName,
    this.sourceFormat,
    this.hasStyles,
    this.designSystem,
    this.toleranceChanged = const [],
    this.findings = const [],
    this.findingsTruncated = 0,
    this.regions = const [],
    this.regionsTruncated = 0,
    this.masks = const [],
    this.warnings = const [],
  });

  /// `pass`, `fail`, or `undetermined`.
  final String verdict;

  /// Reasons such as `pixels:budget` or `findings:error`.
  final List<String> reasons;

  /// Pixel status.
  final String? pixelStatus;

  /// Why the pixel comparison was undetermined.
  final String? pixelReason;

  /// Explanation of [pixelReason].
  final String? pixelDetail;

  /// Largest passing fraction of differing pixels.
  final double? budgetRatio;

  /// Largest passing region in logical px².
  final double? budgetRegion;

  /// Logical frame size `[w, h]` of the design.
  final List<double>? designSize;

  /// Logical size `[w, h]` of the capture.
  final List<double>? renderSize;

  /// Logical size `[w, h]` of the compared images.
  final List<double>? comparedSize;

  /// Design frame node id.
  final String? frameId;

  /// Design frame name.
  final String? frameName;

  /// Specification format, such as `figma-rest`.
  final String? sourceFormat;

  /// Whether the specification carried styles.
  final bool? hasStyles;

  /// Design system name, such as `CoUI`.
  final String? designSystem;

  /// Tolerances that differ from the defaults.
  final List<String> toleranceChanged;

  /// Findings, most severe first, known differences last.
  final List<GalleryDesignFinding> findings;

  /// Findings left out of [findings].
  final int findingsTruncated;

  /// Regions, largest first.
  final List<GalleryDesignRegion> regions;

  /// Regions left out of [regions].
  final int regionsTruncated;

  /// Masks.
  final List<GalleryDesignMask> masks;

  /// Comparison warnings.
  final List<String> warnings;

  /// Regions that no finding explains and that are not known.
  Iterable<GalleryDesignRegion> get unexplainedRegions =>
      regions.where((region) => region.unexplained);

  /// Parses a decoded report. Throws a [FormatException] when it is not a
  /// readable `co_golden.design_report`.
  static GalleryDesignReport parse(Object? json) {
    if (json is! Map<String, Object?> ||
        json['schema'] != galleryDesignReportSchema) {
      throw const FormatException('is not a $galleryDesignReportSchema');
    }
    final version = json['schemaVersion'];
    if (version is! int || version > supportedDesignReportSchemaVersion) {
      throw FormatException(
        'uses schema version $version; this gallery reads up to '
        '$supportedDesignReportSchemaVersion',
      );
    }
    final verdict = json['verdict'];
    if (verdict is! String || !_verdicts.contains(verdict)) {
      throw const FormatException('has an invalid verdict');
    }
    final design = _map(json['design']);
    final frame = _map(design?['frame']);
    final render = _map(json['render']);
    final pixels = _map(json['pixels']);
    final tolerance = _map(json['tolerance']);
    final scale = _double(pixels?['scale']);
    final pixelWidth = _double(pixels?['width']);
    final pixelHeight = _double(pixels?['height']);
    final rawFindings = [
      for (final item in _list(json['findings'])) ?_map(item),
    ];
    final parsed = [for (final raw in rawFindings) _finding(raw)];
    final order = {for (var i = 0; i < parsed.length; i++) parsed[i]: i};
    final findings = [...parsed]
      ..sort((a, b) {
        final byRank = _findingOrder(a, b);
        return byRank != 0 ? byRank : order[a]!.compareTo(order[b]!);
      });
    final rawRegions = [
      for (final item in _list(json['regions']))
        if (_map(item) case final map?)
          if (_rect(map['rect']) != null) map,
    ];
    return GalleryDesignReport(
      verdict: verdict,
      reasons: _strings(json['verdictReasons']),
      pixelStatus: _verdictOrNull(pixels?['status']),
      pixelReason: _string(pixels?['reason']),
      pixelDetail: _string(pixels?['detail']),
      budgetRatio: _double(tolerance?['budgetRatio']),
      budgetRegion: _double(tolerance?['budgetRegion']),
      designSize: _size(frame?['width'], frame?['height']),
      renderSize: _size(render?['width'], render?['height']),
      comparedSize: scale == null || scale <= 0
          ? null
          : _size(
              pixelWidth == null ? null : pixelWidth / scale,
              pixelHeight == null ? null : pixelHeight / scale,
            ),
      frameId: _string(frame?['id']),
      frameName: _string(frame?['name']),
      sourceFormat: _string(_map(design?['source'])?['format']),
      hasStyles: design?['hasStyles'] is bool
          ? design!['hasStyles']! as bool
          : null,
      designSystem: _string(_map(json['designSystem'])?['name']),
      toleranceChanged: _strings(tolerance?['changed']),
      findings: List.unmodifiable(findings.take(galleryFindingLimit)),
      findingsTruncated: findings.length > galleryFindingLimit
          ? findings.length - galleryFindingLimit
          : 0,
      regions: List.unmodifiable([
        for (final raw in rawRegions.take(galleryRegionLimit)) _region(raw),
      ]),
      regionsTruncated: rawRegions.length > galleryRegionLimit
          ? rawRegions.length - galleryRegionLimit
          : 0,
      masks: List.unmodifiable([
        for (final item in _list(json['masks']))
          if (_map(item) case final mask?)
            if (_rect(mask['rect']) case final rect?)
              GalleryDesignMask(
                rect: rect,
                reason: _string(mask['reason']) ?? '',
                source: _string(mask['source']),
              ),
      ]),
      warnings: _strings(json['warnings']),
    );
  }

  /// Data embedded in the page for the viewer.
  Map<String, Object?> toViewJson() => {
    'designSize': designSize,
    'renderSize': renderSize,
    'comparedSize': comparedSize,
    'findings': [for (final finding in findings) finding.toViewJson()],
    'findingsTruncated': findingsTruncated,
    'regions': [for (final region in regions) region.toViewJson()],
    'regionsTruncated': regionsTruncated,
    'masks': [for (final mask in masks) mask.toViewJson()],
    'warnings': [
      ...warnings,
      if (toleranceChanged.isNotEmpty)
        '기본값과 다른 허용 오차: ${toleranceChanged.join(', ')}',
    ],
  };
}

GalleryDesignFinding _finding(Map<String, Object?> json) {
  final design = _map(json['design']);
  final widget = _map(json['widget']);
  final component = _map(json['component']);
  final known = _map(json['known']);
  final severity = json['severity'];
  return GalleryDesignFinding(
    id: _string(json['id']) ?? '',
    category: _string(json['category']) ?? 'visual',
    severity: severity is String && _severities.contains(severity)
        ? severity
        : 'info',
    message: _string(json['message']) ?? '',
    diffs: [
      for (final item in _list(json['diffs']))
        if (_map(item) case final diff?)
          GalleryFindingDiff(
            property: _string(diff['property']) ?? '',
            expected: _plain(diff['expected']),
            actual: _plain(diff['actual']),
            unit: _string(diff['unit']),
            delta: _double(diff['delta']),
            scope: _string(diff['scope']),
            severity: _severities.contains(diff['severity'])
                ? diff['severity']! as String
                : 'info',
          ),
    ],
    designId: _string(design?['id']),
    designName: _string(design?['name']),
    designType: _string(design?['type']),
    designPath: _string(design?['path']),
    designRole: _string(design?['role']),
    designTextStyle: _string(design?['textStyle']),
    designComponent: _string(design?['component']),
    designRect: _rect(design?['rect']),
    widgetType: _string(widget?['type']),
    widgetKind: _string(widget?['kind']),
    widgetText: _string(widget?['text']),
    widgetKey: _string(widget?['key']),
    widgetSource: _string(widget?['source']),
    widgetPath: _string(widget?['path']),
    widgetRole: _string(widget?['role']),
    widgetRect: _rect(widget?['rect']),
    componentName: _string(component?['name']),
    componentLibrary: _string(component?['library']),
    componentSource: _string(component?['source']),
    componentProperties: {
      for (final MapEntry(:key, :value)
          in (_map(component?['properties']) ?? const {}).entries)
        if (value != null) key: '$value',
    },
    componentRect: _rect(component?['rect']),
    rect: _rect(json['rect']),
    hint: _string(json['hint']),
    owner: switch (json['owner']) {
      'app' => 'app',
      'designSystem' => 'designSystem',
      _ => null,
    },
    knownReason: known == null ? null : (_string(known['reason']) ?? '알려진 차이'),
    knownIssue: _httpUrl(known?['issue']),
  );
}

GalleryDesignRegion _region(Map<String, Object?> json) {
  final design = _map(json['design']);
  final widget = _map(json['widget']);
  final known = _map(json['known']);
  return GalleryDesignRegion(
    id: _string(json['id']) ?? '',
    rect: _rect(json['rect'])!,
    logicalPixels: _double(json['logicalPixels']) ?? 0,
    meanDeltaE: _double(json['meanDeltaE']),
    designColor: _string(json['designColor']),
    renderColor: _string(json['renderColor']),
    designId: _string(design?['id']),
    designName: _string(design?['name']),
    widgetType: _string(widget?['type']),
    widgetText: _string(widget?['text']),
    widgetSource: _string(widget?['source']),
    findings: _strings(json['findings']),
    knownReason: known == null ? null : (_string(known['reason']) ?? '알려진 차이'),
    knownIssue: _httpUrl(known?['issue']),
  );
}

int _findingOrder(GalleryDesignFinding a, GalleryDesignFinding b) {
  if (a.known != b.known) return a.known ? 1 : -1;
  return _severities
      .indexOf(a.severity)
      .compareTo(_severities.indexOf(b.severity));
}

/// `0.420%`, or `<0.001%` for a nonzero ratio that would round to zero.
String galleryPercent(double ratio) {
  final percent = ratio * 100;
  if (percent > 0 && percent < .001) return '<0.001%';
  return '${percent.toStringAsFixed(3)}%';
}

/// A number without needless decimals: `16`, `0.24`, `-0.25`, `45.5`.
String galleryNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// A design or implementation value for messages.
String galleryValue(Object? value) => switch (value) {
  null => '없음',
  final num number => galleryNumber(number),
  final String text => text,
  final bool flag => flag ? 'true' : 'false',
  _ => jsonEncode(value),
};

String _clip(String value, int length) =>
    value.length > length ? '${value.substring(0, length - 1)}…' : value;

bool _unit(num value) => value.isFinite && value >= 0 && value <= 1;

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

List<Object?> _list(Object? value) => value is List<Object?> ? value : const [];

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

double? _double(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;

List<String> _strings(Object? value) => List.unmodifiable([
  for (final item in _list(value))
    if (item is String) item,
]);

String? _verdictOrNull(Object? value) =>
    value is String && _verdicts.contains(value) ? value : null;

List<double>? _size(Object? width, Object? height) {
  final w = _double(width);
  final h = _double(height);
  return w == null || h == null || w <= 0 || h <= 0
      ? null
      : List.unmodifiable([w, h]);
}

List<double>? _rect(Object? value) {
  if (value is! List<Object?> || value.length != 4) return null;
  final numbers = [for (final item in value) _double(item)];
  if (numbers.any((n) => n == null)) return null;
  final rect = numbers.cast<double>();
  if (rect[2] < 0 || rect[3] < 0) return null;
  return List.unmodifiable(rect);
}

/// Keeps JSON scalars and small structures; drops anything else.
Object? _plain(Object? value) => switch (value) {
  null || num() || String() || bool() => value,
  List<Object?>() || Map<String, Object?>() => value,
  _ => '$value',
};

String? _httpUrl(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  return uri != null &&
          const {'http', 'https'}.contains(uri.scheme) &&
          uri.host.isNotEmpty
      ? value
      : null;
}
