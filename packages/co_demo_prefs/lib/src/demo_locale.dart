/// The eleven locales a demo accepts — the same set, in the same order, as the
/// cocode sites (cocode.im and demo.cocode.im).
///
/// Korean is the base locale; the other ten are English plus the languages of
/// the ten largest economies. Locales travel as BCP-47 tags ([tag]) without a
/// region subtag (`zh-Hans` carries a script subtag, not a region).
enum DemoLocale {
  /// Korean — the base locale.
  ko('ko'),

  /// English.
  en('en'),

  /// Chinese (Simplified).
  zhHans('zh-Hans'),

  /// Japanese.
  ja('ja'),

  /// German.
  de('de'),

  /// French.
  fr('fr'),

  /// Spanish.
  es('es'),

  /// Portuguese (Brazil).
  pt('pt'),

  /// Italian.
  it('it'),

  /// Russian.
  ru('ru'),

  /// Arabic — written right to left.
  ar('ar');

  const DemoLocale(this.tag);

  /// The BCP-47 tag — the `lang` value in URLs and the `locale` value in
  /// messages.
  final String tag;

  /// The language subtag (`zh`).
  String get languageCode => tag.split('-').first;

  /// The script subtag (`Hans`), or `null`.
  String? get scriptCode => this == zhHans ? 'Hans' : null;

  /// Whether the locale is written right to left.
  bool get isRtl => this == ar;

  /// Matches [raw] to one of the eleven locales, or returns `null` — a demo
  /// keeps its current locale when nothing matches.
  ///
  /// Case, `_`/`-` and region subtags are ignored (`EN_us` → [en],
  /// `pt-PT` → [pt]). Chinese accepts Simplified only: `zh`, `zh-CN`, `zh-SG`
  /// and `zh-Hans` map to [zhHans], while `zh-TW`, `zh-HK`, `zh-MO` and
  /// `zh-Hant` return `null`, so Traditional readers are never handed
  /// Simplified text (the same rule as the cocode sites' locale picker).
  static DemoLocale? parse(String? raw) {
    final value = raw?.trim().replaceAll('_', '-').toLowerCase();
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-');
    final language = parts.first;
    if (language == 'zh') {
      final rest = parts.skip(1).toSet();
      if (rest.contains('hans')) return zhHans;
      if (rest.intersection(const {'hant', 'tw', 'hk', 'mo'}).isNotEmpty) {
        return null;
      }
      return zhHans;
    }
    for (final locale in values) {
      if (locale != zhHans && locale.tag == language) return locale;
    }
    return null;
  }
}
