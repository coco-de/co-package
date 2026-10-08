import '../../saas_data.dart';

/// Japanese (`ja`) SaaS data for `faker.saas`.
///
/// `null` until its language Story fills it, and `faker.saas` then reads
/// the English data. To fill it, replace `null` with a
/// `const CoFakerSaasData` that follows `CoFakerSaasData.english`:
///
/// - translate every list and text, `ops` included;
/// - set `currency` and `priceScale` (the VAT rate and the prepaid wallet
///   amounts) for JPY (¥, no minor units);
/// - set `businessNumberFormat` for the shape of a tenant's business number;
/// - set `koreanValues` to `CoKoreanValues.none`, so that no Korean-only value
///   appears.
///
/// `ja`, `ja_JP`, and `CoFaker.forLanguage('ja')` read it.
/// `../co_l10n_clinic.dart` already points here: nothing else changes.
const CoFakerSaasData? jaSaas = null;
