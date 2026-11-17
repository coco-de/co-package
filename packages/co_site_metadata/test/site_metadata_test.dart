import 'package:co_site_metadata/co_site_metadata.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

SiteMetadata site(
  Iterable<SiteRoute> routes, {
  String base = 'https://example.com/docs/',
  Iterable<String> disallow = const [],
}) => SiteMetadata(
  baseUrl: Uri.parse(base),
  name: 'Example',
  description: 'Public docs',
  routes: routes,
  disallow: disallow,
);

SiteRoute page(String path) =>
    SiteRoute(path: path, title: 'Guide', description: 'Getting started');

void main() {
  test('one snapshot supplies canonical, sitemap, robots and LLM links', () {
    final route = SiteRoute(
      path: '/guide/',
      title: 'Guide',
      description: 'Getting started',
      lastModified: DateTime.parse('2026-10-01T12:30:00+09:00'),
    );
    final metadata = site([route]);
    final xml = XmlDocument.parse(metadata.sitemapXml());
    expect(
      xml.rootElement.namespaceUri,
      'http://www.sitemaps.org/schemas/sitemap/0.9',
    );
    expect(
      xml.findAllElements('loc').single.innerText,
      'https://example.com/docs/guide/',
    );
    expect(
      xml.findAllElements('lastmod').single.innerText,
      '2026-10-01T03:30:00.000Z',
    );
    expect(
      metadata.canonicalUrl(route).toString(),
      'https://example.com/docs/guide/',
    );
    expect(metadata.llmsTxt(), contains('(<https://example.com/docs/guide/>)'));
    expect(
      metadata.robotsTxt(),
      contains('Sitemap: https://example.com/docs/sitemap.xml'),
    );
    expect(metadata.artifacts().keys, [
      'sitemap.xml',
      'robots.txt',
      'llms.txt',
    ]);
  });

  test(
    'noindex is excluded from every discovery output, even with public text',
    () {
      const private = SiteRoute(
        path: '/account/',
        title: 'Account',
        description: 'Private account',
        noindex: true,
        publicMarkdown: 'MUST NOT EXPORT',
      );
      final metadata = site([page('/'), private]);
      for (final content in metadata.artifacts(includeFullText: true).values) {
        expect(content, isNot(contains('account')));
        expect(content, isNot(contains('MUST NOT EXPORT')));
      }
      expect(private.robots, 'noindex, follow');
      expect(
        metadata.robotsTxt(),
        'User-agent: *\nDisallow:\n\nSitemap: https://example.com/docs/sitemap.xml\n',
      );
    },
  );

  test('full content is opt-in and never fabricates missing page content', () {
    final metadata = site([
      page('/missing/'),
      const SiteRoute(
        path: '/public/',
        title: 'Public',
        description: 'Summary',
        publicMarkdown: '# Approved\n\n**Body**',
      ),
    ]);
    expect(metadata.artifacts(), isNot(contains('llms-full.txt')));
    expect(metadata.llmsFullTxt(), contains('# Approved\n\n**Body**'));
    expect(metadata.llmsFullTxt(), isNot(contains('/missing/')));
  });

  test('base paths, encoded Unicode and explicit trailing slashes survive', () {
    final routes = [
      page('/'),
      page('/안내/'),
      page('/guide'),
      page('/guide/'),
      page('/v1.0/'),
    ];
    final metadata = site(routes, base: 'https://example.com/docs');
    expect(
      metadata.canonicalUrl(routes[0]).toString(),
      'https://example.com/docs/',
    );
    expect(metadata.canonicalUrl(routes[1]).pathSegments, ['docs', '안내', '']);
    expect(
      metadata.canonicalUrl(routes[2]).toString(),
      'https://example.com/docs/guide',
    );
    expect(
      metadata.canonicalUrl(routes[3]).toString(),
      'https://example.com/docs/guide/',
    );
    expect(
      site([page('/')], base: 'https://example.com').baseUrl.toString(),
      'https://example.com/',
    );
  });

  test(
    'XML parses escaped URLs; Markdown labels cannot inject links or headings',
    () {
      const route = SiteRoute(
        path: '/a&b/',
        title: 'Title]\n## Inject <tag>',
        description: '[click](https://evil.test)',
      );
      final metadata = site([route]);
      final xml = XmlDocument.parse(metadata.sitemapXml());
      expect(
        xml.findAllElements('loc').single.innerText,
        'https://example.com/docs/a&b/',
      );
      expect(metadata.sitemapXml(), contains('a&amp;b'));
      expect(metadata.llmsTxt(), contains(r'Title\] \#\# Inject \<tag\>'));
      expect(metadata.llmsTxt(), contains(r'\[click\]\(https://evil\.test\)'));
    },
  );

  test('snapshot is immutable and rejects equivalent duplicate URLs', () {
    final routes = [page('/a/')];
    final rules = ['/docs/api/'];
    final metadata = site(routes, disallow: rules);
    routes.clear();
    rules.clear();
    expect(metadata.routes, hasLength(1));
    expect(metadata.disallow, ['/docs/api/']);
    expect(() => metadata.routes.clear(), throwsUnsupportedError);
    expect(() => site([page('/a/'), page('/%61/')]), throwsArgumentError);
    expect(() => site([page('/a/'), page('/a/')]), throwsArgumentError);
  });

  for (final path in [
    '/../x',
    '/a/./b',
    '/%2e%2e/x',
    '/a/%2F/b',
    '/a/%5c/b',
    '//other.test/x',
    '/a//b',
    '/a?x=1',
    '/a#fragment',
    '/a\\b',
    '/a\nb',
    '/a%0ab',
    'relative',
    'https://other.test',
  ]) {
    test('rejects ambiguous or non-local route $path', () {
      expect(() => site([page(path)]), throwsArgumentError);
    });
  }

  for (final base in [
    'file:///tmp/docs',
    'https://user:pass@example.com/',
    'https://example.com/?a',
    'https://example.com/#a',
    'https://example.com/a//b',
  ]) {
    test('rejects invalid base $base', () {
      expect(() => site([], base: base), throwsArgumentError);
    });
  }

  test('robots accepts explicit patterns and rejects directive injection', () {
    expect(
      site([], disallow: ['/docs/api/*']).robotsTxt(),
      contains('Disallow: /docs/api/*\n'),
    );
    for (final rule in ['admin/', '/admin/\nAllow: /', '/a #comment']) {
      expect(() => site([], disallow: [rule]), throwsArgumentError);
    }
  });

  test('empty sitemap remains valid', () {
    final xml = XmlDocument.parse(site([]).sitemapXml());
    expect(xml.findAllElements('url'), isEmpty);
  });

  test('rejects oversize sitemaps instead of silently truncating pages', () {
    final metadata = site(List.generate(50001, (i) => page('/$i')));
    expect(metadata.sitemapXml, throwsStateError);
    expect(site([page('/${'x' * 2048}')]).sitemapXml, throwsStateError);
  });
}
