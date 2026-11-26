import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

void main() {
  late List<String> calls;
  late List<String> order;

  setUp(() {
    calls = [];
    order = ['a', 'b', 'c'];
  });

  NoteLinkNavigator build({
    String? currentNoteId,
    String? Function(String noteId, int page)? pageIdOfOtherNote,
  }) => NoteLinkNavigator(
    pageOrder: () => order,
    goToPage: (page) => calls.add('page $page'),
    openNote: (note, page) => calls.add('note $note $page'),
    openUrl: (url) => calls.add('url $url'),
    onUnresolved: (target) => calls.add('unresolved ${target.format()}'),
    currentNoteId: currentNoteId,
    pageIdOfOtherNote: pageIdOfOtherNote,
  );

  test('a page link goes to that position of the page order', () {
    final navigator = build();

    expect(navigator.navigate(const NotePageLink(2)), isTrue);
    expect(calls, ['page b']);
  });

  test('the page order is read at navigation time', () {
    final navigator = build();
    order = ['z', 'a'];

    navigator.navigate(const NotePageLink(1));

    expect(calls, ['page z']);
  });

  test('a page outside the note is unresolved', () {
    final navigator = build();

    expect(navigator.navigate(const NotePageLink(4)), isFalse);
    order = [];
    expect(navigator.navigate(const NotePageLink(1)), isFalse);
    expect(calls, ['unresolved page:4', 'unresolved page:1']);
  });

  test('a page-id link follows the page after reordering', () {
    final navigator = build();
    order = ['c', 'a', 'b'];

    expect(navigator.navigate(const NotePageIdLink('b')), isTrue);
    expect(navigator.navigate(const NotePageIdLink('gone')), isFalse);
    expect(calls, ['page b', 'unresolved pageid:gone']);
  });

  test('a note link opens the note', () {
    build().navigate(const NoteNoteLink('other'));

    expect(calls, ['note other null']);
  });

  test('a note link with a page passes the resolved page id', () {
    final navigator = build(
      pageIdOfOtherNote: (note, page) => '$note-page-$page',
    );

    navigator.navigate(const NoteNoteLink('other', page: 3));
    navigator.navigate(const NoteNoteLink('other'));

    expect(calls, ['note other other-page-3', 'note other null']);
  });

  test('openNoteAtPage keeps a page number nothing can resolve', () {
    final navigator = NoteLinkNavigator(
      pageOrder: () => order,
      goToPage: (page) => calls.add('page $page'),
      openNote: (note, page) => calls.add('note $note $page'),
      openUrl: (url) => calls.add('url $url'),
      pageIdOfOtherNote: (note, page) => page == 1 ? 'first' : null,
      openNoteAtPage: (note, page) => calls.add('at $note #$page'),
    );

    navigator
      ..navigate(const NoteNoteLink('other', page: 7))
      ..navigate(const NoteNoteLink('other', page: 1))
      ..navigate(const NoteNoteLink('other'));

    expect(calls, ['at other #7', 'note other first', 'note other null']);
  });

  test('without a resolver the page id is null', () {
    build().navigate(const NoteNoteLink('other', page: 3));

    expect(calls, ['note other null']);
  });

  test('links to the open note stay in the note', () {
    final navigator = build(currentNoteId: 'me');

    expect(navigator.navigate(const NoteNoteLink('me', page: 3)), isTrue);
    expect(navigator.navigate(const NoteNoteLink('me')), isTrue);
    expect(navigator.navigate(const NoteNoteLink('me', page: 9)), isFalse);

    expect(calls, ['page c', 'page a', 'unresolved note:me#page:9']);
  });

  test('URLs are opened, empty ones are unresolved', () {
    final navigator = build();

    expect(navigator.navigate(const NoteUrlLink('https://x.y')), isTrue);
    expect(navigator.navigate(const NoteUrlLink('  ')), isFalse);
    expect(navigator.navigate(const NoteNoteLink('')), isFalse);

    expect(calls.first, 'url https://x.y');
    expect(calls.length, 3);
  });

  test('only safe schemes reach openUrl by default', () {
    final navigator = build();

    // Links come from documents that may have been imported from anyone.
    for (final unsafe in [
      'file:///etc/passwd',
      'intent://scan/#Intent;scheme=zxing;end',
      'javascript://%0aalert(1)',
      'myapp://settings/delete-account',
      'content://com.android.contacts/contacts',
    ]) {
      expect(
        navigator.navigate(NoteLinkTarget.parse(unsafe)!),
        isFalse,
        reason: unsafe,
      );
    }
    expect(calls.where((call) => call.startsWith('url')), isEmpty);
    expect(calls, hasLength(5));

    calls.clear();
    for (final safe in [
      'HTTPS://x.y',
      'http://x.y',
      'mailto:a@b.c',
      'tel:+82101234',
    ]) {
      expect(
        navigator.navigate(NoteLinkTarget.parse(safe)!),
        isTrue,
        reason: safe,
      );
    }
    expect(calls, hasLength(4));
  });

  test('a host can allow its own scheme explicitly', () {
    final navigator = NoteLinkNavigator(
      pageOrder: () => const [],
      goToPage: (_) {},
      openNote: (_, _) {},
      openUrl: (url) => calls.add('url $url'),
      allowedSchemes: const {'https', 'myapp'},
    );

    expect(navigator.navigate(const NoteUrlLink('myapp://page')), isTrue);
    expect(navigator.navigate(const NoteUrlLink('http://x.y')), isFalse);
    expect(calls, ['url myapp://page']);
  });

  test('follows parsed wire targets', () {
    final navigator = build();

    for (final raw in ['page:1', 'note:n7#page:2', 'example.com']) {
      navigator.navigate(NoteLinkTarget.parse(raw)!);
    }

    expect(calls, ['page a', 'note n7 null', 'url https://example.com']);
  });

  test('onUnresolved is optional', () {
    final navigator = NoteLinkNavigator(
      pageOrder: () => const [],
      goToPage: (_) {},
      openNote: (_, _) {},
      openUrl: (_) {},
    );

    expect(navigator.navigate(const NotePageLink(1)), isFalse);
  });
}
