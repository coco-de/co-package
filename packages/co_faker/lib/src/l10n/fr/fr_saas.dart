import '../../saas_data.dart';

/// French (`fr`) SaaS data for `faker.saas`.
///
/// `null` until its language Story fills it, and `faker.saas` then reads
/// the English data. To fill it, replace `null` with a
/// `const CoFakerSaasData` that follows `CoFakerSaasData.english`:
///
/// - translate every list and text, `ops` included;
/// - set `currency` and `priceScale` (the VAT rate and the prepaid wallet
///   amounts) for EUR (€, two minor units);
/// - set `businessNumberFormat` for the shape of a tenant's business number;
/// - set `koreanValues` to `CoKoreanValues.none`, so that no Korean-only value
///   appears.
///
/// `fr`, `fr_FR`, and `CoFaker.forLanguage('fr')` read it.
/// `../co_l10n_clinic.dart` already points here: nothing else changes.
const CoFakerSaasData? frSaas = null;
