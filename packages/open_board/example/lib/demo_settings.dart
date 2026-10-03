import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:flutter/material.dart';

import 'i18n/strings.g.dart';

/// 예제 앱의 테마 모드. 포털이 넘긴 값이 없으면 시스템 설정을 따른다.
///
/// 받은 값은 저장하지 않는다 — 방문 동안만 쓰고, 새로고침해도 URL 이 다시
/// 넘겨준다(co_demo_prefs 프로토콜).
final ValueNotifier<ThemeMode> demoThemeMode = ValueNotifier(ThemeMode.system);

/// 앱 크롬의 테마. 필기 종이 · 책 본문 같은 콘텐츠 면은 [LightSurface] 로
/// 다크에서도 원래 색을 유지한다.
ThemeData exampleTheme(Brightness brightness) => ThemeData(
  colorSchemeSeed: Colors.indigo,
  brightness: brightness,
  useMaterial3: true,
);

/// 데모 포털(demo.cocode.im)이 넘긴 언어 · 테마를 적용한다.
///
/// 언어는 slang [LocaleSettings] 로 바꿔 `MaterialApp.locale` 까지 바뀌게
/// 한다 — 아랍어가 오른쪽에서 왼쪽으로 배치되려면 앱의 로케일 상태를 거쳐야
/// 한다. 값이 없는 항목은 그대로 둔다.
void applyDemoPrefs(DemoPrefs prefs) {
  if (prefs.locale case final locale?) {
    LocaleSettings.setLocaleSync(appLocaleOf(locale));
  }
  if (prefs.theme case final theme?) {
    demoThemeMode.value = switch (theme) {
      DemoTheme.light => ThemeMode.light,
      DemoTheme.dark => ThemeMode.dark,
    };
  }
}

/// 첫 값 — `runApp` 전에 부른다. URL 의 `lang` · `theme` 이 우선이고, 언어가
/// 없으면 기기 언어를 포털과 같은 규칙([DemoLocale.parse])으로 맞춰 보고,
/// 그래도 없으면 기본 언어(한국어)를 쓴다.
void applyInitialDemoPrefs(Uri uri, {Locale? deviceLocale}) {
  final prefs = DemoPrefs.fromUri(uri);
  final locale =
      prefs.locale ?? DemoLocale.parse(deviceLocale?.toLanguageTag());
  applyDemoPrefs(DemoPrefs(locale: locale, theme: prefs.theme));
}

/// [DemoLocale] → slang [AppLocale]. 두 집합은 같은 11개 언어다.
AppLocale appLocaleOf(DemoLocale locale) => AppLocaleUtils.parseLocaleParts(
  languageCode: locale.languageCode,
  scriptCode: locale.scriptCode,
);
