import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_lasso_shape.dart';

/// Lasso settings.
///
/// JSON: `{"shape": "freeform" | "rectangle"}`.
@immutable
class NoteLassoSettings {
  /// The selection outline.
  final NoteLassoShape shape;

  /// Creates settings; the default shape is freeform.
  const NoteLassoSettings({this.shape = NoteLassoShape.freeform});

  /// Reads the JSON form; never throws.
  factory NoteLassoSettings.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteLassoSettings(
      shape: NoteJson.enumByName(
        NoteLassoShape.values,
        map['shape'],
        NoteLassoShape.freeform,
      ),
    );
  }

  @override
  int get hashCode => shape.hashCode;

  /// A copy with the given values replaced.
  NoteLassoSettings copyWith({NoteLassoShape? shape}) =>
      NoteLassoSettings(shape: shape ?? this.shape);

  /// The JSON form described on the class.
  JsonMap toJson() => {'shape': shape.name};

  @override
  bool operator ==(Object other) =>
      other is NoteLassoSettings && other.shape == shape;

  @override
  String toString() => 'NoteLassoSettings(${shape.name})';
}
