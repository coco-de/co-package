/// The authored domain text of one language.
///
/// A bundle maps a text key to the texts that key can show. The domain packs
/// and the dedicated generators (`fx`, `remit`, `vet`, `catalog`, `exam_prep`,
/// `helpdesk`, ...) read their labels, names, and sentences from the bundle of
/// the generator's language through `faker.l10n`, so a language is added with
/// data alone: write a bundle and register it, and no pack changes.
///
/// ```dart
/// const bundle = CoL10nBundle(
///   language: 'es',
///   texts: {
///     'dental.dentalProcedure': [
///       'Limpieza dental',
///       'Ejemplo de endodoncia',
///       'Ejemplo de restauración con resina',
///       'Ejemplo de plan de corona',
///     ],
///     'workplace.sprintName': ['Sprint {n}'],
///   },
/// );
/// ```
///
/// ## Keys
///
/// A key is `<pack>.<role>`: `dental.dentalProcedure` is the text of the role
/// `dentalProcedure` of the `dental` pack. The dedicated generators use
/// `<generator>.<name>` (`fx.currencyName.USD`, `vet.breed.dog`), and text
/// that several packs share lives under `common`. The English bundle defines
/// every key; its keys are the reference.
///
/// ## Texts
///
/// The value of a key is a list. A key that offers choices (a role that picks
/// one of several labels) lists them; a key with a single sentence is a list
/// of one. `{name}` marks a placeholder that the generator fills in, for
/// example `Sprint {n}`.
///
/// ## Alignment
///
/// A key has the same number of texts in every language, so the same seed
/// picks the same entry whatever the language: Korean `0`, English `0`, and
/// Japanese `0` are translations of one another. Text `i` of a key translates
/// text `i` of the English key, and the list order follows the English one.
/// [CoL10nRegistry] checks it when the bundles load, and a custom locale's
/// bundle is checked when one of its keys is read.
///
/// A language does not have to translate every key. A key that is missing
/// falls back to English, key by key.
///
/// ## Adding a language without changing co_faker
///
/// A custom `CoFakerLocale` carries a bundle of its own (`CoFakerLocale.l10n`),
/// and the generators of that locale read it before the shipped bundle of their
/// language. [CoL10nRegistry.validate] checks such a bundle in a test.
class CoL10nBundle {
  /// Creates a bundle of [texts] written in [language].
  const CoL10nBundle({
    required this.language,
    this.texts = const <String, List<String>>{},
    this.allowSameAsEnglish = const <String, List<String>>{},
  });

  /// Lower-case ISO 639-1 code of the language, such as `ja`.
  final String language;

  /// The texts by key. Every list has at least one entry, and every entry is
  /// a non-empty string.
  final Map<String, List<String>> texts;

  /// The texts of this language that are allowed to read exactly like the
  /// English ones: loanwords, acronyms, units, and proper names that no
  /// translation would change.
  ///
  /// The coverage gate (`dart run co_faker:coverage --language ja --strict`)
  /// reports every text that equals the English text at the same place, since
  /// that is how an untranslated text looks. A text that is the same on
  /// purpose is listed here by the name of its slot and its value:
  ///
  /// ```dart
  /// allowSameAsEnglish: {
  ///   // Units are written the same way in Japanese.
  ///   'catalog.groceryUnit': ['500g', '1kg'],
  ///   // An acronym.
  ///   'exam_prep.correctChoice': ['TCP'],
  ///   // Every text of the slot is a unit symbol.
  ///   'clinic.procedures.unit': ['*'],
  /// }
  /// ```
  ///
  /// A slot is a key of [texts] (`catalog.groceryUnit`) or the name of a
  /// clinic or SaaS field (`clinic.cardIssuers`, `saas.plans.name`); the gate
  /// prints the name of every slot with a text it finds equal. `*` allows
  /// every text of a slot. An entry that no text uses any more is reported,
  /// so the list never keeps a text that has since been translated. The
  /// language owns this list, and it is not for texts that can be translated.
  final Map<String, List<String>> allowSameAsEnglish;

  /// The pattern of a placeholder: `{name}`, a name of letters, digits, and
  /// underscores that does not start with a digit.
  static final RegExp placeholderPattern = RegExp(r'\{([A-Za-z_]\w*)\}');

  /// The names of the placeholders in [text]: `{n}` and `{root}` for
  /// `{root} · subtopic {n}`.
  static Set<String> placeholdersOf(String text) => <String>{
    for (final match in placeholderPattern.allMatches(text)) match.group(1)!,
  };

  /// Whether the bundle has no text. An empty bundle is a placeholder for a
  /// language that has no authored domain text yet.
  bool get isEmpty => texts.isEmpty;

  /// Whether the bundle has at least one text.
  bool get isNotEmpty => texts.isNotEmpty;

  @override
  String toString() => 'CoL10nBundle($language, ${texts.length} keys)';
}
