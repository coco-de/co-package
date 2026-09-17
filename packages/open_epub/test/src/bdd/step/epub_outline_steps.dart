// BDD Steps for epub_outline.feature
// Story: S1.2, S1.3, S1.15 — NCX/nav 목차 + sparse-ncx/empty-toc 보정
//
// '목차 패널' UI는 kobic 호스트 책임 — 패키지 레벨에서는
// session.book.outline(목차 트리)과 jumpTo(목차 항목 탭→이동)로 치환 검증한다.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

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

/// 챕터 i의 목차 제목. 3장은 시나리오 '목차 항목 클릭 시 이동'이 탭하는 제목.
String _chapterTitle(int i) => i == 3 ? '3장. 시작하기' : '$i장. 챕터';

/// nav.xhtml에 [chapters]개 챕터가 정의된 EPUB 3.
Uint8List _navEpub3(int chapters) {
  final manifest = StringBuffer();
  final spine = StringBuffer();
  final navItems = StringBuffer();
  final files = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
  };
  for (var i = 1; i <= chapters; i++) {
    manifest.writeln(
        '<item id="c$i" href="ch$i.xhtml" media-type="application/xhtml+xml"/>');
    spine.writeln('<itemref idref="c$i"/>');
    navItems.writeln('<li><a href="ch$i.xhtml">${_chapterTitle(i)}</a></li>');
    files['OEBPS/ch$i.xhtml'] =
        '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
        '<p>$i장 본문 시작</p></body></html>';
  }
  files['OEBPS/content.opf'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>목차 $chapters챕터 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-outline-nav</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    $manifest
  </manifest>
  <spine>
    $spine
  </spine>
</package>
''';
  files['OEBPS/nav.xhtml'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>$navItems</ol></nav></body>
</html>
''';
  return zipEpub(files);
}

/// NCX가 spine [spineCount]개 중 [percent]%만 커버하는 EPUB 2.
Uint8List _sparseNcxEpub2({required int spineCount, required int percent}) {
  final covered = (spineCount * percent / 100).round();
  final manifest = StringBuffer();
  final spine = StringBuffer();
  final navPoints = StringBuffer();
  final files = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
  };
  for (var i = 1; i <= spineCount; i++) {
    manifest.writeln(
        '<item id="c$i" href="ch$i.xhtml" media-type="application/xhtml+xml"/>');
    spine.writeln('<itemref idref="c$i"/>');
    if (i <= covered) {
      navPoints.writeln('''
<navPoint id="n$i">
  <navLabel><text>$i장</text></navLabel>
  <content src="ch$i.xhtml"/>
</navPoint>''');
    }
    files['OEBPS/ch$i.xhtml'] = '<html><body>$i</body></html>';
  }
  files['OEBPS/content.opf'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>sparse NCX $percent% 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-outline-sparse</dc:identifier>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    $manifest
  </manifest>
  <spine toc="ncx">
    $spine
  </spine>
</package>
''';
  files['OEBPS/toc.ncx'] = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    $navPoints
  </navMap>
</ncx>
''';
  return zipEpub(files);
}

/// 목차 트리 전체(중첩 포함)의 spineHref를 평탄화한다.
List<String> _flattenOutlineHrefs(List<EpubOutlineItem> items) => [
      for (final item in items) ...[
        item.spineHref,
        ..._flattenOutlineHrefs(item.children),
      ],
    ];

/// 목차 트리에서 [title] 항목을 깊이 우선으로 찾는다.
EpubOutlineItem? _findByTitle(List<EpubOutlineItem> items, String title) {
  for (final item in items) {
    if (item.title == title) return item;
    final nested = _findByTitle(item.children, title);
    if (nested != null) return nested;
  }
  return null;
}

/// Usage: Given EPUB 3 책의 nav.xhtml에 `<n>`개 챕터가 정의되어 있다
Future<void> navHasChapters(BddWorld world, int n) async {
  world.bytes = _navEpub3(n);
}

