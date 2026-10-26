import 'dart:math' as math;

import 'color.dart';
import 'design_system.dart';
import 'finding.dart';
import 'geometry.dart';
import 'pixel_diff.dart';
import 'render_node.dart';
import 'spec.dart';
import 'tolerance.dart';

/// Inputs of a structural comparison that do not come from the design or the
/// render.
final class GoldenStructuralContext {
  /// Creates the context.
  const GoldenStructuralContext({
    required this.tolerance,
    this.catalog,
    this.mappings = const [],
    this.colorTokens = const {},
    this.masks = const [],
    this.regions,
    this.textScale = 1,
  });

  /// Tolerances.
  final GoldenDesignTolerance tolerance;

  /// Design-system catalog (components and text roles).
  final GoldenComponentCatalog? catalog;

  /// Explicit design ↔ widget mappings.
  final List<GoldenComponentMapping> mappings;

  /// Named theme colors, `0xAARRGGBB` by token name.
  final Map<String, int> colorTokens;

  /// Masked rectangles; nodes inside them are not compared.
  final List<GoldenRect> masks;

  /// Pixel regions, used as evidence for missing boxes. `null` when pixels
  /// were not compared.
  final List<GoldenPixelRegion>? regions;

  /// Text scale of the variant.
  final double textScale;
}

/// Result of a structural comparison.
final class GoldenStructuralResult {
  /// Creates a result.
  const GoldenStructuralResult({
    required this.findings,
    required this.matches,
    required this.compared,
  });

  /// Findings in no particular order.
  final List<GoldenDesignFinding> findings;

  /// Design node id → rendered node id.
  final Map<String, int> matches;

  /// Design nodes that took part.
  final int compared;
}

/// Compares a design specification with what the app rendered.
GoldenStructuralResult compareDesignStructure(
  GoldenDesignSpec spec,
  GoldenRenderSnapshot snapshot,
  GoldenStructuralContext context,
) => _StructuralDiff(spec, snapshot, context).run();

/// Findings that need no design specification: unloaded fonts.
List<GoldenDesignFinding> goldenFontFindings(GoldenRenderSnapshot snapshot) {
  final findings = <GoldenDesignFinding>[];
  for (final MapEntry(key: family, value: loaded) in snapshot.fonts.entries) {
    if (loaded) continue;
    final users = snapshot.nodes
        .where((n) => n.text?.style.fontFamily == family)
        .toList();
    if (users.isEmpty) continue;
    findings.add(
      GoldenDesignFinding(
        id: 'font@$family',
        category: GoldenFindingCategory.font,
        severity: GoldenFindingSeverity.error,
        message:
            '서체 ‘$family’가 테스트에 로드되지 않아 대체 서체로 그려졌습니다 '
            '(텍스트 ${users.length}개). 글자 차이는 모두 이 원인부터 확인하세요.',
        diffs: const [
          GoldenFindingDiff(
            property: 'fontLoaded',
            expected: true,
            actual: false,
            severity: GoldenFindingSeverity.error,
          ),
        ],
        widget: users.first,
        hint:
            'flutter_test_config.dart 에서 loadGoldenFonts() 또는 '
            "loadGoldenFontFiles({'$family': [...]}) 로 서체를 로드하세요.",
      ),
    );
  }
  return findings;
}

enum _Kind { text, box, image, icon }

final class _Match {
  _Match(this.design, this.render, this.kind, {this.partial = false});

  final GoldenDesignNode design;
  final GoldenRenderNode render;
  final _Kind kind;
  final bool partial;
}

final class _StructuralDiff {
  _StructuralDiff(this.spec, this.snapshot, this.context);

  final GoldenDesignSpec spec;
  final GoldenRenderSnapshot snapshot;
  final GoldenStructuralContext context;
  final List<GoldenDesignFinding> findings = [];
  final Map<String, _Match> matched = {};
  final Set<int> usedRender = {};
  final Set<int> usedComponents = {};
  final Map<String, int> _ids = {};

  GoldenDesignTolerance get tol => context.tolerance;

  bool _masked(GoldenRect rect) =>
      context.masks.any((mask) => rect.coveredBy(mask) >= 0.9);

  late final List<GoldenDesignNode> designNodes = [
    for (final node in spec.nodes)
      if (!node.rect.isEmpty &&
          !goldenIsSystemBarName(node.name) &&
          !spec.ancestors(node).any((a) => goldenIsSystemBarName(a.name)) &&
          !_masked(node.rect))
        node,
  ];

  late final List<GoldenRenderNode> renderNodes = [
    for (final node in snapshot.nodes)
      if (!_masked(node.visibleRect)) node,
  ];

  GoldenStructuralResult run() {
    _frame();
    _matchTexts();
    if (spec.hasStyles) _matchComponents();
    _matchImagesAndIcons();
    if (spec.hasStyles) _matchBoxes();
    _layout();
    return GoldenStructuralResult(
      findings: findings,
      matches: {
        for (final MapEntry(:key, :value) in matched.entries)
          key: value.render.id,
      },
      compared: designNodes.length,
    );
  }

  // ─────────────────────────────── frame ───────────────────────────────────

  void _frame() {
    final dw = snapshot.width - spec.frame.rect.width;
    final dh = snapshot.height - spec.frame.rect.height;
    if (dw.abs() > 0.5 || dh.abs() > 0.5) {
      _add(
        category: GoldenFindingCategory.frame,
        key: 'size',
        severity: dw.abs() > 0.5
            ? GoldenFindingSeverity.error
            : GoldenFindingSeverity.warning,
        message:
            'Figma 프레임 크기(${_n(spec.frame.rect.width)}×${_n(spec.frame.rect.height)})와 '
            '캡처 크기(${_n(snapshot.width)}×${_n(snapshot.height)})가 다릅니다. '
            '위치 비교는 왼쪽 위를 기준으로 합니다.',
        diffs: [
          if (dw.abs() > 0.5)
            _diff('width', spec.frame.rect.width, snapshot.width, 'px'),
          if (dh.abs() > 0.5)
            _diff('height', spec.frame.rect.height, snapshot.height, 'px'),
        ],
        design: spec.frame,
        hint:
            'GoldenDevice(logicalSize: Size(${_n(spec.frame.rect.width)}, '
            '${_n(spec.frame.rect.height)})) 처럼 프레임과 같은 크기의 기기로 캡처하세요.',
      );
    }
    if (context.textScale != 1) {
      _add(
        category: GoldenFindingCategory.frame,
        key: 'textScale',
        severity: GoldenFindingSeverity.warning,
        message:
            '글자 배율 ${context.textScale} 변형을 배율 1 기준의 디자인과 비교합니다. '
            '서체 크기와 위치 차이는 배율 때문일 수 있습니다.',
        diffs: [
          _diff(
            'textScale',
            1,
            context.textScale,
            null,
            severity: GoldenFindingSeverity.warning,
          ),
        ],
      );
    }
    final fill = spec.frame.solidFill;
    if (fill != null && (fill.color! >> 24) > 0) {
      final background = renderNodes
          .where(
            (n) =>
                n.kind == GoldenRenderKind.box &&
                n.box?.color != null &&
                n.visibleRect.area >= snapshot.width * snapshot.height * 0.9,
          )
          .firstOrNull;
      if (background != null) {
        _compareColor(
          key: 'background',
          property: 'background',
          design: spec.frame,
          render: background,
          expected: fill.color!,
          actual: background.box!.color!,
          expectedToken: fill.variable,
          label: '화면 배경',
        );
      }
    }
  }

