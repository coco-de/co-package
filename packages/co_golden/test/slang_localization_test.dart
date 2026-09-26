import 'dart:io';

import 'package:co_golden/co_golden.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang/generated.dart' show Node;
import 'package:slang/slang.dart';

import 'lazy_translations.dart' deferred as lazy;

final FakeAppLocale _ko = FakeAppLocale(languageCode: 'ko');
final FakeAppLocale _en = FakeAppLocale(languageCode: 'en');
final FakeAppLocale _zhHant = FakeAppLocale(
  languageCode: 'zh',
  scriptCode: 'Hant',
);

final class _Utils extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  _Utils() : super(baseLocale: _ko, locales: [_ko, _en, _zhHant]);
}

final class _Settings
    extends BaseLocaleSettings<FakeAppLocale, FakeTranslations> {
  _Settings() : super(utils: _Utils(), lazy: false);
}

/// A locale whose translations live in a deferred library, like every
/// non-base locale Slang generates for lazy settings. Building it
/// synchronously before the library is loaded throws in the VM.
final class _DeferredLocale extends FakeAppLocale {
  _DeferredLocale({required super.languageCode});

  @override
  Future<FakeTranslations> build({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) async {
    await lazy.loadLibrary();
    return buildSync();
  }

  @override
  FakeTranslations buildSync({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) => lazy.buildLazyTranslations(this);
}

final FakeAppLocale _lazyKo = FakeAppLocale(languageCode: 'ko');
final _DeferredLocale _lazyEn = _DeferredLocale(languageCode: 'en');

final class _LazyUtils
    extends BaseAppLocaleUtils<FakeAppLocale, FakeTranslations> {
  _LazyUtils() : super(baseLocale: _lazyKo, locales: [_lazyKo, _lazyEn]);
}

final class _LazySettings
    extends BaseLocaleSettings<FakeAppLocale, FakeTranslations> {
  _LazySettings() : super(utils: _LazyUtils(), lazy: true);
}

void main() {
  // ⚠️ Keep this group first: a deferred library stays loaded for the rest of
  // the test process, so the "not loaded" case must run before anything
  // loads it.
  group('lazy Slang settings', () {
    final settings = _LazySettings()..setLocaleSync(_lazyKo);
    final localization =
        SlangGoldenLocalization<FakeAppLocale, FakeTranslations>(
          settings: settings,
        );

    test('activate fails before preload instead of a deferred-load '
        'error, and switches nothing', () {
      expect(settings.isLocaleLoaded(_lazyEn), isFalse);
      expect(
        () => localization.activate(const Locale('en')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('"en"'), contains('preload()')),
          ),
        ),
      );
      expect(settings.currentLocale.languageTag, 'ko');
    });

    test(
      'preload loads the planned locales and tolerates unknown ones',
      () async {
        await localization.preload(const [Locale('en'), Locale('ja')]);

        expect(settings.isLocaleLoaded(_lazyEn), isTrue);
      },
    );

    test('activate switches synchronously once preloaded', () {
      localization.activate(const Locale('en'));
      expect(settings.currentLocale.languageTag, 'en');

      localization.restore();
      expect(settings.currentLocale.languageTag, 'ko');
    });
  });

  late _Settings settings;
  late SlangGoldenLocalization<FakeAppLocale, FakeTranslations> localization;

  setUp(() {
    settings = _Settings()..setLocaleSync(_ko);
    localization = SlangGoldenLocalization(
      settings: settings,
      provider: (child) =>
          KeyedSubtree(key: const Key('provider'), child: child),
    );
  });

  test('activates the variant locale and restores the previous one', () {
    localization.activate(const Locale('en'));
    expect(settings.currentLocale.languageCode, 'en');

    localization.restore();
    expect(settings.currentLocale.languageCode, 'ko');
  });

  test('matches script subtags', () {
    localization.activate(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(settings.currentLocale.languageTag, 'zh-Hant');
    localization.restore();
  });

  test('fails on a locale the app does not ship without switching', () {
    expect(
      () => localization.activate(const Locale('ja')),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('"ja"'),
        ),
      ),
    );
    expect(settings.currentLocale.languageCode, 'ko');
  });

  test('restore is a no-op without activate', () {
    localization.restore();
    expect(settings.currentLocale.languageCode, 'ko');
  });

  test('wraps the app with the provider', () {
    final wrapped = localization.wrap(const SizedBox());

    expect(wrapped, isA<KeyedSubtree>());
    expect((wrapped as KeyedSubtree).key, const Key('provider'));
  });

  test('the none binding changes nothing', () async {
    const child = SizedBox();

    await GoldenLocalization.none.preload(const [Locale('en')]);
    GoldenLocalization.none.activate(const Locale('en'));
    GoldenLocalization.none.restore();
    expect(GoldenLocalization.none.wrap(child), same(child));
  });

  final output = Directory.systemTemp.createTempSync('co_golden_slang_');
  tearDownAll(() => output.deleteSync(recursive: true));
  final lazySettings = _LazySettings()..setLocaleSync(_lazyKo);
  final rendered = <String>[];
  GoldenMatrix<Brightness>(
    suite: 'slang',
    environment: GoldenMatrixEnvironment(
      mode: GoldenMatrixMode.capture,
      outputDirectory: output.path,
    ),
    coverage: const GoldenCoverage<Brightness>(
      devices: [GoldenDevice.phoneCompact],
      themes: [GoldenTheme(name: 'light', data: Brightness.light)],
      locales: [Locale('ko'), Locale('en')],
    ),
    localization: SlangGoldenLocalization<FakeAppLocale, FakeTranslations>(
      settings: lazySettings,
    ),
    app: (variant, child) =>
        Directionality(textDirection: TextDirection.ltr, child: child),
  ).scenario(
    'lazy-locale',
    build: (variant) {
      rendered.add(
        '${variant.fileStem} '
        '${lazySettings.currentTranslations.$meta.locale.languageTag}',
      );
      return const SizedBox.expand();
    },
  );

  test('the matrix preloads lazy locales before the variants run', () {
    expect(rendered, [
      'phone-compact__light__ko ko',
      'phone-compact__light__en en',
    ]);
    expect(lazySettings.currentLocale.languageTag, 'ko');
  });
}
