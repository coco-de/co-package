import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/style/style.dart';

void main() {
  group('NoteShapeStyle', () {
    test('has plain defaults', () {
      final style = NoteShapeStyle();
      expect(style, NoteShapeStyle.plain);
      expect(style.fillColor, isNull);
      expect(style.fillOpacity, 1);
      expect(style.strokeOpacity, 1);
      expect(style.cornerRadius, 0);
      expect(style.lineStyle, NoteLineStyle.solid);
      expect(style.headStyle, NoteShapeHeadStyle.triangle);
      expect(NoteShapeStyle.plain.encode(), '{}');
    });

    test('clamps numbers and ignores non-finite ones', () {
      final style = NoteShapeStyle(
        fillOpacity: 3,
        strokeOpacity: -1,
        cornerRadius: 1e9,
      );
      expect(style.fillOpacity, 1);
      expect(style.strokeOpacity, 0);
      expect(style.cornerRadius, NoteShapeStyle.maxCornerRadius);
      final odd = NoteShapeStyle(
        fillOpacity: double.nan,
        cornerRadius: double.infinity,
      );
      expect(odd, NoteShapeStyle.plain);
    });

    test('decode(encode(x)) == x', () {
      final lines = [
        NoteLineStyle.solid,
        NoteLineStyle.of(NoteLineStyleKind.dotted),
        NoteLineStyle(kind: NoteLineStyleKind.double, doubleGap: 0.1 + 0.2),
      ];
      const colors = <Color?>[
        null,
        Color(0xFF123456),
        Color(0x80FF0000),
        Color.from(alpha: 0.4, red: 0.123, green: 0.456, blue: 0.789),
      ];
      for (final fill in colors) {
        for (final line in lines) {
          for (final head in NoteShapeHeadStyle.values) {
            for (final opacity in [0.0, 1 / 3, 1.0]) {
              final style = NoteShapeStyle(
                fillColor: fill,
                fillOpacity: opacity,
                strokeOpacity: 1 - opacity,
                cornerRadius: opacity * 12.5,
                lineStyle: line,
                headStyle: head,
              );
              expect(NoteShapeStyle.decode(style.encode()), style);
              expect(NoteShapeStyle.fromJson(style.toJson()), style);
            }
          }
        }
      }
    });

    test('colours are stored with 8 bits per channel', () {
      final style = NoteShapeStyle(
        fillColor: const Color.from(
          alpha: 0.4,
          red: 0.123,
          green: 0.456,
          blue: 0.789,
        ),
      );
      expect(style.fillColor, Color(style.fillColor!.toARGB32()));
    });

    test('malformed strings read as the default and never throw', () {
      final inputs = <String?>[
        null,
        '',
        '{',
        '}',
        '[]',
        '"x"',
        '12',
        'null',
        'solid',
        '{"fillColor":"red"}',
        '{"fillColor":1e999}',
        '{"fillOpacity":"high","cornerRadius":[]}',
        '{"lineStyle":42,"headStyle":"banana"}',
        '{"unknown":true}',
        '[' * 100000,
        '{"a":' * 20000,
      ];
      for (final input in inputs) {
        expect(
          NoteShapeStyle.decode(input),
          NoteShapeStyle.plain,
          reason: '$input',
        );
      }
      expect(NoteShapeStyle.decode('{"fillColor":1e300}').fillColor, isNotNull);
      expect(NoteShapeStyle.decode('{"cornerRadius":-5}').cornerRadius, 0);
      expect(
        NoteShapeStyle.decode('{"lineStyle":"dashed:2:3"}').lineStyle,
        NoteLineStyle.decode('dashed:2:3'),
      );
    });

    test('copyWith replaces and clears', () {
      final style = NoteShapeStyle(
        fillColor: const Color(0xFF00FF00),
        cornerRadius: 4,
      );
      expect(style.copyWith(), style);
      expect(style.copyWith(clearFillColor: true).fillColor, isNull);
      expect(style.copyWith(cornerRadius: 9).cornerRadius, 9);
      expect(
        style.copyWith(headStyle: NoteShapeHeadStyle.dot).headStyle,
        NoteShapeHeadStyle.dot,
      );
    });

    test('equality and hashCode', () {
      final a = NoteShapeStyle(cornerRadius: 3);
      final b = NoteShapeStyle(cornerRadius: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(NoteShapeStyle(cornerRadius: 4)));
      expect(a.toString(), 'NoteShapeStyle({"cornerRadius":3.0})');
    });
  });
}
