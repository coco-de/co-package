import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/note_pencil_gesture.dart';

/// Which action each stylus gesture runs.
///
/// JSON: `{"doubleTap": action name, "squeeze": action name}`; the names are
/// those of [NotePencilAction]. A missing or unknown name gives the default.
@immutable
class NotePencilGestureMap {
  /// Default action of a double tap.
  static const NotePencilAction defaultDoubleTap =
      NotePencilAction.switchPreviousTool;

  /// Default action of a squeeze.
  static const NotePencilAction defaultSqueeze =
      NotePencilAction.showToolPalette;

  /// Action of a double tap.
  final NotePencilAction doubleTap;

  /// Action of a squeeze.
  final NotePencilAction squeeze;

  /// Creates a map. By default a double tap switches to the previous tool and a
  /// squeeze shows the tool palette.
  const NotePencilGestureMap({
    this.doubleTap = defaultDoubleTap,
    this.squeeze = defaultSqueeze,
  });

  /// Reads the JSON form; never throws.
  factory NotePencilGestureMap.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NotePencilGestureMap(
      doubleTap: NoteJson.enumByName(
        NotePencilAction.values,
        map['doubleTap'],
        defaultDoubleTap,
      ),
      squeeze: NoteJson.enumByName(
        NotePencilAction.values,
        map['squeeze'],
        defaultSqueeze,
      ),
    );
  }

  @override
  int get hashCode => Object.hash(doubleTap, squeeze);

  /// The action of [gesture].
  NotePencilAction actionFor(NotePencilGesture gesture) => switch (gesture) {
    NotePencilGesture.doubleTap => doubleTap,
    NotePencilGesture.squeeze => squeeze,
  };

  /// A copy in which [gesture] runs [action].
  NotePencilGestureMap withAction(
    NotePencilGesture gesture,
    NotePencilAction action,
  ) => switch (gesture) {
    NotePencilGesture.doubleTap => copyWith(doubleTap: action),
    NotePencilGesture.squeeze => copyWith(squeeze: action),
  };

  /// A copy with the given values replaced.
  NotePencilGestureMap copyWith({
    NotePencilAction? doubleTap,
    NotePencilAction? squeeze,
  }) => NotePencilGestureMap(
    doubleTap: doubleTap ?? this.doubleTap,
    squeeze: squeeze ?? this.squeeze,
  );

  /// The JSON form described on the class.
  JsonMap toJson() => {'doubleTap': doubleTap.name, 'squeeze': squeeze.name};

  @override
  bool operator ==(Object other) =>
      other is NotePencilGestureMap &&
      other.doubleTap == doubleTap &&
      other.squeeze == squeeze;

  @override
  String toString() => 'NotePencilGestureMap(${toJson()})';
}
