import 'language_safety.dart';

/// Korean: a fictional name carries `(가상)`, and consultation text starts
/// with `일반 정보 예시`.
const LanguageSafety koSafety = LanguageSafety(
  fictionalMarker: '(가상)',
  generalInfoPrefix: '일반 정보 예시',
  deniedPromises: <String>[
    '100%',
    '100 %',
    '승소',
    '무조건',
    '반드시',
    '확실히',
    '보장합니다',
    '절세됩니다',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    '넥스가드',
    '브라벡토',
    '하트가드',
    '레볼루션',
    '타이레놀',
    '부루펜',
    // Works, companies, and services.
    '해리 포터',
    '원피스',
    '나 혼자만 레벨업',
    '미생',
    '삼성',
    '스타벅스',
    '카카오',
    '네이버',
  ],
);
