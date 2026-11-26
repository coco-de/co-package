import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';

/// Recognises handwriting so it can be searched. The package ships no
/// recogniser: the host plugs one in (an OCR or ink-recognition service).
///
/// The host indexes the result with
/// `NoteSearchIndex.indexPage(…, kind: NoteSearchHitKind.handwriting)`.
abstract interface class NoteHandwritingIndexer {
  /// The text recognised in the strokes of [scribble], one entry per line (or
  /// chunk), in reading order. Completes with an empty list when nothing is
  /// recognised.
  Future<List<String>> recognize(Scribble scribble);
}