  // ─────────────────────────────── texts ───────────────────────────────────

  void _matchTexts() {
    final texts = designNodes.where((n) => n.isText).toList();
    final rendered = renderNodes
        .where((n) => n.kind == GoldenRenderKind.text)
        .toList();
    if (!spec.hasStyles || texts.every((t) => t.text?.characters == null)) {
      _matchTextsByGeometry(texts, rendered);
      return;
    }
    // 1. Exact content, closest first.
    final pairs = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    for (final design in texts) {
      final wanted = _normalize(design.text?.displayed ?? '');
      if (wanted.isEmpty) continue;
      for (final render in rendered) {
        if (_normalize(render.text!.text) == wanted) {
          pairs.add((
            design,
            render,
            _glyphs(design).centerDistance(render.text!.contentRect),
          ));
        }
      }
    }
    _assign(pairs, _Kind.text);
    // 2. Similar content nearby.
    final fuzzy = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    final reach = math.max(64.0, spec.frame.rect.width * 0.15);
    for (final design in texts) {
      if (matched.containsKey(design.id)) continue;
      final wanted = _normalize(design.text?.displayed ?? '');
      if (wanted.isEmpty) continue;
      for (final render in rendered) {
        if (usedRender.contains(render.id)) continue;
        final similarity = _similarity(wanted, _normalize(render.text!.text));
        final distance = _glyphs(
          design,
        ).centerDistance(render.text!.contentRect);
        if (similarity >= 0.6 && distance <= reach) {
          fuzzy.add((design, render, (1 - similarity) * 100 + distance / 10));
        }
      }
    }
    _assign(fuzzy, _Kind.text);
    // 3. A design text that is part of a longer rendered text (Figma split a
    //    sentence that the app renders as one paragraph, or the reverse).
    for (final design in texts) {
      if (matched.containsKey(design.id)) continue;
      final wanted = _normalize(design.text?.displayed ?? '');
      if (wanted.length < 2) continue;
      for (final render in rendered) {
        final content = _normalize(render.text!.text);
        final rect = _textRect(design);
        if ((content.contains(wanted) || wanted.contains(content)) &&
            content.length >= 2 &&
            (rect.intersect(render.text!.contentRect.inflate(4, 4)) != null)) {
          matched[design.id] = _Match(
            design,
            render,
            _Kind.text,
            partial: true,
          );
          usedRender.add(render.id);
          break;
        }
      }
    }
    for (final design in texts) {
      final match = matched[design.id];
      if (match == null) {
        _missingText(design, rendered);
      } else {
        _compareText(match);
      }
    }
    for (final render in rendered) {
      if (usedRender.contains(render.id)) continue;
      if (render.text!.editable && render.text!.text.trim().isEmpty) continue;
      _add(
        category: GoldenFindingCategory.presence,
        key: 'extra',
        severity: GoldenFindingSeverity.warning,
        message: '구현에 Figma에 없는 텍스트 ‘${render.label}’가 있습니다.',
        diffs: [
          _diff(
            'present',
            false,
            true,
            null,
            severity: GoldenFindingSeverity.warning,
          ),
        ],
        render: render,
        hint: '디자인에 없는 문구인지, 다른 상태의 화면을 캡처했는지 확인하세요.',
      );
    }
  }

  void _matchTextsByGeometry(
    List<GoldenDesignNode> texts,
    List<GoldenRenderNode> rendered,
  ) {
    final pairs = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    for (final design in texts) {
      final rect = design.inkRect ?? design.rect;
      for (final render in rendered) {
        final iou = rect.iou(render.text!.contentRect);
        if (iou >= 0.3 ||
            render.text!.contentRect.contains(rect.centerX, rect.centerY)) {
          pairs.add((design, render, 1 - iou));
        }
      }
    }
    _assign(pairs, _Kind.text);
    for (final design in texts) {
      if (matched.containsKey(design.id)) continue;
      _add(
        category: GoldenFindingCategory.presence,
        key: 'missing',
        severity: GoldenFindingSeverity.error,
        message: 'Figma 텍스트 ‘${design.name}’ 자리에 구현 텍스트가 없습니다.',
        diffs: [_diff('present', true, false, null)],
        design: design,
      );
    }
  }

  void _missingText(GoldenDesignNode design, List<GoldenRenderNode> rendered) {
    final rect = _textRect(design);
    final overlapping = rendered
        .where((r) => r.text!.contentRect.intersect(rect) != null)
        .toList();
    final displayed = design.text?.displayed ?? design.name;
    final there = overlapping.isEmpty
        ? ''
        : ' 그 자리에는 ‘${overlapping.first.label}’가 그려졌습니다.';
    _add(
      category: GoldenFindingCategory.presence,
      key: 'missing',
      severity: GoldenFindingSeverity.error,
      message: 'Figma 텍스트 ‘${_short(displayed)}’가 구현에 없습니다.$there',
      diffs: [
        _diff('text', displayed, overlapping.firstOrNull?.text?.text, null),
      ],
      design: design,
      render: overlapping.firstOrNull,
      hint: overlapping.isEmpty
          ? '이 문구를 그리는 위젯이 빠졌거나 다른 상태를 캡처했습니다.'
          : '문구(번역 키·데이터)가 디자인과 같은지 확인하세요.',
    );
  }

