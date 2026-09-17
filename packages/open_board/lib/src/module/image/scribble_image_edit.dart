import 'package:flutter/foundation.dart';
import 'package:open_board/src/data/model/protobuf/scribble.pb.dart';

/// The operation that applied an image membership change, not its human origin.
// Keep the kind and its payload together as one small public API.
// ignore: prefer-match-file-name
enum ScribbleImageEditKind { edit, undo, redo }

/// Image snapshots for a committed membership change.
///
/// Both lists and their deep-copied protobuf images are immutable, so a captured
/// edit can safely be retained across asynchronous work.
@immutable
final class ScribbleImageEdit {
  final List<ImageDrawable> before;
  final List<ImageDrawable> after;
  final ScribbleImageEditKind kind;

  ScribbleImageEdit({
    required List<ImageDrawable> before,
    required List<ImageDrawable> after,
    required this.kind,
  }) : before = List.unmodifiable(
         before.map((image) => image.deepCopy()..freeze()),
       ),
       after = List.unmodifiable(
         after.map((image) => image.deepCopy()..freeze()),
       );
}
