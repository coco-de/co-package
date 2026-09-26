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

  String render({
    String title = 'Gallery',
    bool noindex = false,
    List<(String, String)> metadata = const [],
  }) => renderGalleryHtml(
    catalog,
    GalleryPageOptions(
      title: title,
      noindex: noindex,
      metadata: metadata,
      generatedAt: DateTime.utc(2026, 9, 26, 3, 4),
    ),
    imageUrl: (image) => 'https://cdn.example/runs/abc/${image.path}',
  );

  test('escapes text from manifests and options', () {
    final html = render(title: '<b>Title</b>');

    expect(html, contains('&lt;b&gt;Title&lt;/b&gt;'));
    expect(html, isNot(contains('<b>Title</b>')));
    expect(html, contains('Login &lt;form&gt; &amp; social buttons'));
  });

  test('keeps embedded data from closing the script element', () {
    final html = render();
    final data = RegExp(
      r'<script type="application/json" id="gallery-data">(.*?)</script>',
      dotAll: true,
    ).firstMatch(html)!.group(1)!;

    expect(data, isNot(contains('</script')));
    const slash = r'\';
    expect(data, contains('${slash}u003c/script${slash}u003e'));
  });

  test('adds the robots meta only when asked', () {
    expect(render(), isNot(contains('name="robots"')));
    expect(render(noindex: true), contains('content="noindex, nofollow"'));
  });

  test('renders a matrix table for manifest scenarios', () {
    final html = render();

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

  test('renders cards for plain images', () {
    final html = render();

    expect(html, contains('<div class="cards">'));
    expect(html, contains('<figcaption>login_page</figcaption>'));
    expect(html, contains('width="20" height="10"'));
  });

  test('shows counts and metadata in the header', () {
    final html = render(metadata: const [('commit', 'abc1234')]);

    expect(html, contains('<b>2</b> 시나리오'));
    expect(html, contains('<b>3</b> 이미지'));
    expect(html, contains('<b>1</b> 실패'));
    expect(html, contains('<dt>commit</dt><dd>abc1234</dd>'));
    expect(html, contains('2026-09-26T03:04 UTC'));
  });

  test('rejects a brand color that is not #RRGGBB', () {
    expect(
      () => GalleryPageOptions(brandColor: 'red;} body{display:none'),
      throwsArgumentError,
    );
  });
}
