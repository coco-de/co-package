import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

const NoteTagRef _target = NoteTagRef(noteId: 'n1', pageId: 'p1');
const NoteTagRef _other = NoteTagRef(noteId: 'n2');
const NoteTagRef _third = NoteTagRef(noteId: 'n3');

void main() {
  late NoteTags tags;
  late List<String> tapped;

  setUp(() {
    tags = NoteTags()
      ..add('Math', _target)
      ..add('chemistry', _other)
      ..add('Physics', _other)
      ..add('physics', _third);
    tapped = [];
  });

  Future<void> pump(WidgetTester tester, {int maxSuggestions = 8}) => pumpPanel(
    tester,
    Align(
      alignment: Alignment.topCenter,
      child: NoteTagEditor(
        tags: tags,
        target: _target,
        onTagSelected: tapped.add,
        maxSuggestions: maxSuggestions,
      ),
    ),
  );

  final field = find.byType(EditableText);
  Finder chip(String tag) => byKeyName('note-tag-chip-$tag');
  Finder suggestion(String tag) => byKeyName('note-tag-suggestion-$tag');

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(field, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the tags and the other tags, most used first', (
    tester,
  ) async {
    await pump(tester);

    expect(chip('Math'), findsOneWidget);
    expect(suggestion('Math'), findsNothing);
    expect(
      tester.getTopLeft(suggestion('Physics')).dx,
      lessThan(tester.getTopLeft(suggestion('chemistry')).dx),
    );
  });

  testWidgets('narrows the suggestions while typing', (tester) async {
    await pump(tester);

    await tester.enterText(field, 'CHEM');
    await tester.pump();

    expect(suggestion('chemistry'), findsOneWidget);
    expect(suggestion('Physics'), findsNothing);
  });

  testWidgets('submitting adds a normalised tag and keeps the focus', (
    tester,
  ) async {
    await pump(tester);

    await submit(tester, '  선형   대수 ');

    expect(tags.tagsOf(_target), ['Math', '선형 대수']);
    expect(chip('선형 대수'), findsOneWidget);
    final editable = tester.widget<EditableText>(field);
    expect(editable.controller.text, isEmpty);
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('the first tag keeps the input and its focus', (tester) async {
    tags = NoteTags();
    await pump(tester);
    final before = tester.state<EditableTextState>(field);

    await submit(tester, 'first');
    await submit(tester, 'second');

    expect(tags.tagsOf(_target), ['first', 'second']);
    expect(tester.state<EditableTextState>(field), same(before));
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
  });

  testWidgets('submitting an existing tag only clears the input', (
    tester,
  ) async {
    await pump(tester);

    await submit(tester, 'MATH');

    expect(tags.tagsOf(_target), ['Math']);
    expect(tester.widget<EditableText>(field).controller.text, isEmpty);
  });

  testWidgets('a blank submit does nothing', (tester) async {
    await pump(tester);

    await submit(tester, '    ');

    expect(tags.tagsOf(_target), ['Math']);
  });

  testWidgets('tapping a suggestion applies it without taking the focus', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(suggestion('Physics'));
    await tester.pump();
    await tester.pump();

    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
    expect(tags.tagsOf(_target), ['Math', 'Physics']);
    expect(suggestion('Physics'), findsNothing);
    expect(chip('Physics'), findsOneWidget);
  });

  testWidgets('removes a tag and reports tapped tags', (tester) async {
    await pump(tester);

    await tester.tap(chip('Math'));
    expect(tapped, ['Math']);
    await tester.tap(byKeyName('note-tag-remove-Math'));
    await tester.pump();

    expect(tapped, ['Math']);
    expect(tags.tagsOf(_target), isEmpty);
    expect(tags.contains('math'), isFalse);
    expect(chip('Math'), findsNothing);
  });

  testWidgets('limits the suggestions', (tester) async {
    await pump(tester, maxSuggestions: 1);

    expect(suggestion('Physics'), findsOneWidget);
    expect(suggestion('chemistry'), findsNothing);
  });

  testWidgets('can show no suggestions at all', (tester) async {
    await pump(tester, maxSuggestions: 0);

    expect(suggestion('Physics'), findsNothing);
  });

  testWidgets('follows changes made elsewhere', (tester) async {
    await pump(tester);

    tags.add('exam', _target);
    await tester.pump();

    expect(chip('exam'), findsOneWidget);
  });

  testWidgets('labels the remove button for accessibility', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(find.bySemanticsLabel('Remove tag Math'), findsOneWidget);
    semantics.dispose();
  });
}
