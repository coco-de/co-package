import 'co_faker_country.dart';
import 'co_faker_locality.dart';
import 'co_faker_phone_format.dart';

/// Country data that turns a `CoFakerLocale` into a national locale.
///
/// Generators read this data only when a locale carries it. The language-only
/// locales shipped before national locales existed have none, so their output
/// does not change.
class CoFakerNationalData {
  /// Creates national locale data.
  const CoFakerNationalData({
    required this.country,
    required this.localities,
    required this.phoneFormats,
    required this.addressFormat,
    this.mobileShare = 0.6,
    this.streetLineFormat = '{number} {street}',
    this.houseNumberFormats = const <String>['@##', '@#', '@'],
    this.postalLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    this.femaleLastNames = const <String>[],
    this.maleLastNames = const <String>[],
    this.romanizations = const <String, String>{},
    this.productNameFormat = '{adjective} {noun}',
    this.wordSeparator = ' ',
    this.sentenceSeparator = ' ',
    this.sentenceTerminator = '.',
  });

  /// The country this locale describes.
  final CoFakerCountry country;

  /// Cities with their region and postal code templates.
  final List<CoFakerLocality> localities;

  /// Fictional phone number formats.
  final List<CoFakerPhoneFormat> phoneFormats;

  /// Share of generated numbers that are mobile numbers when [phoneFormats]
  /// has both mobile and landline formats.
  final double mobileShare;

  /// One-line address template. Supports `{line1}`, `{city}`, `{region}`,
  /// `{regionCode}`, `{postalCode}` and `{country}`.
  final String addressFormat;

  /// Street line template with `{street}` and `{number}` placeholders.
  final String streetLineFormat;

  /// House number templates: `#` is any digit, `@` a digit from 1 to 9 and
  /// other characters are literal.
  final List<String> houseNumberFormats;

  /// Letters that may replace `?` in postal code templates.
  final String postalLetters;

  /// Family names in their female form, for languages such as Russian where
  /// the family name agrees with the person's sex. Empty when family names do
  /// not change.
  final List<String> femaleLastNames;

  /// Family names in their male form; see [femaleLastNames].
  final List<String> maleLastNames;

  /// Latin spellings of names that cannot be transliterated letter by letter,
  /// such as Chinese and Japanese names, used for usernames and emails.
  final Map<String, String> romanizations;

  /// Product name template with `{adjective}` and `{noun}` placeholders.
  final String productNameFormat;

  /// Text between generated words.
  final String wordSeparator;

  /// Text between generated sentences.
  final String sentenceSeparator;

  /// Punctuation that ends a generated sentence.
  final String sentenceTerminator;

  /// Whether family names change with the person's sex.
  bool get hasGenderedLastNames =>
      femaleLastNames.isNotEmpty && maleLastNames.isNotEmpty;

  /// Spells [value] in ASCII-friendly Latin letters.
  ///
  /// An exact entry in [romanizations] wins. Otherwise Latin letters with
  /// diacritics and Cyrillic letters are transliterated one by one (German
  /// umlauts become `ae`, `oe`, `ue`); characters without a mapping, such as
  /// Chinese characters, are kept as they are.
  String romanize(String value) {
    final known = romanizations[value];
    if (known != null) return known;
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final lower = character.toLowerCase();
      final mapped = _letters[lower];
      if (mapped == null) {
        buffer.write(character);
      } else {
        buffer.write(lower == character ? mapped : _capitalize(mapped));
      }
    }
    return buffer.toString();
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  /// Latin diacritics and Russian Cyrillic (BGN/PCGN-style, simplified).
  static const Map<String, String> _letters = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'ae', 'å': 'a', 'æ': 'ae', //
    'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
    'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
    'ö': 'oe', 'ø': 'o', 'œ': 'oe', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'ue',
    'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
  };
}
