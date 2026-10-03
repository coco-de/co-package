// co-package#44 — 리더가 그리는 문구(오류 화면 등)를 앱이 바꿔 넣는다.
// 문구 묶음을 넣지 않은 기존 사용처는 지금과 같은 글을 본다.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

void main() {
  const ja = EpubReaderStrings(
    fileTooLarge: 'ファイルが大きすぎて開けません。',
    networkFailure: 'ネットワークエラーのため本を取得できませんでした。',
    corruptedFile: '破損しているか、正しくない EPUB です。',
    openFailed: '本を開くときにエラーが発生しました。',
  );

  // EPUB(zip)이 아닌 바이트 — 리더가 오류 화면을 그린다.
  EpubSource brokenSource() =>
      EpubSource.bytes(Uint8List.fromList(List<int>.filled(64, 7)));

  Future<void> pumpReader(
    WidgetTester tester, {
    EpubReaderStrings? strings,
    EpubReaderStrings? scope,
  }) async {
    Widget reader = EpubReader(source: brokenSource(), strings: strings);
    if (scope != null) {
      reader = EpubReaderStringsScope(strings: scope, child: reader);
    }
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: reader)));
    await tester.pumpAndSettle();
  }

  bool shows(String message) =>
      find.textContaining(message).evaluate().isNotEmpty;

  test('기본값은 지금까지 보여 주던 글이다', () {
    const strings = EpubReaderStrings();

    expect(strings.fileTooLarge, '파일이 너무 커서 열 수 없습니다.');
    expect(strings.networkFailure, '네트워크 오류로 책을 가져오지 못했습니다.');
    expect(strings.corruptedFile, '손상되었거나 올바르지 않은 EPUB입니다.');
    expect(strings.openFailed, '책을 여는 중 오류가 발생했습니다.');
    expect(strings.positionRestoreFailed, '마지막 위치를 찾을 수 없어 처음부터 표시합니다');
    expect(strings.emptyBook, '이 책에는 표시할 내용이 없습니다.');
    expect(strings.emptyPage, '이 페이지에는 표시할 내용이 없습니다.');
    expect(strings.chapterLoadFailed, '본문을 불러올 수 없습니다.');
    expect(strings.pageLoadFailed, '페이지를 불러올 수 없습니다.');
    expect(strings.formula, '수식');
    expect(const EpubReaderStrings(), const EpubReaderStrings());
    expect(ja, isNot(const EpubReaderStrings()));
  });

  testWidgets('문구 묶음이 없으면 오류 화면이 지금과 같은 한국어다', (tester) async {
    await pumpReader(tester);

    final korean = [
      const EpubReaderStrings().corruptedFile,
      const EpubReaderStrings().openFailed,
    ];
    expect(korean.any(shows), isTrue);
  });

  testWidgets('EpubReader.strings 로 넣은 문구로 오류 화면이 바뀐다', (tester) async {
    await pumpReader(tester, strings: ja);

    expect([ja.corruptedFile, ja.openFailed].any(shows), isTrue);
    expect(shows(const EpubReaderStrings().corruptedFile), isFalse);
    expect(shows(const EpubReaderStrings().openFailed), isFalse);
  });

  testWidgets('EpubReaderStringsScope 의 문구도 따른다', (tester) async {
    await pumpReader(tester, scope: ja);

    expect([ja.corruptedFile, ja.openFailed].any(shows), isTrue);
    expect(shows(const EpubReaderStrings().openFailed), isFalse);
  });

  testWidgets('생성자 문구가 스코프보다 우선한다', (tester) async {
    const en = EpubReaderStrings(
      corruptedFile: 'This EPUB is damaged or not valid.',
      openFailed: 'Could not open this book.',
    );
    await pumpReader(tester, strings: en, scope: ja);

    expect([en.corruptedFile, en.openFailed].any(shows), isTrue);
    expect([ja.corruptedFile, ja.openFailed].any(shows), isFalse);
  });
}
