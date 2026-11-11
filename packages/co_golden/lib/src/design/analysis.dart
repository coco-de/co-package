import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

import '../design_reference.dart';
import 'design_system.dart';
import 'finding.dart';
import 'geometry.dart';
import 'icon_raster_evidence.dart';
import 'image_raster_evidence.dart';
import 'inspection.dart';
import 'mask.dart';
import 'package_map.dart';
import 'pixel_diff.dart';
import 'region_attribution.dart';
import 'render_node.dart';
import 'report.dart';
import 'spec.dart';
import 'structural_diff.dart';
import 'text_raster_evidence.dart';
import 'tolerance.dart';
import 'visual_regions.dart';

/// Configures the design analysis that runs in capture mode for every
/// variant with a [GoldenDesignReference].
///
/// The analysis explains *how* a capture differs from its design:
///
/// - a tolerant pixel comparison (perceptual color distance, positional
///   radius, anti-aliasing) measured against a budget, with differing
///   regions attributed to the design node and the widget under them;
/// - with a design specification ([GoldenDesignReference.specPath]), a
///   structural comparison of every text, box, image, icon, and component:
///   font family, size, weight, line height, letter spacing, text role,
///   colors and tokens, radii, borders, shadows, positions, sizes, gaps,
///   component variants, missing and extra elements;
/// - checks that need no design: fonts that silently fell back to the test
///   font, and images that were not decoded at capture time.
///
/// Each finding names the source location that created the widget, so a
/// person or an AI agent can go straight to the line to fix. The verdict is
/// informational unless [failOnMismatch] is set.
@immutable
final class GoldenDesignAnalysis {
  /// Creates an analysis configuration.
  const GoldenDesignAnalysis({
    this.enabled = true,
    this.tolerance = const GoldenDesignTolerance(),
    this.designSystem = const GoldenDesignSystem(),
    this.maskSafeArea = true,
    this.masks = const [],
    this.knownDifferences = const [],
    this.failOnMismatch = false,
  });

  /// Runs only the exact RGBA comparison of earlier versions.
  static const GoldenDesignAnalysis off = GoldenDesignAnalysis(enabled: false);

  /// Whether the analysis runs.
  final bool enabled;

  /// Tolerances; a reference may override them.
  final GoldenDesignTolerance tolerance;

  /// How design-system components and text roles are recognized.
  final GoldenDesignSystem designSystem;

  /// Masks the device's safe-area bands (status bar, home indicator), which
  /// the design draws and the app does not.
  final bool maskSafeArea;

  /// Masks for every variant; references add their own.
  final List<GoldenDesignMask> masks;

  /// Known differences for every variant; references add their own.
  final List<GoldenKnownDifference> knownDifferences;

  /// Fails the variant when the verdict is
  /// [GoldenDesignVerdict.fail] — a design gate for CI.
  final bool failOnMismatch;
}

/// Everything the analysis needs from a running variant.
final class GoldenDesignAnalysisInput {
  /// Creates the input.
  const GoldenDesignAnalysisInput({
    required this.analysis,
    required this.reference,
    required this.outputDirectory,
    required this.suite,
    required this.scenario,
    required this.fileStem,
    required this.variant,
    required this.renderPath,
    required this.referencePath,
    required this.referenceImage,
    required this.renderImage,
    required this.referenceBytes,
    required this.boundaryElement,
    required this.boundary,
    required this.safeAreaTop,
    required this.safeAreaBottom,
    required this.textScale,
    this.themeContext,
  });

  /// Configuration.
  final GoldenDesignAnalysis analysis;

  /// Design reference of the variant.
  final GoldenDesignReference reference;

  /// Capture output directory.
  final String outputDirectory;

  /// Suite name.
  final String suite;

  /// Scenario name.
  final String scenario;

  /// Variant file stem.
  final String fileStem;

  /// Variant axes as JSON.
  final Map<String, Object?> variant;