  void _compareText(_Match match) {
    final design = match.design;
    final render = match.render;
    final text = design.text;
    final rendered = render.text!;
    if (text == null) return;
    final typography = text.typography;
    final style = _styleAt(rendered, match, design);
    final diffs = <GoldenFindingDiff>[];

    // Content.
    final displayed = text.displayed ?? '';
    if (!match.partial && _normalize(displayed) != _normalize(rendered.text)) {
      final upper = typography.textCase == 'UPPER';
      _add(
        category: GoldenFindingCategory.content,
        key: 'text',
        severity: GoldenFindingSeverity.error,
        message:
            '문구가 다릅니다: Figma ‘${_short(displayed)}’ → 구현 ‘${_short(rendered.text)}’.',
        diffs: [_diff('text', displayed, rendered.text, null)],
        design: design,
        render: render,
        hint: upper
            ? 'Figma는 글자 대소문자 변환(UPPER)을 적용합니다.'
            : '번역 문구나 표시 데이터를 디자인 문구와 맞추세요.',
      );
    }

    // Typography.
    if (typography.fontFamily != null &&
        _family(typography.fontFamily) != _family(style.fontFamily)) {
      diffs.add(
        _diff(
          'fontFamily',
          typography.fontFamily,
          style.fontFamily ?? '(기본 서체)',
          null,
        ),
      );
    }
    if (typography.fontWeight != null &&
        typography.fontWeight != style.fontWeight) {
      diffs.add(
        _diff(
          'fontWeight',
          typography.fontWeight,
          style.fontWeight,
          null,
          delta: (style.fontWeight - typography.fontWeight!).toDouble(),
        ),
      );
    }
    if (typography.fontSize != null) {
      final delta = style.fontSize - typography.fontSize!;
      if (delta.abs() > tol.fontSize) {
        diffs.add(
          _diff(
            'fontSize',
            typography.fontSize,
            style.fontSize,
            'px',
            delta: delta,
            severity: delta.abs() > 1
                ? GoldenFindingSeverity.error
                : GoldenFindingSeverity.warning,
          ),
        );
      }
    }
    final measured = rendered.lineCount > 0
        ? rendered.contentRect.height / rendered.lineCount
        : null;
    if (typography.lineHeight != null) {
      final actual = style.lineHeight ?? measured;
      if (actual != null &&
          (actual - typography.lineHeight!).abs() > tol.lineHeight) {
        diffs.add(
          _diff(
            'lineHeight',
            typography.lineHeight,
            style.lineHeight == null ? '${_n(actual)} (auto)' : actual,
            'px',
            delta: actual - typography.lineHeight!,
            severity: (actual - typography.lineHeight!).abs() > 4
                ? GoldenFindingSeverity.error
                : GoldenFindingSeverity.warning,
          ),
        );
      }
    } else if (typography.lineHeightAuto && style.lineHeight != null) {
      diffs.add(
        _diff(
          'lineHeight',
          'auto',
          style.lineHeight,
          'px',
          severity: GoldenFindingSeverity.warning,
        ),
      );
    }
    if (typography.letterSpacing != null) {
      final delta = style.letterSpacing - typography.letterSpacing!;
      if (delta.abs() > tol.letterSpacing) {
        diffs.add(
          _diff(
            'letterSpacing',
            _round(typography.letterSpacing!),
            _round(style.letterSpacing),
            'px',
            delta: delta,
            severity: GoldenFindingSeverity.warning,
          ),
        );
      }
    }
    if (typography.italic != null && typography.italic != style.italic) {
      diffs.add(_diff('italic', typography.italic, style.italic, null));
    }
    final decoration = switch (typography.textDecoration) {
      'UNDERLINE' => 'underline',
      'STRIKETHROUGH' => 'lineThrough',
      _ => null,
    };
    if (typography.textDecoration != null && decoration != style.decoration) {
      diffs.add(
        _diff(
          'decoration',
          decoration ?? 'none',
          style.decoration ?? 'none',
          null,
        ),
      );
    }
    final align = text.align?.toLowerCase();
    final hugs = text.autoResize == 'WIDTH_AND_HEIGHT';
    if (align != null &&
        !hugs &&
        rendered.lineCount == 1 &&
        _alignName(align) != rendered.align &&
        (design.rect.width - rendered.contentRect.width) > 2) {
      diffs.add(
        _diff(
          'textAlign',
          _alignName(align),
          rendered.align,
          null,
          severity: GoldenFindingSeverity.warning,
        ),
      );
    }
    final catalog = context.catalog;
    final designRole = _designRole(typography, catalog);
    final widgetRole = _roleOf(style);
    if (designRole != null && designRole.name != widgetRole?.name) {
      diffs.insert(
        0,
        _diff(
          'role',
          designRole.name,
          widgetRole?.name ?? '(역할 없음)',
          null,
          severity: diffs.any((d) => d.severity == GoldenFindingSeverity.error)
              ? GoldenFindingSeverity.error
              : GoldenFindingSeverity.warning,
        ),
      );
    }
    diffs.addAll(_runDiffs(text, rendered, match));
    if (diffs.isNotEmpty) {
      final parts = diffs
          .take(4)
          .map(
            (d) =>
                '${_propertyLabel(d.property)} ${_v(d.expected)} → ${_v(d.actual)}',
          )
          .join(', ');
      _add(
        category: GoldenFindingCategory.typography,
        key: 'typography',
        severity: _worst(diffs),
        message: '‘${_short(rendered.text)}’ 서체가 Figma와 다릅니다 — $parts.',
        diffs: diffs,
        design: design,
        render: render,
        designRole: designRole?.name,
        widgetRole: widgetRole?.name,
        hint: _typographyHint(typography, designRole, catalog),
      );
    }

    // Color.
    final expectedColor = typography.color;
    final actualColor = style.color;
    if (expectedColor != null && actualColor != null) {
      _compareColor(
        key: 'text',
        property: 'textColor',
        design: design,
        render: render,
        expected: expectedColor,
        actual: actualColor,
        expectedToken: typography.colorVariable,
        label: '‘${_short(rendered.text)}’ 글자색',
      );
    }

    // Truncation and wrapping.
    if (rendered.truncated && !text.truncated) {
      _add(
        category: GoldenFindingCategory.content,
        key: 'truncated',
        severity: GoldenFindingSeverity.error,
        message:
            '‘${_short(rendered.text)}’가 구현에서 잘립니다(최대 ${rendered.maxLines}줄). '
            'Figma는 전부 보여 줍니다.',
        diffs: [_diff('truncated', false, true, null)],
        design: design,
        render: render,
        hint: '폭·서체·자간이 디자인과 같은지 확인하고, 그래도 넘치면 maxLines를 디자인에 맞추세요.',
      );
    }
    final designLines =
        typography.lineHeight != null && typography.lineHeight! > 0
        ? (design.rect.height / typography.lineHeight!).round()
        : null;
    if (!match.partial &&
        designLines != null &&
        designLines > 0 &&
        designLines != rendered.lineCount &&
        !rendered.truncated) {
      _add(
        category: GoldenFindingCategory.content,
        key: 'lines',
        severity: GoldenFindingSeverity.warning,
        message:
            '‘${_short(rendered.text)}’ 줄 수가 다릅니다: Figma $designLines줄 → 구현 '
            '${rendered.lineCount}줄. 폭이나 서체 차이로 줄바꿈이 달라졌습니다.',
        diffs: [
          _diff(
            'lines',
            designLines,
            rendered.lineCount,
            null,
            severity: GoldenFindingSeverity.warning,
          ),
        ],
        design: design,
        render: render,
      );
    }
  }

  /// Rendered style that corresponds to [design]: the run that holds the
  /// design text for partial matches, otherwise the dominant style.
  GoldenRenderTextStyle _styleAt(
    GoldenRenderText rendered,
    _Match match,
    GoldenDesignNode design,
  ) {
    if (!match.partial || rendered.runs.isEmpty) return rendered.style;
    final wanted = design.text?.displayed ?? '';
    final at = rendered.text.indexOf(wanted.trim());
    if (at < 0) return rendered.style;
    for (final run in rendered.runs) {
      if (at >= run.start && at < run.end) return run.style;
    }
    return rendered.style;
  }

  List<GoldenFindingDiff> _runDiffs(
    GoldenDesignText text,
    GoldenRenderText rendered,
    _Match match,
  ) {
    if (match.partial || text.runs.isEmpty && rendered.runs.isEmpty) {
      return const [];
    }
    final characters = text.characters;
    if (characters == null || characters != rendered.text) return const [];
    final diffs = <GoldenFindingDiff>[];
    GoldenRenderTextStyle styleAt(int index) {
      for (final run in rendered.runs) {
        if (index >= run.start && index < run.end) return run.style;
      }
      return rendered.style;
    }

    for (final run in text.runs) {
      if (run.start >= run.end || run.end > characters.length) continue;
      final expected = text.typography.merge(run.typography);
      final actual = styleAt(run.start);
      final scope = '‘${_short(characters.substring(run.start, run.end))}’';
      if (expected.fontWeight != null &&
          expected.fontWeight != actual.fontWeight) {
        diffs.add(
          _diff(
            'fontWeight',
            expected.fontWeight,
            actual.fontWeight,
            null,
            scope: scope,
          ),
        );
      }
      if (expected.fontSize != null &&
          (expected.fontSize! - actual.fontSize).abs() > tol.fontSize) {
        diffs.add(
          _diff(
            'fontSize',
            expected.fontSize,
            actual.fontSize,
            'px',
            scope: scope,
          ),
        );
      }
      if (expected.color != null &&
          actual.color != null &&
          _deltaE(expected.color!, actual.color!) > tol.propertyDeltaE) {
        diffs.add(
          _diff(
            'color',
            GoldenColorMath.hexArgb(expected.color!),
            GoldenColorMath.hexArgb(actual.color!),
            'ΔE',
            delta: _deltaE(expected.color!, actual.color!),
            scope: scope,
          ),
        );
      }
    }
    return diffs;
  }

