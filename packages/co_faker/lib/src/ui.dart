import 'co_faker.dart';
import 'ui_copy_data.dart';

/// Authored component examples for design canvases, previews, and fixtures.
///
/// Korean follows the designer-approved CoUI #6010 copy (2026-11-10), including
/// its later Autocomplete and fictional-name decisions. English offers the
/// same examples in the same order. Other languages fall back to English;
/// these examples are separate from the domain packs' translation coverage.
///
/// Keys name a component and its text slot, such as `textField.placeholder`.
/// These are fixture lookup keys, not CoUI property or localization API names.
/// Keep a product's approved copy when it exists; these are component examples.
class CoFakerUi {
  /// Reads examples in the language selected by [faker].
  CoFakerUi(this.faker);

  /// Source of the locale and random stream.
  final CoFaker faker;

  /// The designer-approved source of the Korean examples.
  static const sourceUrl =
      'https://github.com/coco-de/coui/issues/6010#issuecomment-6759151296';

  /// Final implementation record, including names that supersede the table.
  static const decisionsUrl =
      'https://github.com/coco-de/coui/issues/6010#issuecomment-6762684567';

  /// Date of the approved table and its follow-up decisions.
  static const revision = '2026-11-10';

  /// Language of the returned copy: Korean when selected, otherwise English.
  String get language => faker.l10n.language == 'ko' ? 'ko' : 'en';

  /// All available `component.slot` keys, in catalog order.
  static Iterable<String> get keys => uiCopyData.keys;

  /// The immutable examples of [key], in the same order in both languages.
  ///
  /// Does not draw from the random stream. Unknown keys throw [ArgumentError].
  List<String> list(String key) {
    final copy = uiCopyData[key];
    if (copy == null) {
      throw ArgumentError.value(key, 'key', 'unknown UI example key');
    }
    return language == 'ko' ? copy.ko : copy.en;
  }

  /// The single example of [key], without drawing from the random stream.
  ///
  /// Throws [StateError] for a list: use [list], [pick], or [pickBalanced].
  String text(String key) {
    final values = list(key);
    if (values.length != 1) {
      throw StateError('UI example "$key" has ${values.length} texts.');
    }
    return values.single;
  }

  /// Picks an example using the parent's random stream.
  String pick(String key) => faker.random.pick(list(key));

  /// Cycles through examples by [index], without drawing random values.
  String pickBalanced(String key, int index) =>
      faker.random.pickBalanced(list(key), index);
}
