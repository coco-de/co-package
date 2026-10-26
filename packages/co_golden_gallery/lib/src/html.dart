import 'dart:convert';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/server.dart' as jaspr;

import 'design_analysis.dart';
import 'favicon.dart';
import 'model.dart';
import 'view.dart';

/// Resolves the `src` of an image in the rendered page.
typedef GalleryImageUrl = String Function(GalleryImage image);

/// Page-level settings of a rendered gallery.
@immutable
final class GalleryPageOptions {
  /// Creates page options. [brandColor] must be a `#RRGGBB` color.
  GalleryPageOptions({
    this.title = 'Golden Gallery',
    this.brandColor = '#5BE0C8',
    this.noindex = false,
    this.metadata = const [],
    this.links = const [],
    this.plainTitle = '축 없는 이미지',
    DateTime? generatedAt,
  }) : generatedAt = (generatedAt ?? DateTime.now()).toUtc() {
    if (!isGalleryColor(brandColor)) {
      throw ArgumentError.value(brandColor, 'brandColor', 'must be #RRGGBB');
    }
  }

  /// Page title and heading.
  final String title;

  /// Accent color as `#RRGGBB`.
  final String brandColor;

  /// Adds `<meta name="robots" content="noindex, nofollow">`.
  final bool noindex;

  /// Label and value pairs shown in the header, such as the commit.
  final List<(String, String)> metadata;

  /// Label and URL pairs linked from the header.
  final List<(String, String)> links;

  /// Build time shown in the header.
  final DateTime generatedAt;

  /// Heading of the section that holds images without device, theme, or
  /// locale, such as regression baselines.
  final String plainTitle;
}

/// Whether [value] is a `#RRGGBB` color.
bool isGalleryColor(String value) =>
    RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value);