  /// Role named by the text style, else by a bound font-size variable such
  /// as `font-size/body-small`.
  GoldenTextRole? _designRole(
    GoldenDesignTypography typography,
    GoldenComponentCatalog? catalog,
  ) {
    if (catalog == null) return null;
    final style = typography.styleName;
    if (style != null) return catalog.roleNamed(style);
    final variable = typography.variables['fontSize'];
    if (variable == null) return null;
    final tail = variable.substring(variable.lastIndexOf('/') + 1);
    return catalog.roleNamed(tail);
  }

  GoldenTextRole? _roleOf(GoldenRenderTextStyle style) {
    final roles = [...?context.catalog?.textRoles];
    for (final role in roles) {
      if (role.matches(
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        height: style.height,
        letterSpacing: style.letterSpacing,
      )) {
        return role;
      }
    }
    return null;
  }

  String? _typographyHint(
    GoldenDesignTypography typography,
    GoldenTextRole? role,
    GoldenComponentCatalog? catalog,
  ) {
    if (role != null && catalog?.name == 'CoUI') {
      return "Text('…').${role.name} 처럼 Figma 텍스트 스타일 "
          '${typography.styleName}의 역할을 쓰세요(굵기·색만 다르면 '
          '.semiBold 같은 수식을 이어 붙입니다).';
    }
    final parts = [
      if (typography.fontFamily != null)
        "fontFamily: '${typography.fontFamily}'",
      if (typography.fontSize != null) 'fontSize: ${_n(typography.fontSize!)}',
      if (typography.fontWeight != null)
        'fontWeight: FontWeight.w${typography.fontWeight}',
      if (typography.lineHeight != null && typography.fontSize != null)
        'height: ${(typography.lineHeight! / typography.fontSize!).toStringAsFixed(3)}',
      if (typography.letterSpacing != null)
        'letterSpacing: ${_round(typography.letterSpacing!)}',
    ];
    if (parts.isEmpty) return null;
    final style = typography.styleName == null
        ? ''
        : '디자인 시스템의 ‘${typography.styleName}’ 스타일 또는 ';
    return '${style}TextStyle(${parts.join(', ')})';
  }

  // ───────────────────────────── components ────────────────────────────────

  void _matchComponents() {
    final instances = designNodes
        .where((n) => n.isInstance && n.instance?.name != null && !_isIcon(n))
        .toList();
    final components = [
      for (final component in snapshot.components)
        if (!_masked(component.rect)) component,
    ];
    final pairs = <(GoldenDesignNode, GoldenRenderComponent, double)>[];
    for (final design in instances) {
      final expected = _expectedWidget(design);
      for (final component in components) {
        if (goldenNormalizeName(component.name) !=
            goldenNormalizeName(expected)) {
          continue;
        }
        final iou = design.rect.iou(component.rect);
        final centered =
            component.rect.contains(design.rect.centerX, design.rect.centerY) &&
            design.rect.contains(
              component.rect.centerX,
              component.rect.centerY,
            );
        if (iou >= 0.3 || centered) pairs.add((design, component, 1 - iou));
      }
    }
    pairs.sort((a, b) => a.$3.compareTo(b.$3));
    final assigned = <String, GoldenRenderComponent>{};
    for (final (design, component, _) in pairs) {
      if (assigned.containsKey(design.id) ||
          usedComponents.contains(component.id)) {
        continue;
      }
      assigned[design.id] = component;
      usedComponents.add(component.id);
    }
    for (final design in instances) {
      final component = assigned[design.id];
      if (component != null) {
        _compareComponent(design, component);
      } else {
        _unmatchedInstance(design, components);
      }
    }
  }

  String _expectedWidget(GoldenDesignNode design) {
    final name = design.instance!.name!;
    for (final mapping in context.mappings) {
      if (goldenNormalizeName(mapping.figma) == goldenNormalizeName(name)) {
        return mapping.widget;
      }
    }
    return name;
  }

  GoldenComponentMapping? _mappingFor(String figmaName) {
    for (final mapping in context.mappings) {
      if (goldenNormalizeName(mapping.figma) ==
          goldenNormalizeName(figmaName)) {
        return mapping;
      }
    }
    return null;
  }

  void _compareComponent(
    GoldenDesignNode design,
    GoldenRenderComponent component,
  ) {
    final instance = design.instance!;
    final mapping = _mappingFor(instance.name!);
    final listed = context.catalog?.component(component.name);
    final diffs = <GoldenFindingDiff>[];
    final hints = <String>[];
    for (final MapEntry(key: axis, value: value) in instance.variant.entries) {
      if (mapping?.ignore.contains(axis) ?? false) continue;
      final normalizedAxis = goldenNormalizeName(axis);
      final normalizedValue = goldenNormalizeName(value);
      if (normalizedAxis == 'state' || normalizedAxis == 'enabled') {
        final enabled = component.properties['enabled'];
        if (enabled == null) continue;
        final expectedEnabled = switch (normalizedValue) {
          'disabled' || 'false' => 'false',
          'enabled' || 'default' || 'normal' || 'rest' || 'true' => 'true',
          _ => null,
        };
        if (expectedEnabled != null && expectedEnabled != enabled) {
          diffs.add(
            _diff(
              'enabled',
              expectedEnabled == 'true',
              enabled == 'true',
              null,
            ),
          );
          hints.add(
            expectedEnabled == 'true'
                ? 'onPressed 같은 콜백을 연결하거나 enabled: true'
                : '콜백을 비우거나 enabled: false',
          );
        }
        continue;
      }
      final field = _componentField(axis, value, component, listed, mapping);
      if (field == null) continue;
      final actual = component.properties[field];
      if (actual == null) continue;
      final expected = mapping?.values[axis]?[value] ?? value;
      if (goldenNormalizeName(expected) != goldenNormalizeName(actual)) {
        diffs.add(_diff(field, expected, actual, null));
        final enumName = listed?.axisFor(axis, expected)?.enumName;
        hints.add(
          enumName == null
              ? '$field: $expected'
              : '$field: $enumName.$expected',
        );
      }
    }
    if (diffs.isEmpty) return;
    final variant = instance.variant.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    final props = component.properties.entries
        .where(
          (e) =>
              e.key != 'enabled' || diffs.any((d) => d.property == 'enabled'),
        )
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    _add(
      category: GoldenFindingCategory.component,
      key: 'variant',
      severity: GoldenFindingSeverity.error,
      message:
          'Figma ‘${instance.name}’($variant)과 구현 ${component.name}($props)의 '
          '변형이 다릅니다.',
      diffs: diffs,
      design: design,
      component: component,
      rect: component.rect,
      hint: '${component.name}(${hints.join(', ')})',
    );
  }

