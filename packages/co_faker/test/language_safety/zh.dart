import 'language_safety.dart';

/// Chinese: not declared yet. The Story that localizes the language fills this
/// in with the conventions of Chinese (see `LanguageSafety`):
///
/// - `fictionalMarker`: how Chinese marks a fictional drug, product, or event
///   name, as the drug and medicine roles write it;
/// - `generalInfoPrefix`: how the general-information consultation texts begin;
/// - `deniedPromises`: the phrases that promise a result or give advice, which
///   a consultation example must not make;
/// - `deniedBrands`: the spellings of real brands, works, companies, and
///   medicines in the writing system of Chinese (`三星`).
///
/// While the bundle of the language is empty this stays empty. Once the
/// bundle is filled, an empty declaration fails the safety scan.
const LanguageSafety zhSafety = LanguageSafety();
