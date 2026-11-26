import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/src/note/core/core.dart';
import 'package:open_note/src/note/tools/tools.dart';

const _red = Color(0xFFFF0000);
const _green = Color(0xFF00FF00);
const _blue = Color(0xFF0000FF);

List<int> _argb(List<Color> colors) => [
  for (final color in colors) color.toARGB32(),
];

void main() {
  group('NoteColorSlots', () {
    test('starts empty with 12 slots', () {
      final slots = NoteColorSlots();

      expect(slots.max, 12);
      expect(slots.favorites, isEmpty);
      expect(slots.recents, isEmpty);
      expect(slots.favoritesFull, isFalse);
    });

    test('clamps max and cuts the lists', () {
      final slots = NoteColorSlots(
        favorites: const [_red, _green, _red, _blue],
        recents: const [_blue, _blue, _green],
        max: 2,
      );

      expect(_argb(slots.favorites), [0xFFFF0000, 0xFF00FF00]);
      expect(_argb(slots.recents), [0xFF0000FF, 0xFF00FF00]);
      expect(NoteColorSlots(max: 0).max, 1);
      expect(NoteColorSlots(max: 500).max, 64);
    });

    test('lists are unmodifiable', () {
      final slots = NoteColorSlots(favorites: const [_red]);

      expect(() => slots.favorites.add(_blue), throwsUnsupportedError);
      expect(() => slots.recents.add(_blue), throwsUnsupportedError);
    });

    test('adds favourites in order, once, up to max', () {
      var slots = NoteColorSlots(max: 2).addFavorite(_red).addFavorite(_green);

      expect(slots.addFavorite(_red), same(slots));
      expect(slots.favoritesFull, isTrue);
      expect(slots.addFavorite(_blue), same(slots));
      expect(_argb(slots.favorites), _argb(const [_red, _green]));
      slots = slots.removeFavorite(_red).addFavorite(_blue);
      expect(_argb(slots.favorites), _argb(const [_green, _blue]));
    });

    test('toggles and removes favourites', () {
      final slots = NoteColorSlots().toggleFavorite(_red);

      expect(slots.isFavorite(_red), isTrue);
      expect(slots.toggleFavorite(_red).isFavorite(_red), isFalse);
      expect(slots.removeFavorite(_blue), same(slots));
    });

    test('treats colours with the same 32 bit value as one', () {
      final slots = NoteColorSlots(favorites: const [_red]);

      expect(
        slots.isFavorite(Color.from(alpha: 1, red: 1, green: 1e-6, blue: 0)),
        isTrue,
      );
      expect(slots.isFavorite(const Color(0x7FFF0000)), isFalse);
    });

    test('moves favourites to their final index', () {
      final slots = NoteColorSlots(favorites: const [_red, _green, _blue]);

      expect(
        _argb(slots.moveFavorite(0, 2).favorites),
        _argb(const [_green, _blue, _red]),
      );
      expect(
        _argb(slots.moveFavorite(2, -1).favorites),
        _argb(const [_blue, _red, _green]),
      );
      expect(slots.moveFavorite(1, 1), same(slots));
      expect(slots.moveFavorite(5, 0), same(slots));
    });

    test('keeps recent colours newest first, without repeats', () {
      var slots = NoteColorSlots(max: 3);
      for (final color in const [_red, _green, _red, _blue]) {
        slots = slots.addRecent(color);
      }

      expect(_argb(slots.recents), _argb(const [_blue, _red, _green]));
      expect(slots.addRecent(_blue), same(slots));
      final next = slots.addRecent(const Color(0xFF123456));
      expect(next.recents.length, 3);
      expect(_argb(next.recents).first, 0xFF123456);
      expect(next.clearRecents().recents, isEmpty);
      expect(NoteColorSlots().clearRecents().recents, isEmpty);
    });

    test('keeps favourites when recents change', () {
      final slots = NoteColorSlots(favorites: const [_red]).addRecent(_blue);

      expect(_argb(slots.favorites), [0xFFFF0000]);
    });

    test('round trips through JSON', () {
      final slots = NoteColorSlots(
        favorites: const [_red, Color(0x7F00FF00)],
        recents: const [_blue],
        max: 5,
      );
      final json = NoteJson.decodeMap(NoteJson.encode(slots.toJson()));

      final decoded = NoteColorSlots.fromJson(json);

      expect(decoded, slots);
      expect(decoded.hashCode, slots.hashCode);
      expect(slots.toJson(), {
        'max': 5,
        'favorites': [0xFFFF0000, 0x7F00FF00],
        'recents': [0xFF0000FF],
      });
      expect(slots.toString(), contains('max'));
    });

    test('never throws on malformed JSON', () {
      for (final json in <Object?>[null, 3, 'x', <Object?>[], {}]) {
        expect(NoteColorSlots.fromJson(json), NoteColorSlots());
      }
      final slots = NoteColorSlots.fromJson({
        'max': -2,
        'favorites': ['red', null, double.nan, 0xFF112233, 0xFF445566],
        'recents': 7,
      });

      expect(slots.max, 1);
      expect(_argb(slots.favorites), [0xFF112233]);
      expect(slots.recents, isEmpty);
    });

    test('has value equality', () {
      final a = NoteColorSlots(favorites: const [_red]);

      expect(a, NoteColorSlots(favorites: const [_red]));
      expect(a, isNot(NoteColorSlots(favorites: const [_blue])));
      expect(a, isNot(a.copyWith(max: 3)));
      expect(a.copyWith(recents: const [_blue]), isNot(a));
    });
  });
}
