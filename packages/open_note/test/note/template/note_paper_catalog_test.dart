import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/template/template.dart';

void main() {
  late NotePaperCatalog catalog;
  var notifications = 0;

  setUp(() {
    notifications = 0;
    catalog = NotePaperCatalog()..addListener(() => notifications++);
  });

  List<String> ids() => [for (final t in catalog.templates) t.id];

  test('lists the six built-ins with stable ids in order', () {
    expect(ids(), [
      'builtin.blank',
      'builtin.lined',
      'builtin.grid',
      'builtin.dotted',
      'builtin.cornell',
      'builtin.music',
    ]);
    expect(catalog.isBuiltIn(NotePaperCatalog.gridId), isTrue);
    expect(catalog.isBuiltIn('custom'), isFalse);
    expect(catalog.find(NotePaperCatalog.linedId), NotePaperTemplate.lined());
    expect(catalog.find('nope'), isNull);
    expect(() => catalog.templates.clear(), throwsUnsupportedError);
  });

  test('built-ins are made for the page size', () {
    final small = NotePaperCatalog(pageSize: NotePageSize.a5);
    expect(small.templates.every((t) => t.size == NotePageSize.a5), isTrue);
    small.dispose();
  });

  test('register adds after the built-ins and byKind filters', () {
    final custom = NotePaperTemplate.lined(id: 'wide', lineSpacing: 40);
    expect(catalog.register(custom), isTrue);
    expect(ids().last, 'wide');
    expect(catalog.find('wide'), custom);
    expect(catalog.byKind(NotePaperKind.lined).map((t) => t.id), [
      'builtin.lined',
      'wide',
    ]);
    expect(catalog.byKind(NotePaperKind.image), isEmpty);
    expect(notifications, 1);
  });

  test('only real changes notify', () {
    final custom = NotePaperTemplate.grid(id: 'mine');
    catalog
      ..register(custom)
      ..register(NotePaperTemplate.grid(id: 'mine'));
    expect(notifications, 1);
    expect(catalog.register(custom.copyWith(lineSpacing: 30)), isTrue);
    expect(ids().where((id) => id == 'mine'), hasLength(1));
    expect(notifications, 2);
    expect(catalog.register(NotePaperTemplate(id: '')), isFalse);
    expect(catalog.unregister('missing'), isFalse);
    expect(notifications, 2);
  });

  test('unregister removes custom papers', () {
    catalog.register(NotePaperTemplate.grid(id: 'mine'));
    expect(catalog.unregister('mine'), isTrue);
    expect(catalog.find('mine'), isNull);
    expect(notifications, 2);
  });

  test('a built-in can be overridden in place and restored', () {
    final original = catalog.find(NotePaperCatalog.linedId)!;
    expect(catalog.unregister(NotePaperCatalog.linedId), isFalse);
    expect(catalog.register(original.copyWith(lineSpacing: 33)), isTrue);
    expect(ids()[1], NotePaperCatalog.linedId);
    expect(catalog.find(NotePaperCatalog.linedId)!.lineSpacing, 33);
    expect(catalog.unregister(NotePaperCatalog.linedId), isTrue);
    expect(catalog.find(NotePaperCatalog.linedId), original);
    expect(catalog.templates, hasLength(6));
    expect(notifications, 2);
  });

  test('changes after dispose are ignored', () {
    catalog.dispose();
    expect(catalog.register(NotePaperTemplate.grid(id: 'late')), isFalse);
    expect(catalog.unregister(NotePaperCatalog.gridId), isFalse);
    expect(catalog.find('late'), isNull);
    expect(notifications, 0);
  });
}
