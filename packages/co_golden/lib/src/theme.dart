import 'dart:ui' show Brightness;

import 'package:meta/meta.dart';

/// A named theme on the golden theme axis.
///
/// The theme type [T] is not tied to Material: pass whatever your app root
/// consumes, for example a CoUI `ThemeData` or a Material `ThemeData`. The app
/// builder of the matrix decides how [data] is installed. [brightness] is also
/// reported to the test view as the platform brightness.
@immutable
final class GoldenTheme<T> {
  /// Creates a theme axis value.
  const GoldenTheme({
    required this.name,
    required this.data,
    this.brightness = Brightness.light,
  });

  /// Stable theme name used in test names, file names, and manifests.
  final String name;

  /// Theme object handed to the app builder.
  final T data;

  /// Brightness reported by the test view while this theme is active.
  final Brightness brightness;

  @override
  String toString() => 'GoldenTheme($name, ${brightness.name})';
}
