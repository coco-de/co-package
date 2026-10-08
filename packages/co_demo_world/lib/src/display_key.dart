/// The stable address of one generated display value: an entity kind, the
/// entity's id and a field.
///
/// Keys use the entity's **id**, never its position in a list, so deleting or
/// reordering records does not change the display values of the others.
class DisplayKey {
  /// Creates a key. None of the parts may be empty or contain `/`.
  DisplayKey(this.entity, this.id, this.field) {
    _check(entity, 'entity');
    _check(id, 'id');
    _check(field, 'field');
  }

  /// The entity kind, for example `pet`.
  final String entity;

  /// The entity id, for example `pet-0001`.
  final String id;

  /// The field, for example `name`.
  final String field;

  /// The derivation key, `entity/id/field`.
  String get path => '$entity/$id/$field';

  /// The field-set key, `entity.field` — the generator that owns this value.
  String get fieldKey => '$entity.$field';

  static void _check(String value, String name) {
    if (value.isEmpty || value.contains('/')) {
      throw ArgumentError.value(
        value,
        name,
        'must be non-empty and must not contain "/"',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DisplayKey &&
      other.entity == entity &&
      other.id == id &&
      other.field == field;

  @override
  int get hashCode => Object.hash(entity, id, field);

  @override
  String toString() => 'DisplayKey($path)';
}