/// Usage: When 사용자가 목차 패널을 연다
/// 목차 패널 UI는 kobic 호스트 책임 — 패키지는 세션을 열고 목차 트리를
/// 노출하는 것까지 보증한다.
Future<void> userOpensOutlinePanel(BddWorld world) async {
  if (world.session == null) await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Then 목차 트리에 `<n>`개 챕터가 표시된다
Future<void> outlineTreeShowsChapters(BddWorld world, int n) async {
  final outline = world.requireSession.book.outline;
  expect(_flattenOutlineHrefs(outline.items), hasLength(n));
}

/// Usage: Given 목차 패널이 열려 있다
Future<void> outlinePanelIsOpen(BddWorld world) async {
  world.bytes ??= _navEpub3(5);
  if (world.session == null) await world.openSession();
  expect(world.lastError, isNull);
  expect(world.requireSession.book.outline.items, isNotEmpty);
}

/// Usage: When 사용자가 "`<title>`" 항목을 탭한다
/// 목차 항목 탭 = 해당 항목 href로 [EpubBookSession.jumpTo] 치환.
Future<void> userTapsOutlineItem(BddWorld world, String title) async {
  final session = world.requireSession;
  final item = _findByTitle(session.book.outline.items, title);
  expect(item, isNotNull, reason: '목차에 "$title" 항목이 있어야 합니다');
  final hrefs = [
    for (final s in session.book.spine)
      if (s.linear) s.href,
  ];
  final index = hrefs.indexOf(item!.spineHref);
  expect(index, isNonNegative, reason: '목차 항목의 spineHref가 spine에 존재해야 합니다');
  final denom = hrefs.length <= 1 ? 1 : hrefs.length - 1;
  await session.jumpTo(EpubReflowablePosition(
    spineHref: item.spineHref,
    progress: index / denom,
    charOffset: item.charOffset ?? 0,
  ));
  expect(session.position.spineHref, item.spineHref);
  await world.settle();
}

/// Usage: Then 본문 첫 부분이 표시된다
Future<void> bodyShowsFirstPortion(BddWorld world) async {
  final session = world.requireSession;
  final position = session.position;
  expect(position, isA<EpubReflowablePosition>());
  expect((position as EpubReflowablePosition).charOffset, 0);
  final xhtml = session.readSpineXhtml(position.spineHref);
  expect(xhtml, isNotNull);
  expect(xhtml, contains('본문 시작'));
}

/// Usage: Given EPUB 2의 NCX에 spine 항목의 `<percent>`%만 등록되어 있다
Future<void> ncxHasSparseSpineEntries(BddWorld world, int percent) async {
  world.bytes = _sparseNcxEpub2(spineCount: 10, percent: percent);
}

/// Usage: When 책이 열린다
Future<void> bookIsOpened(BddWorld world) async {
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Then 누락 spine이 NCX에 자동 추가되어 표시된다
Future<void> missingSpineAutoAddedToNcx(BddWorld world) async {
  final session = world.requireSession;
  final spineHrefs = [
    for (final s in session.book.spine)
      if (s.linear) s.href,
  ];
  final outlineHrefs = _flattenOutlineHrefs(session.book.outline.items);
  expect(outlineHrefs, containsAll(spineHrefs),
      reason: '보정 후 목차가 모든 linear spine을 커버해야 합니다');
}

/// Usage: Then BookSessionDiagnostics에 "`<patchId>`" patch가 기록된다
Future<void> diagnosticsRecordsPatch(BddWorld world, String patchId) async {
  final applied =
      world.requireSession.diagnostics.appliedPatches.map((p) => p.patchId);
  expect(applied, contains(patchId));
}

/// Usage: Given EPUB의 NCX와 nav가 모두 비어 있다
Future<void> ncxAndNavAreEmpty(BddWorld world) async {
  world.bytes = noTocEpub3();
}

/// Usage: Then spine 기반 자동 목차가 생성된다
Future<void> spineBasedOutlineGenerated(BddWorld world) async {
  final session = world.requireSession;
  final spineHrefs = [
    for (final s in session.book.spine)
      if (s.linear) s.href,
  ];
  final outlineHrefs = _flattenOutlineHrefs(session.book.outline.items);
  expect(outlineHrefs, spineHrefs,
      reason: '빈 목차는 linear spine 순서 그대로 자동 생성되어야 합니다');
  for (final item in session.book.outline.items) {
    expect(item.title, isNotEmpty);
  }
}
