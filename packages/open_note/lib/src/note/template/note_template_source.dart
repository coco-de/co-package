import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/template/note_template_descriptor.dart';

/// A "resource center" of paper templates (a server, a bundle, a store). The
/// host implements it; the package ships `MemoryNoteTemplateSource`.
abstract interface class NoteTemplateSource {
  /// A page of templates, in the source's own order.
  ///
  /// [query] filters by name or tag (case-insensitive substring; `null` or
  /// blank matches all). [offset] skips results and [limit] caps them; negative
  /// values count as 0. May throw if the source cannot be reached.
  Future<List<NoteTemplateDescriptor>> list({
    String? query,
    int offset = 0,
    int limit = 50,
  });

  /// The template behind a descriptor [id], or `null` when it does not exist.
  Future<NotePaperTemplate?> fetch(String id);
}
