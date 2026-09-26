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
/// other.
///
/// [preload] runs once per scenario, in `setUpAll`, with every locale the
/// scenario plans. [activate] runs before each variant is built and
/// [restore] after capture, even when the variant fails. [wrap] places a
/// provider widget above the app.
///
/// Widget tests run in a fake-async zone where real asynchronous work — such
/// as loading a deferred library — never completes, so a test that awaits it
/// hangs. Load in [preload], which runs outside that zone, and keep
/// [activate] synchronous.
abstract base class GoldenLocalization {
  /// Creates a localization binding.
  const GoldenLocalization();

  /// A binding that switches nothing. Use it when the app reads its strings
  /// from Flutter's `Localizations` only.
  static const GoldenLocalization none = _NoGoldenLocalization();

  /// Loads what [activate] needs for [locales]. Does nothing by default.
  FutureOr<void> preload(Iterable<Locale> locales) {}

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
///
/// Slang generates lazy settings by default: every locale except the base one
/// lives in a deferred library. [preload] loads the planned locales — the
/// matrix calls it in `setUpAll` — and [activate] fails with a [StateError]
/// when a locale was not loaded, instead of the VM's deferred-load error.
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
  Future<void> preload(Iterable<Locale> locales) async {
    for (final locale in locales) {
      // An unknown tag resolves to the base locale, which is always loaded;
      // activate reports it.
      await settings.loadLocale(settings.utils.parse(locale.toLanguageTag()));
    }
  }

  @override
  void activate(Locale locale) {
    final requested = locale.toLanguageTag();
    final target = settings.utils.parse(requested);
    if (!_matches(target, locale)) {
      throw StateError(
        'Slang does not ship the locale "$requested" (it resolved to '
        '"${target.languageTag}"). Add the locale to the app or remove it '
        'from the golden coverage.',
      );
    }
    if (!settings.isLocaleLoaded(target)) {
      throw StateError(
        'The Slang translations of "$requested" are not loaded. GoldenMatrix '
        'loads the planned locales through preload() in setUpAll; await '
        'preload() first when you use this binding on its own.',
      );
    }
    _previous ??= settings.currentLocale;
    settings.setLocaleSync(target);
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
