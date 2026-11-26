import 'package:flutter/widgets.dart';
import 'package:open_note/src/note/library/note_summary.dart';

/// Lets the host show a preview of a note, such as its first page, in a
/// `NoteTile` instead of the cover.
abstract interface class NoteThumbnailProvider {
  /// The preview of [note], or `null` to show its cover.
  ///
  /// It is called during build, so it must return at once: load slow previews
  /// in the returned widget, or return `null` until they are ready and rebuild
  /// the library view. The widget gets tight constraints in the proportions of
  /// the note's cover and is clipped to its rounded corners.
  Widget? thumbnailFor(BuildContext context, NoteSummary note);
}
