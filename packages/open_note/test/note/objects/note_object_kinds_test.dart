import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/objects/objects.dart';

const Rect bounds = Rect.fromLTWH(10, 20, 120, 80);

NoteObjectRegistry registry() {
  final result = NoteObjectRegistry();
  registerNoteObjects(result);

  return result;
}

/// Encodes to a JSON string and decodes through the registry, as a page load
/// does.
NoteObject reload(NoteObject object) =>
    registry().decode(jsonDecode(jsonEncode(object.toJson())))!;

/// Decodes a document with [payload] of [kind] over default base fields.
NoteObject decodePayload(String kind, Map<String, Object?> payload) =>
    registry().decode({
      'kind': kind,
      'id': 'x',
      'bounds': NoteJson.rectToJson(bounds),
      'payload': payload,
    })!;

void main() {
  const sticky = NoteStickyObject(
    id: 'x',
    bounds: bounds,
    text: 'note\nsecond line 한글',
    paperColor: Color(0xFF112233),
    textColor: Color(0xFF445566),
    fontSize: 18,
    shadow: false,
    rotation: 0.4,
    opacity: 0.5,
    locked: true,
  );
  const arrow = NoteArrowObject(
    id: 'x',
    bounds: bounds,
    start: Offset(0.1, 0.9),
    end: Offset(1, 0),
    color: Color(0xFF223344),
    width: 5,
    headStyle: NoteArrowCap.open,
    tailStyle: NoteArrowCap.triangle,
    dashed: true,
  );
  const link = NoteLinkObject(
    id: 'x',
    bounds: bounds,
    target: 'note:other#page:4',
    appearance: NoteLinkAppearance.underline,
    color: Color(0xFF334455),
  );
  const sticker = NoteStickerObject(
    id: 'x',
    bounds: bounds,
    source: '/stickers/cat.png',
    flipHorizontal: true,
  );
  const all = <NoteObject>[sticky, arrow, link, sticker];

  test('registerNoteObjects registers exactly the four kinds', () {
    expect(
      registry().kinds,
      unorderedEquals(['sticky', 'arrow', 'link', 'sticker']),
    );
    expect(all.map((object) => object.kind), [
      'sticky',
      'arrow',
      'link',
      'sticker',
    ]);
  });

  for (final object in all) {
    group(object.kind, () {
      test('survives a JSON round trip unchanged', () {
        final loaded = reload(object);

        expect(loaded, object);
        expect(loaded.hashCode, object.hashCode);
        expect(loaded.toJson(), object.toJson());
      });

      test('withBase changes only the shared fields', () {
        final moved = object.withBase(
          bounds: const Rect.fromLTWH(1, 2, 30, 40),
          rotation: 1,
          opacity: 0.25,
          locked: true,
        );

        expect(moved.runtimeType, object.runtimeType);
        expect(moved.id, object.id);
        expect(moved.bounds, const Rect.fromLTWH(1, 2, 30, 40));
        expect(moved.rotation, 1);
        expect(moved.opacity, 0.25);
        expect(moved.locked, isTrue);
        expect(moved.payloadToJson(), object.payloadToJson());
        expect(object.withBase(), object);
      });

      test('withId changes only the id', () {
        final renamed = (object as NoteReidentifiableObject).withId('y');

        expect(renamed.id, 'y');
        expect(renamed, isNot(object));
        expect(renamed.toJson(), {...object.toJson(), 'id': 'y'});
      });

      test('decodes an empty payload with its defaults', () {
        final empty = decodePayload(object.kind, {});

        expect(empty.runtimeType, object.runtimeType);
        expect(empty.bounds, bounds);
        expect(reload(empty), empty);
      });

      test('never throws on a hostile payload', () {
        final payload = {
          for (final key in object.payloadToJson().keys) key: [null, {}],
        };

        expect(
          decodePayload(object.kind, payload),
          decodePayload(object.kind, {}),
        );
      });

      test('mirrors negative stored sizes', () {
        final decoded = registry().decode({
          ...object.toJson(),
          'bounds': {'x': 50, 'y': 60, 'w': -30, 'h': -20},
        })!;

        expect(decoded.bounds, const Rect.fromLTRB(20, 40, 50, 60));
      });
    });
  }

  test('equality notices every payload field', () {
    final changes = <NoteObject>[
      sticky.copyWith(text: 'other'),
      sticky.copyWith(paperColor: const Color(0xFF000000)),
      sticky.copyWith(textColor: const Color(0xFF000000)),
      sticky.copyWith(fontSize: 19),
      sticky.copyWith(shadow: true),
    ];
    for (final changed in changes) {
      expect(changed, isNot(sticky));
    }
    for (final changed in [
      arrow.copyWith(start: Offset.zero),
      arrow.copyWith(end: Offset.zero),
      arrow.copyWith(color: const Color(0xFF000000)),
      arrow.copyWith(width: 6),
      arrow.copyWith(headStyle: NoteArrowCap.none),
      arrow.copyWith(tailStyle: NoteArrowCap.none),
      arrow.copyWith(dashed: false),
    ]) {
      expect(changed, isNot(arrow));
    }
    expect(link.copyWith(target: 'page:1'), isNot(link));
    expect(link.copyWith(appearance: NoteLinkAppearance.hidden), isNot(link));
    expect(link.copyWith(color: const Color(0xFF000000)), isNot(link));
    expect(sticker.copyWith(source: 'b'), isNot(sticker));
    expect(sticker.copyWith(flipHorizontal: false), isNot(sticker));
    expect(sticker, isNot(link));
  });

  group('sticky', () {
    test('has the documented defaults', () {
      const plain = NoteStickyObject(id: 'x', bounds: bounds);

      expect(plain.text, '');
      expect(plain.paperColor, NoteStickyObject.defaultPaperColor);
      expect(plain.fontSize, 14);
      expect(plain.shadow, isTrue);
    });

    test('clamps the font size', () {
      NoteStickyObject sized(Object value) =>
          decodePayload('sticky', {'fontSize': value}) as NoteStickyObject;

      expect(sized(1).fontSize, NoteStickyObject.minFontSize);
      expect(sized(1000).fontSize, NoteStickyObject.maxFontSize);
      expect(sized('big').fontSize, 14);
      expect(
        const NoteStickyObject(
          id: 'x',
          bounds: bounds,
          fontSize: 1,
        ).textStyle.fontSize,
        NoteStickyObject.minFontSize,
      );
    });

    test('is written with the documented keys', () {
      expect(sticky.payloadToJson(), {
        'text': 'note\nsecond line 한글',
        'paperColor': 0xFF112233,
        'textColor': 0xFF445566,
        'fontSize': 18.0,
        'shadow': false,
      });
    });
  });

  group('arrow', () {
    test('clamps fractions and width, and ignores unknown caps', () {
      final decoded =
          decodePayload('arrow', {
                'start': {'x': -3, 'y': 9},
                'end': {'x': 0.5, 'y': 0.25},
                'width': 500,
                'headStyle': 'rocket',
                'tailStyle': 'open',
              })
              as NoteArrowObject;

      expect(decoded.start, const Offset(0, 1));
      expect(decoded.end, const Offset(0.5, 0.25));
      expect(decoded.width, NoteArrowObject.maxWidth);
      expect(decoded.headStyle, NoteArrowCap.triangle);
      expect(decoded.tailStyle, NoteArrowCap.open);
      expect(
        (decodePayload('arrow', {'width': 0}) as NoteArrowObject).width,
        NoteArrowObject.minWidth,
      );
    });

    test('is written with the documented keys', () {
      expect(arrow.payloadToJson(), {
        'start': {'x': 0.1, 'y': 0.9},
        'end': {'x': 1.0, 'y': 0.0},
        'color': 0xFF223344,
        'width': 5.0,
        'headStyle': 'open',
        'tailStyle': 'triangle',
        'dashed': true,
      });
    });

    test('fromPoints keeps both ends, in either direction', () {
      for (final (from, to) in const [
        (Offset(10, 10), Offset(110, 60)),
        (Offset(110, 60), Offset(10, 10)),
        (Offset(110, 10), Offset(10, 60)),
      ]) {
        final made = NoteArrowObject.fromPoints(id: 'a', from: from, to: to);

        expect(made.bounds, const Rect.fromLTRB(10, 10, 110, 60));
        expect(made.startPoint, from);
        expect(made.endPoint, to);
      }
    });

    test('fromPoints gives a flat line a minimum height', () {
      final made = NoteArrowObject.fromPoints(
        id: 'a',
        from: const Offset(0, 50),
        to: const Offset(100, 50),
        dashed: true,
        width: 6,
      );

      expect(made.bounds, const Rect.fromLTRB(0, 44, 100, 56));
      expect(made.start, const Offset(0, 0.5));
      expect(made.end, const Offset(1, 0.5));
      expect(made.dashed, isTrue);
      expect(made.width, 6);
    });

    test('draws a clamped width even from bad constructor values', () {
      double effective(double width) =>
          NoteArrowObject(id: 'a', bounds: bounds, width: width).effectiveWidth;

      expect(effective(-4), NoteArrowObject.minWidth);
      expect(effective(1e9), NoteArrowObject.maxWidth);
      expect(effective(double.nan), NoteArrowObject.defaultWidth);
    });
  });

  group('link', () {
    test('linkTarget parses the wire form', () {
      NoteLinkTarget? targetOf(String target) =>
          NoteLinkObject(id: 'l', bounds: bounds, target: target).linkTarget;

      expect(targetOf('page:3'), const NotePageLink(3));
      expect(targetOf('note:n1'), const NoteNoteLink('n1'));
      expect(targetOf('note:n1#page:2'), const NoteNoteLink('n1', page: 2));
      expect(
        targetOf('https://example.com'),
        const NoteUrlLink('https://example.com'),
      );
      expect(targetOf('example.com'), const NoteUrlLink('https://example.com'));
      expect(targetOf('  '), isNull);
      expect(targetOf('note:'), isNull);
    });

    test('keeps an unknown appearance readable as an outline', () {
      final decoded =
          decodePayload('link', {'appearance': 'glow', 'target': 'page:2'})
              as NoteLinkObject;

      expect(decoded.appearance, NoteLinkAppearance.outline);
      expect(decoded.target, 'page:2');
    });

    test('is written with the documented keys', () {
      expect(link.payloadToJson(), {
        'target': 'note:other#page:4',
        'appearance': 'underline',
        'color': 0xFF334455,
      });
    });
  });

  group('sticker', () {
    test('has no link target and is written with the documented keys', () {
      expect(sticker.linkTarget, isNull);
      expect(sticker.payloadToJson(), {
        'source': '/stickers/cat.png',
        'flipHorizontal': true,
      });
    });
  });

  test('strings name known kinds and fall back for others', () {
    const strings = NoteObjectsStrings();

    expect(strings.nameOf('sticky'), 'Sticky note');
    expect(strings.nameOf('table'), 'Object (table)');
    expect(
      const NoteObjectsStrings(kindNames: {'table': 'Table'}).nameOf('table'),
      'Table',
    );
  });
}
