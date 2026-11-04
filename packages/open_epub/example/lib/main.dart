import 'package:co_example_ui/co_example_ui.dart';
import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:open_epub/open_epub.dart' show EpubReaderStringsScope;

import 'demo_settings.dart';
// open_epub 1.0 데모 진입점. S11.1(#88)에서 레거시 EpubReaderWidget 데모를
// 제거하고, 1.0 코어(EpubBookSession + EpubReader) 데모만 노출한다.
import 'fixed_layout_demo_page.dart' show FixedLayoutDemoPage;
import 'highlight_demo_page.dart' show HighlightDemoPage;
import 'i18n/strings.g.dart';
import 'l10n.dart';
import 'sample_library_page.dart' show SampleLibraryPage;
import 'v1_demo_page.dart' show V1DemoPage;

const bool _isFlutterTest = bool.fromEnvironment(
  'FLUTTER_TEST',
  defaultValue: false,
);

void main() {
  // marionette 통합테스트용 바인딩(디버그 전용). Material IconButton/InkWell 등은
  // 기본 상호작용 위젯으로 감지되고, 데모 컨트롤에는 ValueKey를 부착했다.
  if (kDebugMode && !_isFlutterTest) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // 데모 포털에서 고른 언어 · 테마로 연다 — 첫 값은 runApp 전에(URL), 포털
  // 미리보기 iframe 안에서는 이후 바뀌는 값도 재시작 없이 따른다(postMessage).
  applyInitialDemoPrefs(
    Uri.base,
    deviceLocale: PlatformDispatcher.instance.locale,
  );
  DemoEmbedSync(allowLocalhost: kDebugMode).start(applyDemoPrefs);
  runApp(TranslationProvider(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: demoThemeMode,
      builder: (context, themeMode, _) => MaterialApp(
        onGenerateTitle: (context) => context.tr.app.title,
        debugShowCheckedModeBanner: false,
        // slang 로케일이 MaterialApp.locale 을 움직인다 — ar 이면 RTL.
        // TranslationProvider 없이 띄운 테스트에서도 동작하도록 현재 로케일을 쓴다.
        locale: context.tr.$meta.locale.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: exampleTheme(Brightness.light),
        darkTheme: exampleTheme(Brightness.dark),
        themeMode: themeMode,
        // 리더 패키지가 그리는 문구(오류 화면 · 빈 페이지 안내 등)도 번역한다.
        builder: (context, child) => ExampleThemeScope(
          child: EpubReaderStringsScope(
            strings: epubReaderStringsOf(context.tr),
            child: child!,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

// ============================================================
// Home: 1.0 데모 런처
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    return ExampleCatalog(
      title: t.app.title,
      product: 'OPEN EPUB',
      reading: true,
      settings: ExampleSettings(
        themeMode: demoThemeMode,
        locale: DemoLocale.parse(t.$meta.locale.languageCode),
        onLocaleChanged: (locale) => applyDemoPrefs(DemoPrefs(locale: locale)),
      ),
      entries: [
        ExampleEntry(
          title: t.home.library.title,
          description: t.home.library.description,
          icon: Icons.local_library_outlined,
          page: const SampleLibraryPage(),
          id: 'demo-sample-library',
        ),
        ExampleEntry(
          title: t.home.core.title,
          description: 'EpubBookSession + EpubReader',
          icon: Icons.auto_stories_outlined,
          page: const V1DemoPage(),
          id: 'demo-v1-core',
        ),
        ExampleEntry(
          title: t.home.highlight.title,
          description: t.home.highlight.description,
          icon: Icons.border_color_outlined,
          page: const HighlightDemoPage(),
        ),
        ExampleEntry(
          title: t.home.fixedLayout.title,
          description: t.home.fixedLayout.description,
          icon: Icons.insert_drive_file_outlined,
          page: const FixedLayoutDemoPage(),
          id: 'demo-fixed-layout-a4',
        ),
      ],
    );
  }
}
