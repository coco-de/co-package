import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/tools/tools.dart';

int? _parse(String input) => NoteColorUtils.parseHex(input)?.toARGB32();

void main() {
  group('NoteColorUtils.parseHex', () {
    test('reads #RGB as opaque', () {
      expect(_parse('#F80'), 0xFFFF8800);
      expect(_parse('abc'), 0xFFAABBCC);
    });

    test('reads #RRGGBB as opaque', () {
      expect(_parse('#336699'), 0xFF336699);
      expect(_parse('336699'), 0xFF336699);
    });

    test('reads #AARRGGBB with the alpha first', () {
      expect(_parse('#80FF0000'), 0x80FF0000);
      expect(_parse('00112233'), 0x00112233);
      expect(_parse('#FFFFFFFF'), 0xFFFFFFFF);
    });

    test('ignores case and surrounding spaces', () {
      expect(_parse('  #aAbBcC  '), 0xFFAABBCC);
      expect(_parse('FfF'), 0xFFFFFFFF);
    });

    test('rejects everything else', () {
      const bad = [
        '',
        '#',
        '#1',
        '#12',
        '#1234',
        '#12345',
        '#1234567',
        '#123456789',
        'GGG',
        '#12345G',
        '0x336699',
        '##336699',
        '33 66 99',
        '-123',
        '+12345',
      ];

      for (final input in bad) {
        expect(NoteColorUtils.parseHex(input), isNull, reason: input);
      }
    });
  });

  group('NoteColorUtils.toHex', () {
    test('drops the alpha unless asked for it', () {
      const color = Color(0x80ABCDEF);

      expect(NoteColorUtils.toHex(color), '#ABCDEF');
      expect(NoteColorUtils.toHex(color, alpha: true), '#80ABCDEF');
    });

    test('pads small channels', () {
      expect(NoteColorUtils.toHex(const Color(0x0000000A)), '#00000A');
      expect(
        NoteColorUtils.toHex(const Color(0x0000000A), alpha: true),
        '#0000000A',
      );
    });

    test('round trips through parseHex', () {
      for (final argb in [0xFF000000, 0x7FFFE400, 0x01020304, 0xFFFEFDFC]) {
        final hex = NoteColorUtils.toHex(Color(argb), alpha: true);

        expect(_parse(hex), argb);
      }
    });
  });
}
