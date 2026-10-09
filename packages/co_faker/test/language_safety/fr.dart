import 'language_safety.dart';

/// French: a fictional name carries `(fictif)`, a sample label carries
/// `(exemple)`, and consultation text starts with `Information générale`.
///
/// The marker is the same masculine word after every name, whatever the
/// gender of the noun before it, so that the scan can test for one string:
/// it reads as the tag `(nom fictif)` and not as an adjective that agrees.
/// The promises are the phrases in the register of the language (`vous`) that
/// guarantee a result or tell a person what to do, which an example of a
/// consultation must not write. The brands are the French spellings of
/// medicines, works, and companies that the Latin ones of the English list do
/// not cover (`Voltarène`, `Astérix`, `L’Oréal`).
const LanguageSafety frSafety = LanguageSafety(
  fictionalMarker: '(fictif)',
  generalInfoPrefix: 'Information générale',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'garanti',
    'vous devez',
    'vous devriez',
    'vous gagnerez',
    'vous allez gagner',
    'je vous recommande',
    'nous vous recommandons',
    'sans aucun doute',
    'à coup sûr',
    'résultat assuré',
    'obligatoirement',
  ],
  deniedBrands: <String>[
    // Medicines.
    'Doliprane',
    'Efferalgan',
    'Dafalgan',
    'Spasfon',
    'Smecta',
    'Voltarène',
    'Biafine',
    'Nurofen',
    // Works, companies, and services.
    'Astérix',
    'Asterix',
    'Tintin',
    'Le Petit Prince',
    'Carrefour',
    'Decathlon',
    'Danone',
    'Michelin',
    'Renault',
    'Peugeot',
    'Citroën',
    'Doctolib',
    'L’Oréal',
    "L'Oréal",
  ],
);
