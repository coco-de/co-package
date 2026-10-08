import '../co_l10n_bundle.dart';

/// Simplified Chinese domain text.
///
/// Empty until the language is localized: generators read English for it and
/// `CoFakerLanguage.domain` is `false`. Give `texts` the keys of the English
/// bundle, translating each list entry for entry, and the language turns its
/// domain data on; the registry never changes. See [CoL10nBundle].
///
/// `dart run co_faker:coverage --language zh --strict` says when the
/// language is finished. A text that is the same as English on purpose (a
/// unit, an acronym, a name) goes in `allowSameAsEnglish`. The clinic and
/// SaaS data of the language are filled in the same change, and
/// `docs/languages/zh.md` says what the Story of the language writes.
const CoL10nBundle zhBundle = CoL10nBundle(language: 'zh');