/// Escapes [value] for HTML text and double- or single-quoted attributes.
String escapeGalleryHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Renders a standalone gallery with Jaspr and CoUI Web components.
///
/// CSS and script stay inline. The CLI writes the cocode favicon files in
/// [galleryFavicons] beside the page. CoUI components render on the server;
/// the small script adds filters, theme switching, and the lightbox.
Future<String> renderGalleryHtml(
  GalleryCatalog catalog,
  GalleryPageOptions options, {
  required GalleryImageUrl imageUrl,
}) async {
  final lightbox = <Map<String, Object?>>[];
  final imageIndices = <GalleryImage, int>{};
  for (final scenario in catalog.scenarios) {
    for (final image in scenario.images) {
      if (image.path.isEmpty) continue;
      imageIndices[image] = lightbox.length;
      lightbox.add({
        'src': imageUrl(image),
        'title': '${scenario.suite} / ${scenario.name}',
        'label': image.label,
        'status': image.status.name,
        'errors': image.errors,
        if (image.designComparison case final design?)
          'design': {
            'reference': imageUrl(
              GalleryImage(name: design.label, path: design.reference),
            ),
            'label': design.label,
            'sourceUrl': design.sourceUrl,
            'status': design.status,
            'summary': design.summary,
            'referenceWidth': design.referenceWidth,
            'referenceHeight': design.referenceHeight,
            'renderWidth': design.renderWidth,
            'renderHeight': design.renderHeight,
            'diff': design.diff == null
                ? null
                : imageUrl(GalleryImage(name: 'diff', path: design.diff!)),
            if (design.analysis case final analysis?)
              'analysis': _analysisData(analysis, imageUrl),
          },
      });
    }
  }

  jaspr.Jaspr.initializeApp();
  final response = await jaspr.renderComponent(
    CoUIWeb(
      theme: ThemeData.coui,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      disableBrowserContextMenu: false,
      enableScrollInterception: false,
      enableThemeAnimation: false,
      child: GalleryView(
        catalog: catalog,
        title: options.title,
        plainTitle: options.plainTitle,
        metadata: options.metadata,
        links: options.links,
        generatedAt: options.generatedAt,
        imageUrl: imageUrl,
        imageIndices: imageIndices,
      ),
    ),
    standalone: true,
  );
  if (response.statusCode != 200) {
    throw StateError('CoUI gallery rendering failed (${response.statusCode}).');
  }
  final body = utf8.decode(response.body);
  final head = StringBuffer()
    ..write('<meta charset="utf-8">')
    ..write(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..write('<meta name="generator" content="co_golden_gallery">')
    ..write('${galleryFavicons.map((icon) => icon.link).join('\n')}\n')
    ..write('<title>${escapeGalleryHtml(options.title)}</title>')
    ..write('<style>${_css(options.brandColor)}</style>');
  if (options.noindex) {
    head.write('<meta name="robots" content="noindex, nofollow">');
  }
  final scripts =
      '<script type="application/json" id="gallery-data">'
      '${_jsonForScript(lightbox)}</script><script>$_script</script>';
  return '<!doctype html><html lang="ko" data-theme="dark"><head>$head</head>'
      '<body>$body$scripts</body></html>';
}

/// Viewer data of one analysis: summary, URLs, and the trimmed report.
Map<String, Object?> _analysisData(
  GalleryDesignAnalysis analysis,
  GalleryImageUrl imageUrl,
) {
  final details = analysis.details;
  return {
    'verdict': analysis.verdict,
    'pixelStatus': analysis.pixelStatus,
    'summary': analysis.summary,
    'line': analysis.line,
    'report': imageUrl(GalleryImage(name: 'report', path: analysis.report)),
    'diff': analysis.diff == null
        ? null
        : imageUrl(GalleryImage(name: 'analysis', path: analysis.diff!)),
    if (details != null)
      ...details.toViewJson()
    else ...{
      'findings': const <Object?>[],
      'findingsTruncated': 0,
      'regions': const <Object?>[],
      'regionsTruncated': 0,
      'masks': const <Object?>[],
      'warnings': const ['분석 리포트 파일이 없어 지적 사항을 보여 줄 수 없습니다.'],
    },
  };
}

String _jsonForScript(Object? value) {
  const slash = r'\';
  return jsonEncode(value)
      .replaceAll('<', '${slash}u003c')
      .replaceAll('>', '${slash}u003e')
      .replaceAll('&', '${slash}u0026');
}

// The colors and geometry follow cocode-home's site tokens. CoUI's semantic
// slots resolve to the same palette, while these page rules lay out the data.
String _css(String brand) {
  final lightBrand = brand.toUpperCase() == '#5BE0C8'
      ? '#167463'
      : 'color-mix(in srgb, $brand 55%, #000)';
  return '''
:root {
  --gallery-content-width: 1200px; --gallery-gutter: 24px;
  --bg: #0b0d0e; --surface: #121517; --panel: #181c1e;
  --ink: #e7eaeb; --secondary: #9aa1a3; --muted: #81888b;
  --line: #22282a; --line-strong: #343b3e;
  --soft: #181c1e; --fail: #e38b78; --fail-soft: #2b1b18; --on-fail: #0b0d0e;
  --ok: #5be0c8; --brand: $brand;
  --warn: #e3b341; --mark-design: #ff4fd8; --mark-widget: #2ec5ff; --mark-region: #ff6b5f;
  --mark-mask: #6a8dff;
  --coui-surface: 11 13 14; --coui-surface-container-low: 18 21 23;
  --coui-surface-container: 24 28 30; --coui-on-surface: 231 234 235;
  --coui-on-surface-variant: 154 161 163; --coui-outline: 106 114 117;
  --coui-outline-variant: 34 40 42; --coui-primary: 231 234 235;
  --coui-on-primary: 11 13 14; --coui-error: 227 139 120;
  color-scheme: dark;
  font-family: Pretendard, "Apple SD Gothic Neo", "Segoe UI", system-ui, sans-serif;
}
@media (prefers-color-scheme: light) {
  :root:not([data-theme]) {
    --bg: #fafbfc; --surface: #ffffff; --panel: #eaeef0;
    --ink: #14161a; --secondary: #4a5053; --muted: #62686b;
    --line: #dce1e4; --line-strong: #bdc3c7;
    --soft: #eaeef0; --fail: #b53e24; --fail-soft: #fbece7; --on-fail: #ffffff;
    --ok: #167463; --brand: $lightBrand;
    --warn: #8a5f00; --mark-design: #b8128f; --mark-widget: #00699e; --mark-region: #c4291f;
    --mark-mask: #3a5bd9;
    --coui-surface: 250 251 252; --coui-surface-container-low: 255 255 255;
    --coui-surface-container: 234 238 240; --coui-on-surface: 20 22 26;
    --coui-on-surface-variant: 74 80 83; --coui-outline: 121 127 130;
    --coui-outline-variant: 220 225 228; --coui-primary: 20 22 26;
    --coui-on-primary: 243 245 247; --coui-error: 181 62 36;
    color-scheme: light;
  }
}
:root[data-theme="light"] {
  --bg: #fafbfc; --surface: #ffffff; --panel: #eaeef0;
  --ink: #14161a; --secondary: #4a5053; --muted: #62686b;
  --line: #dce1e4; --line-strong: #bdc3c7;
  --soft: #eaeef0; --fail: #b53e24; --fail-soft: #fbece7; --on-fail: #ffffff;
  --ok: #167463; --brand: $lightBrand;
    --warn: #8a5f00; --mark-design: #b8128f; --mark-widget: #00699e; --mark-region: #c4291f;
  --mark-mask: #3a5bd9;
  --coui-surface: 250 251 252; --coui-surface-container-low: 255 255 255;
  --coui-surface-container: 234 238 240; --coui-on-surface: 20 22 26;
  --coui-on-surface-variant: 74 80 83; --coui-outline: 121 127 130;
  --coui-outline-variant: 220 225 228; --coui-primary: 20 22 26;
  --coui-on-primary: 243 245 247; --coui-error: 181 62 36;
  color-scheme: light;
}
* { box-sizing: border-box; }
[hidden] { display: none !important; }
html { scroll-padding-top: 94px; }
body { margin: 0; min-height: 100vh; background: var(--bg); color: var(--ink); font-size: 14px; line-height: 1.6; }
.coui-root { width: 100%; color: var(--ink); font-family: inherit; }
a { color: var(--brand); }
button, select, input { font: inherit; color: inherit; }
:focus-visible { outline: 2px solid var(--brand); outline-offset: 2px; }
h1, h2, h3, p, figure, dl, dd { margin: 0; }
/* Keep the centered shell's gutter inside its own max-width. Percentage padding on
   a max-width child resolves against the viewport and shrinks content on wide screens. */
.top, .layout { max-width: calc(var(--gallery-content-width) + 2 * var(--gallery-gutter));
  margin-inline: auto; padding-inline: var(--gallery-gutter); }
.top { display: flex; flex-wrap: wrap; gap: 24px;
  justify-content: space-between; align-items: flex-end; padding-block: 56px 36px; }
.title { display: grid; gap: 12px; min-width: 0; }
.eyebrow { color: var(--brand); font: 500 11px/1.4 ui-monospace, "SF Mono", Menlo, monospace; letter-spacing: .16em; }
h1 { font-size: clamp(30px, 4vw, 54px); line-height: 1.15; font-weight: 650; letter-spacing: -.035em; text-wrap: balance; }
.stats { display: flex; flex-wrap: wrap; gap: 6px 22px; padding: 0; list-style: none; color: var(--secondary); }
.stats b { color: var(--ink); font-variant-numeric: tabular-nums; }
.stats .bad b { color: var(--fail); }
.stats .good b { color: var(--ok); }
.meta { display: flex; flex-wrap: wrap; gap: 4px 18px; font-size: 12px; color: var(--muted); }
.meta div { display: flex; gap: 6px; }
.meta dt { font-weight: 600; }
.meta dd { font-family: ui-monospace, "SF Mono", Menlo, monospace; }
.actions { display: flex; flex-wrap: wrap; gap: 8px; }
.link, .viewer-button { display: inline-flex; align-items: center; justify-content: center; min-height: 40px;
  padding: 0 14px; border: 1px solid var(--line-strong); border-radius: 6px; background: transparent;
  color: var(--ink); text-decoration: none; cursor: pointer; font-weight: 600; }
.link:hover, .viewer-button:hover { background: var(--panel); }
.toolbar { position: sticky; top: 0; z-index: 5; display: flex; flex-wrap: wrap; gap: 12px 18px;
  align-items: flex-end; padding: 16px max(var(--gallery-gutter), calc((100% - var(--gallery-content-width)) / 2));
  background: color-mix(in srgb, var(--bg) 94%, transparent); backdrop-filter: blur(10px);
  border-block: 1px solid var(--line); }
.field { display: grid; gap: 5px; font-size: 12px; color: var(--secondary); }
.field.grow { flex: 1 1 240px; }
.field input, .field select { min-height: 40px; padding: 0 12px; border: 1px solid var(--line-strong);
  border-radius: 6px; background: var(--panel); color: var(--ink); }
.check { display: inline-flex; gap: 7px; align-items: center; min-height: 40px; }
.check input { accent-color: var(--brand); }
#visible { margin-inline-start: auto; color: var(--muted); font-variant-numeric: tabular-nums; }
.layout { display: grid; grid-template-columns: 220px minmax(0, 1fr);
  gap: 40px; padding-block: 36px 100px; }
.toc { position: sticky; top: 94px; align-self: start; max-height: calc(100vh - 118px); overflow: auto; }
.toc summary { font-weight: 600; cursor: pointer; margin-block-end: 12px; }
.toc h2 { margin: 20px 0 6px; color: var(--brand); font: 500 11px/1.5 ui-monospace, "SF Mono", Menlo, monospace;
  letter-spacing: .08em; text-transform: uppercase; }
.toc ul { margin: 0; padding: 0; list-style: none; display: grid; gap: 5px; }
.toc li { display: flex; gap: 8px; align-items: baseline; }
.toc-link { color: var(--secondary); text-decoration: none; overflow-wrap: anywhere; }
.toc-link:hover { color: var(--brand); }
.count { font: 500 11px/1.4 ui-monospace, "SF Mono", Menlo, monospace; color: var(--muted); white-space: nowrap; }
.count.fail { color: var(--fail); }
main { display: grid; gap: 56px; min-width: 0; }
.suite { display: grid; gap: 20px; }
.suite-title { padding-block-end: 12px; border-bottom: 1px solid var(--line-strong); font-size: 24px;
  font-weight: 600; letter-spacing: -.02em; }
.suite.plain .suite-title { border-bottom-color: var(--line); }
.suite-note { margin-block-start: -8px; color: var(--secondary); font-size: 13px; }
.scenario { scroll-margin-top: 100px; }
.scenario-card { width: 100%; background: var(--surface) !important; border: 1px solid var(--line) !important;
  border-radius: 6px !important; box-shadow: none !important; }
.scenario-content { display: grid; gap: 18px; min-width: 0; }
.scenario-head { display: flex; flex-wrap: wrap; gap: 6px 12px; align-items: center; }
.scenario-head h3 { font-size: 18px; font-weight: 600; letter-spacing: -.02em; }
.scenario-head p { color: var(--secondary); flex-basis: 100%; }
.badges { display: flex; gap: 6px; margin-inline-start: auto; }
.status-badge { display: inline-flex; align-items: center; min-height: 25px; padding: 2px 8px;
  border: 1px solid var(--line-strong) !important; border-radius: 4px !important;
  background: var(--panel) !important; color: var(--secondary) !important; font-size: 12px; }
.status-badge.fail { border-color: var(--fail) !important; background: var(--fail-soft) !important;
  color: var(--fail) !important; }
.matrix-wrap { overflow-x: auto; border-block-start: 1px solid var(--line); }
.matrix { border-collapse: collapse; }
.matrix th, .matrix td { padding: 12px; border-bottom: 1px solid var(--line); vertical-align: top; }
.matrix thead th { position: sticky; top: 0; background: var(--surface); font-size: 12px; font-weight: 600;
  color: var(--secondary); text-align: start; white-space: nowrap; }
.matrix tbody th { font-size: 12px; text-align: start; white-space: nowrap; color: var(--secondary); font-weight: 600; }
.matrix tr:last-child th, .matrix tr:last-child td { border-bottom: 0; }
.matrix td.none { background: repeating-linear-gradient(45deg, transparent 0 6px, var(--panel) 6px 12px); min-width: 80px; }
.shot { position: relative; display: block; padding: 0; border: 1px solid var(--line-strong); border-radius: 6px;
  overflow: hidden; background: var(--panel); cursor: zoom-in; }
.shot img { display: block; height: 240px; width: auto; max-width: none; }
.shot.failed { border-color: var(--fail); outline: 2px solid var(--fail); outline-offset: -1px; }
.shot.missing { display: grid; place-items: center; gap: 4px; width: 120px; height: 240px;
  color: var(--fail); background: var(--fail-soft); cursor: default; }
.flag { position: absolute; inset-block-start: 6px; inset-inline-start: 6px; z-index: 1; padding: 1px 6px;
  border-radius: 4px; background: var(--fail); color: var(--on-fail); font-size: 11px; font-weight: 600; }
.flag + .flag { inset-block-start: 28px; }
.shot.missing .flag { position: static; }
.errors { max-width: 320px; margin-block-start: 6px; font-size: 12px; color: var(--fail); }
.errors ul { margin: 4px 0 0; padding-inline-start: 16px; }
.cards { display: flex; flex-wrap: wrap; gap: 16px; }
.card { display: grid; gap: 6px; }
.card figcaption { font-size: 12px; color: var(--secondary); overflow-wrap: anywhere; max-width: 320px; }
.card .shot img { height: 220px; }
.muted .shot { filter: grayscale(1); }
.empty { color: var(--secondary); }
dialog { width: min(1200px, 96vw); max-height: 94vh; padding: 0; border: 1px solid var(--line-strong);
  border-radius: 6px; background: var(--surface); color: var(--ink); }
dialog::backdrop { background: rgba(8, 9, 10, .8); }
.viewer-bar { display: flex; flex-wrap: wrap; gap: 8px 16px; justify-content: space-between; align-items: center;
  padding: 14px 18px; border-bottom: 1px solid var(--line); }
#viewer-title { font-weight: 600; }
#viewer-label { color: var(--secondary); font-size: 12px; }
.viewer-actions { display: flex; gap: 8px; }
#viewer-errors { margin: 0; padding: 8px 32px 0; color: var(--fail); font-size: 12px; }
#viewer-errors:empty { display: none; }
.viewer-body { overflow: auto; max-height: calc(94vh - 72px); padding: 16px; display: grid; place-items: center; }
.viewer-body img { max-width: 100%; height: auto; }
.design-flag { position: absolute; bottom: 6px; left: 6px; padding: 2px 6px;
  background: var(--surface); color: var(--ink); border: 1px solid var(--line-strong); border-radius: 4px; font-size: 11px; }
.compare-tools { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; padding: 12px 16px; border-bottom: 1px solid var(--line); }
.compare-tools label { display: flex; gap: 8px; align-items: center; }
.compare-tools select { background: var(--panel); border: 1px solid var(--line-strong); padding: 6px; border-radius: 4px; }
#compare-summary { font-size: 12px; color: var(--secondary); flex: 1 1 260px; }
#compare-summary[data-status="sizeMismatch"] { color: var(--fail); }
#compare-stage { display: grid; width: 100%; align-items: start; justify-items: center; }
#compare-stage > figure { display: none; min-width: 0; width: 100%; }
#compare-stage[data-mode="render"] #render-pane,
#compare-stage[data-mode="reference"] #reference-pane,
#compare-stage[data-mode="overlay"] #reference-pane,
#compare-stage[data-mode="overlay"] #render-pane,
#compare-stage[data-mode="split"] #reference-pane,
#compare-stage[data-mode="split"] #render-pane,
#compare-stage[data-mode="diff"] #diff-pane,
#compare-stage[data-mode="tolerant"] #diff-pane { display: block; }
#compare-stage img { display: block; margin: auto; }
#compare-stage figcaption { font-size: 12px; color: var(--secondary); padding-bottom: 6px; }
#compare-stage[data-mode="split"] { grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 16px; }
#compare-stage[data-mode="overlay"] > figure { grid-area: 1 / 1; }
#compare-stage[data-mode="overlay"] figcaption { display: none; }
#compare-stage[data-mode="overlay"] #render-pane img { opacity: var(--render-opacity, .5); }
#compare-stage[data-mode="overlay"] #reference-marks { display: none; }
/* Every mode shows the images at their natural size, never enlarged, so the overlay keeps the
   design's pixel geometry; same-size images shrink together on narrow screens. The frame hugs
   its image, so the marks layer covers exactly the image even when a page stylesheet resizes it. */
.frame { position: relative; width: fit-content; max-width: 100%; margin: auto; }
.marks { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; overflow: visible; }
.marks rect { fill: none; stroke-width: 2px; vector-effect: non-scaling-stroke; }
.marks .mark-design { stroke: var(--mark-design); }
.marks .mark-widget { stroke: var(--mark-widget); stroke-dasharray: 6 3; }
.marks .mark-component { stroke: var(--mark-widget); stroke-dasharray: 2 3; opacity: .75; }
.marks .mark-area { stroke: var(--warn); }
.marks .mark-region { stroke: var(--mark-region); fill: color-mix(in srgb, var(--mark-region) 14%, transparent); }
.marks .mark-region.known { stroke-dasharray: 4 3; opacity: .7; }
.marks .mark-mask { stroke: var(--mark-mask); fill: color-mix(in srgb, var(--mark-mask) 16%, transparent); }
.marks .mark-selected { stroke-width: 3px; }
.design-flag[data-design-status="fail"] { border-color: var(--fail); color: var(--fail); }
.design-flag[data-design-status="undetermined"] { border-color: var(--warn); color: var(--warn); }
.viewer-body.has-analysis { grid-template-columns: minmax(0, 1fr) minmax(260px, 360px); place-items: start stretch; gap: 16px; }
.viewer-body.has-analysis #compare-stage { position: sticky; top: 0;
  max-height: calc(94vh - 104px); overflow: auto; }
.analysis-panel { display: grid; gap: 10px; align-content: start; min-width: 0; font-size: 12px; color: var(--secondary); }
#analysis-summary { color: var(--ink); font-weight: 600; }
#analysis-summary[data-verdict="fail"] { color: var(--fail); }
#analysis-summary[data-verdict="undetermined"] { color: var(--warn); }
#analysis-summary[data-verdict="pass"] { color: var(--ok); }
.analysis-actions { display: flex; flex-wrap: wrap; gap: 4px 14px; align-items: center; }
.analysis-actions .check { min-height: 32px; }
.mark-legend { display: flex; flex-wrap: wrap; gap: 4px 12px; }
.legend::before { content: ""; display: inline-block; width: 12px; height: 8px; margin-inline-end: 5px;
  border: 2px solid currentColor; vertical-align: -1px; }
.legend-design { color: var(--mark-design); }
.legend-widget { color: var(--mark-widget); }
.legend-region { color: var(--mark-region); }
.legend-mask { color: var(--mark-mask); }
.finding-group h3 { margin: 6px 0 4px; font-size: 12px; font-weight: 600; color: var(--ink); }
.finding-group h3 .count { margin-inline-start: 2px; }
.finding-group ul, .analysis-regions ul, .analysis-warnings { margin: 0; padding: 0; list-style: none; display: grid; gap: 6px; }
button.finding, button.region { display: grid; gap: 3px; width: 100%; padding: 8px 10px; text-align: start; font-size: 12px;
  line-height: 1.5; border: 1px solid var(--line-strong); border-inline-start-width: 4px; border-radius: 6px;
  background: var(--panel); color: var(--ink); cursor: pointer; }
.finding[data-severity="error"] { border-inline-start-color: var(--fail); }
.finding[data-severity="warning"] { border-inline-start-color: var(--warn); }
button.finding[aria-pressed="true"], button.region[aria-pressed="true"] { outline: 2px solid var(--brand); outline-offset: 1px; }
.known button.finding, .known button.region { border-style: dashed; opacity: .8; }
.sev { font-weight: 700; }
.finding[data-severity="error"] .sev { color: var(--fail); }
.finding[data-severity="warning"] .sev { color: var(--warn); }
.finding-diffs { font-family: ui-monospace, "SF Mono", Menlo, monospace; overflow-wrap: anywhere; }
.finding-design, .finding-widget, .finding-component, .finding-hint { color: var(--secondary); overflow-wrap: anywhere; }
.finding-owner { color: var(--ink); font-weight: 600; }
.finding-where { font: 11px/1.4 ui-monospace, "SF Mono", Menlo, monospace; color: var(--brand); overflow-wrap: anywhere; }
.finding-known { margin: 2px 0 0; font-size: 11px; color: var(--muted); }
button.region code { font: 11px/1.4 ui-monospace, "SF Mono", Menlo, monospace; color: var(--brand); }
.region-flag { justify-self: start; padding: 0 5px; border-radius: 4px; background: var(--fail-soft); color: var(--fail); font-size: 11px; }
.analysis-regions summary { cursor: pointer; font-weight: 600; color: var(--ink); }
.analysis-regions li.mask, .analysis-warnings li, .muted-note { color: var(--muted); }
@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr); gap: 24px; }
  .toc { position: static; max-height: none; }
  .shot img { height: 180px; }
  .viewer-body.has-analysis { grid-template-columns: minmax(0, 1fr); }
  .viewer-body.has-analysis #compare-stage { position: static; }
}
@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }
''';
}

const String _script = r'''
(() => {
  const data = JSON.parse(document.getElementById('gallery-data').textContent);
  const $ = (id) => document.getElementById(id);
  const root = document.documentElement;
  const toggle = $('theme-toggle');
  const labels = { auto: '테마: 자동', light: '테마: 밝게', dark: '테마: 어둡게' };
  let mode = 'dark';
  try { mode = localStorage.getItem('co-golden-theme') || 'dark'; } catch (_) {}
  const applyMode = () => {
    if (mode === 'auto') root.removeAttribute('data-theme'); else root.setAttribute('data-theme', mode);
    toggle.textContent = labels[mode] || labels.auto;
  };
  applyMode();
  toggle.addEventListener('click', () => {
    mode = mode === 'dark' ? 'light' : mode === 'light' ? 'auto' : 'dark';
    try { localStorage.setItem('co-golden-theme', mode); } catch (_) {}
    applyMode();
  });

  const inputs = ['q', 'f-suite', 'f-device', 'f-theme', 'f-locale', 'f-failed', 'f-design'].map($);
  const matches = (el, filter) =>
    (!filter.device || el.dataset.device === filter.device) &&
    (!filter.theme || el.dataset.theme === filter.theme) &&
    (!filter.locale || el.dataset.locale === filter.locale);

  const apply = () => {
    const filter = {
      q: $('q').value.trim().toLowerCase(),
      suite: $('f-suite').value,
      device: $('f-device').value,
      theme: $('f-theme').value,
      locale: $('f-locale').value,
      failed: $('f-failed').checked,
      design: $('f-design').checked,
    };
    let shown = 0;
    let total = 0;
    document.querySelectorAll('.scenario').forEach((section) => {
      let visible = 0;
      const cells = section.querySelectorAll('[data-status]');
      total += cells.length;
      const suiteOk = !filter.suite || section.dataset.suite === filter.suite;
      const textOk = !filter.q || section.dataset.search.includes(filter.q);
      const table = section.querySelector('table.matrix');
      if (table) {
        const heads = [...table.querySelectorAll('thead th')];
        const keep = heads.map((th, i) => i === 0 ||
          ((!filter.theme || th.dataset.theme === filter.theme) &&
           (!filter.locale || th.dataset.locale === filter.locale)));
        table.querySelectorAll('tr').forEach((tr) => {
          [...tr.children].forEach((cell, i) => { cell.hidden = !keep[i]; });
          if (tr.dataset.device !== undefined) {
            tr.hidden = !!filter.device && tr.dataset.device !== filter.device;
          }
        });
      }
      cells.forEach((cell) => {
        const hasDesignDifference = ['different', 'sizeMismatch', 'fail', 'undetermined']
          .includes(cell.dataset.designStatus);
        const ok = matches(cell, filter) && (!filter.failed || cell.dataset.status === 'failed') &&
          (!filter.design || hasDesignDifference);
        if (table) {
          cell.classList.toggle('muted', (filter.failed && cell.dataset.status !== 'failed') ||
            (filter.design && !hasDesignDifference));
        } else {
          cell.hidden = !ok;
        }
        if (ok) visible += 1;
      });
      const show = suiteOk && textOk && visible > 0;
      section.hidden = !show;
      if (show) shown += visible;
      const tocItem = document.querySelector('[data-toc="' + section.id + '"]');
      if (tocItem) tocItem.hidden = !show;
    });
    document.querySelectorAll('.suite').forEach((suite) => {
      suite.hidden = !suite.querySelector('.scenario:not([hidden])');
    });
    document.querySelectorAll('.toc-suite').forEach((group) => {
      group.hidden = !group.querySelector('li:not([hidden])');
    });
    $('empty').hidden = shown > 0;
    $('visible').textContent = shown + ' / ' + total + ' 표시';
  };
  inputs.forEach((el) => el.addEventListener('input', apply));
  apply();

  const viewer = $('viewer');
  let current = -1;
  let selected = null;
  const compareMode = $('compare-mode');
  const opacity = $('compare-opacity');
  const panel = $('analysis-panel');
  const showRegions = $('show-regions');
  const SVG_NS = 'http://www.w3.org/2000/svg';
  const layers = { reference: $('reference-marks'), render: $('render-marks'), diff: $('diff-marks') };
  const categoryOrder = ['font', 'frame', 'presence', 'component', 'typography', 'content', 'color',
    'layout', 'shape', 'visual'];
  const categoryLabels = { font: '폰트 로딩', frame: '프레임', presence: '누락/추가', component: '컴포넌트',
    typography: '서체', content: '내용', color: '색상', layout: '레이아웃', shape: '모양', visual: '픽셀' };
  const severityLabels = { error: '오류', warning: '경고', info: '정보' };
  const node = (tag, className, text) => {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text !== undefined && text !== null) element.textContent = text;
    return element;
  };
  const analysisOf = (item) => (item && item.design && item.design.analysis) || null;
  const validSize = (size) => (Array.isArray(size) && size[0] > 0 && size[1] > 0 ? size : null);
  const sameSize = (a, b) => !!a && !!b && Math.abs(a[0] - b[0]) < 1 && Math.abs(a[1] - b[1]) < 1;
  const addRect = (layer, rect, className) => {
    if (!Array.isArray(rect) || rect.length !== 4) return;
    const shape = document.createElementNS(SVG_NS, 'rect');
    shape.setAttribute('x', rect[0]);
    shape.setAttribute('y', rect[1]);
    shape.setAttribute('width', Math.max(rect[2], 0.5));
    shape.setAttribute('height', Math.max(rect[3], 0.5));
    shape.setAttribute('class', className);
    layer.appendChild(shape);
  };
  // Design rects use the frame's logical size, widget rects the capture's,
  // and regions the compared images'. A rect is drawn on another layer only
  // when both share one logical size, so no mark is ever rescaled.
  const drawMarks = () => {
    Object.values(layers).forEach((layer) => layer.replaceChildren());
    const analysis = analysisOf(data[current]);
    if (!analysis) return;
    const compared = validSize(analysis.comparedSize);
    const design = validSize(analysis.designSize) || compared || validSize(analysis.renderSize);
    const render = validSize(analysis.renderSize) || design;
    const diffSize = compared || design;
    [[layers.reference, design], [layers.render, render], [layers.diff, diffSize]].forEach(([layer, size]) => {
      if (size) layer.setAttribute('viewBox', '0 0 ' + size[0] + ' ' + size[1]);
      else layer.removeAttribute('viewBox');
    });
    const shared = sameSize(design, render);
    const designLayers = [layers.reference, layers.diff].concat(shared ? [layers.render] : []);
    const renderLayers = [layers.render].concat(shared ? [layers.reference, layers.diff] : []);
    const regionLayers = [layers.reference, layers.diff].concat(sameSize(diffSize, render) ? [layers.render] : []);
    if (showRegions.checked) {
      analysis.masks.forEach((mask) => regionLayers.forEach((layer) => addRect(layer, mask.rect, 'mark-mask')));
      analysis.regions.forEach((region) => regionLayers.forEach((layer) =>
        addRect(layer, region.rect, region.known ? 'mark-region known' : 'mark-region')));
    }
    if (!selected) return;
    if (selected.type === 'region') {
      const region = analysis.regions[selected.index];
      if (region) regionLayers.forEach((layer) => addRect(layer, region.rect, 'mark-region mark-selected'));
      return;
    }
    const finding = analysis.findings[selected.index];
    if (!finding) return;
    const designRect = finding.design && finding.design.rect;
    const widgetRect = finding.widget && finding.widget.rect;
    const componentRect = finding.component && finding.component.rect;
    // A pixel finding is about its differing region; the node and the widget
    // under the region only give context.
    const visual = finding.category === 'visual' && !!finding.rect;
    const element = visual ? '' : ' mark-selected';
    if (componentRect) renderLayers.forEach((layer) => addRect(layer, componentRect, 'mark-component'));
    if (designRect) designLayers.forEach((layer) => addRect(layer, designRect, 'mark-design' + element));
    if (widgetRect) renderLayers.forEach((layer) => addRect(layer, widgetRect, 'mark-widget' + element));
    if (visual) {
      regionLayers.forEach((layer) => addRect(layer, finding.rect, 'mark-region mark-selected'));
    } else if (!designRect && !widgetRect && finding.rect) {
      regionLayers.forEach((layer) => addRect(layer, finding.rect, 'mark-area mark-selected'));
    }
  };
  const select = (next) => {
    selected = next;
    panel.querySelectorAll('button[aria-pressed]').forEach((button) => {
      const on = !!next && button.dataset[next.type] === String(next.index);
      button.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    drawMarks();
    // Center the selected element in the stage (only the stage scrolls; tall
    // phone captures do not fit the dialog).
    const stage = $('compare-stage');
    const mark = [...stage.querySelectorAll('.mark-selected')]
      .find((shape) => shape.getBoundingClientRect().width > 0);
    if (mark) {
      const box = mark.getBoundingClientRect();
      const view = stage.getBoundingClientRect();
      if (box.top < view.top || box.bottom > view.bottom) {
        stage.scrollTop += box.top - view.top - Math.max(0, (view.height - box.height) / 2);
      }
      if (box.left < view.left || box.right > view.right) {
        stage.scrollLeft += box.left - view.left - Math.max(0, (view.width - box.width) / 2);
      }
    }
  };
  const findingItem = (finding, index) => {
    const item = node('li', finding.known ? 'known' : '');
    const button = node('button', 'finding');
    button.type = 'button';
    button.dataset.finding = String(index);
    button.dataset.severity = finding.severity;
    button.setAttribute('aria-pressed', 'false');
    button.append(
      node('span', 'sev', severityLabels[finding.severity] || finding.severity),
      node('span', 'finding-message', finding.message),
    );
    if (finding.diffs.length) button.append(node('span', 'finding-diffs', finding.diffs.join(' · ')));
    if (finding.design && finding.design.label) button.append(node('span', 'finding-design', finding.design.label));
    if (finding.widget && finding.widget.label) {
      button.append(node('span', 'finding-widget', '구현: ' + finding.widget.label));
    }
    if (finding.component && finding.component.label) {
      button.append(node('span', 'finding-component', '컴포넌트: ' + finding.component.label));
    }
    if (finding.where) button.append(node('code', 'finding-where', finding.where));
    if (finding.owner) button.append(node('span', 'finding-owner', '고칠 곳: ' + finding.owner));
    if (finding.hint) button.append(node('span', 'finding-hint', '고칠 방향: ' + finding.hint));
    item.append(button);
    if (finding.known) {
      const known = node('p', 'finding-known', '알려진 차이 · ' + finding.known.reason);
      if (finding.known.issue) {
        const link = node('a', '', '추적 이슈');
        link.href = finding.known.issue;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        known.append(' ', link);
      }
      item.append(known);
    }
    return item;
  };
  const renderAnalysis = (analysis) => {
    $('viewer-body').classList.toggle('has-analysis', !!analysis);
    panel.hidden = !analysis;
    const findings = $('analysis-findings');
    const regions = $('analysis-regions');
    findings.replaceChildren();
    regions.replaceChildren();
    $('analysis-warnings').replaceChildren();
    if (!analysis) return;
    const summary = $('analysis-summary');
    summary.textContent = analysis.line;
    summary.dataset.verdict = analysis.verdict;
    const report = $('analysis-report');
    report.hidden = !analysis.report;
    if (analysis.report) report.href = analysis.report;
    else report.removeAttribute('href');
    const groups = new Map();
    analysis.findings.forEach((finding, index) => {
      if (!groups.has(finding.category)) groups.set(finding.category, []);
      groups.get(finding.category).push(index);
    });
    // co_golden turns only the largest unexplained regions into pixel
    // findings; say so, or the region marks outnumber the list.
    const unexplained = analysis.regions.filter((region) => region.unexplained).length;
    categoryOrder.concat([...groups.keys()].filter((category) => !categoryOrder.includes(category)))
      .filter((category) => groups.has(category))
      .forEach((category) => {
        const section = node('section', 'finding-group');
        const heading = node('h3', '', categoryLabels[category] || category);
        heading.append(' ', node('span', 'count', String(groups.get(category).length)));
        const list = node('ul');
        groups.get(category).forEach((index) => list.append(findingItem(analysis.findings[index], index)));
        section.append(heading, list);
        if (category === 'visual' && unexplained > groups.get(category).length) {
          section.append(node('p', 'muted-note', '설명 없는 픽셀 영역 ' + unexplained + '개 중 ' +
            groups.get(category).length + '개만 지적 사항입니다. 전체는 아래 픽셀 영역 목록에 있습니다.'));
        }
        findings.append(section);
      });
    if (!analysis.findings.length) findings.append(node('p', 'muted-note', '구조 지적 사항이 없습니다.'));
    if (analysis.findingsTruncated) {
      findings.append(node('p', 'muted-note', '나머지 ' + analysis.findingsTruncated + '건은 분석 리포트 JSON에 있습니다.'));
    }
    analysis.regions.forEach((region, index) => {
      const item = node('li', region.known ? 'known' : '');
      const button = node('button', 'region');
      button.type = 'button';
      button.dataset.region = String(index);
      button.setAttribute('aria-pressed', 'false');
      button.append(node('code', '', region.id), node('span', '', region.label));
      if (region.unexplained) button.append(node('span', 'region-flag', '설명 없는 픽셀 차이'));
      if (region.known) button.append(node('span', 'region-flag', '알려진 차이 · ' + region.known.reason));
      item.append(button);
      regions.append(item);
    });
    analysis.masks.forEach((mask) => {
      regions.append(node('li', 'mask', '가림 · ' + mask.reason + (mask.source ? ' (' + mask.source + ')' : '')));
    });
    $('analysis-regions-title').textContent = '픽셀 영역 ' + analysis.regions.length + '개' +
      (analysis.regionsTruncated ? ' (+' + analysis.regionsTruncated + ')' : '') +
      (analysis.masks.length ? ' · 가림 ' + analysis.masks.length + '개' : '');
    $('analysis-regions-box').hidden = !analysis.regions.length && !analysis.masks.length;
    analysis.warnings.forEach((warning) => $('analysis-warnings').append(node('li', '', warning)));
  };
  const buttonSelection = (target) => {
    const button = target.closest('button[data-finding], button[data-region]');
    if (!button) return null;
    const type = button.dataset.finding !== undefined ? 'finding' : 'region';
    return { type, index: Number(button.dataset[type]) };
  };
  panel.addEventListener('click', (event) => {
    const next = buttonSelection(event.target);
    if (next) select(next);
  });
  panel.addEventListener('focusin', (event) => {
    const next = buttonSelection(event.target);
    if (next) select(next);
  });
  panel.addEventListener('keydown', (event) => {
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
    const buttons = [...panel.querySelectorAll('button[data-finding], button[data-region]')]
      .filter((button) => button.offsetParent !== null);
    const at = buttons.indexOf(document.activeElement);
    if (at < 0) return;
    event.preventDefault();
    buttons[(at + (event.key === 'ArrowDown' ? 1 : -1) + buttons.length) % buttons.length].focus();
  });
  showRegions.addEventListener('change', drawMarks);
  const updateComparison = () => {
    const item = data[current];
    if (!item) return;
    const design = item.design;
    const analysis = analysisOf(item);
    const mode = design ? compareMode.value : 'render';
    const stage = $('compare-stage');
    stage.dataset.mode = mode;
    stage.style.setProperty('--render-opacity', Number(opacity.value) / 100);
    $('opacity-control').hidden = mode !== 'overlay';
    $('compare-opacity-value').textContent = opacity.value + '%';
    opacity.setAttribute('aria-valuetext', '실제 구현 ' + opacity.value + '%');
    const diffImage = $('viewer-diff');
    const source = mode === 'tolerant' ? analysis && analysis.diff : mode === 'diff' ? design && design.diff : null;
    if (source) {
      if (diffImage.getAttribute('src') !== source) diffImage.src = source;
    } else {
      diffImage.removeAttribute('src');
    }
    diffImage.alt = mode === 'tolerant' ? '허용 오차를 적용한 디자인 차이 지도' : '디자인과 실제 구현의 RGBA 픽셀 차이';
    $('diff-label').textContent = mode === 'tolerant'
      ? '허용 오차 차이 · 빨강 차이 · 노랑 안티앨리어싱 · 파랑 가림'
      : 'RGBA 완전 일치 기준 차이 · 자홍 차이';
    drawMarks();
  };
  compareMode.addEventListener('change', updateComparison);
  opacity.addEventListener('input', updateComparison);
  const visibleShots = () => [...document.querySelectorAll('button.shot')]
    .filter((b) => b.offsetParent !== null && !b.closest('.muted'));
  const show = (index) => {
    const item = data[index];
    if (!item) return;
    current = index;
    selected = null;
    $('viewer-image').src = item.src;
    $('viewer-image').alt = item.title + ' — ' + item.label;
    $('viewer-title').textContent = item.title;
    $('viewer-label').textContent = item.label + (item.status === 'failed' ? ' · 실패' : '');
    const design = item.design;
    const analysis = analysisOf(item);
    $('compare-tools').hidden = !design;
    const source = $('compare-source');
    source.hidden = !design?.sourceUrl;
    source.removeAttribute('href');
    $('viewer-reference').removeAttribute('src');
    $('viewer-diff').removeAttribute('src');
    compareMode.value = design ? 'overlay' : 'render';
    opacity.value = '50';
    if (design) {
      $('viewer-reference').src = design.reference;
      $('viewer-reference').alt = design.label + ' 디자인 원본';
      $('reference-label').textContent = design.label + ' 원본';
      $('reference-option').textContent = design.label + ' 원본';
      if (design.sourceUrl) source.href = design.sourceUrl;
      const sizeMismatch = design.status === 'sizeMismatch';
      compareMode.querySelector('[value="overlay"]').disabled = sizeMismatch;
      compareMode.querySelector('[value="diff"]').disabled = sizeMismatch || !design.diff;
      compareMode.querySelector('[value="tolerant"]').disabled = !(analysis && analysis.diff);
      if (sizeMismatch) compareMode.value = 'split';
      $('compare-summary').dataset.status = design.status;
      $('compare-summary').textContent = (analysis ? '정확한 픽셀: ' : '') +
        design.summary + ' · 원본 ' +
        design.referenceWidth + '×' + design.referenceHeight + ' / 구현 ' +
        design.renderWidth + '×' + design.renderHeight +
        (sizeMismatch ? ' · 크기가 달라 겹치기·픽셀 비교 불가 (자동 크기 조정 없음)' : ' · RGBA 완전 일치 기준, 캡처 성공과 별도');
    }
    renderAnalysis(analysis);
    updateComparison();
    const errors = $('viewer-errors');
    errors.replaceChildren(...item.errors.map((e) => {
      const li = document.createElement('li');
      li.textContent = e;
      return li;
    }));
    if (!viewer.open) viewer.showModal();
  };
  const step = (delta) => {
    const shots = visibleShots();
    const at = shots.findIndex((b) => Number(b.dataset.index) === current);
    const next = shots[(at + delta + shots.length) % shots.length];
    if (next) show(Number(next.dataset.index));
  };
  document.addEventListener('click', (event) => {
    const shot = event.target.closest('button.shot');
    if (shot) show(Number(shot.dataset.index));
  });
  $('viewer-prev').addEventListener('click', () => step(-1));
  $('viewer-next').addEventListener('click', () => step(1));
  $('viewer-close').addEventListener('click', () => viewer.close());
  viewer.addEventListener('keydown', (event) => {
    if (event.target.matches('input, select, textarea')) return;
    if (event.target.closest('#analysis-panel')) return;
    if (event.key === 'ArrowLeft') step(-1);
    if (event.key === 'ArrowRight') step(1);
  });
})();
''';
