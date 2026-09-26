import 'package:co_golden/co_golden.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slang/slang.dart';

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

void main() {
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

  test('fails on a locale the app does not ship and restores first', () {
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

  test('the none binding changes nothing', () {
    const child = SizedBox();

    GoldenLocalization.none.activate(const Locale('en'));
    GoldenLocalization.none.restore();
    expect(GoldenLocalization.none.wrap(child), same(child));
  });
}
