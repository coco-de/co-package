import 'language_safety.dart';

/// Brazilian Portuguese: a fictional name carries `(fictício)`, a sample label
/// carries `(exemplo)`, and consultation text starts with
/// `Informação geral`.
///
/// The marker is the same masculine word after every name, whatever the gender
/// of the noun before it, so that the scan can test for one string: it reads as
/// the tag `(nome fictício)` and not as an adjective that agrees. The promises
/// are the phrases in the register of the language (`você`) that guarantee a
/// result or tell a person what to do, which an example of a consultation must
/// not write. The brands are the Brazilian spellings of medicines, works,
/// companies, and health plans that the Latin ones of the English list do not
/// cover (`Neosaldina`, `Turma da Mônica`, `Magazine Luiza`); each of them is
/// long and particular enough not to be a word of another language, because
/// the entries of every language are scanned in the texts of every language.
const LanguageSafety ptSafety = LanguageSafety(
  fictionalMarker: '(fictício)',
  generalInfoPrefix: 'Informação geral',
  deniedPromises: <String>[
    '100%',
    '100 %',
    'garantido',
    'garantida',
    'garantimos',
    'garanto',
    'você deve',
    'você deveria',
    'você precisa',
    'você vai ganhar',
    'vai ganhar',
    'recomendo que',
    'recomendamos que',
    'sem dúvida',
    'com certeza',
    'certamente',
    'resultado certo',
    'resultado garantido',
    'sucesso garantido',
    'obrigatoriamente',
    'ganho de causa',
  ],
  deniedBrands: <String>[
    // Medicines and veterinary products.
    'Neosaldina',
    'Novalgina',
    'Dorflex',
    'Cataflam',
    'Benegrip',
    'Resfenol',
    'Merthiolate',
    'Mertiolate',
    'Torsilax',
    'Hipoglós',
    'Bepantol',
    'Nebacetin',
    // Works, companies, health plans, and services.
    'Turma da Mônica',
    'Sítio do Picapau Amarelo',
    'Magazine Luiza',
    'Casas Bahia',
    'Lojas Americanas',
    'Mercado Livre',
    'Mercado Pago',
    'Petrobras',
    'Embraer',
    'Havaianas',
    'Nubank',
    'Bradesco',
    'Itaú Unibanco',
    'Globoplay',
    'iFood',
    'PicPay',
    'Unimed',
    'Hapvida',
    'SulAmérica',
    'Doctoralia',
    'Drogasil',
    'Guaraná Antarctica',
  ],
);
