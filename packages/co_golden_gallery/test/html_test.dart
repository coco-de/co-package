import 'dart:io';

import 'package:co_golden_gallery/co_golden_gallery.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  late Directory root;
  late GalleryCatalog catalog;

  setUp(() {
    root = sampleSource();
    catalog = scanGallerySources([root]).catalog;
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<String> render({
    String title = 'Gallery',
    bool noindex = false,
    List<(String, String)> metadata = const [],
    String? plainTitle,
  }) => renderGalleryHtml(
    catalog,
    GalleryPageOptions(
      title: title,
      noindex: noindex,
      metadata: metadata,
      plainTitle: plainTitle ?? '축 없는 이미지',
      generatedAt: DateTime.utc(2026, 9, 26, 3, 4),
    ),
    imageUrl: (image) => 'https://cdn.example/runs/abc/${image.path}',
  );

  test('escapes text from manifests and options', () async {
    final html = await render(title: '<b>Title</b>');

    expect(html, contains('&lt;b&gt;Title&lt;/b&gt;'));
    expect(html, isNot(contains('<b>Title</b>')));
    expect(html, contains('Login &lt;form&gt; &amp; social buttons'));
  });

  test('keeps embedded data from closing the script element', () async {
    final html = await render();
    final data = RegExp(
      r'<script type="application/json" id="gallery-data">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)!.group(1)!;

    expect(data, isNot(contains('</script')));
    const slash = r'\';
    expect(data, contains('${slash}u003c/script${slash}u003e'));
  });

  test('adds the robots meta only when asked', () async {
    expect(await render(), isNot(contains('name="robots"')));
    expect(
      await render(noindex: true),
      contains('content="noindex, nofollow"'),
    );
  });

  test('renders a matrix table for manifest scenarios', () async {
    final html = await render();

    expect(html, contains('<table class="matrix">'));
    expect(html, contains('<tr data-device="phone">'));
    expect(html, contains('data-theme="dark" data-locale="ko">dark · ko</th>'));
    expect(html, contains('data-status="failed"'));
    expect(html, contains('오버플로 1'));
    expect(
      html,
      contains('src="https://cdn.example/runs/abc/images/auth/login/'),
    );
  });

  test('renders cards for plain images', () async {
    final html = await render();

    expect(html, contains('<div class="cards">'));
    expect(html, contains('<figcaption>login_page</figcaption>'));
    expect(html, contains('width="20" height="10"'));
  });

  test('shows counts and metadata in the header', () async {
    final html = await render(metadata: const [('commit', 'abc1234')]);

    expect(html, contains('<b>2</b> 시나리오'));
    expect(html, contains('<b>3</b> 이미지'));
    expect(html, contains('<b>1</b> 실패'));
    expect(html, contains('<dt>commit</dt><dd>abc1234</dd>'));
    expect(html, contains('2026-09-26T03:04 UTC'));
  });

  test('renders CoUI components with the cocode-home dark palette', () async {
    final html = await render();

    expect(html, contains('<html lang="ko" data-theme="dark">'));
    expect(html, contains('class="coui-root '));
    expect(html, contains('scenario-card'));
    expect(html, contains('var(--coui-radius-6)'));
    expect(html, contains('--bg: #0b0d0e'));
    expect(html, contains('--brand: #5BE0C8'));
    expect(html, contains('id="theme-toggle"'));
  });

  test('lets the hidden attribute win over display rules', () async {
    // The filter hides scenarios and cards with `hidden`; `.scenario` and
    // `.card` set `display: grid`, which beats the browser's own rule.
    expect(await render(), contains('[hidden] { display: none !important; }'));
  });

  test('links the cocode favicon files relative to the page', () async {
    final html = await render();
    final head = html.substring(0, html.indexOf('</head>'));

    expect(
      head,
      contains(
        '<link rel="icon" type="image/svg+xml" href="favicon.svg">\n'
        '<link rel="icon" sizes="32x32" href="favicon.ico">\n'
        '<link rel="apple-touch-icon" href="apple-touch-icon.png">\n',
      ),
    );
    expect(head, isNot(contains('data:image')));
  });

  test('collects images without axes after the matrix suites', () async {
    final html = await render();
    final matrix = html.indexOf('<section class="suite" data-suite="auth">');
    final plain = html.indexOf('<section class="suite plain">');

    expect(matrix, isNonNegative);
    expect(plain, greaterThan(matrix));
    expect(html, contains('<h2 class="suite-title">축 없는 이미지</h2>'));
    expect(html, contains('<h3>regression / auth</h3>'));
    expect(html, contains('<div class="toc-suite plain">'));
    expect(
      html,
      isNot(contains('<section class="suite" data-suite="regression">')),
    );
  });

  test('takes the heading of the plain section from the options', () async {
    expect(
      await render(plainTitle: '회귀 골든'),
      contains('<h2 class="suite-title">회귀 골든</h2>'),
    );
  });

  group('matrix order', () {
    // The order pairwise sampling leaves: the first device has only
    // light · ko and dark · en.
    final pairwise = [
      result(
        stem: 'phone-compact__light__ko',
        device: 'phone-compact',
        theme: 'light',
        locale: 'ko',
      ),
      result(
        stem: 'phone-compact__dark__en',
        device: 'phone-compact',
        theme: 'dark',
        locale: 'en',
      ),
      result(
        stem: 'phone__light__en',
        device: 'phone',
        theme: 'light',
        locale: 'en',
      ),
      result(
        stem: 'phone__dark__ko',
        device: 'phone',
        theme: 'dark',
        locale: 'ko',
      ),
    ];

    String section(String html, String anchor) {
      final idAt = html.indexOf('id="$anchor"');
      final start = html.lastIndexOf('<section', idAt);
      expect(start, isNonNegative, reason: anchor);
      return html.substring(start, html.indexOf('</section>', start));
    }

    List<String> columns(String html, String anchor) => [
      for (final match in RegExp(
        r'data-locale="[^"]*">([^<]+)</th>',
      ).allMatches(section(html, anchor)))
        match.group(1)!,
    ];

    List<String> rows(String html, String anchor) => [
      for (final match in RegExp(
        r'<tr data-device="([^"]+)">',
      ).allMatches(section(html, anchor)))
        match.group(1)!,
    ];

    test('follows the declared theme × locale order', () async {
      writeManifest(
        root,
        suite: 'store',
        scenario: 'header',
        results: pairwise,
        axes: {
          'devices': ['phone', 'phone-compact'],
          'themes': ['light', 'dark'],
          'locales': ['en', 'ko'],
          'textScales': [1],
        },
      );
      catalog = scanGallerySources([root]).catalog;
      final html = await render();

      expect(columns(html, 'store--header'), [
        'light · en',
        'light · ko',
        'dark · en',
        'dark · ko',
      ]);
      expect(rows(html, 'store--header'), ['phone', 'phone-compact']);
    });

    test(
      'groups by theme, then locale, when the manifest has no axes',
      () async {
        writeManifest(
          root,
          suite: 'store',
          scenario: 'footer',
          results: pairwise,
        );
        catalog = scanGallerySources([root]).catalog;
        final html = await render();

        // First appearance alone gave light · ko | dark · en | light · en |
        // dark · ko.
        expect(columns(html, 'store--footer'), [
          'light · ko',
          'light · en',
          'dark · ko',
          'dark · en',
        ]);
        expect(rows(html, 'store--footer'), ['phone-compact', 'phone']);
      },
    );
  });

  test('rejects a brand color that is not #RRGGBB', () async {
    expect(
      () => GalleryPageOptions(brandColor: 'red;} body{display:none'),
      throwsArgumentError,
    );
  });
}
