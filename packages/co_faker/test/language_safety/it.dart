import 'language_safety.dart';

/// Italian: a fictional name carries `(di fantasia)`, a sample label carries
/// `(esempio)`, and consultation text starts with `Informazione generale`.
///
/// The marker is the same phrase after every name, whatever the gender and the
/// number of the noun before it: `di fantasia` does not agree with anything, so
/// that the scan can test for one string. The promises are the phrases in the
/// register of the language (`Lei`) that guarantee a result or tell a person
/// what to do, which an example of a consultation must not write. The brands
/// are the Italian spellings of medicines, works, publishers, banks, and
/// companies that the Latin ones of the English list do not cover
/// (`Tachipirina`, `Pinocchio`, `Mondadori`, `Barilla`). A short word that is
/// also a name or a common word (`Fiat`, `Coop`, `Illy`) is left out, because
/// the scan reads every language for every entry of this list and matches
/// part of a word.
const LanguageSafety itSafety = LanguageSafety(
  fictionalMarker: '(di fantasia)',
  generalInfoPrefix: 'Informazione generale',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'garantito',
    'garantita',
    'garantiamo',
    'garantisco',
    'risultato assicurato',
    'senza alcun dubbio',
    'sicuramente',
    'Le consiglio di',
    'Le consigliamo di',
    'deve presentare',
    'dovrebbe',
    'vincerà',
    'avrà successo',
    'obbligatoriamente',
  ],
  deniedBrands: <String>[
    // Medicines.
    'Tachipirina',
    'Aspirina',
    'Voltaren',
    'Buscopan',
    'Brufen',
    'Augmentin',
    'Fluimucil',
    'Enterogermina',
    'Gaviscon',
    'Zirtec',
    'Okitask',
    // Works and publishers.
    'Pinocchio',
    'Topolino',
    'Geronimo Stilton',
    'Dylan Dog',
    'Diabolik',
    'Gomorra',
    'Montalbano',
    'Mondadori',
    'Feltrinelli',
    'Rizzoli',
    'Einaudi',
    'Bompiani',
    'Sellerio',
    'Adelphi',
    // Companies, banks, and services.
    'Barilla',
    'Mulino Bianco',
    'Nutella',
    'Lavazza',
    'Esselunga',
    'Eataly',
    'Autogrill',
    'Luxottica',
    'Trenitalia',
    'Alitalia',
    'Pirelli',
    'Intesa Sanpaolo',
    'Unicredit',
    'Mediolanum',
    'Fineco',
    'Monte dei Paschi',
    'Humanitas',
    'San Raffaele',
  ],
);
