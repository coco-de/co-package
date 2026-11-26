import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/io/io.dart';

NotePdfTextRun _run(String text, double left, double top) =>
    NotePdfTextRun(text: text, rect: Rect.fromLTWH(left, top, 40, 12));

void main() {
  // 두 줄. 순서를 섞어 둔다(PDF 가 읽는 순서를 지키지 않기도 한다).
  final runs = [
    _run('quick', 60, 11),
    _run('brown', 10, 40),
    _run('The', 10, 10),
    _run('fox', 60, 41),
    const NotePdfTextRun(text: 'hidden', rect: Rect.zero),
  ];
  final ordered = NotePdfTextSelection.readingOrder(runs);

  test('reads top to bottom, left to right', () {
    expect(ordered.map((run) => run.text), ['The', 'quick', 'brown', 'fox']);
    expect(NotePdfTextSelection.textOf(ordered), 'The quick\nbrown fox');
  });

  test('selects from one point to another, either way round', () {
    List<String> between(Offset from, Offset to) => [
      for (final run in NotePdfTextSelection.between(ordered, from, to))
        run.text,
    ];

    expect(between(const Offset(70, 15), const Offset(20, 45)), [
      'quick',
      'brown',
    ]);
    expect(between(const Offset(20, 45), const Offset(70, 15)), [
      'quick',
      'brown',
    ]);
    // 줄 끝 너머로 끌면 그 줄의 끝까지.
    expect(between(const Offset(15, 16), const Offset(300, 18)), [
      'The',
      'quick',
    ]);
    // 한 점은 그 낱말 하나.
    expect(between(const Offset(65, 46), const Offset(65, 46)), ['fox']);
    // 글에서 먼 곳에서 시작하면 고르지 않는다.
    expect(between(const Offset(300, 300), const Offset(20, 15)), isEmpty);
    expect(
      NotePdfTextSelection.between(const [], Offset.zero, Offset.zero),
      [],
    );
  });
}
