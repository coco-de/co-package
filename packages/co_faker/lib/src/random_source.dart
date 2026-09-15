import 'dart:core';
import 'dart:math';
import 'dart:core' as core;

/// Small, testable random source shared by all faker modules.
class CoRandom {
  /// Creates a random source. A [seed] makes every generated value repeatable.
  ///
  /// When [seed] is omitted the stream is random, but streams created with
  /// [derive] still stay consistent with each other for the lifetime of this
  /// instance because they branch from one base seed.
  CoRandom([core.int? seed])
    : seed = seed,
      _baseSeed = seed ?? Random().nextInt(_maxSeed),
      _random = Random(seed);

  /// The seed given at construction, or `null` for a random stream.
  final core.int? seed;

  final core.int _baseSeed;
  final Random _random;

  /// Returns an integer in the inclusive range [min]..[max].
  core.int int({core.int min = 0, core.int max = 999}) {
    if (min > max) {
      throw ArgumentError.value(
        min,
        'min',
        'must be less than or equal to max',
      );
    }
    final range = max - min + 1;
    if (range <= _maxNextInt) {
      return min + _random.nextInt(range);
    }
    return min + (_random.nextDouble() * range).floor();
  }

  /// Returns a double in the inclusive range [min]..[max].
  core.double double({core.double min = 0, core.double max = 1}) {
    if (min > max) {
      throw ArgumentError.value(
        min,
        'min',
        'must be less than or equal to max',
      );
    }
    return min + (_random.nextDouble() * (max - min));
  }

  /// Returns a random boolean.
  core.bool bool() => _random.nextBool();

  /// Picks one item from [items].
  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    return items[_random.nextInt(items.length)];
  }

  /// Picks the item for [index] so that consecutive indexes cycle through
  /// [items] in order.
  ///
  /// Unlike [pick] this does not consume the random stream, which makes it
  /// useful for enum-like fields where every value must appear at least once
  /// in a fixture of `items.length` records or more.
  T pickBalanced<T>(List<T> items, core.int index) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'must not be negative');
    }
    return items[index % items.length];
  }

  /// Replaces each `#` with a random digit.
  String digits(String pattern) {
    return pattern.replaceAllMapped(
      RegExp('#'),
      (_) => int(min: 0, max: 9).toString(),
    );
  }

  /// Returns a random string from [alphabet].
  String string(core.int length, {String alphabet = _lettersAndDigits}) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length', 'must not be negative');
    }
    return List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }

  /// Creates an independent stream whose seed is derived from this source's
  /// base seed and [key].
  ///
  /// The derived stream does not share state with this source, so drawing
  /// values from one never changes the values produced by the other. The same
  /// base seed and [key] always produce the same derived stream.
  CoRandom derive(String key) => CoRandom(deriveSeed(_baseSeed, key));

  /// Combines [seed] and [key] into a stable, non-negative seed using the
  /// FNV-1a hash.
  static core.int deriveSeed(core.int seed, String key) {
    var hash = 0x811c9dc5;
    for (final code in '$seed|$key'.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  static const String _lettersAndDigits =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static const core.int _maxNextInt = 0x100000000;
  static const core.int _maxSeed = 0x7fffffff;
}
