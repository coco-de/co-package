import 'package:co_site_metadata/co_site_metadata.dart';

void main() {
  final site = SiteMetadata(
    baseUrl: Uri.parse('https://example.com/docs/'),
    name: 'Example docs',
    description: 'Public product documentation',
    routes: const [
      SiteRoute(
        path: '/',
        title: 'Documentation',
        description: 'Start here.',
        publicMarkdown: '# Documentation\n\nPublic getting-started content.',
      ),
      SiteRoute(
        path: '/account/',
        title: 'Account',
        description: 'Your account.',
        noindex: true,
      ),
    ],
  );
  // Hand these strings to your build writer or HTTP response adapter.
  final files = site.artifacts(includeFullText: true);
  assert(files['sitemap.xml']!.contains('https://example.com/docs/'));
  assert(!files['llms-full.txt']!.contains('/account/'));
}
