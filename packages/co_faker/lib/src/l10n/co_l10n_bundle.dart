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
class CoL10nBundle {
  /// Creates a bundle of [texts] written in [language].
  const CoL10nBundle({
    required this.language,
    this.texts = const <String, List<String>>{},
  });

  /// Lower-case ISO 639-1 code of the language, such as `ja`.
  final String language;

  /// The texts by key. Every list has at least one entry, and every entry is
  /// a non-empty string.
  final Map<String, List<String>> texts;

  /// Whether the bundle has no text. An empty bundle is a placeholder for a
  /// language that has no authored domain text yet.
  bool get isEmpty => texts.isEmpty;

  /// Whether the bundle has at least one text.
  bool get isNotEmpty => texts.isNotEmpty;

  @override
  String toString() => 'CoL10nBundle($language, ${texts.length} keys)';
}
