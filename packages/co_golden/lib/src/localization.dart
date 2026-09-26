import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show Widget;
import 'package:slang/slang.dart';

/// Switches the app's own localization layer for each variant.
///
/// Flutter's `Localizations` follow the locale that the app builder passes to
/// its app widget. Apps that keep a separate translation singleton (such as
/// Slang's `LocaleSettings`) also need that singleton switched before the
/// widget is built, and restored afterwards so variants do not leak into each
/// other. [activate] runs before the build and [restore] after capture, even
/// when the variant fails. [wrap] places a provider widget above the app.
abstract base class GoldenLocalization {
  /// Creates a localization binding.
  const GoldenLocalization();

  /// A binding that switches nothing. Use it when the app reads its strings
  /// from Flutter's `Localizations` only.
  static const GoldenLocalization none = _NoGoldenLocalization();

  /// Activates [locale] before the variant is built.
  FutureOr<void> activate(Locale locale);

  /// Restores the locale that was active before [activate].
  FutureOr<void> restore();

  /// Wraps the app widget, for example with a translation provider.
  Widget wrap(Widget child) => child;
}

final class _NoGoldenLocalization extends GoldenLocalization {
  const _NoGoldenLocalization();

  @override
  void activate(Locale locale) {}

  @override
  void restore() {}
}

/// Switches a Slang `LocaleSettings` singleton per variant.
///
/// ```dart
/// final localization = SlangGoldenLocalization(
///   settings: LocaleSettings.instance,
///   provider: (child) => TranslationProvider(child: child),
/// );
/// ```
///
/// A locale that the app does not ship fails the variant instead of falling
/// back silently: Slang resolves unknown tags to the base locale, which would
/// otherwise produce an image labelled `en` that shows the base language.
final class SlangGoldenLocalization<
  E extends BaseAppLocale<E, T>,
  T extends BaseTranslations<E, T>
>
    extends GoldenLocalization {
  /// Binds the generated `LocaleSettings.instance` of an app. [provider]
  /// wraps the app, usually with the generated `TranslationProvider`.
  SlangGoldenLocalization({required this.settings, this.provider});

  /// The app's Slang settings singleton.
  final BaseLocaleSettings<E, T> settings;

  /// Builds the translation provider above the app, or `null` for none.
  final Widget Function(Widget child)? provider;

  E? _previous;

  @override
  void activate(Locale locale) {
    _previous ??= settings.currentLocale;
    final requested = locale.toLanguageTag();
    final applied = settings.setLocaleRawSync(requested);
    if (!_matches(applied, locale)) {
      restore();
      throw StateError(
        'Slang does not ship the locale "$requested" (it resolved to '
        '"${applied.languageTag}"). Add the locale to the app or remove it '
        'from the golden coverage.',
      );
    }
  }

  @override
  void restore() {
    final previous = _previous;
    if (previous == null) {
      return;
    }
    _previous = null;
    settings.setLocaleSync(previous);
  }

  @override
  Widget wrap(Widget child) => provider?.call(child) ?? child;

  static bool _matches(BaseAppLocale<dynamic, dynamic> applied, Locale locale) {
    if (applied.languageCode != locale.languageCode) {
      return false;
    }
    final script = locale.scriptCode;
    if (script != null && applied.scriptCode != script) {
      return false;
    }
    final country = locale.countryCode;
    return country == null || applied.countryCode == country;
  }
}
