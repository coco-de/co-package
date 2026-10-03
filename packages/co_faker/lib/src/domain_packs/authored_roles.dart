import '../co_faker.dart';
import '../domain.dart';

// New packs deliberately have no global/suffix field patterns. Entity mappings
// and explicit qualified roles cannot capture an existing pack's name/status.
/// Creates a strict primitive adapter, optionally using a coherent row stream.
CoDomainRole authoredRole(
  CoDomainRoleGenerator generate, {
  String type = 'String',
  String description = 'Authored fictional example; Korean or English fallback',
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

/// Picks from authored Korean/English text, never generic lorem.
CoDomainRole textRole(List<String> ko, List<String> en) =>
    authoredRole((f, _) => f.random.pick(f.locale.startsWith('ko') ? ko : en));

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
CoDomainRole maskedNameRole() => authoredRole(
  (f, _) => f.locale.startsWith('ko')
      ? '${f.person.lastName()}○○'
      : '${f.person.firstName().substring(0, 1)}***',
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
CoDomainRole taxonomyRole(List<String> ko, List<String> en) =>
    authoredRole((f, c) {
      final names = f.locale.startsWith('ko') ? ko : en;
      final rootCount = names.length;
      if (c.index < rootCount) {
        return names[c.index];
      }
      final child = c.index - rootCount;
      final root = names[child % rootCount];
      final ordinal = 1 + child ~/ rootCount;
      return localized(f, '$root · 세부 $ordinal', '$root · subtopic $ordinal');
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

/// Selects Korean or an English fallback without random draws.
String localized(CoFaker f, String ko, String en) =>
    f.locale.startsWith('ko') ? ko : en;
