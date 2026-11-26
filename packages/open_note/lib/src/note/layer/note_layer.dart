import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_json.dart';

/// Metadata of one ink layer of a page. A page lists its layers bottom to top.
///
/// JSON: `{"id": String, "name": String, "visible": bool, "locked": bool,
/// "opacity": 0..1}`.
@immutable
class NoteLayer {
  const NoteLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.opacity = 1,
  }) : assert(opacity >= 0 && opacity <= 1, 'opacity must be within 0..1');

  /// Decodes a layer; a missing or empty id becomes [fallbackId].
  factory NoteLayer.fromJson(Object? value, {required String fallbackId}) {
    final json = NoteJson.asMap(value) ?? const <String, Object?>{};
    final id = NoteJson.string(json, 'id');

    return NoteLayer(
      id: id.isEmpty ? fallbackId : id,
      name: NoteJson.string(json, 'name'),
      visible: NoteJson.boolean(json, 'visible', true),
      locked: NoteJson.boolean(json, 'locked'),
      opacity: NoteJson.number(json, 'opacity', 1).clamp(0.0, 1.0),
    );
  }

  /// Unique within the page.
  final String id;
  final String name;

  /// A hidden layer is not drawn and cannot be drawn on.
  final bool visible;

  /// A locked layer cannot be drawn on or erased.
  final bool locked;

  /// 0 (transparent) to 1 (opaque).
  final double opacity;

  NoteLayer copyWith({
    String? name,
    bool? visible,
    bool? locked,
    double? opacity,
  }) => NoteLayer(
    id: id,
    name: name ?? this.name,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    opacity: (opacity ?? this.opacity).clamp(0.0, 1.0),
  );

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'locked': locked,
    'opacity': opacity,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteLayer &&
      other.id == id &&
      other.name == name &&
      other.visible == visible &&
      other.locked == locked &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(id, name, visible, locked, opacity);

  @override
  String toString() =>
      'NoteLayer($id, "$name", visible: $visible, locked: $locked, '
      'opacity: $opacity)';
}
