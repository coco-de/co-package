import 'dart:math' as math;

import 'package:open_note/src/note/template/note_paper_template.dart';
import 'package:open_note/src/note/template/note_template_descriptor.dart';
import 'package:open_note/src/note/template/note_template_source.dart';

/// A [NoteTemplateSource] kept in memory, for tests and the example.
class MemoryNoteTemplateSource implements NoteTemplateSource {
  final Map<String, (NotePaperTemplate, NoteTemplateDescriptor)> _entries = {};

  /// A source holding [templates], without tags or previews.
  MemoryNoteTemplateSource([Iterable<NotePaperTemplate> templates = const []]) {
    templates.forEach(add);
  }

  /// Number of templates.
  int get length => _entries.length;

  /// Adds [template] (replacing one with the same id, keeping its position) with
  /// search [tags] and an optional preview. A template with an empty id is
  /// ignored.
  void add(
    NotePaperTemplate template, {
    List<String> tags = const [],
    String? thumbnailSource,
  }) {
    if (template.id.isEmpty) return;
    _entries[template.id] = (
      template,
      NoteTemplateDescriptor.of(
        template,
        tags: tags,
        thumbnailSource: thumbnailSource,
      ),
    );
  }

  /// Removes the template with [id]; returns whether it existed.
  bool remove(String id) => _entries.remove(id) != null;

  @override
  Future<List<NoteTemplateDescriptor>> list({
    String? query,
    int offset = 0,
    int limit = 50,
  }) async {
    final wanted = query?.trim().toLowerCase() ?? '';

    return [
      for (final (_, descriptor) in _entries.values)
        if (_matches(descriptor, wanted)) descriptor,
    ].skip(math.max(0, offset)).take(math.max(0, limit)).toList();
  }

  @override
  Future<NotePaperTemplate?> fetch(String id) async => _entries[id]?.$1;

  static bool _matches(NoteTemplateDescriptor descriptor, String wanted) =>
      wanted.isEmpty ||
      descriptor.name.toLowerCase().contains(wanted) ||
      descriptor.tags.any((tag) => tag.toLowerCase().contains(wanted));
}