  /// Output-relative render path.
  final String renderPath;

  /// Output-relative reference snapshot path.
  final String referencePath;

  /// Decoded design export.
  final image.Image referenceImage;

  /// Decoded render.
  final image.Image renderImage;

  /// Original bytes of the design export.
  final List<int> referenceBytes;

  /// Element of the capture boundary.
  final Element boundaryElement;

  /// Render object of the capture boundary.
  final RenderBox boundary;

  /// Device safe area at the top, in logical pixels.
  final double safeAreaTop;

  /// Device safe area at the bottom, in logical pixels.
  final double safeAreaBottom;

  /// Text scale of the variant.
  final double textScale;

  /// A context below the app's theme, for [GoldenDesignSystem.colorTokens].
  final BuildContext? themeContext;
}

final Map<String, (GoldenPackageMap, GoldenComponentCatalog?)> _systems = {};

/// Runs the design analysis, writes the report and the tolerant difference
/// map, and returns the report.
///
/// Synchronous on purpose: widget tests run in a fake-async zone where real
/// asynchronous IO never completes. Configuration errors (a missing or
/// unreadable spec, a mask without a reason, invalid tolerances) throw; an
/// unexpected failure inside inspection or comparison becomes a report
/// warning and an `undetermined` part instead of failing a capture that the
/// exact comparison alone would have passed.
GoldenDesignReport runDesignAnalysis(GoldenDesignAnalysisInput input) {
  final reference = input.reference;
  final analysis = input.analysis;
  final tolerance = reference.tolerance ?? analysis.tolerance;
  tolerance.validate();
  final warnings = <String>[];

  // Design specification: read once, snapshot the exact bytes.
  GoldenDesignSpec? spec;
  String? specSha;
  final specPath = reference.specPath;
  if (specPath != null) {
    final file = File(specPath);
    if (!file.existsSync()) {
      throw FormatException('Design specification not found: $specPath');
    }
    final bytes = file.readAsBytesSync();
    specSha = sha256.convert(bytes).toString();
    spec = GoldenDesignSpec.parse(
      jsonDecode(utf8.decode(bytes)),
      nodeId: reference.nodeId,
    );
    final copy = File(
      p.join(
        input.outputDirectory,
        p.posix.join(
          'references',
          input.suite,
          input.scenario,
          '${input.fileStem}.design.json',
        ),
      ),
    );
    copy.parent.createSync(recursive: true);
    copy.writeAsBytesSync(bytes, flush: true);
  }

  // Design system and inspection.
  final system = analysis.designSystem;
  final (packages, catalog) = _systemFor(system);
  GoldenRenderSnapshot snapshot;
  try {
    snapshot = GoldenRenderInspector(
      designSystem: system,
      packages: packages,
      catalog: catalog,
    ).inspect(input.boundaryElement, input.boundary);
  } on Object catch (error) {
    snapshot = GoldenRenderSnapshot(
      width: input.boundary.size.width,
      height: input.boundary.size.height,
      nodes: const [],
      warnings: ['Inspection failed: $error'],
    );
  }
  final colorTokens = <String, int>{};
  final context = input.themeContext;
  if (system.colorTokens != null && context != null) {
    try {
      for (final MapEntry(:key, :value)
          in system.colorTokens!(context).entries) {
        colorTokens[key] = value.toARGB32();
      }
    } on Object catch (error) {
      warnings.add('colorTokens failed: $error');
    }
  }

  // Masks.
  final masks = _masks(input, spec, snapshot, warnings);

  // Pixels.
  final diffPath = p.posix.join(
    'analysis',
    input.suite,
    input.scenario,
    '${input.fileStem}.png',
  );
  GoldenReportPixels pixels;
  GoldenRgbImage? referencePixels;
  GoldenRgbImage? renderPixels;
  try {
    referencePixels = GoldenRgbImage.fromImage(input.referenceImage);
    renderPixels = GoldenRgbImage.fromImage(input.renderImage);
    final diff = compareDesignPixels(
      reference: referencePixels,
      render: renderPixels,
      logicalWidth: snapshot.width,
      tolerance: tolerance,
      masks: [for (final mask in masks) mask.rect],
      textBoxes: [
        if (spec != null)
          for (final node in spec.nodes)
            if (node.isText) node.inkRect ?? node.rect,
        for (final node in snapshot.nodes)
          if (node.text != null) node.text!.contentRect,
      ],
    );
    final file = File(p.join(input.outputDirectory, diffPath));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(
      image.encodePng(diff.diffMap(referencePixels)),
      flush: true,
    );
    pixels = GoldenReportPixels.compared(diff, diffPath: diffPath);
  } on GoldenPixelUndetermined catch (error) {
    pixels = GoldenReportPixels.undetermined(error.reason, error.detail);
  } on Object catch (error) {
    pixels = GoldenReportPixels.undetermined('error', '$error');
  }

  // Structure and setup checks.
  final findings = <GoldenDesignFinding>[...goldenFontFindings(snapshot)];
  var matchedDesign = 0;
  var matchedRender = 0;
  var compared = 0;
  final structuralMatches = <String, int>{};
  if (spec != null) {
    try {
      final result = compareDesignStructure(
        spec,
        snapshot,
        GoldenStructuralContext(
          tolerance: tolerance,
          catalog: catalog,
          mappings: system.components,
          colorTokens: colorTokens,
          masks: [for (final mask in masks) mask.rect],
          regions: pixels.diff?.regions,
          textScale: input.textScale,
        ),
      );
      findings.addAll(result.findings);
      matchedDesign = result.matches.length;
      matchedRender = result.matches.values.toSet().length;
      compared = result.compared;
      structuralMatches.addAll(result.matches);
    } on Object catch (error) {
      warnings.add('Structural comparison failed: $error');
    }
  }
  if (snapshot.warnings.any((w) => w.startsWith('An image'))) {
    findings.add(
      const GoldenDesignFinding(
        id: 'content.image',
        category: GoldenFindingCategory.content,
        severity: GoldenFindingSeverity.warning,
        message: '이미지가 디코딩되기 전에 캡처됐습니다 — 빈 상자로 비교됩니다.',
        hint: 'scenario(pump: GoldenPumps.withRealAsyncWork()) 로 캡처하세요.',
      ),
    );
  }

  // Known differences accept findings first; regions follow their findings.
  final known = [...analysis.knownDifferences, ...reference.knownDifferences];
  GoldenDesignFinding accept(GoldenDesignFinding finding) {
    for (final difference in known) {
      if (finding.matches(difference)) return finding.accept(difference);
    }
    return finding;
  }

  final resolved = [for (final finding in findings) accept(finding)];
  final regions = _regions(
    pixels,
    spec,
    snapshot,
    resolved,
    known,
    structuralMatches,
    tolerance,
  );

  // Regions that no finding explains become visual findings.
  final rasterEvidence = <String, GoldenTextRasterEvidence?>{};
  final imageAssets = <String, Uint8List?>{};
  final refPixels = referencePixels;
  final actualPixels = renderPixels;
  for (final region in goldenGroupUnexplainedRegions(regions)) {
    GoldenTextRasterEvidence? evidence;
    final design = region.design;
    final widget = region.widget;
    if (design != null &&
        widget != null &&
        refPixels != null &&
        actualPixels != null &&
        structuralMatches[design.id] == widget.id) {
      evidence = rasterEvidence.putIfAbsent(
        '${design.id}/${widget.id}',
        () => GoldenTextRasterEvidence.compare(
          design: design,
          render: widget,
          fonts: snapshot.fonts,
          reference: refPixels,
          actual: actualPixels,
          logicalWidth: snapshot.width,
          tolerance: tolerance,
        ),
      );
    }
    final iconEvidence =
        design != null &&
            widget != null &&
            refPixels != null &&
            actualPixels != null &&
            structuralMatches[design.id] == widget.id
        ? goldenIconRasterEvidence(
            design: design,
            render: widget,
            snapshot: snapshot,
            reference: refPixels,
            actual: actualPixels,
            logicalWidth: snapshot.width,
            tolerance: tolerance,
          )
        : null;
    GoldenImageRasterEvidence? imageEvidence;
    if (design != null &&
        widget != null &&
        refPixels != null &&
        actualPixels != null &&
        structuralMatches[design.id] == widget.id &&
        widget.imageDescription != null) {
      final bytes = imageAssets.putIfAbsent(
        widget.imageDescription!,
        () => goldenAssetImageBytes(widget.imageDescription, packages),
      );
      if (bytes != null) {
        imageEvidence = GoldenImageRasterEvidence.compare(
          design: design,
          render: widget,
          sourceBytes: bytes,
          reference: refPixels,
          actual: actualPixels,
          logicalWidth: snapshot.width,
          tolerance: tolerance,
        );
      }
    }
    resolved.add(
      accept(
        _visualFinding(
          region,
          spec,
          snapshot,
          tolerance,
          rasterCoverage:
              evidence?.coverage ??
              iconEvidence?.coverage ??
              imageEvidence?.coverage,
          rasterKind: imageEvidence != null
              ? '이미지'
              : iconEvidence == null
              ? '글자'
              : '아이콘',
        ),
      ),
    );
  }
  resolved.sort(_compareFindings);

  final report = GoldenDesignReport(
    suite: input.suite,
    scenario: input.scenario,
    fileStem: input.fileStem,
    variant: input.variant,
    label: reference.label,
    sourceUrl: reference.sourceUrl,
    reference: input.referencePath,
    referenceSha256: sha256.convert(input.referenceBytes).toString(),
    specPath: specPath,
    specSha256: specSha,
    spec: spec,
    render: input.renderPath,
    tolerance: tolerance,
    pixels: pixels,
    snapshot: snapshot,
    designSystem: {
      'name': system.name ?? catalog?.name ?? 'none',
      if (catalog?.path != null) 'catalog': packages.display(catalog!.path!),
      if (catalog != null) 'components': catalog.components.length,
      if (catalog != null) 'textRoles': catalog.textRoles.length,
      if (system.components.isNotEmpty) 'mappings': system.components.length,
      'colorTokens': colorTokens.length,
    },
    masks: masks,
    regions: regions,
    findings: resolved,
    matchedDesign: matchedDesign,
    matchedRender: matchedRender,
    comparedDesign: compared,
    warnings: [...?spec?.warnings, ...warnings],
  );
  report.write(input.outputDirectory, reportPathOf(input));
  return report;
}

