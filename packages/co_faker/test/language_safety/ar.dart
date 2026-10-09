import 'language_safety.dart';

/// Arabic (Saudi Arabia): a fictional name carries `(افتراضي)`, a sample label
/// carries `(مثال)`, and consultation text starts with `معلومات عامة`.
///
/// The marker is one word after every name, whatever the gender of the noun
/// before it, so that the scan can test for one string. The promises are the
/// phrases of a formal register that guarantee a result or tell a person what
/// to do, which an example of a consultation must not write. The brands are
/// the Arabic spellings of medicines, companies, banks, insurers, and services
/// that the Latin ones of the English list do not cover; each of them is long
/// and particular enough not to be a common word, because the entries of
/// every language are scanned in the texts of every language.
const LanguageSafety arSafety = LanguageSafety(
  fictionalMarker: '(افتراضي)',
  generalInfoPrefix: 'معلومات عامة',
  deniedPromises: <String>[
    '100%',
    'مضمون',
    'مضمونة',
    'نضمن',
    'أضمن',
    'يجب عليك',
    'يجب عليكم',
    'ننصحك',
    'ننصحكم',
    'نوصيك',
    'بلا شك',
    'بالتأكيد',
    'نتيجة مؤكدة',
    'ربح مؤكد',
    'ستربح القضية',
  ],
  deniedBrands: <String>[
    // Medicines.
    'بنادول',
    'فيفادول',
    'أدول',
    'بروفين',
    'فولتارين',
    // Companies, banks, insurers, retailers, and services.
    'أرامكو',
    'سابك',
    'المراعي',
    'موبايلي',
    'الاتصالات السعودية',
    'زين السعودية',
    'مصرف الراجحي',
    'البنك الأهلي',
    'بنك الرياض',
    'مكتبة جرير',
    'إكسترا',
    'بنده',
    'العثيم',
    'هنقرستيشن',
    'التعاونية للتأمين',
    'بوبا العربية',
    'طيران ناس',
    'الخطوط السعودية',
    'صيدلية النهدي',
    'صيدليات الدواء',
  ],
);
