import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

const _bounds = Rect.fromLTWH(0, 0, 10, 10);

const _other = NoteUnknownObject(
  id: 'o',
  bounds: _bounds,
  unknownKind: 'sticky',
  payload: {},
);

List<NoteObject> _page() => [
  NoteMaskObject(id: 'a', bounds: _bounds),
  _other,
  NoteTapeObject(id: 'b', bounds: _bounds, revealed: true, locked: true),
  NoteMaskObject(
    id: 'c',
    bounds: _bounds,
    scope: NoteMaskScope.document,
    opacity: 0.5,
  ),
];

void main() {
  test('counts covers and revealed covers only', () {
    expect(NoteMaskOps.counts(_page()), (total: 3, revealed: 1));
    expect(NoteMaskOps.counts(const []), (total: 0, revealed: 0));
    expect(NoteMaskOps.counts(const [_other]), (total: 0, revealed: 0));
  });

  test('revealAll lifts every cover, locked ones too', () {
    final page = _page();

    final next = NoteMaskOps.revealAll(page);

    expect(NoteMaskOps.counts(next), (total: 3, revealed: 3));
    expect([for (final object in next) object.id], ['a', 'o', 'b', 'c']);
    expect(identical(next[1], page[1]), isTrue);
    expect(identical(next[2], page[2]), isTrue);
    expect(NoteMaskOps.counts(page), (total: 3, revealed: 1));
  });

  test('hideAll lays every cover back', () {
    final page = _page();

    final next = NoteMaskOps.hideAll(page);

    expect(NoteMaskOps.counts(next), (total: 3, revealed: 0));
    expect(identical(next[0], page[0]), isTrue);
    expect(next[1], same(_other));
  });

  test('clearAll removes masks and tapes and keeps the rest', () {
    expect(NoteMaskOps.clearAll(_page()), [_other]);
  });

  test('restyleAll sets fill and fill opacity of covers only', () {
    const fill = NoteMaskFill.dots(color: Color(0xFF00AA00));

    final next = NoteMaskOps.restyleAll(_page(), fill: fill, opacity: 3);

    final first = next[0] as NoteMaskObject;
    final tape = next[2] as NoteTapeObject;
    expect(first.fill, fill);
    expect(first.fillOpacity, 1);
    expect(tape.fill, fill);
    expect(tape.revealed, isTrue);
    expect(next[1], same(_other));
    expect(next[3].opacity, 0.5);
  });

  test('restyleAll with nothing to change keeps the instances', () {
    final page = _page();

    final same_ = NoteMaskOps.restyleAll(page);
    final ignored = NoteMaskOps.restyleAll(page, opacity: double.nan);

    for (var i = 0; i < page.length; i++) {
      expect(identical(same_[i], page[i]), isTrue);
      expect(identical(ignored[i], page[i]), isTrue);
    }
  });

  test('restyleAll can change only the opacity', () {
    final next = NoteMaskOps.restyleAll(_page(), opacity: 0.4);

    expect((next[0] as NoteMaskObject).fillOpacity, 0.4);
    expect((next[2] as NoteTapeObject).fillOpacity, 0.4);
    expect((next[2] as NoteTapeObject).fill, NoteTapeObject.defaultFill);
  });

  test('documentMasks lists the masks every page repeats', () {
    expect(
      [for (final mask in NoteMaskOps.documentMasks(_page())) mask.id],
      ['c'],
    );
  });

  test('isCover and isRevealed', () {
    final page = _page();

    expect(
      [for (final object in page) NoteMaskOps.isCover(object)],
      [true, false, true, true],
    );
    expect(NoteMaskOps.isRevealed(page[2]), isTrue);
    expect(NoteMaskOps.isRevealed(_other), isFalse);
  });
}
