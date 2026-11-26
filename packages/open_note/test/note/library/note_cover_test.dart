import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/library/library.dart';

void main() {
  group('NoteCoverCatalog', () {
    test('has at least twelve distinct built-in covers', () {
      const ids = NoteCoverCatalog.builtIn;

      expect(ids.length, greaterThanOrEqualTo(12));
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, contains(NoteCoverCatalog.defaultId));
      expect(ids.every(NoteCoverCatalog.contains), isTrue);
      expect(
        {for (final id in ids) NoteCoverCatalog.designOf(id)},
        hasLength(ids.length),
        reason: 'every id needs its own look',
      );
    });

    test('draws unknown ids like the default', () {
      final fallback = NoteCoverCatalog.designOf(NoteCoverCatalog.defaultId);

      expect(NoteCoverCatalog.designOf('from-the-future'), fallback);
      expect(NoteCoverCatalog.designOf(null), fallback);
      expect(NoteCoverCatalog.contains('from-the-future'), isFalse);
      expect(NoteCoverCatalog.contains(null), isFalse);
    });

    test('resolves colour and image covers', () {
      const fill = Color(0xFF123456);

      expect(
        NoteCoverCatalog.resolve(const NoteCover.solid(fill)),
        NoteCoverDesign.solid(fill),
      );
      expect(
        NoteCoverCatalog.resolve(const NoteCover.picture('a.png')),
        NoteCoverCatalog.imagePlaceholder,
      );
      expect(
        NoteCoverCatalog.resolve(const NoteCover.builtIn('forest')),
        NoteCoverCatalog.designOf('forest'),
      );
    });
  });

  group('NoteCover', () {
    test('the standard cover is the default built-in on A4 portrait', () {
      expect(NoteCover.standard.kind, NoteCoverKind.builtin);
      expect(NoteCover.standard.builtinId, NoteCoverCatalog.defaultId);
      expect(NoteCover.standard.pageSize, NotePageSize.a4);
      expect(NoteCover.standard.aspectRatio, closeTo(595 / 842, 1e-9));
    });

    test('orientation wins over the order of width and height', () {
      const turned = NoteCover.builtIn(
        'ocean',
        orientation: NotePageOrientation.landscape,
      );
      const upright = NoteCover.builtIn('ocean', size: NotePageSize(842, 595));

      expect(turned.pageSize, const NotePageSize(842, 595));
      expect(turned.aspectRatio, greaterThan(1));
      expect(upright.pageSize, NotePageSize.a4);
    });

    test('round-trips every kind through JSON', () {
      const covers = [
        NoteCover.builtIn('sunset', size: NotePageSize.letter),
        NoteCover.solid(Color(0x80FF8800), size: NotePageSize.a5),
        NoteCover.picture(
          '/tmp/cover.png',
          orientation: NotePageOrientation.landscape,
        ),
      ];

      for (final cover in covers) {
        final text = NoteJson.encode(cover.toJson());

        expect(NoteCover.fromJson(NoteJson.decodeMap(text)), cover);
      }
    });

    test('writes only the field its kind uses', () {
      final json = const NoteCover.solid(Color(0xFF000000)).toJson();

      expect(
        json.keys,
        unorderedEquals(['kind', 'color', 'size', 'orientation']),
      );
    });

    test('does not save fields its kind does not use', () {
      const cover = NoteCover(
        kind: NoteCoverKind.builtin,
        builtinId: 'plum',
        color: Color(0xFF000000),
        imageSource: 'unused.png',
      );

      expect(
        cover.toJson().keys,
        unorderedEquals(['kind', 'builtinId', 'size', 'orientation']),
      );
    });

    test('falls back to a built-in cover on malformed input', () {
      for (final value in [null, 42, 'ocean', <Object?>[]]) {
        expect(NoteCover.fromJson(value), NoteCover.standard);
      }
      expect(NoteCover.fromJson(<String, Object?>{}), NoteCover.standard);
      expect(
        NoteCover.fromJson({'kind': 'color'}),
        NoteCover.standard,
        reason: 'a colour cover without a colour',
      );
      expect(
        NoteCover.fromJson({'kind': 'color', 'color': 'red'}),
        NoteCover.standard,
      );
      expect(
        NoteCover.fromJson({'kind': 'image', 'imageSource': ''}),
        NoteCover.standard,
      );
      expect(
        NoteCover.fromJson({'kind': 'hologram', 'builtinId': 'plum'}),
        const NoteCover.builtIn('plum'),
      );
    });

    test('keeps unknown built-in ids so a newer cover is not lost', () {
      final cover = NoteCover.fromJson({
        'kind': 'builtin',
        'builtinId': 'aurora',
      });

      expect(cover.builtinId, 'aurora');
      expect(cover.toJson()['builtinId'], 'aurora');
    });

    test('repairs a bad size and derives a missing orientation', () {
      expect(NoteCover.fromJson({'size': 'huge'}).size, NotePageSize.a4);
      expect(
        NoteCover.fromJson({
          'size': {'w': 800, 'h': 600},
        }).orientation,
        NotePageOrientation.landscape,
      );
      expect(
        NoteCover.fromJson({
          'size': {'w': 800, 'h': 600},
          'orientation': 'portrait',
        }).pageSize,
        const NotePageSize(600, 800),
      );
    });

    test('copyWith keeps only the payload of the resulting kind', () {
      const base = NoteCover.builtIn('mint', size: NotePageSize.a5);
      final painted = base.copyWith(
        kind: NoteCoverKind.color,
        color: const Color(0xFF00FF00),
      );

      expect(
        painted,
        const NoteCover.solid(Color(0xFF00FF00), size: NotePageSize.a5),
      );
      expect(painted.builtinId, isNull);
      expect(base.copyWith(), base);
      expect(
        painted.copyWith(kind: NoteCoverKind.builtin).builtinId,
        NoteCoverCatalog.defaultId,
      );
    });

    test('equality and hash code cover every field', () {
      const a = NoteCover.picture('one.png');

      expect(a, const NoteCover.picture('one.png'));
      expect(a.hashCode, const NoteCover.picture('one.png').hashCode);
      expect(a, isNot(const NoteCover.picture('two.png')));
      expect(a, isNot(a.copyWith(size: NotePageSize.square)));
      expect(a, isNot(a.copyWith(orientation: NotePageOrientation.landscape)));
    });

    test('asserts that each kind has its payload', () {
      expect(
        () => NoteCover(kind: NoteCoverKind.color),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => NoteCover(kind: NoteCoverKind.image),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => NoteCover(kind: NoteCoverKind.builtin),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
