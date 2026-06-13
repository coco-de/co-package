// Story: S7.5 (E7) — EpubBookSession.resolveLink (책 내부 링크 내비게이션)

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/src/api/epub_book_session.dart';
import 'package:open_epub/src/api/epub_position.dart';
import 'package:open_epub/src/api/epub_source.dart';

import '../_fixtures/epub_fixtures.dart';

void main() {
  Future<EpubBookSession> open() =>
      EpubBookSession.open(EpubSource.bytes(searchableEpub3()));

  test('책 내부 상대 경로는 해당 spine 위치로 변환', () async {
    final session = await open();
    addTearDown(session.dispose);

    final pos = session.resolveLink('ch2.xhtml');
    expect(pos, isA<EpubReflowablePosition>());
    expect(pos!.spineHref, 'ch2.xhtml');
    expect((pos as EpubReflowablePosition).charOffset, 0);
  });

  test('fragment는 무시하고 spine으로 점프', () async {
    final session = await open();
    addTearDown(session.dispose);

    final pos = session.resolveLink('ch3.xhtml#sec2');
    expect(pos?.spineHref, 'ch3.xhtml');
  });

  test('경로에 디렉터리가 붙어도 파일명으로 매칭', () async {
    final session = await open();
    addTearDown(session.dispose);

    expect(session.resolveLink('../text/ch2.xhtml')?.spineHref, 'ch2.xhtml');
  });

  test('외부 URL·하이라이트 링크·빈 값은 null', () async {
    final session = await open();
    addTearDown(session.dispose);

    expect(session.resolveLink('https://example.com'), isNull);
    expect(session.resolveLink('mailto:a@b.com'), isNull);
    expect(session.resolveLink('openepub-hl:h1'), isNull);
    expect(session.resolveLink('   '), isNull);
    expect(session.resolveLink('#anchor-only'), isNull);
  });

  test('알 수 없는 책 내부 경로는 null', () async {
    final session = await open();
    addTearDown(session.dispose);
    expect(session.resolveLink('nope.xhtml'), isNull);
  });
}
