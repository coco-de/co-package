import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_board/open_board.dart';
import 'package:open_board_example/demo_settings.dart';
import 'package:open_board_example/i18n/strings.g.dart';
import 'package:open_board_example/main.dart';

/// 데모 포털 이어받기 · 11개 언어 · 다크 테마 (co-package#43).
void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ko);
    demoThemeMode.value = ThemeMode.system;
  });

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(child: const OpenBoardExampleApp()),
    );
    await tester.pumpAndSettle();
    return tester.element(find.byType(HomeMenuPage));
  }

  testWidgets('넘겨받은 값이 없으면 한국어 · 시스템(라이트) 테마로 연다', (tester) async {
    final context = await pumpApp(tester);

    expect(find.text('Open Board 데모'), findsOneWidget);
    expect(find.text('보드 데모'), findsOneWidget);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('URL 의 lang=fr&theme=dark 로 프랑스어 · 다크로 연다', (tester) async {
    applyInitialDemoPrefs(
      Uri.parse(
        'https://docs.cocode.im/co-package/open-board/?lang=fr&theme=dark',
      ),
    );
    final context = await pumpApp(tester);

    expect(find.text('Démo Open Board'), findsOneWidget);
    expect(find.text('Démo du tableau'), findsOneWidget);
    expect(find.text('Démo d’annotation EPUB'), findsOneWidget);
    expect(Localizations.localeOf(context), const Locale('fr'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('포털 sync 메시지에 재시작 없이 언어 · 테마가 바뀐다', (tester) async {
    await pumpApp(tester);
    expect(find.text('Open Board 데모'), findsOneWidget);

    applyDemoPrefs(
      const DemoPrefs(locale: DemoLocale.ja, theme: DemoTheme.dark),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeMenuPage));
    expect(find.text('Open Board デモ'), findsOneWidget);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('아랍어는 MaterialApp.locale 을 거쳐 오른쪽에서 왼쪽으로 배치된다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.ar));
    final context = await pumpApp(tester);

    expect(find.text('عرض Open Board التوضيحي'), findsOneWidget);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('zh-Hans 는 간체 — Material 내장 문구도 간체다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.zhHans));
    final context = await pumpApp(tester);

    expect(find.text('Open Board 演示'), findsOneWidget);
    expect(
      Localizations.localeOf(context),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(MaterialLocalizations.of(context).cancelButtonLabel, '取消');
  });

  testWidgets('패키지 문구 묶음(링크 대화상자 · 도구 이름)도 앱 언어를 따른다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.fr));
    final context = await pumpApp(tester);

    final strings = OpenBoardStringsScope.of(context);
    expect(strings.addLink, 'Ajouter un lien');
    expect(strings.linkDialogTitle, 'Lien');
    expect(strings.toolLabel(DrawingTool.pen), 'Stylo');
    expect(strings.undo, 'Annuler');
  });

  testWidgets('다크 테마에서도 필기 종이는 원래 색(라이트)이다', (tester) async {
    applyDemoPrefs(
      const DemoPrefs(locale: DemoLocale.en, theme: DemoTheme.dark),
    );
    await pumpApp(tester);

    await tester.tap(find.text('Board Demo'));
    await tester.pumpAndSettle();

    final chrome = tester.element(find.byType(AppBar));
    expect(Theme.of(chrome).brightness, Brightness.dark);
    final paper = tester.element(find.text('Page 1'));
    expect(Theme.of(paper).brightness, Brightness.light);
    expect(Material.of(paper).color, Colors.white);
  });

  testWidgets('분할 필기 — 패키지 플로팅 도구의 툴팁이 앱 언어다', (tester) async {
    applyDemoPrefs(const DemoPrefs(locale: DemoLocale.fr));
    await pumpApp(tester);

    await tester.tap(find.text('Démo écran partagé'));
    await tester.pumpAndSettle();

    expect(
      find.text('Écran partagé — un seul panneau d’outils flottant'),
      findsOneWidget,
    );
    expect(find.byTooltip('Stylo'), findsOneWidget);
    expect(find.byTooltip('Gomme'), findsOneWidget);
    expect(find.byTooltip('Pen'), findsNothing);
  });

  test('언어가 URL 에 없으면 기기 언어를 포털과 같은 규칙으로 맞춘다', () {
    applyInitialDemoPrefs(
      Uri.parse('https://docs.cocode.im/co-package/open-board/'),
      deviceLocale: const Locale('pt', 'BR'),
    );
    expect(LocaleSettings.currentLocale, AppLocale.pt);

    // 번체 중국어는 간체로 바꾸지 않는다 — 지금 언어(기본 한국어)를 유지.
    LocaleSettings.setLocaleSync(AppLocale.ko);
    applyInitialDemoPrefs(
      Uri.parse('https://docs.cocode.im/co-package/open-board/'),
      deviceLocale: const Locale('zh', 'TW'),
    );
    expect(LocaleSettings.currentLocale, AppLocale.ko);

    // URL 값이 기기 언어보다 우선한다.
    applyInitialDemoPrefs(
      Uri.parse('https://docs.cocode.im/co-package/open-board/?lang=de'),
      deviceLocale: const Locale('en'),
    );
    expect(LocaleSettings.currentLocale, AppLocale.de);
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
