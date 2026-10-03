// 예제 번역 접근 (co-package#44).
import 'package:flutter/widgets.dart';
import 'package:open_epub/open_epub.dart' show EpubReaderStrings;

import 'i18n/strings.g.dart';

/// 화면에서 쓰는 번역.
extension DemoTranslations on BuildContext {
  /// 현재 언어의 번역. 앱(TranslationProvider 아래)에서는 언어가 바뀌면 다시
  /// 빌드된다. 테스트처럼 페이지만 띄우면 현재 [LocaleSettings] 번역(기본
  /// 한국어)을 쓴다.
  Translations get tr =>
      dependOnInheritedWidgetOfExactType<
            InheritedLocaleData<AppLocale, Translations>
          >()
          ?.translations ??
      t;
}

/// 현재 언어의 번역으로 리더 패키지 문구 묶음을 만든다 — 오류 화면 · 위치
/// 복원 배너 · 빈 페이지 · 로드 실패 안내 · 수식 라벨.
EpubReaderStrings epubReaderStringsOf(Translations t) => EpubReaderStrings(
  fileTooLarge: t.epubReader.fileTooLarge,
  networkFailure: t.epubReader.networkFailure,
  corruptedFile: t.epubReader.corruptedFile,
  openFailed: t.epubReader.openFailed,
  positionRestoreFailed: t.epubReader.positionRestoreFailed,
  emptyBook: t.epubReader.emptyBook,
  emptyPage: t.epubReader.emptyPage,
  chapterLoadFailed: t.epubReader.chapterLoadFailed,
  pageLoadFailed: t.epubReader.pageLoadFailed,
  formula: t.epubReader.formula,
);
