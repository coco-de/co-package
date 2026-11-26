import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/document/document.dart';
import 'package:open_note/src/note/nav/nav.dart';
import 'package:open_note/src/note/objects/objects.dart';
import 'package:open_note/src/note/template/note_paper_template.dart';

import 'support/document_fixtures.dart';

void main() {
  late NoteDocument document;

  setUp(() => document = newDocument(template: NotePaperTemplate.grid()));
  tearDown(() => document.dispose());

  test('a new document has one page', () {
    expect(document.pageCount, 1);
    expect(document.pageAt(0).template.kind, NotePaperTemplate.grid().kind);
  });

  group('adding pages', () {
    test('after, before and at an index', () {
      final first = document.pageIds.single;
      final after = document.addPage(after: first);
      final before = document.addPage(before: first);
      final atIndex = document.addPage(index: 1);

      expect(document.pageIds, [before.id, atIndex.id, first, after.id]);
    });

    test('inherits the neighbour paper and size unless told otherwise', () {
      final first = document.pageAt(0);

      final same = document.addPage(after: first.id);
      final dotted = document.addPage(template: NotePaperTemplate.dotted());
      final landscape = document.addPage(
        after: first.id,
        orientation: NotePageOrientation.landscape,
      );

      expect(same.size, first.size);
      expect(same.template.kind, first.template.kind);
      expect(dotted.template.kind, NotePaperTemplate.dotted().kind);
      expect(landscape.size.width, greaterThan(landscape.size.height));
    });

    test('duplicate lands right after the original', () {
      final first = document.pageIds.single;
      final last = document.addPage().id;

      final copy = document.duplicatePage(first)!;

      expect(document.pageIds, [first, copy.id, last]);
      expect(document.duplicatePage('unknown'), isNull);
    });

    test('import copies chosen pages of another note, keeping links', () {
      final source = newDocument(id: 'source', idFactory: counterIds('src'));
      addTearDown(source.dispose);
      final a = source.pageIds.single;
      final b = source.addPage().id;
      final c = source.addPage().id;
      source.replacePage(
        source
            .page(a)!
            .copyWith(
              objects: [
                linkTo('pageid:$c', id: 'to-c'),
                linkTo('pageid:$b', id: 'to-b'),
              ],
            ),
      );

      final imported = document.importPages(source, [
        a,
        c,
        'unknown',
      ], index: 0);

      expect(imported, hasLength(2));
      expect(document.pageIds.take(2), [for (final page in imported) page.id]);
      final targets = [
        for (final object in imported.first.objects)
          (object as NoteLinkObject).target,
      ];
      // The link into the imported set follows the copy; the other is kept.
      expect(targets, ['pageid:${imported.last.id}', 'pageid:$b']);
      expect(source.pageCount, 3);
    });
  });

  group('removing pages', () {
    test('the last page stays', () {
      expect(document.removePage(document.pageIds.single), isFalse);
    });

    test('a removed page keeps its entries until it is purged', () {
      final second = document.addPage().id;
      document.bookmarks.toggle(second);
      document.outline.add('Chapter', second);
      document.tags.add('exam', NoteTagRef(noteId: 'note', pageId: second));
      document.excerpts.add(
        pageId: second,
        rect: const Rect.fromLTWH(0, 0, 0.5, 0.5),
      );

      expect(document.removePage(second), isTrue);
      expect(document.indexOf(second), -1);
      expect(document.trashedPages.single.page.id, second);
      expect(document.bookmarks.isBookmarked(second), isTrue);

      expect(document.restorePage(second), isTrue);
      expect(document.indexOf(second), 1);

      document
        ..removePage(second)
        ..emptyPageTrash();
      expect(document.trashedPages, isEmpty);
      expect(document.page(second), isNull);
      expect(document.bookmarks.isBookmarked(second), isFalse);
      expect(document.outline.toJson().toString(), isNot(contains(second)));
      expect(document.tags.refsOf('exam'), isEmpty);
      expect(document.excerpts.byPage(second), isEmpty);
    });

    test('move clamps the target index', () {
      final first = document.pageIds.single;
      final second = document.addPage().id;

      expect(document.movePage(first, 99), isTrue);
      expect(document.pageIds, [second, first]);
      expect(document.movePage(first, 1), isFalse);
    });
  });

  group('recordings stay on their page', () {
    test('numbers follow reordering and come back after a restore', () {
      final second = document.addPage().id;
      document.recordings = {
        'recordings': [
          {'id': 'r', 'source': 'a.m4a', 'pageNumber': 2},
        ],
      };

      document.addPage(index: 0);
      expect(document.recordingPageNumber('r'), 3);

      document.removePage(second);
      expect(document.recordingPageNumber('r'), isNull);
      final list = document.recordings['recordings']! as List;
      expect((list.single as Map).containsKey('pageNumber'), isFalse);
      // Saving the detached list back must not forget the page.
      document.recordings = document.recordings;
      document.restorePage(second);
      expect(document.recordingPageNumber('r'), 3);
    });

    test('purging the page or dropping the recording forgets the link', () {
      final second = document.addPage().id;
      document.recordings = {
        'recordings': [
          {'id': 'r', 'source': 'a.m4a', 'pageNumber': 2},
        ],
      };
      document
        ..removePage(second)
        ..purgePage(second);
      expect(document.recordingPageIds, isEmpty);

      document.recordings = {'recordings': []};
      expect(document.recordingPageIds, isEmpty);
    });
  });

  test('pages with ink and printed numbers', () {
    final second = document.addPage();
    document
      ..replacePage(withStroke(second, const Offset(1, 1), const Offset(9, 9)))
      ..numbering = NotePageNumbering(startsAtPageId: second.id);

    expect(document.pagesWithInk.map((page) => page.id), [second.id]);
    expect(document.labelOf(second.id), '1');
    expect(document.labelOf(document.pageIds.first), startsWith('0-'));
    expect(document.labelOf('unknown'), '');
  });

  test('rotating, margins and paper changes mark the page dirty', () {
    document.markSaved();
    final first = document.pageIds.single;

    document.rotatePage(first);
    expect(document.dirtyPageIds, {first});
    expect(document.page(first)!.paperTurns, 1);

    document
      ..markSaved()
      ..setPageMargins(
        first,
        const EdgeInsets.only(left: 10),
        marginTemplate: NotePaperTemplate.blank(),
      );
    expect(document.page(first)!.marginTemplate, isNotNull);

    document
      ..markSaved()
      ..setTemplate([first], NotePaperTemplate.dotted());
    expect(
      document.page(first)!.template.kind,
      NotePaperTemplate.dotted().kind,
    );
    expect(document.dirtyPageIds, {first});
  });

  test('every change notifies, including bookmark edits', () {
    var notifications = 0;
    document.addListener(() => notifications++);
    final before = document.revision;

    document.bookmarks.toggle(document.pageIds.single);
    document.title = 'Notes';
    document.title = 'Notes';

    expect(notifications, 2);
    expect(document.revision, before + 2);
  });
}
