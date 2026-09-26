import 'dart:convert';

import 'package:meta/meta.dart';

import 'model.dart';

/// Resolves the `src` of an image in the rendered page.
typedef GalleryImageUrl = String Function(GalleryImage image);

/// Page-level settings of a rendered gallery.
@immutable
final class GalleryPageOptions {
  /// Creates page options. [brandColor] must be a `#RRGGBB` color.
  GalleryPageOptions({
    this.title = 'Golden Gallery',
    this.brandColor = '#0062D1',
    this.noindex = false,
    this.metadata = const [],
    this.links = const [],
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

/// Renders the whole gallery as one self-contained HTML document.
///
/// Styles and script are inline and no external resource is loaded besides
/// the images themselves, whose URLs come from [imageUrl].
String renderGalleryHtml(
  GalleryCatalog catalog,
  GalleryPageOptions options, {
  required GalleryImageUrl imageUrl,
}) {
  final lightbox = <Map<String, Object?>>[];
  final out = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="ko">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    );
  if (options.noindex) {
    out.writeln('<meta name="robots" content="noindex, nofollow">');
  }
  out
    ..writeln('<meta name="generator" content="co_golden_gallery">')
    ..writeln('<title>${escapeGalleryHtml(options.title)}</title>')
    ..writeln('<style>${_css(options.brandColor)}</style>')
    ..writeln('</head>')
    ..writeln('<body>');

  _writeHeader(out, catalog, options);
  _writeToolbar(out, catalog);
  out
    ..writeln('<div class="layout">')
    ..writeln('<nav class="toc" aria-label="시나리오 목록">')
    ..writeln('<details open><summary>시나리오</summary>');
  for (final suite in catalog.suites) {
    out
      ..writeln(
        '<div class="toc-suite" data-suite="${escapeGalleryHtml(suite)}">',
      )
      ..writeln('<h2>${escapeGalleryHtml(suite)}</h2><ul>');
    for (final scenario in catalog.scenarios.where((s) => s.suite == suite)) {
      final failed = scenario.failedCount;
      out.writeln(
        '<li data-toc="${escapeGalleryHtml(scenario.anchor)}">'
        '<a href="#${escapeGalleryHtml(scenario.anchor)}">'
        '${escapeGalleryHtml(scenario.name)}</a>'
        '<span class="count">${scenario.images.length}</span>'
        '${failed > 0 ? '<span class="count fail">실패 $failed</span>' : ''}'
        '</li>',
      );
    }
    out.writeln('</ul></div>');
  }
  out
    ..writeln('</details>')
    ..writeln('</nav>')
    ..writeln('<main id="gallery">');

  for (final suite in catalog.suites) {
    out
      ..writeln(
        '<section class="suite" data-suite="${escapeGalleryHtml(suite)}">',
      )
      ..writeln('<h2 class="suite-title">${escapeGalleryHtml(suite)}</h2>');
    for (final scenario in catalog.scenarios.where((s) => s.suite == suite)) {
      _writeScenario(out, scenario, imageUrl, lightbox);
    }
    out.writeln('</section>');
  }
  out
    ..writeln('<p class="empty" id="empty" hidden>조건에 맞는 이미지가 없습니다.</p>')
    ..writeln('</main>')
    ..writeln('</div>')
    ..writeln(_dialog)
    ..writeln(
      '<script type="application/json" id="gallery-data">'
      '${_jsonForScript(lightbox)}</script>',
    )
    ..writeln('<script>$_script</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return out.toString();
}

void _writeHeader(
  StringBuffer out,
  GalleryCatalog catalog,
  GalleryPageOptions options,
) {
  final generated = options.generatedAt.toIso8601String().substring(0, 16);
  out
    ..writeln('<header class="top">')
    ..writeln('<div class="title">')
    ..writeln('<h1>${escapeGalleryHtml(options.title)}</h1>')
    ..writeln('<ul class="stats">')
    ..writeln('<li><b>${catalog.scenarios.length}</b> 시나리오</li>')
    ..writeln('<li><b>${catalog.imageCount}</b> 이미지</li>')
    ..writeln(
      '<li class="${catalog.failedCount > 0 ? 'bad' : 'good'}">'
      '<b>${catalog.failedCount}</b> 실패</li>',
    )
    ..writeln('</ul>')
    ..writeln('<dl class="meta">');
  for (final (label, value) in options.metadata) {
    out.writeln(
      '<div><dt>${escapeGalleryHtml(label)}</dt>'
      '<dd>${escapeGalleryHtml(value)}</dd></div>',
    );
  }
  out
    ..writeln('<div><dt>생성</dt><dd>$generated UTC</dd></div>')
    ..writeln('</dl>')
    ..writeln('</div>')
    ..writeln('<div class="actions">');
  for (final (label, url) in options.links) {
    out.writeln(
      '<a class="link" href="${escapeGalleryHtml(url)}" rel="noopener">'
      '${escapeGalleryHtml(label)}</a>',
    );
  }
  out
    ..writeln(
      '<button type="button" id="theme-toggle" class="link" '
      'aria-label="화면 테마 전환">테마: 자동</button>',
    )
    ..writeln('</div>')
    ..writeln('</header>');
}

void _writeToolbar(StringBuffer out, GalleryCatalog catalog) {
  final images = [for (final scenario in catalog.scenarios) ...scenario.images];
  List<String> distinct(String? Function(GalleryImage image) pick) {
    final seen = <String>{};
    return [
      for (final image in images)
        if (pick(image) case final value? when seen.add(value)) value,
    ];
  }

  void select(String id, String label, List<String> values) {
    out.writeln(
      '<label class="field"><span>$label</span>'
      '<select id="$id"><option value="">전체</option>',
    );
    for (final value in values) {
      final escaped = escapeGalleryHtml(value);
      out.writeln('<option value="$escaped">$escaped</option>');
    }
    out.writeln('</select></label>');
  }

  out
    ..writeln('<div class="toolbar" role="search">')
    ..writeln(
      '<label class="field grow"><span>검색</span>'
      '<input id="q" type="search" autocomplete="off" '
      'placeholder="시나리오, 설명, 파일 이름"></label>',
    );
  select('f-suite', '스위트', catalog.suites);
  select('f-device', '기기', distinct((image) => image.device));
  select('f-theme', '테마', distinct((image) => image.theme));
  select('f-locale', '언어', distinct((image) => image.locale));
  out
    ..writeln(
      '<label class="check"><input id="f-failed" type="checkbox"> 실패만</label>',
    )
    ..writeln('<output id="visible" aria-live="polite"></output>')
    ..writeln('</div>');
}

void _writeScenario(
  StringBuffer out,
  GalleryScenario scenario,
  GalleryImageUrl imageUrl,
  List<Map<String, Object?>> lightbox,
) {
  final search = [
    scenario.suite,
    scenario.name,
    scenario.description ?? '',
    for (final image in scenario.images) image.name,
  ].join(' ').toLowerCase();
  out
    ..writeln(
      '<section class="scenario" id="${escapeGalleryHtml(scenario.anchor)}" '
      'data-suite="${escapeGalleryHtml(scenario.suite)}" '
      'data-search="${escapeGalleryHtml(search)}">',
    )
    ..writeln('<div class="scenario-head">')
    ..writeln('<h3>${escapeGalleryHtml(scenario.name)}</h3>');
  if (scenario.description case final description?) {
    out.writeln('<p>${escapeGalleryHtml(description)}</p>');
  }
  out
    ..writeln('<ul class="badges">')
    ..writeln(
      '<li>${scenario.fromManifest ? '매트릭스' : '이미지'} '
      '${scenario.images.length}</li>',
    );
  if (scenario.failedCount > 0) {
    out.writeln('<li class="fail">실패 ${scenario.failedCount}</li>');
  }
  out
    ..writeln('</ul>')
    ..writeln('</div>');
  if (scenario.fromManifest) {
    _writeMatrix(out, scenario, imageUrl, lightbox);
  } else {
    _writeCards(out, scenario, imageUrl, lightbox);
  }
  out.writeln('</section>');
}

void _writeMatrix(
  StringBuffer out,
  GalleryScenario scenario,
  GalleryImageUrl imageUrl,
  List<Map<String, Object?>> lightbox,
) {
  final devices = <String>[];
  final columns = <String>[];
  final cells = <String, GalleryImage>{};
  for (final image in scenario.images) {
    final device = image.device ?? image.name;
    if (!devices.contains(device)) {
      devices.add(device);
    }
    if (!columns.contains(image.columnKey)) {
      columns.add(image.columnKey);
    }
    cells['$device\u0000${image.columnKey}'] = image;
  }
  GalleryImage? sample(String column) {
    for (final image in scenario.images) {
      if (image.columnKey == column) {
        return image;
      }
    }
    return null;
  }

  out
    ..writeln('<div class="matrix-wrap"><table class="matrix">')
    ..writeln('<thead><tr><th scope="col">기기</th>');
  for (final column in columns) {
    final first = sample(column);
    out.writeln(
      '<th scope="col" data-theme="${escapeGalleryHtml(first?.theme ?? '')}" '
      'data-locale="${escapeGalleryHtml(first?.locale ?? '')}">'
      '${escapeGalleryHtml(column)}</th>',
    );
  }
  out.writeln('</tr></thead><tbody>');
  for (final device in devices) {
    out.writeln(
      '<tr data-device="${escapeGalleryHtml(device)}">'
      '<th scope="row">${escapeGalleryHtml(device)}</th>',
    );
    for (final column in columns) {
      final image = cells['$device\u0000$column'];
      if (image == null) {
        out.writeln('<td class="none" aria-label="해당 조합 없음"></td>');
        continue;
      }
      out
        ..write('<td ${_dataAttributes(image)}>')
        ..write(_shot(scenario, image, imageUrl, lightbox))
        ..writeln('</td>');
    }
    out.writeln('</tr>');
  }
  out.writeln('</tbody></table></div>');
}

void _writeCards(
  StringBuffer out,
  GalleryScenario scenario,
  GalleryImageUrl imageUrl,
  List<Map<String, Object?>> lightbox,
) {
  out.writeln('<div class="cards">');
  for (final image in scenario.images) {
    out
      ..write('<figure class="card" ${_dataAttributes(image)}>')
      ..write(_shot(scenario, image, imageUrl, lightbox))
      ..write('<figcaption>${escapeGalleryHtml(image.name)}</figcaption>')
      ..writeln('</figure>');
  }
  out.writeln('</div>');
}

String _dataAttributes(GalleryImage image) =>
    'data-device="${escapeGalleryHtml(image.device ?? '')}" '
    'data-theme="${escapeGalleryHtml(image.theme ?? '')}" '
    'data-locale="${escapeGalleryHtml(image.locale ?? '')}" '
    'data-status="${image.status.name}"';

String _shot(
  GalleryScenario scenario,
  GalleryImage image,
  GalleryImageUrl imageUrl,
  List<Map<String, Object?>> lightbox,
) {
  final failed = image.status == GalleryStatus.failed;
  final overflow = image.overflowCount > 0
      ? '<span class="flag">오버플로 ${image.overflowCount}</span>'
      : '';
  final flag = failed ? '<span class="flag">실패</span>$overflow' : '';
  if (image.path.isEmpty) {
    return '<div class="shot missing">$flag<span>캡처 없음</span>'
        '${_errors(image)}</div>';
  }
  final index = lightbox.length;
  final src = imageUrl(image);
  lightbox.add({
    'src': src,
    'title': '${scenario.suite} / ${scenario.name}',
    'label': image.label,
    'status': image.status.name,
    'errors': image.errors,
  });
  final size = image.width != null && image.height != null
      ? ' width="${image.width}" height="${image.height}"'
      : '';
  final alt = escapeGalleryHtml('${scenario.name} — ${image.label}');
  return '<button type="button" class="shot${failed ? ' failed' : ''}" '
      'data-index="$index" aria-label="$alt 크게 보기">$flag'
      '<img src="${escapeGalleryHtml(src)}" alt="$alt" loading="lazy" '
      'decoding="async"$size></button>${_errors(image)}';
}

String _errors(GalleryImage image) {
  if (image.errors.isEmpty) {
    return '';
  }
  final items = image.errors
      .map((error) => '<li>${escapeGalleryHtml(error)}</li>')
      .join();
  return '<details class="errors"><summary>오류 ${image.errors.length}'
      '</summary><ul>$items</ul></details>';
}

/// JSON that is safe inside a `<script>` element.
String _jsonForScript(Object? value) {
  // JSON escapes for `<`, `>` and `&`, so the data can never close the
  // script element or open a comment. Built from a backslash constant so the
  // escape sequences stay literal text in this source file.
  const slash = r'\';
  return jsonEncode(value)
      .replaceAll('<', '${slash}u003c')
      .replaceAll('>', '${slash}u003e')
      .replaceAll('&', '${slash}u0026');
}

const String _dialog = '''
<dialog id="viewer" aria-labelledby="viewer-title">
  <div class="viewer-bar">
    <div><p id="viewer-title"></p><p id="viewer-label"></p></div>
    <div class="viewer-actions">
      <button type="button" id="viewer-prev" aria-label="이전 이미지">이전</button>
      <button type="button" id="viewer-next" aria-label="다음 이미지">다음</button>
      <button type="button" id="viewer-close" aria-label="닫기">닫기</button>
    </div>
  </div>
  <ul id="viewer-errors"></ul>
  <div class="viewer-body"><img id="viewer-image" alt=""></div>
</dialog>''';

String _css(String brand) =>
    '''
:root {
  --brand: $brand;
  --bg: #f4f6f9; --surface: #ffffff; --ink: #121a26; --muted: #5b6878;
  --line: #d8dfe8; --soft: #e9eef5; --fail: #c62828; --fail-soft: #fdecec;
  --ok: #1d7a4b; --shadow: 0 1px 2px rgba(18, 26, 38, .08);
  color-scheme: light;
  font-family: Pretendard, "Apple SD Gothic Neo", "Noto Sans KR", system-ui, sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0d1219; --surface: #151c26; --ink: #e4eaf2; --muted: #98a6b8;
    --line: #253244; --soft: #1b2533; --fail: #ff6b6b; --fail-soft: #3a1c1f;
    --ok: #5bc98e; --shadow: none; color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --bg: #0d1219; --surface: #151c26; --ink: #e4eaf2; --muted: #98a6b8;
  --line: #253244; --soft: #1b2533; --fail: #ff6b6b; --fail-soft: #3a1c1f;
  --ok: #5bc98e; --shadow: none; color-scheme: dark;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--ink); font-size: 14px; line-height: 1.55; }
a { color: var(--brand); }
button, select, input { font: inherit; color: inherit; }
:focus-visible { outline: 2px solid var(--brand); outline-offset: 2px; }
.top { display: flex; flex-wrap: wrap; gap: 16px 24px; justify-content: space-between; align-items: flex-start;
  padding: 24px 20px 16px; border-bottom: 1px solid var(--line); background: var(--surface); }
.title { display: grid; gap: 8px; min-width: 0; }
h1 { margin: 0; font-size: 24px; line-height: 1.25; letter-spacing: -.01em; text-wrap: balance; }
.stats { display: flex; flex-wrap: wrap; gap: 6px 16px; margin: 0; padding: 0; list-style: none; color: var(--muted); }
.stats b { color: var(--ink); font-variant-numeric: tabular-nums; }
.stats .bad b { color: var(--fail); }
.stats .good b { color: var(--ok); }
.meta { display: flex; flex-wrap: wrap; gap: 4px 16px; margin: 0; font-size: 12px; color: var(--muted); }
.meta div { display: flex; gap: 6px; }
.meta dt { font-weight: 600; }
.meta dd { margin: 0; font-family: ui-monospace, "SF Mono", Menlo, monospace; }
.actions { display: flex; flex-wrap: wrap; gap: 8px; }
.link { display: inline-flex; align-items: center; min-height: 36px; padding: 0 12px; border: 1px solid var(--line);
  border-radius: 8px; background: var(--surface); color: var(--ink); text-decoration: none; cursor: pointer; }
.toolbar { position: sticky; top: 0; z-index: 5; display: flex; flex-wrap: wrap; gap: 10px 14px; align-items: flex-end;
  padding: 12px 20px; background: color-mix(in srgb, var(--bg) 92%, transparent); backdrop-filter: blur(8px);
  border-bottom: 1px solid var(--line); }
.field { display: grid; gap: 2px; font-size: 12px; color: var(--muted); }
.field.grow { flex: 1 1 220px; }
.field input, .field select { min-height: 36px; padding: 0 10px; border: 1px solid var(--line); border-radius: 8px;
  background: var(--surface); }
.check { display: inline-flex; gap: 6px; align-items: center; min-height: 36px; }
#visible { margin-left: auto; color: var(--muted); font-variant-numeric: tabular-nums; }
.layout { display: grid; grid-template-columns: 240px minmax(0, 1fr); gap: 24px; padding: 20px; }
.toc { position: sticky; top: 72px; align-self: start; max-height: calc(100vh - 96px); overflow: auto; }
.toc summary { font-weight: 600; cursor: pointer; margin-bottom: 8px; }
.toc h2 { margin: 12px 0 4px; font-size: 12px; letter-spacing: .06em; text-transform: uppercase; color: var(--muted); }
.toc ul { margin: 0; padding: 0; list-style: none; display: grid; gap: 2px; }
.toc li { display: flex; gap: 6px; align-items: baseline; }
.toc a { color: var(--ink); text-decoration: none; overflow-wrap: anywhere; }
.toc a:hover { color: var(--brand); }
.count { font-size: 11px; color: var(--muted); font-variant-numeric: tabular-nums; }
.count.fail { color: var(--fail); }
main { display: grid; gap: 36px; min-width: 0; }
.suite { display: grid; gap: 20px; }
.suite-title { margin: 0; font-size: 20px; padding-bottom: 6px; border-bottom: 2px solid var(--brand); }
.scenario { display: grid; gap: 12px; scroll-margin-top: 80px; }
.scenario-head { display: flex; flex-wrap: wrap; gap: 4px 12px; align-items: baseline; }
.scenario-head h3 { margin: 0; font-size: 16px; }
.scenario-head p { margin: 0; color: var(--muted); flex-basis: 100%; }
.badges { display: flex; gap: 6px; margin: 0; padding: 0; list-style: none; font-size: 12px; }
.badges li { padding: 1px 8px; border-radius: 999px; background: var(--soft); color: var(--muted); }
.badges .fail { background: var(--fail-soft); color: var(--fail); }
.matrix-wrap { overflow-x: auto; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); }
.matrix { border-collapse: collapse; }
.matrix th, .matrix td { padding: 8px; border-bottom: 1px solid var(--line); vertical-align: top; }
.matrix thead th { position: sticky; top: 0; background: var(--surface); font-size: 12px; font-weight: 600; color: var(--muted);
  text-align: left; white-space: nowrap; }
.matrix tbody th { font-size: 12px; text-align: left; white-space: nowrap; color: var(--muted); font-weight: 600; }
.matrix tr:last-child th, .matrix tr:last-child td { border-bottom: 0; }
.matrix td.none { background: repeating-linear-gradient(45deg, transparent 0 6px, var(--soft) 6px 12px); min-width: 80px; }
.shot { position: relative; display: block; padding: 0; border: 1px solid var(--line); border-radius: 8px; overflow: hidden;
  background: var(--soft); cursor: zoom-in; box-shadow: var(--shadow); }
.shot img { display: block; height: 240px; width: auto; max-width: none; }
.shot.failed { border-color: var(--fail); outline: 2px solid var(--fail); outline-offset: -1px; }
.shot.missing { display: grid; place-items: center; gap: 4px; width: 120px; height: 240px; color: var(--fail);
  background: var(--fail-soft); cursor: default; }
.flag { position: absolute; top: 6px; left: 6px; z-index: 1; padding: 1px 6px; border-radius: 4px; background: var(--fail);
  color: #fff; font-size: 11px; font-weight: 600; }
.flag + .flag { top: 28px; }
.shot.missing .flag { position: static; }
.errors { max-width: 320px; margin-top: 6px; font-size: 12px; color: var(--fail); }
.errors ul { margin: 4px 0 0; padding-left: 16px; }
.cards { display: flex; flex-wrap: wrap; gap: 16px; }
.card { margin: 0; display: grid; gap: 6px; }
.card figcaption { font-size: 12px; color: var(--muted); overflow-wrap: anywhere; max-width: 320px; }
.card .shot img { height: 220px; }
.muted .shot { opacity: .2; }
.empty { color: var(--muted); }
dialog { width: min(1200px, 96vw); max-height: 94vh; padding: 0; border: 1px solid var(--line); border-radius: 12px;
  background: var(--surface); color: var(--ink); }
dialog::backdrop { background: rgba(8, 12, 18, .72); }
.viewer-bar { display: flex; flex-wrap: wrap; gap: 8px 16px; justify-content: space-between; align-items: center; padding: 12px 16px;
  border-bottom: 1px solid var(--line); }
.viewer-bar p { margin: 0; }
#viewer-title { font-weight: 600; }
#viewer-label { color: var(--muted); font-size: 12px; }
.viewer-actions { display: flex; gap: 8px; }
.viewer-actions button { min-height: 36px; padding: 0 12px; border: 1px solid var(--line); border-radius: 8px;
  background: var(--surface); cursor: pointer; }
#viewer-errors { margin: 0; padding: 8px 32px 0; color: var(--fail); font-size: 12px; }
#viewer-errors:empty { display: none; }
.viewer-body { overflow: auto; max-height: calc(94vh - 72px); padding: 16px; display: grid; place-items: center; }
.viewer-body img { max-width: 100%; height: auto; }
@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr); padding: 16px; }
  .toc { position: static; max-height: none; }
  .toc details:not([open]) { margin-bottom: 0; }
  .top, .toolbar { padding-inline: 16px; }
  .shot img { height: 180px; }
}
@media (prefers-reduced-motion: reduce) { * { scroll-behavior: auto !important; } }
''';

const String _script = r'''
(() => {
  const data = JSON.parse(document.getElementById('gallery-data').textContent);
  const $ = (id) => document.getElementById(id);
  const root = document.documentElement;
  const toggle = $('theme-toggle');
  const labels = { auto: '테마: 자동', light: '테마: 밝게', dark: '테마: 어둡게' };
  let mode = 'auto';
  try { mode = localStorage.getItem('co-golden-theme') || 'auto'; } catch (_) {}
  const applyMode = () => {
    if (mode === 'auto') root.removeAttribute('data-theme'); else root.setAttribute('data-theme', mode);
    toggle.textContent = labels[mode] || labels.auto;
  };
  applyMode();
  toggle.addEventListener('click', () => {
    mode = mode === 'auto' ? 'light' : mode === 'light' ? 'dark' : 'auto';
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
