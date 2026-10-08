import '../../clinic_data.dart';

/// Simplified Chinese (`zh`) clinic data for `faker.clinic`.
///
/// `null` until its language Story fills it, and `faker.clinic` then reads
/// the English data. To fill it, replace `null` with a
/// `const CoFakerClinicData` that follows `CoFakerClinicData.english`:
///
/// - translate every list and text, `texts` and `ops` included;
/// - set `currency` and `priceScale` for CNY (¥, two minor units);
/// - set `clinicNameFormat` for the order of a clinic name;
/// - set `koreanValues` to `CoKoreanValues.none`, so that no Korean-only value
///   appears.
///
/// `zh`, `zh_CN`, `zh-Hans`, and `CoFaker.forLanguage('zh-Hans')` read it.
/// `../co_l10n_clinic.dart` already points here: nothing else changes.
const CoFakerClinicData? zhClinic = null;