List<GoldenResolvedMask> _masks(
  GoldenDesignAnalysisInput input,
  GoldenDesignSpec? spec,
  GoldenRenderSnapshot snapshot,
  List<String> warnings,
) {
  final masks = <GoldenResolvedMask>[];
  final width = snapshot.width;
  final height = snapshot.height;
  if (input.analysis.maskSafeArea) {
    final top = [
      input.safeAreaTop,
      spec?.insetTop ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    final bottom = [
      input.safeAreaBottom,
      spec?.insetBottom ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    if (top > 0) {
      masks.add(
        GoldenResolvedMask(
          GoldenRect(0, 0, width, top),
          '기기 안전 영역(상태 바) — 앱이 그리지 않는다',
          'safeArea',
        ),
      );
    }
    if (bottom > 0) {
      masks.add(
        GoldenResolvedMask(
          GoldenRect(0, height - bottom, width, bottom),
          '기기 안전 영역(홈 인디케이터) — 앱이 그리지 않는다',
          'safeArea',
        ),
      );
    }
  }
  for (final mask in [...input.analysis.masks, ...input.reference.masks]) {
    if (mask.reason.trim().isEmpty) {
      throw ArgumentError.value(mask, 'mask', 'needs a reason');
    }
    switch (mask) {
      case GoldenDesignRectMask(:final rect):
        masks.add(
          GoldenResolvedMask(
            GoldenRect(rect.left, rect.top, rect.width, rect.height),
            mask.reason,
            'rect',
          ),
        );
      case GoldenDesignNodeMask(:final nodeId):
        final node = spec?[nodeId.replaceAll('-', ':')];
        if (node == null) {
          warnings.add('Mask node $nodeId is not in the design specification.');
        } else {
          masks.add(
            GoldenResolvedMask(node.rect, mask.reason, 'figmaNode:${node.id}'),
          );
        }
      case GoldenDesignFinderMask(:final finder):
        List<Element> found;
        try {
          found = finder.evaluate().toList();
        } on Object catch (error) {
          warnings.add('Mask finder failed ($finder): $error');
          continue;
        }
        if (found.isEmpty) warnings.add('Mask finder found nothing: $finder');
        for (final element in found) {
          final render = element.renderObject;
          if (render is! RenderBox || !render.hasSize || !render.attached) {
            continue;
          }
          final rect = MatrixUtils.transformRect(
            render.getTransformTo(input.boundary),
            Offset.zero & render.size,
          );
          masks.add(
            GoldenResolvedMask(
              GoldenRect(rect.left, rect.top, rect.width, rect.height),
              mask.reason,
              'finder:${element.widget.runtimeType}',
            ),
          );
        }
    }
  }
  return masks;
}

/// Attributes each pixel region to the design node and widget under its
/// center, links the findings that explain it, and decides whether a known
/// difference accepts it: one aimed at the region's node or widget for the
/// `visual` category (or any category when none is given and no property is
/// named), or every finding that explains the region being accepted.
List<GoldenReportRegion> _regions(
  GoldenReportPixels pixels,
  GoldenDesignSpec? spec,
  GoldenRenderSnapshot snapshot,
  List<GoldenDesignFinding> findings,
  List<GoldenKnownDifference> known,
  Map<String, int> matches,
  GoldenDesignTolerance tolerance,
) {
  final renderedById = {for (final node in snapshot.nodes) node.id: node};
  final candidates = [
    if (spec != null)
      for (final node in spec.nodes)
        if (!goldenIsSystemBarName(node.name)) node,
  ];
  final byId = {for (final finding in findings) finding.id: finding};
  final regions = <GoldenReportRegion>[];
  for (final region in pixels.diff?.regions ?? const <GoldenPixelRegion>[]) {
    final cx = region.bounds.centerX;
    final cy = region.bounds.centerY;
    GoldenDesignNode? design;
    for (final node in candidates) {
      if (!node.rect.contains(cx, cy)) continue;
      if (design == null || node.rect.area <= design.rect.area) design = node;
    }
    GoldenRenderNode? widget;
    for (final node in snapshot.nodes) {
      if (!node.visibleRect.contains(cx, cy)) continue;
      if (widget == null || node.visibleRect.area <= widget.visibleRect.area) {
        widget = node;
      }
    }
    if (design == null) {
      final textHit = goldenMatchedTextAt(
        candidates: candidates,
        matches: matches,
        rendered: renderedById,
        selected: widget,
        x: cx,
        y: cy,
        tolerance: tolerance,
      );
      if (textHit != null) {
        design = textHit.$1;
        widget = textHit.$2;
      }
    }
    widget = goldenPreferMatchedText(
      design: design,
      selected: widget,
      matched: renderedById[matches[design?.id]],
      x: cx,
      y: cy,
      tolerance: tolerance,
    );
    final id = design != null
        ? 'node:${design.id}'
        : 'cell:${(region.bounds.left ~/ 8) * 8},${(region.bounds.top ~/ 8) * 8}';
    final ancestors = design == null || spec == null
        ? const <String>{}
        : {
            for (final a in spec.ancestors(design))
              if (a.id != spec.frame.id) a.id,
          };
    bool explains(GoldenDesignFinding finding) {
      final node = finding.design?.id;
      if (design != null && node != null) {
        if (node == design.id || ancestors.contains(node)) return true;
      }
      if (widget != null && finding.widget?.id == widget.id) return true;
      final family = widget?.text?.style.fontFamily;
      if (finding.category == GoldenFindingCategory.font &&
          family != null &&
          finding.id == 'font@$family') {
        return true;
      }
      final rect = finding.rect;
      return rect != null &&
          finding.category != GoldenFindingCategory.frame &&
          finding.category != GoldenFindingCategory.font &&
          region.bounds.coveredBy(rect) >= 0.5;
    }

    final related = [
      for (final finding in findings)
        if (explains(finding)) finding.id,
    ];
    final component = snapshot.componentOf(widget);
    GoldenKnownDifference? accepted;
    for (final difference in known) {
      final aimed =
          (difference.designNode != null &&
              difference.designNode == design?.id) ||
          (difference.widget != null &&
              (difference.widget == widget?.widget ||
                  difference.widget == component?.name));
      final visual =
          difference.property == null &&
          (difference.category == null ||
              difference.category == GoldenFindingCategory.visual);
      if (aimed && visual) {
        accepted = difference;
        break;
      }
    }
    if (accepted == null && related.isNotEmpty) {
      final explaining = [for (final id in related) byId[id]!];
      if (explaining.every((f) => !f.counts)) accepted = explaining.first.known;
    }
    regions.add(
      GoldenReportRegion(
        id: id,
        region: region,
        design: design,
        widget: widget,
        findings: related,
        known: accepted,
      ),
    );
  }
  return regions;
}

GoldenDesignFinding _visualFinding(
  GoldenReportRegion region,
  GoldenDesignSpec? spec,
  GoldenRenderSnapshot snapshot,
  GoldenDesignTolerance tolerance, {
  double? rasterCoverage,
  String rasterKind = '글자',
}) {
  final r = region.region;
  final severity = rasterCoverage != null
      ? GoldenFindingSeverity.info
      : goldenUnexplainedSeverity(region, tolerance);
  final where = [
    if (region.design != null) 'Figma ‘${region.design!.name}’',
    if (region.widget != null)
      '구현 ${region.widget!.label}'
          '${region.widget!.source == null ? '' : ' (${region.widget!.source!.label})'}',
  ].join(' / ');
  String hex(int rgb) =>
      '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  return GoldenDesignFinding(
    id: 'visual@${region.id}',
    category: GoldenFindingCategory.visual,
    severity: severity,
    message:
        '${rasterCoverage == null
            ? '구조 비교로 설명되지 않는 픽셀 차이'
            : rasterKind == '이미지'
            ? '원본 자산·채움·자름이 같은 이미지 보간 차이'
            : '구조·색·$rasterKind 윤곽이 일치하는 렌더러 차이'} '
        '${goldenRound(r.bounds.width, 1)}×${goldenRound(r.bounds.height, 1)}px '
        '(넓이 ${goldenRound(r.logicalPixels, 2)}px², '
        '최대 연결 구역 ${goldenRound(region.largestConnectedPixels ?? r.logicalPixels, 2)}px², '
        'ΔE ${goldenRound(r.meanDeltaE, 2)})'
        '${where.isEmpty ? '' : ' — $where'}.',
    diffs: [
      GoldenFindingDiff(
        property: 'color',
        expected: hex(r.referenceColor),
        actual: hex(r.renderColor),
        unit: 'ΔE',
        delta: r.meanDeltaE,
        severity: severity,
      ),
    ],
    design: region.design,
    designPath: region.design == null ? null : spec?.pathOf(region.design!),
    widget: region.widget,
    component: snapshot.componentOf(region.widget),
    owner: rasterCoverage == null
        ? GoldenFindingOwner.of(
            region.widget,
            snapshot.componentOf(region.widget),
          )
        : null,
    rect: r.bounds,
    hint: rasterCoverage != null && rasterKind == '이미지'
        ? '원본 이미지의 바이트 해시와 크기·채움·정렬·자름·불투명도가 일치하고, 추가 색 필터가 없습니다. 저주파 색 비교도 기존 허용 범위 안입니다. 원시 픽셀 수·차이 지도·수락 판정은 보존합니다.'
        : rasterCoverage != null
        ? '같은 $rasterKind 속성·스타일·색이며, 윤곽이 기존 위치 허용 범위에서 '
              '${goldenRound(rasterCoverage * 100, 2)}% 일치합니다. '
              '원시 픽셀 수·차이 지도·수락 판정은 그대로 보존합니다.'
        : '겹쳐 보기에서 이 영역을 확인하세요 — 아이콘 모양, 이미지, 그림자, '
              '그라디언트, 잘림처럼 구조 비교가 보지 않는 차이일 수 있습니다.',
  );
}