  String? _componentField(
    String axis,
    String value,
    GoldenRenderComponent component,
    GoldenCatalogComponent? listed,
    GoldenComponentMapping? mapping,
  ) {
    final renamed = mapping?.properties[axis];
    if (renamed != null) return renamed;
    final catalogAxis = listed?.axisFor(axis, value);
    if (catalogAxis != null) {
      for (final field in goldenAxisFields(catalogAxis, listed!.name)) {
        if (component.properties.containsKey(field)) return field;
      }
    }
    final lower = axis.isEmpty
        ? axis
        : '${axis[0].toLowerCase()}${axis.substring(1).replaceAll(' ', '')}';
    for (final field in component.properties.keys) {
      if (goldenNormalizeName(field) == goldenNormalizeName(lower)) {
        return field;
      }
    }
    return null;
  }

  void _unmatchedInstance(
    GoldenDesignNode design,
    List<GoldenRenderComponent> components,
  ) {
    final instance = design.instance!;
    final name = instance.name!;
    final catalog = context.catalog;
    final expected = _expectedWidget(design);
    final known =
        catalog?.component(expected) != null || _mappingFor(name) != null;
    final other = components
        .where(
          (c) =>
              !usedComponents.contains(c.id) &&
              (design.rect.iou(c.rect) >= 0.5),
        )
        .firstOrNull;
    if (other != null) {
      _add(
        category: GoldenFindingCategory.component,
        key: 'type',
        severity: GoldenFindingSeverity.error,
        message: 'Figma는 ‘$name’ 컴포넌트인데 구현은 ${other.name}입니다.',
        diffs: [_diff('component', name, other.name, null)],
        design: design,
        component: other,
        rect: other.rect,
        hint: known ? '$expected 컴포넌트로 바꾸세요.' : '‘$name’에 해당하는 코드 컴포넌트를 확인하세요.',
      );
      return;
    }
    final inside = renderNodes
        .where((r) => design.rect.containsRect(r.visibleRect, slack: 2))
        .toList();
    final built = inside.firstOrNull;
    final variant = instance.variant.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    if (known) {
      _add(
        category: GoldenFindingCategory.component,
        key: 'missing',
        severity: GoldenFindingSeverity.error,
        message: built == null
            ? 'Figma ‘$name’${variant.isEmpty ? '' : '($variant)'} 컴포넌트가 '
                  '구현에 없습니다.'
            : 'Figma ‘$name’${variant.isEmpty ? '' : '($variant)'} 자리를 '
                  '${catalog?.name ?? '디자인 시스템'} $expected 대신 직접 만든 위젯'
                  '(${built.widget})으로 그렸습니다.',
        diffs: [_diff('component', name, built?.widget, null)],
        design: design,
        render: built,
        hint:
            '${catalog?.name ?? '디자인 시스템'}의 $expected 컴포넌트를 쓰세요'
            '${variant.isEmpty ? '' : ' ($variant)'}.',
      );
      return;
    }
    _add(
      category: GoldenFindingCategory.component,
      key: 'catalog',
      severity: catalog == null
          ? GoldenFindingSeverity.info
          : GoldenFindingSeverity.warning,
      message: catalog == null
          ? 'Figma 컴포넌트 ‘$name’에 대응하는 코드 컴포넌트를 알 수 없습니다.'
          : 'Figma 컴포넌트 ‘$name’은 ${catalog.name} 카탈로그에 없습니다 — 디자인 시스템 '
                '확장 후보입니다.',
      diffs: [
        _diff(
          'catalog',
          name,
          null,
          null,
          severity: GoldenFindingSeverity.warning,
        ),
      ],
      design: design,
      render: built,
      hint: catalog == null
          ? 'GoldenDesignSystem(components: [GoldenComponentMapping(...)]) 로 '
                '대응을 알려 주세요.'
          : '기존 컴포넌트로 표현된다면 GoldenComponentMapping(figma: '
                "'$name', widget: '…') 을 추가하고, 아니면 ${catalog.name}에 "
                '‘$name’ 컴포넌트를 추가하세요.',
    );
  }

  // ────────────────────────── images and icons ─────────────────────────────

  bool _isIcon(GoldenDesignNode node) {
    final small = node.rect.width <= 64 && node.rect.height <= 64;
    if (!small) return false;
    const vectors = {
      'VECTOR',
      'BOOLEAN_OPERATION',
      'STAR',
      'POLYGON',
      'REGULAR_POLYGON',
      'LINE',
    };
    if (vectors.contains(node.type)) return true;
    final name = '${node.instance?.name ?? ''} ${node.name}'.toLowerCase();
    return node.isInstance && RegExp(r'\bicon|^ic[_/ -]|icon/').hasMatch(name);
  }

  void _matchImagesAndIcons() {
    final images = designNodes.where((n) => n.hasImageFill).toList();
    final renderedImages = renderNodes
        .where(
          (n) => n.kind == GoldenRenderKind.image || (n.box?.image ?? false),
        )
        .toList();
    final imagePairs = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    for (final design in images) {
      for (final render in renderedImages) {
        final iou = design.rect.iou(render.rect);
        if (iou >= 0.5) imagePairs.add((design, render, 1 - iou));
      }
    }
    _assign(imagePairs, _Kind.image);
    for (final design in images) {
      if (matched.containsKey(design.id)) continue;
      _add(
        category: GoldenFindingCategory.presence,
        key: 'missing',
        severity: GoldenFindingSeverity.error,
        message: 'Figma 이미지 ‘${design.name}’가 구현에 없습니다.',
        diffs: [_diff('image', true, false, null)],
        design: design,
      );
    }

    // Icons: design vectors and icon instances that sit outside text.
    final icons = designNodes
        .where((n) => _isIcon(n) && !_insideMatchedOrInstanceIcon(n))
        .toList();
    final renderedIcons = renderNodes
        .where(
          (n) =>
              n.kind == GoldenRenderKind.icon ||
              n.kind == GoldenRenderKind.graphic ||
              (n.kind == GoldenRenderKind.image &&
                  n.rect.width <= 64 &&
                  n.rect.height <= 64),
        )
        .toList();
    final iconPairs = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    for (final design in icons) {
      final size = math.max(design.rect.width, design.rect.height);
      for (final render in renderedIcons) {
        if (usedRender.contains(render.id)) continue;
        final distance = design.rect.centerDistance(render.rect);
        final renderSize = math.max(render.rect.width, render.rect.height);
        final ratio = size == 0 ? 0 : renderSize / size;
        if (distance <= math.max(4, size / 2) && ratio >= 0.5 && ratio <= 2) {
          iconPairs.add((design, render, distance));
        }
      }
    }
    _assign(iconPairs, _Kind.icon);
    for (final design in icons) {
      final match = matched[design.id];
      if (match == null) {
        final evidence = _pixelEvidence(design.rect);
        if (context.regions != null && !evidence) continue;
        _add(
          category: GoldenFindingCategory.presence,
          key: 'missing',
          severity: GoldenFindingSeverity.error,
          message:
              'Figma 아이콘 ‘${design.instance?.name ?? design.name}’가 구현에 '
              '없습니다.',
          diffs: [_diff('icon', true, false, null)],
          design: design,
        );
        continue;
      }
      _compareIcon(match);
    }
  }

  bool _insideMatchedOrInstanceIcon(GoldenDesignNode node) =>
      spec.ancestors(node).any((a) => _isIcon(a));

