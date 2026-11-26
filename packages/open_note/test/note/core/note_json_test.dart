import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/note_json.dart';
import 'package:open_note/src/note/core/note_page_size.dart';

enum _Shade { light, dark }

void main() {
  group('NoteJson readers', () {
    test('return the fallback for missing or wrongly typed keys', () {
      final json = <String, Object?>{'a': 1, 'b': 'x', 'c': null};

      expect(NoteJson.string(json, 'a', 'fb'), 'fb');
      expect(NoteJson.string(json, 'b'), 'x');
      expect(NoteJson.stringOrNull(json, 'a'), isNull);
      expect(NoteJson.integer(json, 'b', 7), 7);
      expect(NoteJson.number(json, 'missing', 1.5), 1.5);
      expect(NoteJson.boolean(json, 'a', true), isTrue);
      expect(NoteJson.list(json, 'a'), isEmpty);
      expect(NoteJson.map(json, 'a'), isEmpty);
    });

    test('numbers accept ints and doubles but not NaN', () {
      expect(NoteJson.integer({'n': 3.9}, 'n'), 3);
      expect(NoteJson.number({'n': 2}, 'n'), 2.0);
      expect(NoteJson.number({'n': double.nan}, 'n', 9), 9);
    });

    test('mapList drops entries that are not objects', () {
      final json = <String, Object?>{
        'xs': [
          {'k': 1},
          'nope',
          {'k': 2},
        ],
      };

      expect(NoteJson.mapList(json, 'xs').map((m) => m['k']), [1, 2]);
    });

    test('asMap stringifies keys of a dynamic map', () {
      expect(NoteJson.asMap(<dynamic, dynamic>{1: 'a'}), {'1': 'a'});
      expect(NoteJson.asMap('x'), isNull);
    });

    test('enumByName falls back for unknown names', () {
      expect(
        NoteJson.enumByName(_Shade.values, 'dark', _Shade.light),
        _Shade.dark,
      );
      expect(
        NoteJson.enumByName(_Shade.values, 'neon', _Shade.light),
        _Shade.light,
      );
      expect(NoteJson.enumByName(_Shade.values, 3, _Shade.light), _Shade.light);
    });

    test('colors round-trip through 32-bit ARGB', () {
      const color = Color(0x80123456);

      expect(
        NoteJson.colorFromJson(
          NoteJson.colorToJson(color),
          const Color(0x00000000),
        ),
        color,
      );
      expect(
        NoteJson.colorFromJson('x', const Color(0xFF00FF00)),
        const Color(0xFF00FF00),
      );
    });

    test('rect and offset round-trip and reject malformed values', () {
      const rect = Rect.fromLTWH(1, 2, 30, 40);

      expect(NoteJson.rectFromJson(NoteJson.rectToJson(rect)), rect);
      expect(NoteJson.rectFromJson({'x': 1}, rect), rect);
      expect(
        NoteJson.offsetFromJson(NoteJson.offsetToJson(const Offset(3, 4))),
        const Offset(3, 4),
      );
      expect(
        NoteJson.offsetFromJson('?', const Offset(9, 9)),
        const Offset(9, 9),
      );
    });

    test('decodeMap returns null for invalid or non-object JSON', () {
      expect(NoteJson.decodeMap('{"a":1}'), {'a': 1});
      expect(NoteJson.decodeMap('[1]'), isNull);
      expect(NoteJson.decodeMap('{oops'), isNull);
      expect(NoteJson.decodeMap(''), isNull);
      expect(NoteJson.decodeMap(null), isNull);
    });
  });

  group('NotePageSize', () {
    test('orientation and rotation', () {
      expect(NotePageSize.a4.orientation, NotePageOrientation.portrait);
      expect(NotePageSize.a4.rotated, const NotePageSize(842, 595));
      expect(
        NotePageSize.a4.rotated.orientation,
        NotePageOrientation.landscape,
      );
      expect(NotePageSize.square.orientation, NotePageOrientation.portrait);
    });

    test('withOrientation turns only when needed', () {
      expect(
        NotePageSize.a4.withOrientation(NotePageOrientation.portrait),
        NotePageSize.a4,
      );
      expect(
        NotePageSize.a4.withOrientation(NotePageOrientation.landscape),
        NotePageSize.a4.rotated,
      );
    });

    test('json round-trip and malformed fallback', () {
      expect(
        NotePageSize.fromJson(NotePageSize.letter.toJson()),
        NotePageSize.letter,
      );
      expect(NotePageSize.fromJson({'w': -1, 'h': 5}), NotePageSize.a4);
      expect(NotePageSize.fromJson(null), NotePageSize.a4);
    });

    test('value equality', () {
      expect(const NotePageSize(1, 2), const NotePageSize(1, 2));
      expect(
        const NotePageSize(1, 2).hashCode,
        const NotePageSize(1, 2).hashCode,
      );
      expect(const NotePageSize(1, 2) == const NotePageSize(2, 1), isFalse);
    });
  });
}
