import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/nav/nav.dart';

import 'nav_test_support.dart';

const Rect _half = Rect.fromLTRB(0.25, 0.25, 0.75, 0.5);

NoteExcerpts _build() =>
    NoteExcerpts(idFactory: countingIds('x'), clock: frozenClock);

void main() {
  group('NoteExcerpt', () {
    test('orders and clamps the rect into the page', () {
      expect(
        NoteExcerpt.normalizeRect(const Rect.fromLTRB(0.9, 1.4, -0.2, 0.1)),
        const Rect.fromLTRB(0, 0.1, 0.9, 1),
      );
      expect(
        NoteExcerpt.normalizeRect(const Rect.fromLTRB(double.nan, 0, 1, 1)),
        Rect.zero,
      );
      expect(
        NoteExcerpt.normalizeRect(
          const Rect.fromLTRB(0, 0, double.infinity, 1),
        ),
        Rect.zero,
      );
    });

    test('cleans label and note', () {
      final excerpt = NoteExcerpt(
        id: 'e',
        pageId: 'p',
        rect: _half,
        createdAt: kNow,
        label: '  중요   공식 ',
        note: '   ',
      );

      expect(excerpt.label, '중요 공식');
      expect(excerpt.note, isNull);
    });

    test('converts between page coordinates and fractions', () {
      const page = Size(600, 800);
      final rect = NoteExcerpt.fractionsOf(
        const Rect.fromLTRB(150, 200, 450, 400),
        page,
      );
      final excerpt = NoteExcerpt(
        id: 'e',
        pageId: 'p',
        rect: rect,
        createdAt: kNow,
      );

      expect(rect, _half);
      expect(excerpt.rectIn(page), const Rect.fromLTRB(150, 200, 450, 400));
      expect(NoteExcerpt.fractionsOf(rect, Size.zero), Rect.zero);
    });

    test('round-trips through JSON with awkward fractions', () {
      for (var step = 1; step <= 40; step++) {
        final excerpt = NoteExcerpt(
          id: 'e$step',
          pageId: 'p',
          rect: Rect.fromLTRB(
            step / 97,
            step / 113,
            step / 97 + 1 / 3,
            step / 113 + 0.1,
          ),
          createdAt: kNow,
          label: 'L',
          note: '메모',
          color: const Color(0x80FF8800),
        );
        final decoded = NoteExcerpt.fromJson(
          NoteJson.decodeMap(NoteJson.encode(excerpt.toJson())),
        );

        expect(decoded, excerpt, reason: 'step $step');
        expect(decoded.hashCode, excerpt.hashCode);
      }
    });

    test('keeps the colour at the 8-bit precision it is stored with', () {
      final excerpt = NoteExcerpt(
        id: 'e',
        pageId: 'p',
        rect: _half,
        createdAt: kNow,
        color: const Color(0xFFFFC107).withValues(alpha: 0.35),
      );

      expect(NoteExcerpt.fromJson(excerpt.toJson()), excerpt);
      expect(excerpt.color!.toARGB32(), 0x59FFC107);
    });

    test('omits absent optional values from JSON', () {
      final json = NoteExcerpt(
        id: 'e',
        pageId: 'p',
        rect: _half,
        createdAt: kNow,
      ).toJson();

      expect(json.keys, isNot(contains('label')));
      expect(json.keys, isNot(contains('note')));
      expect(json.keys, isNot(contains('color')));
    });

    test('fromJson rejects unusable entries and ignores bad options', () {
      final rect = NoteJson.rectToJson(_half);
      expect(NoteExcerpt.fromJson(null), isNull);
      expect(NoteExcerpt.fromJson({'id': 'e', 'pageId': 'p'}), isNull);
      expect(NoteExcerpt.fromJson({'pageId': 'p', 'rect': rect}), isNull);
      expect(NoteExcerpt.fromJson({'id': 'e', 'rect': rect}), isNull);
      expect(
        NoteExcerpt.fromJson({
          'id': 'e',
          'pageId': 'p',
          'rect': {'x': 2, 'y': 2, 'w': 1, 'h': 1},
        }),
        isNull,
      );
      final decoded = NoteExcerpt.fromJson({
        'id': 'e',
        'pageId': 'p',
        'rect': rect,
        'label': 5,
        'note': ['x'],
        'color': 'red',
      })!;

      expect(decoded.label, isNull);
      expect(decoded.note, isNull);
      expect(decoded.color, isNull);
    });

    test('copyWith can clear optional values', () {
      final excerpt = NoteExcerpt(
        id: 'e',
        pageId: 'p',
        rect: _half,
        createdAt: kNow,
        label: 'a',
        note: 'b',
        color: const Color(0xFF000000),
      );
      final cleared = excerpt.copyWith(
        clearLabel: true,
        clearNote: true,
        clearColor: true,
      );

      expect(excerpt.copyWith(), excerpt);
      expect(cleared.label, isNull);
      expect(cleared.note, isNull);
      expect(cleared.color, isNull);
    });
  });

  group('NoteExcerpts', () {
    test('add creates a clean excerpt and rejects unusable input', () {
      final excerpts = _build();
      final counter = NotifyCounter(excerpts);

      final added = excerpts.add(pageId: 'p1', rect: _half, label: 'Math')!;

      expect(added.id, 'x1');
      expect(added.createdAt, kNow);
      expect(excerpts.add(pageId: '', rect: _half), isNull);
      expect(excerpts.add(pageId: 'p1', rect: Rect.zero), isNull);
      expect(
        excerpts.add(pageId: 'p1', rect: const Rect.fromLTRB(2, 2, 3, 3)),
        isNull,
      );
      expect(excerpts.length, 1);
      expect(counter.count, 1);
    });

    test('update replaces by id and notifies only on change', () {
      final excerpts = _build();
      final added = excerpts.add(pageId: 'p1', rect: _half)!;
      final counter = NotifyCounter(excerpts);

      expect(excerpts.update(added), isFalse);
      expect(excerpts.update(added.copyWith(note: 'hi')), isTrue);
      expect(excerpts.update(added.copyWith(id: 'other')), isFalse);
      expect(excerpts.update(added.copyWith(rect: Rect.zero)), isFalse);
      expect(excerpts.byId(added.id)!.note, 'hi');
      expect(counter.count, 1);
    });

    test('remove and removePage', () {
      final excerpts = _build()
        ..add(pageId: 'p1', rect: _half)
        ..add(pageId: 'p2', rect: _half)
        ..add(pageId: 'p1', rect: _half);
      final counter = NotifyCounter(excerpts);

      expect(excerpts.remove('nope'), isFalse);
      expect(excerpts.remove('x2'), isTrue);
      expect(excerpts.removePage('p9'), 0);
      expect(excerpts.removePage('p1'), 2);
      expect(excerpts.isEmpty, isTrue);
      expect(counter.count, 2);
    });

    test('labels are counted case-insensitively with the first spelling', () {
      final excerpts = _build();
      for (final label in ['Physics', 'math', 'MATH', ' Math ', null]) {
        excerpts.add(pageId: 'p', rect: _half, label: label);
      }

      expect(excerpts.labels, {'math': 3, 'Physics': 1});
      expect(excerpts.labels.keys.toList(), ['math', 'Physics']);
      expect(excerpts.byLabel('mAtH').length, 3);
      expect(excerpts.byLabel(null).length, 1);
      expect(excerpts.byLabel('  ').length, 1);
      expect(excerpts.byLabel('none'), isEmpty);
      expect(() => excerpts.labels['x'] = 1, throwsUnsupportedError);
    });

    test('byPage keeps the insertion order', () {
      final excerpts = _build()
        ..add(pageId: 'p1', rect: const Rect.fromLTRB(0, 0.8, 1, 0.9))
        ..add(pageId: 'p2', rect: _half)
        ..add(pageId: 'p1', rect: const Rect.fromLTRB(0, 0.1, 1, 0.2));

      expect([for (final e in excerpts.byPage('p1')) e.id], ['x1', 'x3']);
    });

    test('search matches label and note, with Hangul substrings', () {
      final excerpts = _build()
        ..add(pageId: 'p', rect: _half, note: '미분 적분 노트')
        ..add(pageId: 'p', rect: _half, label: 'Linear Algebra')
        ..add(pageId: 'p', rect: _half, note: '확률');

      expect([for (final e in excerpts.search('적분')) e.id], ['x1']);
      expect([for (final e in excerpts.search('분 노')) e.id], ['x1']);
      expect([for (final e in excerpts.search('ALGEBRA')) e.id], ['x2']);
      expect(
        [for (final e in excerpts.search('  linear   alg ')) e.id],
        ['x2'],
      );
      expect(excerpts.search('없음'), isEmpty);
      expect(excerpts.search('  ').length, 3);
    });

    test('ordered goes by page, then top to bottom, then left to right', () {
      final excerpts = _build()
        ..add(pageId: 'gone', rect: _half)
        ..add(pageId: 'p2', rect: _half)
        ..add(pageId: 'p1', rect: const Rect.fromLTRB(0.6, 0.1, 0.9, 0.2))
        ..add(pageId: 'p1', rect: const Rect.fromLTRB(0.1, 0.5, 0.4, 0.6))
        ..add(pageId: 'p1', rect: const Rect.fromLTRB(0.1, 0.1, 0.4, 0.2));

      expect(
        [
          for (final e in excerpts.ordered(['p1', 'p2'])) e.id,
        ],
        ['x5', 'x3', 'x4', 'x2', 'x1'],
      );
    });

    test('round-trips through JSON and survives malformed input', () {
      final excerpts = _build()
        ..add(pageId: 'p1', rect: _half, label: 'a', note: 'b')
        ..add(pageId: 'p2', rect: _half, color: const Color(0xFF123456));
      final restored = NoteExcerpts.fromJson(
        NoteJson.decodeMap(NoteJson.encode(excerpts.toJson())),
      );

      expect(restored.items, excerpts.items);
      expect(NoteExcerpts.fromJson('x').isEmpty, isTrue);
      final partial = NoteExcerpts.fromJson({
        'excerpts': [
          excerpts.items.first.toJson(),
          excerpts.items.first.toJson(),
          {'id': 'bad'},
          12,
        ],
      });

      expect(partial.length, 1);
    });

    test('mutators do nothing after dispose', () {
      final excerpts = _build();
      final added = excerpts.add(pageId: 'p', rect: _half)!;
      excerpts.dispose();

      expect(excerpts.add(pageId: 'p', rect: _half), isNull);
      expect(excerpts.update(added.copyWith(note: 'x')), isFalse);
      expect(excerpts.remove(added.id), isFalse);
      expect(excerpts.removePage('p'), 0);
      expect(excerpts.length, 1);
    });
  });
}
