import '../co_l10n_bundle.dart';

/// German domain text.
///
/// Empty until the language is localized: generators read English for it and
/// `CoFakerLanguage.domain` is `false`. Give `texts` the keys of the English
/// bundle, translating each list entry for entry, and the language turns its
/// domain data on; no other file changes. See [CoL10nBundle].
const CoL10nBundle deBundle = CoL10nBundle(language: 'de');