  void _compareIcon(_Match match) {
    final design = match.design;
    final render = match.render;
    final diffs = <GoldenFindingDiff>[];
    final expectedSize = math.max(design.rect.width, design.rect.height);
    final actualSize =
        render.iconSize ?? math.max(render.rect.width, render.rect.height);
    if ((expectedSize - actualSize).abs() > tol.size) {
      diffs.add(
        _diff(
          'size',
          expectedSize,
          actualSize,
          'px',
          delta: actualSize - expectedSize,
          severity: (expectedSize - actualSize).abs() > tol.majorOffset
              ? GoldenFindingSeverity.error
              : GoldenFindingSeverity.warning,
        ),
      );
    }
    if (diffs.isNotEmpty) {
      _add(
        category: GoldenFindingCategory.shape,
        key: 'icon',
        severity: _worst(diffs),
        message:
            '아이콘 ‘${design.instance?.name ?? design.name}’ 크기가 다릅니다: '
            '${_n(expectedSize)} → ${_n(actualSize)}px.',
        diffs: diffs,
        design: design,
        render: render,
        hint: 'size: ${_n(expectedSize)}',
      );
    }
    final expected = _vectorColor(design);
    final actual = render.iconColor;
    if (expected != null && actual != null) {
      _compareColor(
        key: 'icon',
        property: 'iconColor',
        design: design,
        render: render,
        expected: expected.color!,
        actual: actual,
        expectedToken: expected.variable,
        label: '아이콘 색',
      );
    }
  }

  GoldenDesignPaint? _vectorColor(GoldenDesignNode node) {
    final own = node.solidFill ?? node.solidStroke;
    if (own != null) return own;
    for (final child in spec.nodes) {
      if (child.parentId == node.id || spec.ancestors(child).contains(node)) {
        final paint = child.solidFill ?? child.solidStroke;
        if (paint != null) return paint;
      }
    }
    return null;
  }

  // ─────────────────────────────── boxes ───────────────────────────────────

  void _matchBoxes() {
    final boxes = designNodes
        .where(
          (n) =>
              !n.isText &&
              !_isIcon(n) &&
              !n.hasImageFill &&
              n.paints &&
              n.rect.area < spec.frame.rect.area * 0.95,
        )
        .toList();
    final rendered = renderNodes
        .where(
          (n) =>
              n.kind == GoldenRenderKind.box &&
              n.visibleRect.area < snapshot.width * snapshot.height * 0.95,
        )
        .toList();
    final pairs = <(GoldenDesignNode, GoldenRenderNode, double)>[];
    for (final design in boxes) {
      for (final render in rendered) {
        final iou = design.rect.iou(render.rect);
        if (iou >= 0.5) pairs.add((design, render, 1 - iou));
      }
    }
    _assign(pairs, _Kind.box, allowShared: true);
    for (final design in boxes) {
      final match = matched[design.id];
      if (match == null || match.kind != _Kind.box) {
        if (match == null) _missingBox(design);
        continue;
      }
      _compareBox(match);
    }
  }

  void _missingBox(GoldenDesignNode design) {
    if (context.regions != null && !_pixelEvidence(design.rect)) return;
    final fill = design.solidFill;
    final what = fill != null
        ? '배경 ${GoldenColorMath.hexArgb(fill.color!)}'
        : (design.strokes.isNotEmpty ? '테두리' : '그림자');
    _add(
      category: GoldenFindingCategory.presence,
      key: 'missing',
      severity: GoldenFindingSeverity.warning,
      message:
          'Figma ‘${design.name}’($what, ${_n(design.rect.width)}×${_n(design.rect.height)})가 '
          '구현에서 보이지 않습니다.',
      diffs: [
        _diff(
          'box',
          true,
          false,
          null,
          severity: GoldenFindingSeverity.warning,
        ),
      ],
      design: design,
    );
  }

  void _compareBox(_Match match) {
    final design = match.design;
    final render = match.render;
    final box = render.box!;
    final fill = design.solidFill;
    if (fill != null && box.color != null && !box.gradient) {
      _compareColor(
        key: 'fill',
        property: 'fill',
        design: design,
        render: render,
        expected: fill.color!,
        actual: box.color!,
        expectedToken: fill.variable,
        label: '‘${design.name}’ 배경색',
      );
    }
    final diffs = <GoldenFindingDiff>[];
    final radii = design.cornerRadii;
    if (radii != null) {
      final actual = box.circle
          ? List.filled(4, math.min(render.rect.width, render.rect.height) / 2)
          : (box.radii ?? const [0.0, 0.0, 0.0, 0.0]);
      final limit = math.min(design.rect.width, design.rect.height) / 2;
      var worst = 0.0;
      for (var i = 0; i < 4; i++) {
        final e = math.min(radii[i], limit);
        final a = math.min(actual[i], limit);
        worst = math.max(worst, (e - a).abs());
      }
      if (worst > tol.radius) {
        diffs.add(
          _diff(
            'radius',
            _radiusLabel(radii, limit),
            _radiusLabel(actual, limit),
            'px',
            delta: worst,
            severity: worst > tol.majorOffset
                ? GoldenFindingSeverity.error
                : GoldenFindingSeverity.warning,
          ),
        );
      }
    }
    final stroke = design.solidStroke;
    final weight = design.strokeWeight ?? (stroke == null ? 0 : 1);
    if (stroke != null && weight > 0) {
      final actualWidth = box.borderWidth ?? 0;
      if ((actualWidth - weight).abs() > tol.strokeWidth) {
        diffs.add(
          _diff(
            'borderWidth',
            weight,
            actualWidth,
            'px',
            delta: actualWidth - weight,
          ),
        );
      } else if (box.borderColor != null) {
        _compareColor(
          key: 'border',
          property: 'borderColor',
          design: design,
          render: render,
          expected: stroke.color!,
          actual: box.borderColor!,
          expectedToken: stroke.variable,
          label: '‘${design.name}’ 테두리색',
        );
      }
    } else if ((box.borderWidth ?? 0) > tol.strokeWidth &&
        design.strokes.isEmpty) {
      diffs.add(
        _diff(
          'borderWidth',
          0,
          box.borderWidth,
          'px',
          severity: GoldenFindingSeverity.warning,
        ),
      );
    }
    final designShadow = design.shadows.any((s) => !s.inner);
    final renderShadow = box.shadows > 0 || (box.elevation ?? 0) > 0;
    if (designShadow != renderShadow) {
      diffs.add(
        _diff(
          'shadow',
          designShadow,
          renderShadow,
          null,
          severity: GoldenFindingSeverity.warning,
        ),
      );
    }
    if (diffs.isEmpty) return;
    _add(
      category: GoldenFindingCategory.shape,
      key: 'shape',
      severity: _worst(diffs),
      message:
          '‘${design.name}’ 모양이 다릅니다 — ${diffs.map((d) => '${_propertyLabel(d.property)} ${_v(d.expected)} → ${_v(d.actual)}').join(', ')}.',
      diffs: diffs,
      design: design,
      render: render,
    );
  }

  String _radiusLabel(List<double> radii, double limit) {
    final values = radii.map((r) => _n(math.min(r, limit))).toSet();
    return values.length == 1 ? values.single : radii.map(_n).join('/');
  }

  // ─────────────────────────────── layout ──────────────────────────────────

