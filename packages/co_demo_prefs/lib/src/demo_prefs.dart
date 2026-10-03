import 'demo_embed_protocol.dart';
import 'demo_locale.dart';
import 'demo_theme.dart';

/// The language and theme a visitor picked on a cocode site — read by a demo
/// app at startup (from the URL) and during an iframe preview (from messages).
///
/// Either value may be missing. A demo app keeps its current value (saved
/// preference, device setting or default) for anything it did not receive.
final class DemoPrefs {
  /// Creates prefs from explicit values.
  const DemoPrefs({this.locale, this.theme});

  /// Reads `?lang=<BCP-47>&theme=<light|dark>` from [uri].
  ///
  /// The protocol puts the values in the query **before** `#`, so hash-routed
  /// apps read them through `Uri.base.queryParameters` unchanged. In case a
  /// hash router moved the query into the fragment (`#/climbs?lang=en`), the
  /// fragment's query is read too; values before `#` win.
  factory DemoPrefs.fromUri(Uri uri) {
    final query = {..._fragmentQuery(uri.fragment), ...uri.queryParameters};
    return DemoPrefs(
      locale: DemoLocale.parse(query[langParam]),
      theme: DemoTheme.parse(query[themeParam]),
    );
  }

  /// The URL query key for the language.
  static const langParam = 'lang';

  /// The URL query key for the theme.
  static const themeParam = 'theme';

  /// The language — one of the eleven, or `null`.
  final DemoLocale? locale;

  /// The theme, or `null`.
  final DemoTheme? theme;

  /// Whether no value was received.
  bool get isEmpty => locale == null && theme == null;

  /// Reads a `sync` message from a preview's parent, or returns `null` when
  /// [data] does not follow the protocol ([DemoEmbedProtocol]).
  ///
  /// [data] is `MessageEvent.data` converted to Dart (a `Map`). The origin is
  /// not checked here — callers filter with
  /// [DemoEmbedProtocol.isAllowedOrigin] first.
  static DemoPrefs? fromMessage(Object? data) {
    if (data is! Map) return null;
    if (data['source'] != DemoEmbedProtocol.siteSource) return null;
    if (data['type'] != DemoEmbedProtocol.syncType) return null;
    final v = data['v'];
    if (v is! num || v != DemoEmbedProtocol.version) return null;
    final locale = data['locale'];
    final theme = data['theme'];
    return DemoPrefs(
      locale: locale is String ? DemoLocale.parse(locale) : null,
      theme: theme is String ? DemoTheme.parse(theme) : null,
    );
  }

  /// The query to append to a URL. Keys without a value are left out.
  Map<String, String> toQuery() => {
    if (locale case final l?) langParam: l.tag,
    if (theme case final t?) themeParam: t.name,
  };

  /// [href] with these values in the query before `#`. Existing `lang` and
  /// `theme` keys are replaced; other query keys and the fragment are kept.
  String applyTo(String href) {
    final hash = href.indexOf('#');
    final base = hash < 0 ? href : href.substring(0, hash);
    final fragment = hash < 0 ? '' : href.substring(hash);
    final uri = Uri.parse(base);
    final query = {...uri.queryParameters, ...toQuery()};
    final next = uri
        .replace(queryParameters: query.isEmpty ? null : query)
        .toString();
    return '$next$fragment';
  }

  @override
  bool operator ==(Object other) =>
      other is DemoPrefs && other.locale == locale && other.theme == theme;

  @override
  int get hashCode => Object.hash(locale, theme);

  @override
  String toString() =>
      'DemoPrefs(locale: ${locale?.tag}, theme: ${theme?.name})';

  static Map<String, String> _fragmentQuery(String fragment) {
    final at = fragment.indexOf('?');
    if (at < 0) return const {};
    try {
      return Uri.splitQueryString(fragment.substring(at + 1));
    } on FormatException {
      return const {};
    }
  }
}
