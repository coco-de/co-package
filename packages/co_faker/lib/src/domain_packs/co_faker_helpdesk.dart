import '../co_faker.dart';
import 'authored_roles.dart';

/// Human-authored simulated AI drafts; no model/runtime/network dependency.
class CoFakerHelpdesk {
  /// Uses the supplied locale.
  const CoFakerHelpdesk(this.faker);

  /// Locale and supplied random source.
  final CoFaker faker;

  /// The category of each draft; the draft text is `helpdesk.draftBody` in the
  /// language bundles, in the same order.
  static const _draftCategories = <String>[
    'account',
    'account',
    'billing',
    'billing',
    'data_export',
    'data_export',
    'integration',
    'bug',
  ];

  /// Eight primitive seed records covering the five required draft categories.
  List<Map<String, Object?>> drafts() => List.generate(
    _draftCategories.length,
    (i) => {
      'code': 'AD-${_draftCategories[i]}-${i + 1}',
      'category': _draftCategories[i],
      'templateBody': indexedText(
        faker,
        'helpdesk.draftBody',
        i,
        rows: _draftCategories.length,
      ),
      'sourceArticleCode': 'HA-${(i + 1).toString().padLeft(4, '0')}',
      'isSimulated': true,
    },
    growable: false,
  );
}
