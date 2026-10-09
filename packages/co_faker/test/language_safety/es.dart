import 'language_safety.dart';

/// Spanish (Spain): a fictional name carries `(ficticio)`, a sample label
/// carries `(ejemplo)`, and consultation text starts with
/// `Información general`.
///
/// The marker is the same masculine word after every name, whatever the gender
/// of the noun before it, so that the scan can test for one string: it reads as
/// the tag `(nombre ficticio)` and not as an adjective that agrees. The
/// promises are the phrases in the register of the language (`usted`) that
/// guarantee a result or tell a person what to do, which an example of a
/// consultation must not write. The brands are the Spanish spellings of
/// medicines, works, companies, and insurers that the Latin ones of the English
/// list do not cover (`Frenadol`, `Mercadona`, `Mapfre`); each of them is long
/// and particular enough not to be a word of another language, because the
/// entries of every language are scanned in the texts of every language.
const LanguageSafety esSafety = LanguageSafety(
  fictionalMarker: '(ficticio)',
  generalInfoPrefix: 'Información general',
  deniedPromises: <String>[
    '100 %',
    '100%',
    'garantizado',
    'garantizada',
    'garantizamos',
    'le garantizo',
    'usted debe',
    'usted debería',
    'debería usted',
    'le recomendamos',
    'recomendamos que',
    'le aconsejamos',
    'sin duda',
    'con toda seguridad',
    'seguro que',
    'resultado asegurado',
    'éxito asegurado',
    'ganará el juicio',
    'obligatoriamente',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'Frenadol',
    'Gelocatil',
    'Dalsy',
    'Espidifen',
    'Couldina',
    'Bisolvon',
    'Almax',
    'Voltadol',
    // Works, companies, insurers, and services.
    'Mercadona',
    'El Corte Inglés',
    'Inditex',
    'Telefónica',
    'Movistar',
    'Iberdrola',
    'Repsol',
    'Santander',
    'Bankinter',
    'CaixaBank',
    'Mapfre',
    'Sanitas',
    'Adeslas',
    'Mutua Madrileña',
    'Glovo',
    'Cabify',
    'Wallapop',
    'Idealista',
    'Mortadelo y Filemón',
    'La Casa de Papel',
  ],
);
