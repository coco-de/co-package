import '../co_faker.dart';
import '../domain.dart';

// New packs deliberately have no global/suffix field patterns. Entity mappings
// and explicit qualified roles cannot capture an existing pack's name/status.
/// Creates a strict primitive adapter, optionally using a coherent row stream.
CoDomainRole authoredRole(
  CoDomainRoleGenerator generate, {
  String type = 'String',
  String description =
      'Authored fictional example in the locale language; English fallback',
  bool coherent = false,
}) => CoDomainRole(
  generate,
  generateRecord: coherent ? generate : null,
  description: description,
  supportedTypes: type == 'int'
      ? const ['int', 'double', 'num', 'String']
      : type == 'double'
      ? const ['double', 'num', 'String']
      : [type],
);

/// Picks from the authored text of [key] in the generator's language, never
/// generic lorem.
///
/// The key is `<pack>.<role>`: its texts live in the language bundles (see
/// `CoL10nBundle`), so a language needs no change here.
CoDomainRole textRole(String key) => authoredRole((f, _) => f.l10n.pick(key));

/// The text of [key] for the record [index], cycling when [index] passes the
/// last text, without consuming random state.
///
/// [rows] is the number of rows of the table the text belongs to: the codes,
/// numbers, or other labels of the same pack that cycle with the same index.
/// The key has one text for each row, in the same order; when it does not, the
/// pack and its bundle disagree, and an assertion fails.
String indexedText(CoFaker f, String key, int index, {required int rows}) {
  assert(
    f.l10n.list(key).length == rows,
    'l10n key "$key" has ${f.l10n.list(key).length} texts for a table of '
    '$rows rows',
  );
  return f.l10n.pickBalanced(key, index);
}

/// Cycles through the authored text of [key] in record order without
/// consuming random state, so roles that follow the same row agree.
///
/// [rows] is the number of rows of the pack's table; see [indexedText].
CoDomainRole indexedTextRole(String key, {required int rows}) => authoredRole(
  (f, c) => indexedText(f, key, c.index, rows: rows),
  coherent: true,
);

/// Cycles enum codes in record order without consuming random state.
CoDomainRole enumRole(List<String> values) => authoredRole(
  (f, c) => f.random.pickBalanced(values, c.index),
  description: 'Enum code: ${values.join(', ')}',
);

/// Generates a bounded, step-aligned illustrative integer.
CoDomainRole intRole(int min, int max, {int step = 1}) => authoredRole(
  (f, _) => f.number.int(min: min ~/ step, max: max ~/ step) * step,
  type: 'int',
  description: 'Illustrative integer in $min..$max (step $step)',
);

/// Generates a bounded decimal with specified precision.
CoDomainRole decimalRole(double min, double max, {int decimals = 1}) =>
    authoredRole(
      (f, _) => f.number.decimal(min: min, max: max, decimals: decimals),
      type: 'double',
      description: 'Illustrative number in $min..$max',
    );

/// Reuses the existing locale's fictional given-name generator.
CoDomainRole firstNameRole() => authoredRole((f, _) => f.person.firstName());

/// Produces a masked example rather than a complete identity.
///
/// The language's `common.maskedName` template chooses what is masked; only
/// the name it uses is drawn.
CoDomainRole maskedNameRole() => authoredRole(
  (f, _) => f.l10n.format('common.maskedName', {
    'lastName': () => f.person.lastName(),
    'firstName': () => f.person.firstName(),
    'initial': () => f.person.firstName().substring(0, 1),
  }),
  description: 'Masked fictional name; no complete identity',
);

/// Produces an ordinal example code, optionally including the UTC date.
CoDomainRole codeRole(
  String prefix, {
  int width = 4,
  bool dated = false,
}) => authoredRole((f, c) {
  final date = f.now
      .toUtc()
      .toIso8601String()
      .substring(2, 10)
      .replaceAll('-', '');
  return '$prefix${dated ? '-$date' : ''}-${(c.index + 1).toString().padLeft(width, '0')}';
}, description: 'Fictional sequence code; UTC clock and record index');

/// Parent pointers for an ordered two-level taxonomy: roots precede children.
CoDomainRole parentRole(int rootCount) => authoredRole(
  (f, c) => c.index < rootCount ? 0 : 1 + (c.index - rootCount) % rootCount,
  type: 'int',
  description: '0 for root, otherwise an earlier root id (1..$rootCount)',
);

/// Names the same two-level taxonomy as [parentRole], keeping children under
/// their root's vocabulary instead of independently sampling unrelated labels.
///
/// The root names are the texts of [key]; a child is named by the language's
/// `common.taxonomyChild` template.
CoDomainRole taxonomyRole(String key) => authoredRole((f, c) {
  final names = f.l10n.list(key);
  final rootCount = names.length;
  if (c.index < rootCount) {
    return names[c.index];
  }
  final child = c.index - rootCount;
  final root = names[child % rootCount];
  final ordinal = 1 + child ~/ rootCount;
  return f.l10n.format('common.taxonomyChild', {'root': root, 'n': ordinal});
}, coherent: true);

/// Adds an integer primary key to primitive role fields.
Map<String, String> roleFields(Map<String, String> roles) => {
  'id': 'int',
  ...roles,
};

/// Maps entity field names to identically named explicit domain roles.
Map<String, String> roleMapping(Iterable<String> fields) => {
  for (final field in fields) field: field,
};
