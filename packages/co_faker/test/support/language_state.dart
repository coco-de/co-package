import 'package:co_faker/co_faker.dart';

/// The languages whose domain data (the text of the domain packs, the clinic
/// data, and the SaaS data) shipped before the languages of the Epic were
/// localized: Korean and English. Their output is pinned by the snapshots of
/// 0.10.0 and 0.11.0, domain keys included.
const Set<String> shippedDomainLanguages = <String>{'ko', 'en'};

/// Whether the domain data of the language that [code] is read as has been
/// written since those snapshots: any of its text bundle, clinic data, and
/// SaaS data is registered, and the language is not Korean or English.
///
/// It is read from the registries, so a language that is filled is localized
/// with no edit here, and every code of a language changes together: `ja`,
/// `ja_JP`, and `ja-JP` all read the Japanese data, while Traditional Chinese
/// (`zh_TW`), a language that is not supported (`xx_YY`), and a language that
/// has no domain data (`es`) read English or nothing, and stay as they were.
bool domainLocalized(String code) {
  final resolved = CoFakerLanguages.resolve(code);
  if (!resolved.supported) return false;
  final language = resolved.language.code;
  if (shippedDomainLanguages.contains(language)) return false;
  final level = CoLanguageData.registered(language).level;
  return level != CoLanguageLevel.planned && level != CoLanguageLevel.base;
}
