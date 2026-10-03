import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:open_board/open_board.dart';

import 'demo_settings.dart';
import 'drawing_demo_page.dart';
import 'epub_annotation_demo_page.dart';
import 'i18n/strings.g.dart';
import 'open_board_strings_l10n.dart';
import 'split_drawing_page.dart';

void main() {
  // AI 에이전트 런타임 구동(탭/스크린샷 등) 지원 — 디버그 모드 전용
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  }
  // 데모 포털에서 고른 언어 · 테마로 연다 — 첫 값은 runApp 전에(URL), 포털
  // 미리보기 iframe 안에서는 이후 바뀌는 값도 재시작 없이 따른다(postMessage).
  applyInitialDemoPrefs(
    Uri.base,
    deviceLocale: PlatformDispatcher.instance.locale,
  );
  DemoEmbedSync(allowLocalhost: kDebugMode).start(applyDemoPrefs);
  runApp(TranslationProvider(child: const OpenBoardExampleApp()));
}

class OpenBoardExampleApp extends StatelessWidget {
  const OpenBoardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: demoThemeMode,
      builder: (context, themeMode, _) => MaterialApp(
        onGenerateTitle: (context) => context.t.app.title,
        debugShowCheckedModeBanner: false,
        // slang 로케일이 MaterialApp.locale 을 움직인다 — ar 이면 RTL.
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: exampleTheme(Brightness.light),
        darkTheme: exampleTheme(Brightness.dark),
        themeMode: themeMode,
        // 패키지가 직접 그리는 문구(링크 메뉴 · 대화상자 · 도구 이름)도 번역한다.
        // Navigator 위라 Overlay 에디터 · 대화상자 라우트까지 닿는다.
        builder: (context, child) => OpenBoardStringsScope(
          strings: openBoardStringsOf(context.t),
          child: child!,
        ),
        home: const HomeMenuPage(),
      ),
    );
  }
}

/// 데모 선택 홈 메뉴
class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.app.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoCard(
            icon: Icons.draw,
            title: t.home.board.title,
            description: t.home.board.description,
            page: const DrawingPage(),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.vertical_split,
            title: t.home.split.title,
            description: t.home.split.description,
            page: const SplitDrawingPage(),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.menu_book,
            title: t.home.epub.title,
            description: t.home.epub.description,
            page: const EpubAnnotationDemoPage(),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget page;

  const _DemoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        ),
      ),
    );
  }
}
