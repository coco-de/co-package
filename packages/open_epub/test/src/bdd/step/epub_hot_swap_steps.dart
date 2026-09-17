// BDD Steps for epub_hot_swap.feature
// Story: S1.22 (#38) — swapSource() 위치 보존 hot-swap (F10)
//
// Author 미리보기 시나리오: 같은 session에서 EpubSource.bytes를 교체하면
// 같은 spineHref가 존재할 때 위치(charOffset 포함)가 보존되고, 사라졌으면
// 첫 페이지 fallback + position-restore-failed 진단이 기록된다.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

/// swap 직전 spine href 목록 (spine 구조 동일성 검증용).
final Expando<List<String>> _preSwapSpine = Expando<List<String>>();

const String _containerXml = '''
<?xml version="1.0"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

/// 3챕터(ch01~ch03) 초안 책 — feature의 spineHref="ch03.xhtml" 전제용.
/// [marker]로 본문을 바꿔 '수정 후 새 bytes'를 표현한다 (spine 구조 동일).
Uint8List _draftEpub3({required String title, required String marker}) {
  String chapter(int n) => '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
      '<p>$n장 본문 ($marker)</p></body></html>';
  return zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-hotswap-draft</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch01.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch02.xhtml" media-type="application/xhtml+xml"/>
    <item id="c3" href="ch03.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
    <itemref idref="c3"/>
  </spine>
</package>
''',
    'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="ch01.xhtml">1장</a></li>
        <li><a href="ch02.xhtml">2장</a></li>
        <li><a href="ch03.xhtml">3장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
    'OEBPS/ch01.xhtml': chapter(1),
    'OEBPS/ch02.xhtml': chapter(2),
    'OEBPS/ch03.xhtml': chapter(3),
  });
}

