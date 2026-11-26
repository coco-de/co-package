import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/data/model/protobuf/scribble.pb.dart';
import 'package:open_note/src/note/nav/nav.dart';

TextDrawable _box(
  String text,
  double x,
  double y, {
  double fontSize = 20,
  bool hidden = false,
}) => TextDrawable(text: text, x: x, y: y, fontSize: fontSize, hidden: hidden);

void main() {
  group('NotePageTextExtractor', () {
    test('reads top to bottom, then left to right', () {
      final scribble = Scribble(
        textDrawables: [
          _box('셋째', 50, 300),
          _box('둘째 오른쪽', 400, 100),
          _box('첫째', 400, 20),
          _box('둘째 왼쪽', 10, 100),
        ],
      );

      expect(NotePageTextExtractor.fromScribble(scribble), [
        '첫째',
        '둘째 왼쪽',
        '둘째 오른쪽',
        '셋째',
      ]);
    });

    test('treats nearly level boxes as one line', () {
      final scribble = Scribble(
        textDrawables: [
          _box('right', 300, 100),
          _box('left', 10, 108),
          _box('below', 0, 140),
        ],
      );

      expect(NotePageTextExtractor.fromScribble(scribble), [
        'left',
        'right',
        'below',
      ]);
    });

    test('starts a new line beyond half a font size', () {
      final scribble = Scribble(
        textDrawables: [
          _box('upper', 300, 100, fontSize: 10),
          _box('lower', 10, 106, fontSize: 10),
        ],
      );

      expect(NotePageTextExtractor.fromScribble(scribble), ['upper', 'lower']);
    });

    test('works without a font size', () {
      final scribble = Scribble(
        textDrawables: [
          TextDrawable(text: 'b', x: 90, y: 50),
          TextDrawable(text: 'a', x: 5, y: 56),
        ],
      );

      expect(NotePageTextExtractor.fromScribble(scribble), ['a', 'b']);
    });

    test('skips blank and hidden boxes and trims the text', () {
      final scribble = Scribble(
        textDrawables: [
          _box('  keep  ', 0, 0),
          _box('   ', 0, 40),
          _box('editing', 0, 80, hidden: true),
          _box('', 0, 120),
        ],
      );

      expect(NotePageTextExtractor.fromScribble(scribble), ['keep']);
      expect(NotePageTextExtractor.fromScribble(Scribble()), isEmpty);
    });

    test('feeds the search index', () {
      final index = NoteSearchIndex()
        ..indexPage(
          'n',
          'p',
          NotePageTextExtractor.fromScribble(
            Scribble(textDrawables: [_box('미분 적분 노트', 0, 0)]),
          ),
        );

      expect(index.search('적분').single.matchedText, '적분');
    });
  });

  test('NoopHandwritingIndexer recognises nothing', () async {
    const NoteHandwritingIndexer indexer = NoopHandwritingIndexer();

    expect(await indexer.recognize(Scribble()), isEmpty);
  });
}
