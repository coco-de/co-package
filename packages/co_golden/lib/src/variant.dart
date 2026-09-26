import 'dart:ui' show Brightness, Locale;

import 'package:flutter/foundation.dart';

import 'device.dart';
import 'naming.dart';
import 'theme.dart';

/// One resolved combination of the golden axes.
@immutable
final class GoldenVariant<T> {
  /// Creates a variant from one value of every axis.
  const GoldenVariant({
    required this.device,
    required this.theme,
    required this.locale,
    this.textScale = 1,
  });

  /// Device geometry and platform.
  final GoldenDevice device;

  /// Theme installed by the app builder.
  final GoldenTheme<T> theme;

  /// Locale reported by the test view and activated by the localization
  /// binding.
  final Locale locale;

  /// System text scale factor reported by the test view.
  final double textScale;

  /// Target platform of [device].
  TargetPlatform get platform => device.platform;

  /// Brightness of [theme].
  Brightness get brightness => theme.brightness;

  /// BCP 47 tag of [locale], for example `zh-Hans`.
  String get localeTag => locale.toLanguageTag();

  /// File name without extension: `phone__dark__en`, plus `__text-1.3` when
  /// the text scale is not 1.
  String get fileStem => [
    device.name,
    theme.name,
    goldenLocaleToken(locale),
    if (textScale != 1) 'text-${goldenScaleToken(textScale)}',
  ].join('__');

  /// Human-readable label used as the test name.
  String get label {
    final scale = textScale == 1
        ? ''
        : ' · text ${goldenScaleToken(textScale)}x';
    return '${device.name} · ${theme.name} · $localeTag$scale';
  }

  /// JSON description written to run manifests.
  Map<String, Object?> toJson() => {
    'device': device.toJson(),
    'theme': theme.name,
    'brightness': brightness.name,
    'locale': localeTag,
    'textScale': textScale,
    'platform': platform.name,
  };

  @override
  bool operator ==(Object other) =>
      other is GoldenVariant<T> &&
      other.device == device &&
      other.theme.name == theme.name &&
      other.locale == locale &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(device, theme.name, locale, textScale);

  @override
  String toString() => 'GoldenVariant($label)';
}
