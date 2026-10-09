/// What a language declares so that the safety scan can read its text.
///
/// The safety scan (`test/authored_data_safety_test.dart`) looks at what the
/// domain packs write in every language that has domain text: that a
/// fictional drug, product, or work is marked as fictional, that no real brand
/// or work appears, and that consultation text promises no result. Those are
/// conventions of a language, in its own writing system, so each language
/// declares its own in `test/language_safety/<language>.dart`, and the scan
/// reads every language that has domain text with no edit.
///
/// A language that has domain text and leaves the declaration empty fails the
/// scan: it is never skipped without a word.
class LanguageSafety {
  /// Creates a declaration. An empty one declares nothing.
  const LanguageSafety({
    this.fictionalMarker = '',
    this.deniedBrands = const <String>[],
    this.deniedPromises = const <String>[],
    this.generalInfoPrefix = '',
  });

  /// How the language marks a fictional drug, product, or event name:
  /// `(fictional)` in English, `(가상)` in Korean. Every text of the drug and
  /// medicine roles carries it.
  final String fictionalMarker;

  /// The spellings of real brands, companies, works, and medicines, in the
  /// writing system of the language (`サムスン`, `三星`, `Самсунг`), that no text
  /// of any language may contain. Case is ignored, and a space in an entry
  /// matches any amount of white space.
  ///
  /// The brand names themselves are data of this list, as in the English and
  /// Korean lists: the package never writes a real brand in its own text. A
  /// language that writes in Latin letters may leave the list empty when
  /// every spelling is one of the Latin ones that English lists, which every
  /// language is scanned for.
  final List<String> deniedBrands;

  /// The phrases in the language that promise a result or give advice that a
  /// consultation example must not make: `guaranteed`, `you should`. Case is
  /// ignored, and a space in an entry matches any amount of white space.
  final List<String> deniedPromises;

  /// How the general-information consultation texts of the language begin:
  /// `General` in English, `일반 정보 예시` in Korean. Every text of those roles
  /// starts with it.
  final String generalInfoPrefix;

  /// Whether the declaration has what the scan needs of a language with
  /// domain text: the marker, the promises, the prefix, and, for a language
  /// that does not write in Latin letters, the brands.
  bool isComplete({required bool latin}) =>
      fictionalMarker.isNotEmpty &&
      generalInfoPrefix.isNotEmpty &&
      deniedPromises.isNotEmpty &&
      (latin || deniedBrands.isNotEmpty);

  /// What is still missing, for the message of a failure.
  List<String> missing({required bool latin}) => <String>[
    if (fictionalMarker.isEmpty) 'fictionalMarker',
    if (generalInfoPrefix.isEmpty) 'generalInfoPrefix',
    if (deniedPromises.isEmpty) 'deniedPromises',
    if (!latin && deniedBrands.isEmpty) 'deniedBrands',
  ];
}

/// A regular expression that matches any of [entries]: the entries are text,
/// not patterns, a space matches any amount of white space, and case is
/// ignored.
RegExp safetyPattern(Iterable<String> entries) => RegExp(
  entries
      .map(
        (entry) =>
            entry.trim().split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s*'),
      )
      .join('|'),
  caseSensitive: false,
);
