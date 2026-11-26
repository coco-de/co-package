# co_site_metadata

One immutable route snapshot supplies canonical URLs, sitemap.xml, robots.txt,
llms.txt and an optional llms-full.txt. Pure Dart; no Flutter, Jaspr, database,
network, filesystem or runtime dependencies. Use alongside CoUI and Serverpod.

```dart
import 'package:co_site_metadata/co_site_metadata.dart';

final site = SiteMetadata(
  baseUrl: Uri.parse('https://example.com/docs/'),
  name: 'Example',
  description: 'Product documentation',
  routes: const [
    SiteRoute(path: '/', title: 'Docs', description: 'Start here.'),
    SiteRoute(path: '/account/', title: 'Account', description: 'Account', noindex: true),
  ],
);
final files = site.artifacts(); // Map<String, String>; no side effects
final canonical = site.canonicalUrl(site.routes.first);
```

```sh
dart pub add co_site_metadata
```

## Integration contract

- Resolve dynamic routes once, then construct the snapshot. Paths must be concrete
  local paths starting with `/`, without query strings or fragments. `/guide`
  and `/guide/` remain distinct: use the form that your host actually serves.
- A `/docs/` base prefix is retained: route `/guide/` becomes
  `https://example.com/docs/guide/`. Duplicate canonical URLs fail loudly.
- Use each route's `title`, `description`, `robots` and `canonicalUrl(route)`
  in server-rendered head tags. The library returns data/text, not HTML or Jaspr
  components. The renderer must escape text using its normal DOM APIs.
- Run the generator after `jaspr build` and after localization, or adapt the
  strings to server responses (`application/xml` for sitemap, `text/plain` for
  robots and `text/markdown` for LLM files; all UTF-8). Deploy artifacts with
  the same snapshot as the page HTML. This does not create page routes or 404s.
- **robots.txt belongs at the origin root**, even when the site is below a
  prefix. Merge with the host's existing policy; do not overwrite sibling-site
  rules. `disallow` values are origin-relative and explicitly supplied.
- `noindex` omits a page from sitemap and both LLM files. Still render the robots
  meta tag/header on that page. Noindex is neither authentication nor a robots
  Disallow rule. A blocked crawler cannot read noindex.
- `llms-full.txt` is opt-in (`includeFullText: true`) and exports only nonempty
  `publicMarkdown` explicitly supplied on indexable routes. It never fetches
  pages or exports account/CMS content automatically. llms.txt is a discovery
  proposal, not a Google ranking requirement or a permission to train models.
- `lastModified` is the real content timestamp, rendered in UTC. No build-time
  timestamp, invented rating, AI crawler allowlist or priority is inferred.
- A single sitemap is limited to 50,000 URLs, 50 MB UTF-8 and URLs shorter than
  2,048 characters. Larger collections fail; sitemap-index partitioning,
  hreflang, JSON-LD and social cards stay in the consuming site's adapter.

## Validation

From this package after workspace dependency resolution:

```bash
dart analyze --fatal-infos
dart test
dart run --enable-asserts example/main.dart
```

See [Flenx assessment](doc/flenx-assessment.md) for provenance and adoption scope.
