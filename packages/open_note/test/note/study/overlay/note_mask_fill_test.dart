import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/study/overlay/overlay.dart';

void main() {
  const fills = [
    NoteMaskFill.solid(Color(0xFF112233)),
    NoteMaskFill.stripes(
      color: Color(0xFF445566),
      patternColor: Color(0x80FFFFFF),
    ),
    NoteMaskFill.dots(color: Color(0xFF778899)),
    NoteMaskFill.image('stickers/cover.png', color: Color(0xFF000000)),
  ];

  test('every kind survives a JSON round trip', () {
    for (final fill in fills) {
      final json = jsonDecode(jsonEncode(fill.toJson()));

      expect(NoteMaskFill.fromJson(json), fill, reason: fill.kind.name);
    }
  });

  test('kind names are the persisted ones', () {
    expect(
      [for (final kind in NoteMaskFillKind.values) kind.name],
      ['solid', 'stripes', 'dots', 'image'],
    );
  });

  test('malformed documents never throw and fall back', () {
    const fallback = NoteMaskFill.dots();

    expect(NoteMaskFill.fromJson(null), const NoteMaskFill());
    expect(NoteMaskFill.fromJson('red', fallback), fallback);
    expect(
      NoteMaskFill.fromJson({'kind': 'plaid', 'color': 'red'}),
      const NoteMaskFill(),
    );
  });

  test('an image without a source becomes solid', () {
    final fill = NoteMaskFill.fromJson({'kind': 'image', 'source': ''});

    expect(fill.kind, NoteMaskFillKind.solid);
    expect(fill.imageSource, isNull);
  });

  test('only an image fill with a source needs a picture', () {
    expect(fills.last.imageSource, 'stickers/cover.png');
    expect(fills.first.imageSource, isNull);
    expect(
      fills.last.copyWith(kind: NoteMaskFillKind.solid).imageSource,
      isNull,
    );
  });

  test('equality covers every field', () {
    const base = NoteMaskFill.stripes();

    expect(base, const NoteMaskFill.stripes());
    expect(base.hashCode, const NoteMaskFill.stripes().hashCode);
    expect(base, isNot(base.copyWith(color: const Color(0xFF010101))));
    expect(base, isNot(base.copyWith(patternColor: const Color(0xFF010101))));
    expect(base, isNot(base.copyWith(kind: NoteMaskFillKind.dots)));
    expect(base, isNot(base.copyWith(source: 'x')));
  });
}
