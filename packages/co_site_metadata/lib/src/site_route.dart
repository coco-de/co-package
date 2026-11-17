/// Metadata for one concrete page, shared by routing, head tags and discovery.
final class SiteRoute {
  /// Creates a page description. Paths are relative to the site's base path.
  const SiteRoute({
    required this.path,
    required this.title,
    required this.description,
    this.noindex = false,
    this.lastModified,
    this.section = 'Pages',
    this.publicMarkdown,
  });

  /// A concrete path starting with `/`, with no query or fragment.
  ///
  /// `/guide/` and `/guide` are distinct; match the deployed router's policy.
  final String path;

  /// Plain text page title, also used for the llms.txt link label.
  final String title;

  /// Plain text description for the page head and llms.txt.
  final String description;

  /// Omits this page from every discovery document, but does not restrict access.
  final bool noindex;

  /// Actual content modification time, never the build time.
  final DateTime? lastModified;

  /// Plain text section heading in llms.txt.
  final String section;

  /// Explicitly approved public content for the optional llms-full.txt export.
  ///
  /// Not fetched or inferred from rendered HTML. Omitted when [noindex] is true.
  final String? publicMarkdown;

  /// Value for a server-rendered robots meta tag (or X-Robots-Tag header).
  String get robots => noindex ? 'noindex, follow' : 'index, follow';
}
