// 데모 포털 이어받기 · 11개 언어 · 다크 테마 · 리더 문구 (co-package#44).

import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';
import 'package:open_epub_example/demo_settings.dart';
import 'package:open_epub_example/i18n/strings.g.dart';
import 'package:open_epub_example/main.dart';
import 'package:open_epub_example/sample_library_page.dart';

/// 지정한 자산만 들어 있는 것처럼 매니페스트를 돌려주는 번들.
class _ManifestBundle extends CachingAssetBundle {
  _ManifestBundle(this.assets);

  final List<String> assets;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final asset in assets)
          asset: [
            {'asset': asset},
          ],
      })!;
    }
    throw FlutterError('unexpected asset $key');
  }
}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ko);
    demoThemeMode.value = ThemeMode.system;
  });

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(TranslationProvider(child: const MyApp()));
    await tester.pumpAndSettle();
    return tester.element(find.byType(HomePage));
  }

  testWidgets('넘겨받은 값이 없으면 한국어 · 시스템(라이트) 테마로 연다', (tester) async {
    final context = await pumpApp(tester);

    expect(find.text('open_epub 데모'), findsOneWidget);
    expect(find.text('EPUB3 샘플 라이브러리'), findsOneWidget);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('URL 의 lang=ja&theme=dark 로 일본어 · 다크로 연다', (tester) async {
    applyInitialDemoPrefs(
      Uri.parse(
        'https://docs.cocode.im/co-package/open-epub/?lang=ja&theme=dark',
      ),
    );
    final context = await pumpApp(tester);

    expect(find.text('open_epub デモ'), findsOneWidget);
    expect(find.text('EPUB3 サンプルライブラリ'), findsOneWidget);
    expect(find.text('ハイライトデモ'), findsOneWidget);
    expect(Localizations.localeOf(context), const Locale('ja'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('포털 sync 메시지에 재시작 없이 언어 · 테마가 바뀐다', (tester) async {
    await pumpApp(tester);
    expect(find.text('open_epub 데모'), findsOneWidget);

    applyDemoPrefs(
      const DemoPrefs(locale: DemoLocale.fr, theme: DemoTheme.dark),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomePage));
    expect(find.text('Démo open_epub'), findsOneWidget);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('아랍어는 MaterialApp.locale 을 거쳐 오른쪽에서 왼쪽으로 배치된다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.ar));
    final context = await pumpApp(tester);

    expect(find.text('عرض open_epub التوضيحي'), findsOneWidget);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('열 수 없는 책의 리더 오류 화면이 앱 언어(일본어)다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.ja));
    final context = await pumpApp(tester);

    final strings = EpubReaderStringsScope.of(context);
    expect(strings.corruptedFile, '破損しているか、正しくない EPUB です。');

    unawaitedPush(
      context,
      Scaffold(
        body: EpubReader(
          source: EpubSource.bytes(Uint8List.fromList(List.filled(64, 7))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final japanese = [strings.corruptedFile, strings.openFailed];
    expect(
      japanese.any((m) => find.textContaining(m).evaluate().isNotEmpty),
      isTrue,
    );
    expect(find.textContaining('올바르지 않은 EPUB'), findsNothing);
    expect(find.textContaining('여는 중 오류'), findsNothing);
  });

  testWidgets('다크 테마에서도 책 본문 면은 원래 색(라이트)이다', (tester) async {
    applyDemoPrefs(
      const DemoPrefs(locale: DemoLocale.en, theme: DemoTheme.dark),
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('demo-fixed-layout-a4')));
    await tester.pumpAndSettle();

    expect(find.text('Fixed Layout A4 Demo'), findsOneWidget);
    final chrome = tester.element(find.byType(AppBar));
    expect(Theme.of(chrome).brightness, Brightness.dark);
    final page = tester.element(find.byType(EpubReader));
    expect(Theme.of(page).brightness, Brightness.light);
    expect(Material.of(page).color, Colors.white);
  });

  testWidgets('샘플 라이브러리 — 번들에 없는 로컬 전용 픽스처는 숨기고, 책 제목은 원문이다', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: SampleLibraryPage(
            bundle: _ManifestBundle(['assets/wasteland.epub']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EPUB3 サンプルライブラリ'), findsOneWidget);
    // 번들에 있는 책 + 합성 A4 샘플만 보인다.
    expect(find.byKey(const ValueKey('sample-wasteland')), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-fixed-a4')), findsOneWidget);
    expect(find.byKey(const ValueKey('sample-nohoechan')), findsNothing);
    expect(find.byKey(const ValueKey('sample-accessible')), findsNothing);
    // 책 제목(고유명)은 원문, 설명 · 칩은 번역.
    expect(find.text('The Waste Land'), findsOneWidget);
    expect(find.text('T.S. Eliot · EPUB3 の基本（nav・CSS）'), findsOneWidget);
    expect(find.text('Fixed Layout A4 デモ'), findsOneWidget);
  });

  test('언어가 URL 에 없으면 기기 언어를 포털과 같은 규칙으로 맞춘다', () {
    applyInitialDemoPrefs(
      Uri.parse('https://docs.cocode.im/co-package/open-epub/'),
      deviceLocale: const Locale('es', 'MX'),
    );
    expect(LocaleSettings.currentLocale, AppLocale.es);

    LocaleSettings.setLocaleSync(AppLocale.ko);
    applyInitialDemoPrefs(
      Uri.parse('https://docs.cocode.im/co-package/open-epub/'),
      deviceLocale: const Locale('zh', 'HK'),
    );
    expect(LocaleSettings.currentLocale, AppLocale.ko);
  });

  test('DemoLocale 11개가 모두 앱 언어에 대응한다', () {
    for (final locale in DemoLocale.values) {
      final appLocale = appLocaleOf(locale);
      expect(appLocale.languageCode, locale.languageCode);
      expect(appLocale.scriptCode, locale.scriptCode);
    }
    expect(AppLocale.values, hasLength(DemoLocale.values.length));
  });
}

/// 테스트에서 라우트를 띄운다(결과는 기다리지 않는다).
void unawaitedPush(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