  void _layout() {
    if (!spec.hasStyles) return;
    for (final match in matched.values) {
      if (match.partial) continue;
      final design = match.design;
      final render = match.render;
      final isText = match.kind == _Kind.text;
      final anchor = _nearestMatchedAncestor(design);
      final (dx0, dy0) = _anchorOf(design, render, isText);
      var (ax, ay) = (0.0, 0.0);
      var (bx, by) = (0.0, 0.0);
      if (anchor != null) {
        (ax, ay) = (anchor.design.rect.left, anchor.design.rect.top);
        (bx, by) = (anchor.render.rect.left, anchor.render.rect.top);
      }
      final expectedX = dx0.$1 - ax;
      final expectedY = dy0.$1 - ay;
      final actualX = dx0.$2 - bx;
      final actualY = dy0.$2 - by;
      final dx = actualX - expectedX;
      final dy = actualY - expectedY;
      final limit = isText ? tol.textPosition : tol.position;
      final diffs = <GoldenFindingDiff>[];
      GoldenFindingSeverity severityOf(double delta) =>
          delta.abs() > tol.majorOffset
          ? GoldenFindingSeverity.error
          : GoldenFindingSeverity.warning;
      if (dx.abs() > limit) {
        diffs.add(
          _diff(
            'x',
            _round(expectedX),
            _round(actualX),
            'px',
            delta: dx,
            severity: severityOf(dx),
          ),
        );
      }
      if (dy.abs() > limit) {
        diffs.add(
          _diff(
            'y',
            _round(expectedY),
            _round(actualY),
            'px',
            delta: dy,
            severity: severityOf(dy),
          ),
        );
      }
      if (!isText) {
        final dw = render.rect.width - design.rect.width;
        final dh = render.rect.height - design.rect.height;
        if (dw.abs() > tol.size) {
          diffs.add(
            _diff(
              'width',
              _round(design.rect.width),
              _round(render.rect.width),
              'px',
              delta: dw,
              severity: severityOf(dw),
            ),
          );
        }
        if (dh.abs() > tol.size) {
          diffs.add(
            _diff(
              'height',
              _round(design.rect.height),
              _round(render.rect.height),
              'px',
              delta: dh,
              severity: severityOf(dh),
            ),
          );
        }
      }
      if (diffs.isEmpty) continue;
      final gap = _gap(match);
      if (gap != null) diffs.add(gap);
      final relative = anchor == null ? '화면 왼쪽 위' : '‘${anchor.design.name}’';
      final moves = [
        if (dx.abs() > limit) '가로 ${dx > 0 ? '+' : ''}${_n(dx)}px',
        if (dy.abs() > limit) '세로 ${dy > 0 ? '+' : ''}${_n(dy)}px',
      ];
      final sizes = diffs
          .where((d) => d.property == 'width' || d.property == 'height')
          .map(
            (d) =>
                '${_propertyLabel(d.property)} ${_v(d.expected)} → ${_v(d.actual)}',
          )
          .toList();
      final parent = spec[design.parentId ?? ''];
      final layout = parent?.layout;
      _add(
        category: GoldenFindingCategory.layout,
        key: 'layout',
        severity: _worst(diffs),
        message:
            '‘${render.label}’ ${[if (moves.isNotEmpty) '위치가 $relative 기준 ${moves.join(', ')}', ...sizes].join(', ')} '
            '어긋납니다.',
        diffs: diffs,
        design: design,
        render: render,
        rect: render.rect,
        hint: _layoutHint(gap, layout, anchor),
      );
    }
  }

  String? _layoutHint(
    GoldenFindingDiff? gap,
    GoldenDesignLayout? layout,
    _Match? anchor,
  ) {
    if (gap != null) {
      return '앞 요소와의 간격을 ${_v(gap.expected)}px로 맞추세요(Gap·SizedBox·padding).';
    }
    if (layout != null) {
      final padding = layout.padding.map(_n).join('/');
      return 'Figma 오토 레이아웃: ${layout.mode == 'VERTICAL' ? '세로' : '가로'}, '
          '간격 ${_n(layout.gap ?? 0)}, 안쪽 여백 $padding(위/오른쪽/아래/왼쪽).';
    }
    return anchor == null ? null : '‘${anchor.design.name}’ 안의 여백과 정렬을 확인하세요.';
  }

  /// Gap to the previous matched sibling along the parent's layout axis.
  GoldenFindingDiff? _gap(_Match match) {
    final design = match.design;
    final parent = spec[design.parentId ?? ''];
    final horizontal = parent?.layout?.mode == 'HORIZONTAL';
    _Match? previous;
    for (final sibling in spec.nodes) {
      if (sibling.parentId != design.parentId || sibling.id == design.id) {
        continue;
      }
      final m = matched[sibling.id];
      if (m == null || m.partial) continue;
      final before = horizontal
          ? sibling.rect.right <= design.rect.left + 0.5
          : sibling.rect.bottom <= design.rect.top + 0.5;
      if (!before) continue;
      if (previous == null ||
          (horizontal
              ? sibling.rect.right > previous.design.rect.right
              : sibling.rect.bottom > previous.design.rect.bottom)) {
        previous = m;
      }
    }
    if (previous == null) return null;
    final expected = horizontal
        ? design.rect.left - previous.design.rect.right
        : design.rect.top - previous.design.rect.bottom;
    final actual = horizontal
        ? match.render.rect.left - previous.render.rect.right
        : match.render.rect.top - previous.render.rect.bottom;
    if ((actual - expected).abs() <= tol.position) return null;
    return _diff(
      'gap',
      _round(expected),
      _round(actual),
      'px',
      delta: actual - expected,
      severity: (actual - expected).abs() > tol.majorOffset
          ? GoldenFindingSeverity.error
          : GoldenFindingSeverity.warning,
      scope: '‘${previous.design.name}’ 다음',
    );
  }

  _Match? _nearestMatchedAncestor(GoldenDesignNode node) {
    for (final ancestor in spec.ancestors(node)) {
      final match = matched[ancestor.id];
      if (match != null && !match.partial && match.kind != _Kind.text) {
        return match;
      }
    }
    return null;
  }

  /// (design x, render x), (design y, render y) of the comparable anchor.
  ((double, double), (double, double)) _anchorOf(
    GoldenDesignNode design,
    GoldenRenderNode render,
    bool isText,
  ) {
    if (!isText) {
      return (
        (design.rect.left, render.rect.left),
        (design.rect.top, render.rect.top),
      );
    }
    final content = render.text!.contentRect;
    final rect = _textRect(design);
    final align = design.text?.align ?? 'LEFT';
    final x = switch (align) {
      'CENTER' => (rect.centerX, content.centerX),
      'RIGHT' => (rect.right, content.right),
      _ => (rect.left, content.left),
    };
    final y = switch (design.text?.verticalAlign) {
      'CENTER' => (rect.centerY, content.centerY),
      'BOTTOM' => (rect.bottom, content.bottom),
      _ => (rect.top, content.top),
    };
    return (x, y);
  }

  /// Box of a design text for anchors (Figma's line box).
  GoldenRect _textRect(GoldenDesignNode node) => node.rect;

  /// Where the glyphs are, for distances: fixed-width text boxes are much
  /// wider than their text.
  GoldenRect _glyphs(GoldenDesignNode node) => node.inkRect ?? node.rect;

  // ─────────────────────────────── colors ──────────────────────────────────

