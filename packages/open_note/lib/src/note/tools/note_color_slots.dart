import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:open_note/src/note/core/core.dart';

/// The user's saved colours: ordered favourites and recently used colours.
///
/// Immutable: every change returns a new object (or this one when nothing
/// changes). Colours are kept as 8-bit ARGB values and each list holds a colour
/// once, with at most [max] entries. [max] is clamped into [minMax]–[maxMax].
///
/// JSON: `{"max": int, "favorites": [int ARGB, ...],
/// "recents": [int ARGB, ...]}` (recents newest first).
@immutable
class NoteColorSlots {
  /// Default [max].
  static const int defaultMax = 12;

  /// Smallest [max].
  static const int minMax = 1;

  /// Largest [max].
  static const int maxMax = 64;

  /// Most colours each list holds.
  final int max;

  /// Favourites in the user's order. Unmodifiable.
  final List<Color> favorites;

  /// Recently used colours, newest first. Unmodifiable.
  final List<Color> recents;

  /// Creates slots. Repeated colours and entries beyond [max] are dropped.
  NoteColorSlots({
    Iterable<Color> favorites = const [],
    Iterable<Color> recents = const [],
    int max = defaultMax,
  }) : this._(max.clamp(minMax, maxMax), favorites, recents);

  NoteColorSlots._(this.max, Iterable<Color> favorites, Iterable<Color> recents)
    : favorites = _unique(favorites, max),
      recents = _unique(recents, max);

  /// Reads the JSON form; never throws. Entries that are not numbers are
  /// skipped.
  factory NoteColorSlots.fromJson(Object? json) {
    final map = NoteJson.asMap(json) ?? <String, Object?>{};

    return NoteColorSlots(
      max: NoteJson.integer(map, 'max', defaultMax),
      favorites: _colorsOf(map, 'favorites'),
      recents: _colorsOf(map, 'recents'),
    );
  }

  /// Whether no more favourites can be added.
  bool get favoritesFull => favorites.length >= max;

  @override
  int get hashCode =>
      Object.hash(max, Object.hashAll(favorites), Object.hashAll(recents));

  /// Whether [color] is a favourite (same 32-bit ARGB value).
  bool isFavorite(Color color) => _indexOf(favorites, color) >= 0;

  /// Appends [color] to the favourites; no change when it already is one or
  /// the list is full (a favourite is never dropped silently).
  NoteColorSlots addFavorite(Color color) {
    if (isFavorite(color) || favoritesFull) return this;

    return copyWith(favorites: [...favorites, color]);
  }

  /// Removes [color] from the favourites.
  NoteColorSlots removeFavorite(Color color) {
    final index = _indexOf(favorites, color);
    if (index < 0) return this;

    return copyWith(favorites: [...favorites]..removeAt(index));
  }

  /// Removes [color] when it is a favourite, otherwise adds it.
  NoteColorSlots toggleFavorite(Color color) =>
      isFavorite(color) ? removeFavorite(color) : addFavorite(color);

  /// Moves the favourite at [oldIndex] so that it ends up at [newIndex]
  /// (clamped); an out of range [oldIndex] changes nothing.
  NoteColorSlots moveFavorite(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= favorites.length) return this;
    final target = newIndex.clamp(0, favorites.length - 1);
    if (target == oldIndex) return this;
    final next = [...favorites];
    next.insert(target, next.removeAt(oldIndex));

    return copyWith(favorites: next);
  }

  /// Puts [color] at the front of the recent colours, dropping the oldest
  /// beyond [max].
  NoteColorSlots addRecent(Color color) {
    if (_indexOf(recents, color) == 0) return this;

    return copyWith(recents: [color, ...recents]);
  }

  /// Forgets the recent colours.
  NoteColorSlots clearRecents() =>
      recents.isEmpty ? this : copyWith(recents: const []);

  /// A copy with the given values replaced.
  NoteColorSlots copyWith({
    Iterable<Color>? favorites,
    Iterable<Color>? recents,
    int? max,
  }) => NoteColorSlots(
    favorites: favorites ?? this.favorites,
    recents: recents ?? this.recents,
    max: max ?? this.max,
  );

  /// The JSON form described on the class.
  JsonMap toJson() => {
    'max': max,
    'favorites': [for (final color in favorites) NoteJson.colorToJson(color)],
    'recents': [for (final color in recents) NoteJson.colorToJson(color)],
  };

  @override
  bool operator ==(Object other) =>
      other is NoteColorSlots &&
      other.max == max &&
      listEquals(other.favorites, favorites) &&
      listEquals(other.recents, recents);

  @override
  String toString() => 'NoteColorSlots(${toJson()})';

  static List<Color> _unique(Iterable<Color> source, int max) {
    // A set literal keeps insertion order.
    final distinct = {for (final color in source) color.toARGB32()};

    return List<Color>.unmodifiable([
      for (final argb in distinct.take(max)) Color(argb),
    ]);
  }

  static List<Color> _colorsOf(JsonMap json, String key) => [
    for (final entry in NoteJson.list(json, key))
      if (entry is num && entry.isFinite)
        NoteJson.colorFromJson(entry, const Color(0x00000000)),
  ];

  static int _indexOf(List<Color> colors, Color color) {
    final argb = color.toARGB32();

    return colors.indexWhere((other) => other.toARGB32() == argb);
  }
}
