import '../../clinic_data.dart';

/// German (`de`) clinic data for `faker.clinic`.
///
/// `null` until its language Story fills it, and `faker.clinic` then reads
/// the English data. To fill it, replace `null` with a
/// `const CoFakerClinicData` that follows `CoFakerClinicData.english`:
///
/// - translate every list and text, `texts` and `ops` included;
/// - set `currency` and `priceScale` for EUR (€, two minor units);
/// - set `clinicNameFormat` for the order of a clinic name;
/// - set `koreanValues` to `CoKoreanValues.none`, so that no Korean-only value
///   appears.
///
/// `de`, `de_DE`, and `CoFaker.forLanguage('de')` read it.
/// `../co_l10n_clinic.dart` already points here: nothing else changes.
const CoFakerClinicData? deClinic = null;