/// fixtures의 fixedLayoutEpub3()(p1~p4)에 새 페이지 p5를 추가한 책.
Uint8List _fixedLayoutEpub3WithAddedPage() {
  String page(String body) => '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><meta name="viewport" content="width=600, height=800"/></head>
  <body><p>$body</p></body>
</html>
''';
  return zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>고정 레이아웃 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-0006</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
    <meta property="rendition:spread">auto</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
    <item id="p3" href="p3.xhtml" media-type="application/xhtml+xml"/>
    <item id="p4" href="p4.xhtml" media-type="application/xhtml+xml"/>
    <item id="p5" href="p5.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="p1"/>
    <itemref idref="p2" properties="page-spread-left"/>
    <itemref idref="p3" properties="page-spread-right"/>
    <itemref idref="p4"/>
    <itemref idref="p5"/>
  </spine>
</package>
''',
    'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="p1.xhtml">1쪽</a></li></ol>
    </nav>
  </body>
</html>
''',
    'OEBPS/p1.xhtml': page('1쪽'),
    'OEBPS/p2.xhtml': page('2쪽'),
    'OEBPS/p3.xhtml': page('3쪽'),
    'OEBPS/p4.xhtml': page('4쪽'),
    'OEBPS/p5.xhtml': page('새 5쪽'),
  });
}

List<String> _spineHrefs(BddWorld world) =>
    [for (final s in world.requireSession.book.spine) s.href];

/// Usage: Given Author가 EPUB "`<filename>`"을 미리보기로 열었다
Future<void> authorOpenedPreview(BddWorld world, String filename) async {
  world.bytes = _draftEpub3(title: '초안 책', marker: 'v1');
  await world.openSession();
  expect(world.lastError, isNull);
  _preSwapSpine[world] = _spineHrefs(world);
}

/// Usage: Given 현재 BookPosition은 spineHref="`<href>`" charOffset=`<offset>`이다
Future<void> currentBookPositionIs(
    BddWorld world, String href, int offset) async {
  final session = world.requireSession;
  final hrefs = _spineHrefs(world);
  final index = hrefs.indexOf(href);
  expect(index, greaterThanOrEqualTo(0),
      reason: '전제: $href가 현재 spine에 있어야 합니다');
  final denominator = hrefs.length <= 1 ? 1 : hrefs.length - 1;
  await session.jumpTo(EpubReflowablePosition(
    spineHref: href,
    progress: index / denominator,
    charOffset: offset,
  ));
  expect(session.position.spineHref, href);
}

/// Usage: When Author가 EPUB을 수정하여 새 bytes를 전달한다
Future<void> authorSendsNewBytes(BddWorld world) async {
  final newBytes = _draftEpub3(title: '수정된 초안 책', marker: 'v2');
  await world.requireSession.swapSource(EpubSource.bytes(newBytes));
  await world.settle();
}

/// Usage: And spine 구조가 동일하다
Future<void> spineStructureUnchanged(BddWorld world) async {
  final before = _preSwapSpine[world];
  expect(before, isNotNull,
      reason: '전제: authorOpenedPreview에서 swap 전 spine을 기록해야 합니다');
  expect(_spineHrefs(world), orderedEquals(before!));
}

/// Usage: Then 뷰어가 즉시 갱신된다
Future<void> viewerImmediatelyRefreshes(BddWorld world) async {
  final session = world.requireSession;
  // 재-open 없이 같은 session에 새 책이 반영된다.
  expect(session.book.metadata.title, '수정된 초안 책');
  // swap은 progress 이벤트를 발사해 뷰어 갱신을 트리거한다.
  expect(world.progressEvents, isNotEmpty);
}

/// Usage: Then BookPosition이 복원된다
Future<void> bookPositionRestored(BddWorld world) async {
  final position = world.requireSession.position;
  expect(position, isA<EpubReflowablePosition>());
  final reflowable = position as EpubReflowablePosition;
  expect(reflowable.spineHref, 'ch03.xhtml');
  // charOffset 5는 ch03 본문("3장 본문 (vN)", 평문 10자) 범위 내 → swap 후에도
  // anchor-of-record로 보존(S12.3 재앵커: 범위 내 offset은 유지, out-of-range만
  // CFI/clamp 보강).
  expect(reflowable.charOffset, 5);
  // 복원 성공 — fallback 진단이 없어야 한다.
  expect(world.diagnosticCodes, isNot(contains('position-restore-failed')));
}

/// Usage: Given Author가 책을 미리보기 중이다
Future<void> authorPreviewingBook(BddWorld world) async {
  world.bytes = validEpub3();
  await world.openSession();
  expect(world.lastError, isNull);
  // 미리보기 중 — 2번째 챕터(ch2.xhtml)를 읽는 중이다.
  await world.requireSession.nextPage();
  expect(world.requireSession.position.spineHref, 'ch2.xhtml');
}

/// Usage: When Author가 spine 항목 순서를 변경한 새 EPUB을 전달한다
Future<void> authorSendsEpubWithReorderedSpine(BddWorld world) async {
  // spine 구조가 바뀌어 현재 위치(ch2.xhtml)가 새 spine에 없는 책.
  await world.requireSession.swapSource(EpubSource.bytes(singleChapterEpub3()));
  await world.settle();
}

/// Usage: Then 뷰어가 갱신된다
Future<void> viewerRefreshes(BddWorld world) async {
  expect(world.requireSession.book.metadata.title, '단일 챕터 책');
}

/// Usage: Then BookPosition 복원이 실패하면 spine의 첫 페이지로 fallback한다
Future<void> fallbackToFirstSpinePageOnFailure(BddWorld world) async {
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
  expect(session.progress, 0.0);
  await diagnosticEventIsRecorded(world, 'position-restore-failed');
}

/// Usage: Then 알림 "`<message>`"가 표시된다
Future<void> notificationShown(BddWorld world, String message) async {
  final messages =
      world.requireSession.diagnostics.unresolvedIssues.map((i) => i.message);
  expect(messages, contains(message));
}

/// Usage: Given Fixed Layout EPUB이 미리보기로 열려 있다
Future<void> fixedLayoutEpubInPreview(BddWorld world) async {
  world.bytes = fixedLayoutEpub3();
  await world.openSession();
  expect(world.lastError, isNull);
  expect(world.requireSession.book.layout, EpubLayout.fixedLayout);
}

/// Usage: When Author가 새 페이지를 추가하고 bytes를 갱신한다
Future<void> authorAddsPageAndUpdatesBytes(BddWorld world) async {
  await world.requireSession
      .swapSource(EpubSource.bytes(_fixedLayoutEpub3WithAddedPage()));
  await world.settle();
}

/// Usage: Then 새 페이지가 spine에 반영된다
Future<void> newPageReflectedInSpine(BddWorld world) async {
  final session = world.requireSession;
  final hrefs = _spineHrefs(world);
  expect(hrefs, hasLength(5));
  expect(hrefs, contains('p5.xhtml'));
  // Fixed Layout 유지 + 기존 위치(p1.xhtml) 보존.
  expect(session.book.layout, EpubLayout.fixedLayout);
  expect(session.position.spineHref, 'p1.xhtml');
}
