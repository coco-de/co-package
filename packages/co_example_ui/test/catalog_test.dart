import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:co_example_ui/co_example_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('packages/co_example_ui/Pretendard')
      ..addFont(
        rootBundle.load('packages/co_example_ui/fonts/Pretendard-Regular.otf'),
      )
      ..addFont(
        rootBundle.load('packages/co_example_ui/fonts/Pretendard-SemiBold.otf'),
      );
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/co_example_ui/NotoSansArabic')..addFont(
          rootBundle.load('packages/co_example_ui/fonts/NotoSansArabic.ttf'),
        ))
        .load();
  });

  Future<void> pumpCatalog(
    WidgetTester tester, {
    required Size size,
    required Locale locale,
    required bool dark,
    bool reading = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mode = ValueNotifier(dark ? ThemeMode.dark : ThemeMode.light);
    addTearDown(mode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: exampleMaterialTheme(Brightness.light),
        darkTheme: exampleMaterialTheme(Brightness.dark),
        themeMode: mode.value,
        locale: locale,
        supportedLocales: const [Locale('ko'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: ExampleThemeScope(child: child!),
        ),
        home: ExampleCatalog(
          title: locale.languageCode == 'ar'
              ? (reading ? 'عرض Open EPUB التوضيحي' : 'عرض Open Board التوضيحي')
              : reading
              ? 'Open EPUB'
              : 'Open Board',
          product: reading ? 'OPEN EPUB' : 'OPEN BOARD',
          reading: reading,
          settings: ExampleSettings(
            themeMode: mode,
            locale: DemoLocale.ko,
            onLocaleChanged: (_) {},
          ),
          entries: [
            for (var i = 0; i < (reading ? 4 : 3); i++)
              ExampleEntry(
                id: 'entry-$i',
                title: locale.languageCode == 'ko'
                    ? '보드 데모 ${i + 1}'
                    : 'Example ${i + 1}',
                description: locale.languageCode == 'ko'
                    ? '다양한 도구로 자유롭게 그리고, 기록하고, 다시 재생해 보세요.'
                    : 'Explore the interactive workspace with accessible controls and responsive layouts.',
                icon: reading
                    ? Icons.auto_stories_outlined
                    : Icons.draw_outlined,
                page: const Scaffold(
                  body: Center(child: Text('Opened example')),
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final reading in [false, true]) {
    for (final scenario in [
      (
        name: 'mobile-ko-light',
        size: const Size(375, 812),
        locale: const Locale('ko'),
        dark: false,
      ),
      (
        name: 'desktop-en-dark',
        size: const Size(1200, 900),
        locale: const Locale('en'),
        dark: true,
      ),
      (
        name: 'mobile-ar-dark',
        size: const Size(375, 812),
        locale: const Locale('ar'),
        dark: true,
      ),
    ]) {
      testWidgets('${reading ? 'reader' : 'board'} ${scenario.name}', (
        tester,
      ) async {
        await pumpCatalog(
          tester,
          size: scenario.size,
          locale: scenario.locale,
          dark: scenario.dark,
          reading: reading,
        );
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/${reading ? 'reader' : 'board'}-${scenario.name}.png',
          ),
        );
        await tester.tap(find.byKey(const ValueKey('example-start')));
        await tester.pumpAndSettle();
        expect(find.text('Opened example'), findsOneWidget);
      });
    }
  }

  testWidgets('320px and large text keep all entries reachable', (
    tester,
  ) async {
    await pumpCatalog(
      tester,
      size: const Size(320, 700),
      locale: const Locale('ko'),
      dark: false,
      textScale: 1.8,
    );
    final target = find.byKey(const ValueKey('entry-2'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.text('Opened example'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
