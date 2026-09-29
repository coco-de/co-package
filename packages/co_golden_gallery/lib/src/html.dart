import 'dart:convert';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/server.dart' as jaspr;

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
@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr); gap: 24px; }
  .toc { position: static; max-height: none; }
  .shot img { height: 180px; }
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

  const inputs = ['q', 'f-suite', 'f-device', 'f-theme', 'f-locale', 'f-failed'].map($);
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
        const ok = matches(cell, filter) && (!filter.failed || cell.dataset.status === 'failed');
        if (table) {
          cell.classList.toggle('muted', filter.failed && cell.dataset.status !== 'failed');
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
  const visibleShots = () => [...document.querySelectorAll('button.shot')]
    .filter((b) => b.offsetParent !== null);
  const show = (index) => {
    const item = data[index];
    if (!item) return;
    current = index;
    $('viewer-image').src = item.src;
    $('viewer-image').alt = item.title + ' — ' + item.label;
    $('viewer-title').textContent = item.title;
    $('viewer-label').textContent = item.label + (item.status === 'failed' ? ' · 실패' : '');
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
    if (event.key === 'ArrowLeft') step(-1);
    if (event.key === 'ArrowRight') step(1);
  });
})();
''';
