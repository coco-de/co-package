import 'dart:convert';

import 'site_route.dart';

/// An immutable snapshot of a site's pages, independent of a web framework.
///
/// Resolve dynamic content once before construction so all documents describe
/// the same snapshot. Duplicate canonical URLs fail instead of hiding a page.
final class SiteMetadata {
  /// Validates and freezes [routes], preserving their authored order.
  ///
  /// [baseUrl] may include a deployment prefix, e.g. `https://example.com/docs/`.
  /// A missing trailing slash is added. [disallow] contains origin-relative
  /// robots.txt paths, not paths relative to [baseUrl]. No crawler-specific
  /// permissions or denials are inferred.
  SiteMetadata({
    required Uri baseUrl,
    required this.name,
    required this.description,
    required Iterable<SiteRoute> routes,
    Iterable<String> disallow = const [],
  }) : baseUrl = _base(baseUrl),
       routes = List.unmodifiable(routes),
       disallow = List.unmodifiable(disallow) {
    final seen = <Uri>{};
    for (final route in this.routes) {
      final url = canonicalUrl(route);
      if (!seen.add(url)) {
        throw ArgumentError.value(route.path, 'routes', 'Duplicate page URL');
      }
    }
    for (final path in this.disallow) {
      if (!path.startsWith('/') ||
          RegExp(r'[\s#\x00-\x1f\x7f]').hasMatch(path)) {
        throw ArgumentError.value(path, 'disallow', 'Expected a robots path');
      }
    }
  }

  /// Absolute HTTP(S) URL of the site, ending with `/`.
  final Uri baseUrl;

  /// Plain text site name.
  final String name;

  /// Plain text site summary.
  final String description;

  /// All concrete routes, including pages excluded from discovery.
  final List<SiteRoute> routes;

  /// Explicit origin-relative crawler exclusions.
  final List<String> disallow;

  /// Routes eligible for both sitemap and LLM discovery.
  Iterable<SiteRoute> get indexableRoutes => routes.where((r) => !r.noindex);

  /// Canonical URL, using exactly the path policy used by discovery documents.
  Uri canonicalUrl(SiteRoute route) => _url(route.path);

  /// Generates one sitemap; fails when a sitemap index would be required.
  String sitemapXml() {
    final visible = indexableRoutes.toList();
    if (visible.length > 50000) {
      throw StateError(
        'More than 50,000 URLs; partition into multiple sitemaps.',
      );
    }
    final xml = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    for (final route in visible) {
      final url = canonicalUrl(route).toString();
      if (url.length >= 2048) {
        throw StateError(
          'Sitemap URL must contain fewer than 2,048 characters.',
        );
      }
      xml
        ..writeln('  <url>')
        ..writeln('    <loc>${_xml(url)}</loc>');
      final modified = route.lastModified;
      if (modified != null) {
        if (modified.year < 1 || modified.year > 9999) {
          throw StateError('Sitemap dates require a four-digit positive year.');
        }
        xml.writeln(
          '    <lastmod>${modified.toUtc().toIso8601String()}</lastmod>',
        );
      }
      xml.writeln('  </url>');
    }
    xml.writeln('</urlset>');
    final result = xml.toString();
    if (utf8.encode(result).length > 50 * 1024 * 1024) {
      throw StateError(
        'Sitemap exceeds 50 MB; partition into multiple sitemaps.',
      );
    }
    return result;
  }

  /// Generates robots.txt for publication at the origin root.
  ///
  /// Merge with the host's existing policy when deploying below a base path.
  /// Noindex routes are not added to Disallow: crawlers need to read their tags.
  String robotsTxt() {
    final text = StringBuffer()..writeln('User-agent: *');
    if (disallow.isEmpty) text.writeln('Disallow:');
    for (final path in disallow) {
      text.writeln('Disallow: $path');
    }
    text
      ..writeln()
      ..writeln('Sitemap: ${_url('/sitemap.xml')}');
    return text.toString();
  }

  /// Generates a Markdown discovery index; this is not a crawler permission.
  String llmsTxt() {
    final text = _intro();
    final sections = <String, List<SiteRoute>>{};
    for (final route in indexableRoutes) {
      sections.putIfAbsent(route.section, () => []).add(route);
    }
    for (final entry in sections.entries) {
      text
        ..writeln('## ${_markdown(entry.key)}')
        ..writeln();
      for (final route in entry.value) {
        text.writeln(
          '- [${_markdown(route.title)}](<${canonicalUrl(route)}>): '
          '${_markdown(route.description)}',
        );
      }
      text.writeln();
    }
    return text.toString();
  }

  /// Exports only explicitly supplied [SiteRoute.publicMarkdown] content.
  ///
  /// Callers must opt in to serving this document. No HTML fetching or private
  /// content fallback occurs. This convenience export is not an indexing promise.
  String llmsFullTxt() {
    final text = _intro();
    for (final route in indexableRoutes) {
      final body = route.publicMarkdown;
      if (body == null || body.trim().isEmpty) continue;
      text
        ..writeln('## ${_markdown(route.title)}')
        ..writeln()
        ..writeln('URL: <${canonicalUrl(route)}>')
        ..writeln()
        ..writeln(body.trim())
        ..writeln();
    }
    return text.toString();
  }

  /// Builds relative filenames and UTF-8 text for a static build or HTTP adapter.
  ///
  /// robots.txt must be served from the origin root even for prefixed sites.
  /// This library performs no filesystem writes and does not generate HTML/404s.
  Map<String, String> artifacts({bool includeFullText = false}) => {
    'sitemap.xml': sitemapXml(),
    'robots.txt': robotsTxt(),
    'llms.txt': llmsTxt(),
    if (includeFullText) 'llms-full.txt': llmsFullTxt(),
  };

  StringBuffer _intro() => StringBuffer()
    ..writeln('# ${_markdown(name)}')
    ..writeln()
    ..writeln('> ${_markdown(description)}')
    ..writeln();

  Uri _url(String path) {
    final parsed = _path(path);
    return Uri.parse('$baseUrl${parsed.toString().substring(1)}');
  }
}

Uri _base(Uri url) {
  if (!['https', 'http'].contains(url.scheme) ||
      !url.hasAuthority ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty ||
      url.hasQuery ||
      url.hasFragment) {
    throw ArgumentError.value(url, 'baseUrl', 'Expected an HTTP(S) site URL');
  }
  _path(url.path.isEmpty ? '/' : url.path);
  return url.path.endsWith('/') ? url : url.replace(path: '${url.path}/');
}

Uri _path(String path) {
  final parsed = Uri.parse(path);
  if (!path.startsWith('/') ||
      path.contains('//') ||
      path.contains('\\') ||
      RegExp(r'[\x00-\x20\x7f]').hasMatch(path) ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.hasQuery ||
      parsed.hasFragment ||
      // Check raw segments too: Uri.parse normalizes literal dot segments.
      path
          .split('/')
          .map(
            (part) => part.replaceAll(RegExp('%2e', caseSensitive: false), '.'),
          )
          .any((part) => part == '.' || part == '..') ||
      parsed.pathSegments.any(
        (part) =>
            part == '.' ||
            part == '..' ||
            part.contains('/') ||
            part.contains('\\') ||
            RegExp(r'[\x00-\x1f\x7f]').hasMatch(part),
      )) {
    throw ArgumentError.value(path, 'path', 'Expected a concrete local path');
  }
  return parsed;
}

String _xml(String value) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(value);

String _markdown(String value) => value
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceAllMapped(RegExp(r'[\\`*_{}\[\]()<>#+.!|~-]'), (m) => '\\${m[0]}');
