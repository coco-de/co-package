import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';

/// A font offered by a `NoteFontSource`.
///
/// JSON: `{"id": String, "family": String, "name": String}`.
@immutable
class NoteFontDescriptor {
  /// Id used to download the font.
  final String id;

  /// Family name to register the font under.
  final String family;

  /// Name to show; may be empty.
  final String name;

  /// Creates a descriptor.
  const NoteFontDescriptor({
    required this.id,
    required this.family,
    this.name = '',
  });

  /// Reads the JSON form; never throws, missing texts read as `''`.
  factory NoteFontDescriptor.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteFontDescriptor(
      id: NoteJson.string(map, 'id'),
      family: NoteJson.string(map, 'family'),
      name: NoteJson.string(map, 'name'),
    );
  }

  /// [name], or [family] when there is no name.
  String get label => name.isEmpty ? family : name;

  @override
  int get hashCode => Object.hash(id, family, name);

  /// A copy with the given values replaced.
  NoteFontDescriptor copyWith({String? id, String? family, String? name}) =>
      NoteFontDescriptor(
        id: id ?? this.id,
        family: family ?? this.family,
        name: name ?? this.name,
      );

  /// The JSON form described on the class.
  JsonMap toJson() => {'id': id, 'family': family, 'name': name};

  @override
  bool operator ==(Object other) =>
      other is NoteFontDescriptor &&
      other.id == id &&
      other.family == family &&
      other.name == name;

  @override
  String toString() => 'NoteFontDescriptor($id, $family)';
}
