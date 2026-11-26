import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/nav/note_handwriting_indexer.dart';

/// The default [NoteHandwritingIndexer]: recognises nothing.
class NoopHandwritingIndexer implements NoteHandwritingIndexer {
  /// Creates the indexer.
  const NoopHandwritingIndexer();

  @override
  Future<List<String>> recognize(Scribble scribble) =>
      Future<List<String>>.value(const []);
}
