import 'language_safety.dart';

/// Spanish: not declared yet. The Story that localizes the language fills this
/// in with the conventions of Spanish (see `LanguageSafety`):
///
/// - `fictionalMarker`: how Spanish marks a fictional drug, product, or event
///   name, as the drug and medicine roles write it;
/// - `generalInfoPrefix`: how the general-information consultation texts begin;
/// - `deniedPromises`: the phrases that promise a result or give advice, which
///   a consultation example must not make;
/// - `deniedBrands`: the spellings of real brands, works, companies, and
///   medicines that differ from the Latin ones that English lists, which
///   every language is scanned for already; it may stay empty.
///
/// While the bundle of the language is empty this stays empty. Once the
/// bundle is filled, an empty declaration fails the safety scan.
const LanguageSafety esSafety = LanguageSafety();