  void _compareColor({
    required String key,
    required String property,
    required GoldenDesignNode design,
    required GoldenRenderNode render,
    required int expected,
    required int actual,
    required String label,
    String? expectedToken,
  }) {
    final delta = _deltaE(expected, actual);
    final alphaDelta =
        (((expected >> 24) & 255) - ((actual >> 24) & 255)).abs() / 255;
    final expectedName = expectedToken == null
        ? null
        : goldenTokenName(expectedToken);
    final actualName = _tokenOf(actual);
    final tokenMismatch =
        expectedName != null &&
        actualName != null &&
        expectedName != actualName &&
        !expectedToken!.startsWith('VariableID:');
    if (delta <= tol.propertyDeltaE && alphaDelta <= 0.1 && !tokenMismatch) {
      return;
    }
    final severity = delta > tol.majorDeltaE || alphaDelta > 0.3
        ? GoldenFindingSeverity.error
        : GoldenFindingSeverity.warning;
    final expectedText =
        '${GoldenColorMath.hexArgb(expected)}${expectedName == null ? '' : ' ($expectedName)'}';
    final actualText =
        '${GoldenColorMath.hexArgb(actual)}${actualName == null ? '' : ' ($actualName)'}';
    _add(
      category: GoldenFindingCategory.color,
      key: key,
      severity: delta <= tol.propertyDeltaE && alphaDelta <= 0.1
          ? GoldenFindingSeverity.warning
          : severity,
      message: delta <= tol.propertyDeltaE && alphaDelta <= 0.1
          ? '$label의 값은 같지만 토큰이 다릅니다: $expectedName → $actualName. '
                '다른 테마(다크 모드)에서 달라집니다.'
          : '$label이 다릅니다: $expectedText → $actualText (ΔE ${_n(delta)}).',
      diffs: [
        _diff(
          property,
          expectedText,
          actualText,
          'ΔE',
          delta: delta,
          severity: severity,
        ),
      ],
      design: design,
      render: render,
      hint: expectedName == null
          ? null
          : '색 토큰 ‘$expectedName’을 쓰세요(리터럴 색을 쓰지 않습니다).',
    );
  }

  String? _tokenOf(int argb) {
    String? best;
    var bestDelta = double.infinity;
    for (final MapEntry(:key, :value) in context.colorTokens.entries) {
      if (((value >> 24) & 255) != ((argb >> 24) & 255)) continue;
      final delta = _deltaE(value, argb);
      if (delta < bestDelta) {
        bestDelta = delta;
        best = key;
      }
    }
    return bestDelta <= 0.5 ? goldenTokenName(best!) : null;
  }

  double _deltaE(int a, int b) => GoldenColorMath.deltaE(
    GoldenColorMath.over(a, 0xffffff),
    GoldenColorMath.over(b, 0xffffff),
  );

  // ─────────────────────────────── helpers ─────────────────────────────────

  bool _pixelEvidence(GoldenRect rect) {
    final regions = context.regions;
    if (regions == null) return true;
    return regions.any((r) => r.bounds.coveredBy(rect) >= 0.3);
  }

  void _assign(
    List<(GoldenDesignNode, GoldenRenderNode, double)> pairs,
    _Kind kind, {
    bool allowShared = false,
  }) {
    pairs.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (design, render, _) in pairs) {
      if (matched.containsKey(design.id)) continue;
      if (!allowShared && usedRender.contains(render.id)) continue;
      matched[design.id] = _Match(design, render, kind);
      usedRender.add(render.id);
    }
  }

  void _add({
    required String category,
    required String key,
    required GoldenFindingSeverity severity,
    required String message,
    List<GoldenFindingDiff> diffs = const [],
    GoldenDesignNode? design,
    GoldenRenderNode? render,
    GoldenRenderComponent? component,
    String? designRole,
    String? widgetRole,
    GoldenRect? rect,
    String? hint,
  }) {
    final subject =
        design?.id ??
        render?.source?.label ??
        (render == null ? key : 'w${render.id}');
    var id = '$category@$subject';
    if (category == GoldenFindingCategory.color ||
        category == GoldenFindingCategory.presence) {
      id = '$category.$key@$subject';
    }
    final seen = _ids[id] = (_ids[id] ?? 0) + 1;
    if (seen > 1) id = '$id#$seen';
    final enclosing = component ?? snapshot.componentOf(render);
    final owner = GoldenFindingOwner.of(render, enclosing);
    final drawnByComponent =
        owner == GoldenFindingOwner.designSystem && enclosing != null;
    findings.add(
      GoldenDesignFinding(
        id: id,
        category: category,
        severity: severity,
        message: message,
        diffs: diffs,
        design: design,
        designPath: design == null ? null : spec.pathOf(design),
        designRole: designRole,
        widget: render,
        component: enclosing,
        widgetRole: widgetRole,
        rect:
            rect ??
            (design != null && render != null
                ? design.rect.union(render.rect)
                : (render?.rect ?? design?.rect)),
        hint: drawnByComponent
            ? '‘${enclosing.name}’'
                  '${enclosing.library == null ? '' : '(${enclosing.library})'}가 '
                  '직접 그린 요소입니다 — 앱에서 덮어쓰지 말고 디자인 시스템 버전 '
                  '차이나 라이브러리와 코드의 차이인지 확인하세요. 추적 이슈가 '
                  "있으면 GoldenKnownDifference(widget: '${enclosing.name}', "
                  'issue: …)로 등록합니다.'
            : hint,
        owner: owner,
      ),
    );
  }

  static GoldenFindingDiff _diff(
    String property,
    Object? expected,
    Object? actual,
    String? unit, {
    double? delta,
    GoldenFindingSeverity severity = GoldenFindingSeverity.error,
    String? scope,
  }) => GoldenFindingDiff(
    property: property,
    expected: expected is double ? _round(expected) : expected,
    actual: actual is double ? _round(actual) : actual,
    severity: severity,
    unit: unit,
    delta: delta,
    scope: scope,
  );
}

GoldenFindingSeverity _worst(List<GoldenFindingDiff> diffs) =>
    diffs.fold(GoldenFindingSeverity.info, (worst, d) => worst.max(d.severity));

String _normalize(String value) => value
    .replaceAll(RegExp('[​-‍﻿￼]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _family(String? family) {
  if (family == null) return '';
  return goldenNormalizeName(
    family
        .replaceFirst(RegExp(r'^packages/[^/]+/'), '')
        .replaceAll(RegExp(r'\s*(variable|vf)$', caseSensitive: false), ''),
  );
}

String _alignName(String figma) => switch (figma.toUpperCase()) {
  'CENTER' => 'center',
  'RIGHT' => 'right',
  'JUSTIFIED' => 'justify',
  _ => 'left',
};

double _similarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final distance = _levenshtein(a, b);
  return 1 - distance / math.max(a.length, b.length);
}

int _levenshtein(String a, String b) {
  if (a.length > 200 || b.length > 200) {
    return a.length > b.length ? a.length : b.length;
  }
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    previous = current;
  }
  return previous[b.length];
}

String _short(String value) {
  final text = _normalize(value);
  return text.length > 32 ? '${text.substring(0, 31)}…' : text;
}

double _round(double value) => goldenRound(value);

String _n(double value) {
  final rounded = goldenRound(value, 1);
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

String _v(Object? value) => switch (value) {
  null => '없음',
  final double d => _n(d),
  true => '있음',
  false => '없음',
  _ => '$value',
};

String _propertyLabel(String property) => switch (property) {
  'role' => '텍스트 역할',
  'fontFamily' => '서체',
  'fontWeight' => '굵기',
  'fontSize' => '크기',
  'lineHeight' => '행간',
  'letterSpacing' => '자간',
  'italic' => '기울임',
  'decoration' => '꾸밈선',
  'textAlign' => '정렬',
  'x' => '가로',
  'y' => '세로',
  'width' => '너비',
  'height' => '높이',
  'gap' => '간격',
  'radius' => '모서리',
  'borderWidth' => '테두리 두께',
  'shadow' => '그림자',
  'color' => '색',
  _ => property,
};
