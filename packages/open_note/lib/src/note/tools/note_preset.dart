import 'package:open_note/src/note/core/core.dart';

/// Something a preset store can hold.
abstract interface class NotePreset {
  /// Stable id, unique within a store. A store never holds an empty id.
  String get id;

  /// The JSON form, including `id`.
  JsonMap toJson();
}
