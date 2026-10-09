import 'language_safety.dart';

/// English: a fictional name carries `(fictional)`, and consultation text
/// starts with `General`. The Latin spellings of the brands are the ones that
/// every language is scanned for.
const LanguageSafety enSafety = LanguageSafety(
  fictionalMarker: '(fictional)',
  generalInfoPrefix: 'General',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'guaranteed',
    'you should',
    'must file',
    'will win',
    'recommend that',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'NexGard',
    'Bravecto',
    'Heartgard',
    'Tylenol',
    'Advil',
    'Pfizer',
    // Works, companies, and services.
    'Harry Potter',
    'One Piece',
    'Solo Leveling',
    'Samsung',
    'Starbucks',
    'Netflix',
    'Marvel',
  ],
);
