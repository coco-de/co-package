# Flenx assessment — 2026-11-17

Reviewed the published [flenx 0.5.1](https://pub.dev/packages/flenx/versions/0.5.1)
archive, published 2026-10-29. SHA-256:
`3661953458131ab48d5531898e8f9daf77596182d7c9bd6ff88c9c2ab02e14a4`.
The package page's cached 0.4.1 result was not used as the implementation basis.
Sources: [repository](https://github.com/pretolio/Flenx), especially
`lib/seo/`, `lib/app.dart`, `lib/site_server.dart`, `bin/bootstrap.dart`,
`lib/auth/jwt_service.dart` and `lib/pay/payment_service.dart` in that archive.

## Decision

Absorb the single route-metadata source and deployment guidance through an
independent implementation. Do not add Flenx as a dependency or fork its complete
framework. Its published dependency graph includes Flutter, Jaspr, Flutter
embedding, PDF/image, HTTP, Shelf, Markdown and YAML; a metadata library needs
none of these at runtime.

| Flenx capability | Cocode destination / decision |
| --- | --- |
| Route registry → canonical + sitemap + LLM files | `co_site_metadata`: immutable snapshot, shared URL policy, explicit noindex filtering |
| Global robots rules | Explicit consumer-supplied paths; no inherited crawler allow/block list |
| Full Markdown export | Optional, only explicitly approved public body content |
| SEO head / Open Graph / JSON-LD | Consumer adapter uses the same snapshot; preserve existing multilingual and social metadata |
| Static/SSR packaging | `cc-jaspr-web` site-discovery guidance; actual host status/redirect checks |
| UI kit / styling | Existing `coui_web` / `coui_core`; avoid a second design system |
| Blog / Markdown | Existing `jaspr_content` or project content pipeline; concrete public routes feed snapshot |
| Flutter islands | Existing Jaspr hydration/embed guidance; no new embedding dependency |
| API / admin / DB / auth / payment / PHP generation | Keep existing Serverpod and provider integrations; outside this metadata adoption |
| Analytics, pixels, cookie banner | Separate product-specific integration; no implicit third-party tracking |
| Apache .htaccess defaults | Host-specific deployment configuration; do not emit for every site |

## Acceptance boundaries

Paths preserve deployment prefixes and the router's slash policy. Duplicate
canonical URLs are errors. XML and generated Markdown labels are escaped. All
discovery outputs omit noindex routes. robots.txt is deployed at the origin root;
noindex is rendered on the actual page and not translated into Disallow.
The static build must check that listed URLs resolve to real localized HTML and
unknown URLs return 404. Metadata alone does not establish search visibility.

The implementations are newly authored, not copied from Flenx. Flenx's archive
is MIT licensed, copyright 2026 Potenza RH. If future work copies substantial
code, retain its copyright and full MIT notice within the distributed package.

References: [sitemap protocol](https://www.sitemaps.org/protocol.html),
[noindex](https://developers.google.com/search/docs/crawling-indexing/block-indexing),
[llms.txt proposal](https://llmstxt.org/). No ranking or AI citation guarantees.
