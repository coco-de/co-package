import 'package:flutter/foundation.dart';
import 'package:open_note/src/note/core/note_page_size.dart';
import 'package:open_note/src/note/template/note_paper_kind.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

/// The papers a note can use: the built-ins followed by the registered ones.
///
/// There is no built-in `image` paper (it needs a picture). Registering a
/// template under a built-in id overrides that built-in in place; unregistering
/// it restores the original. Listeners are notified only on real changes.
/// Methods that change the catalog do nothing after [dispose].
class NotePaperCatalog extends ChangeNotifier {
  /// Id of the built-in blank paper.
  static const String blankId = 'builtin.blank';

  /// Id of the built-in ruled paper.
  static const String linedId = 'builtin.lined';

  /// Id of the built-in squared paper.
  static const String gridId = 'builtin.grid';

  /// Id of the built-in dot-grid paper.
  static const String dottedId = 'builtin.dotted';

  /// Id of the built-in Cornell paper.
  static const String cornellId = 'builtin.cornell';

  /// Id of the built-in staff paper.
  static const String musicId = 'builtin.music';

  final Map<String, NotePaperTemplate> _builtIns;
  final Map<String, NotePaperTemplate> _entries = {};
  bool _disposed = false;

  /// A catalog whose built-ins are made for pages of [pageSize].
  NotePaperCatalog({NotePageSize pageSize = NotePageSize.a4})
    : _builtIns = _index(builtInTemplates(pageSize)) {
    _entries.addAll(_builtIns);
  }

  /// The six built-in papers for pages of [pageSize], in catalog order.
  static List<NotePaperTemplate> builtInTemplates([
    NotePageSize pageSize = NotePageSize.a4,
  ]) => [
    NotePaperTemplate.blank(size: pageSize),
    NotePaperTemplate.lined(size: pageSize),
    NotePaperTemplate.grid(size: pageSize),
    NotePaperTemplate.dotted(size: pageSize),
    NotePaperTemplate.cornell(size: pageSize),
    NotePaperTemplate.music(size: pageSize),
  ];

  static Map<String, NotePaperTemplate> _index(
    List<NotePaperTemplate> templates,
  ) => {for (final template in templates) template.id: template};

  /// Every paper: built-ins first, then registered ones in registration order.
  List<NotePaperTemplate> get templates => List.unmodifiable(_entries.values);

  /// The paper with [id], or `null`.
  NotePaperTemplate? find(String id) => _entries[id];

  /// The papers of [kind], in catalog order.
  List<NotePaperTemplate> byKind(NotePaperKind kind) => [
    for (final template in _entries.values)
      if (template.kind == kind) template,
  ];

  /// Whether [id] belongs to a built-in paper (even an overridden one).
  bool isBuiltIn(String id) => _builtIns.containsKey(id);

  /// Adds [template], or replaces the one with the same id. Returns whether the
  /// catalog changed; a template with an empty id is ignored.
  bool register(NotePaperTemplate template) {
    if (_disposed || template.id.isEmpty) return false;
    if (_entries[template.id] == template) return false;
    _entries[template.id] = template;
    notifyListeners();

    return true;
  }

  /// Removes the paper with [id], or restores the built-in it overrode.
  /// Returns whether the catalog changed (a built-in cannot be removed).
  bool unregister(String id) {
    if (_disposed) return false;
    final original = _builtIns[id];
    if (original == null) {
      if (_entries.remove(id) == null) return false;
    } else {
      if (_entries[id] == original) return false;
      _entries[id] = original;
    }
    notifyListeners();

    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
