import 'language_safety.dart';

/// German: a fictional name carries `(fiktiv)`, and consultation text starts
/// with `Allgemeine` (`Allgemeine Information als Beispiel.`, `Allgemeine
/// Beispielnotiz:`). German writes in Latin letters, so the Latin spellings of
/// the brands that English lists are scanned already; the list below adds the
/// brands, works, and companies of the German market, which the texts of every
/// language must not name either.
const LanguageSafety deSafety = LanguageSafety(
  fictionalMarker: '(fiktiv)',
  generalInfoPrefix: 'Allgemeine',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'garantiert',
    'Erfolg ist sicher',
    'ohne Risiko',
    'Sie werden gewinnen',
    'gewinnen Sie',
    'Sie sollten',
    'Sie müssen',
    'ich empfehle',
    'wir empfehlen',
    'unbedingt',
    'auf jeden Fall',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'Aspirin',
    'Voltaren',
    'Nurofen',
    'Dolormin',
    'Bepanthen',
    'Ratiopharm',
    'Hexal',
    'Frontline',
    'Advantix',
    'Seresto',
    'Drontal',
    'Milbemax',
    // Works, companies, and services.
    'Der Herr der Ringe',
    'Die unendliche Geschichte',
    'Biene Maja',
    'Sendung mit der Maus',
    'Siemens',
    'Volkswagen',
    'Bosch',
    'Lufthansa',
    'Zalando',
    'Lidl',
    'Edeka',
    'Rossmann',
    'Deutsche Bank',
    'Commerzbank',
    'Sparkasse',
    'Volksbank',
    'Postbank',
  ],
);
