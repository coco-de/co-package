import 'dart:core';
import 'dart:math';
import 'dart:core' as core;

/// Small, testable random source shared by all faker modules.
class CoRandom {
  /// Creates a random source. A [seed] makes every generated value repeatable.
  CoRandom([core.int? seed]) : _random = Random(seed);

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

  static const String _lettersAndDigits =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static const core.int _maxNextInt = 0x100000000;
}