/// Output-relative report path of [input].
String reportPathOf(GoldenDesignAnalysisInput input) =>
    goldenReportPath(input.suite, input.scenario, input.fileStem);

/// Output-relative report path of one variant.
String goldenReportPath(String suite, String scenario, String fileStem) =>
    p.posix.join('analysis', suite, scenario, '$fileStem.json');

/// Short failure text for [report], used when [GoldenDesignAnalysis]
/// enforces the verdict.
String describeDesignFailure(GoldenDesignReport report) {
  final top = report.findings
      .where((f) => f.counts && f.severity == GoldenFindingSeverity.error)
      .take(5)
      .map(
        (f) =>
            '  - ${f.message}'
            '${f.widget?.source == null ? '' : ' (${f.widget!.source!.label})'}',
      )
      .join('\n');
  final path = goldenReportPath(report.suite, report.scenario, report.fileStem);
  return 'design: ${report.verdict.name} (${report.verdictReasons.join(', ')})'
      ' — see $path${top.isEmpty ? '' : '\n$top'}';
}

(GoldenPackageMap, GoldenComponentCatalog?) _systemFor(
  GoldenDesignSystem system,
) {
  // Only the file-backed part is cached; names and extra roles differ per
  // design system and are merged on every call.
  final key =
      '${Directory.current.path}|${system.catalogPath}|${system.discoverCoui}';
  final (packages, base) = _systems[key] ??= () {
    final packages = GoldenPackageMap.discover();
    final path = system.catalogPath;
    final catalog = path != null
        ? GoldenComponentCatalog.readCoui(path)
        : (system.discoverCoui
              ? GoldenComponentCatalog.discoverCoui(packages)
              : null);
    return (packages, catalog);
  }();
  if (system.textRoles.isEmpty && system.name == null) return (packages, base);
  if (base == null && system.textRoles.isEmpty) return (packages, null);
  return (
    packages,
    GoldenComponentCatalog(
      name: system.name ?? base?.name ?? 'design system',
      components: [...?base?.components.values],
      textRoles: [...?base?.textRoles, ...system.textRoles],
      path: base?.path,
      library: base?.library,
    ),
  );
}

int _compareFindings(GoldenDesignFinding a, GoldenDesignFinding b) {
  final known = (a.known == null ? 0 : 1).compareTo(b.known == null ? 0 : 1);
  if (known != 0) return known;
  final severity = a.severity.index.compareTo(b.severity.index);
  if (severity != 0) return severity;
  final category = GoldenFindingCategory.values
      .indexOf(a.category)
      .compareTo(GoldenFindingCategory.values.indexOf(b.category));
  if (category != 0) return category;
  final ay = a.rect?.top ?? 0;
  final by = b.rect?.top ?? 0;
  if (ay != by) return ay.compareTo(by);
  return (a.rect?.left ?? 0).compareTo(b.rect?.left ?? 0);
}
