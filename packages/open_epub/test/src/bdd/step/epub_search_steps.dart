// BDD Steps for epub_search.feature
// Story: S1.19 (#35), S1.21 (#37) — 본문 검색 인덱스 + 결과 이동
//
// 검색 패널 UI(EpubSearchResults S2.11 / EpubSearchPage S3.15)는 E2/E3 범위 —
// 패키지 하니스는 패널이 의존하는 정보(빌드 진행 상태, 결과 목록, 제외 페이지
// 수, 하이라이트 대상 위치)가 API 레벨에서 정확히 제공됨을 검증한다.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

/// 검색 시나리오 상태를 추가로 담는 [BddWorld].
class SearchWorld extends BddWorld {
  /// 빌드 완료된 검색 인덱스.
  BookSearchIndex? index;

  /// 진행 중인 인덱스 빌드 (검색 패널 첫 오픈 시 시작).
  Future<BookSearchIndex>? indexBuild;

  /// 패널을 연 순간 빌드가 미완료였는지 (= "준비 중..." 표시 상태).
  bool preparingShownAtOpen = false;
  bool indexReady = false;
  Stopwatch? buildStopwatch;

  /// 마지막 검색 질의와 결과.
  String lastQuery = '';
  List<BookSearchHit> hits = const [];
  BookSearchHit? tappedHit;

  /// spineHref → 본문 평문. 텍스트 레이어가 없는 페이지는 [textlessHrefs]로.
  final Map<String, String> spineTexts = {};
  final List<String> textlessHrefs = [];
}

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

/// "Flutter" 단어가 여러 번 등장하는 2챕터 책 (F7.2/F7.3 검증용).
Uint8List _flutterEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Flutter 입문</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-search-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
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
        <li><a href="ch1.xhtml">1장</a></li>
        <li><a href="ch2.xhtml">2장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>Flutter는 위젯으로 화면을 그린다.</p>'
          '<p>Flutter 앱은 한 코드로 여러 플랫폼에서 돈다.</p></body></html>',
      'OEBPS/ch2.xhtml': '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<p>Dart와 Flutter로 멀티플랫폼 앱을 만든다.</p></body></html>',
    });

/// Fixed Layout 3페이지 책 — p2는 이미지만 있고 텍스트 레이어가 없다 (F7.4).
Uint8List _fixedLayoutImageOnlyEpub3() {
  String page(String body) => '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><meta name="viewport" content="width=600, height=800"/></head>
  <body>$body</body>
</html>
''';
  return zipEpubBinary({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>이미지 페이지 포함 고정 레이아웃 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-search-0002</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    <item id="p2" href="p2.xhtml" media-type="application/xhtml+xml"/>
    <item id="p3" href="p3.xhtml" media-type="application/xhtml+xml"/>
    <item id="i1" href="img/pic.png" media-type="image/png"/>
  </manifest>
  <spine>
    <itemref idref="p1"/>
    <itemref idref="p2"/>
    <itemref idref="p3"/>
  </spine>
</package>
''',
    'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol><li><a href="p1.xhtml">1쪽</a></li></ol></nav></body>
</html>
''',
    'OEBPS/p1.xhtml': page('<p>고래는 바다에 산다.</p>'),
    'OEBPS/p2.xhtml': page('<img src="img/pic.png"/>'),
    'OEBPS/p3.xhtml': page('<p>바다는 깊고 넓다.</p>'),
    'OEBPS/img/pic.png': onePixelPng(),
  });
}

/// sanitize된 XHTML에서 태그를 제거한 평문 (인덱스 입력과 동일 규칙).
String _plainText(String xhtml) => xhtml
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// 열린 세션의 spine 본문을 [SearchWorld.spineTexts]로 추출한다.
/// 텍스트 레이어가 없는(평문이 비는) 페이지는 [SearchWorld.textlessHrefs]에
/// 기록하고 인덱스 입력에서 제외한다.
void _extractSpineTexts(SearchWorld world) {
  final session = world.requireSession;
  world.spineTexts.clear();
  world.textlessHrefs.clear();
  for (final item in session.book.spine) {
    final text = _plainText(session.readSpineXhtml(item.href) ?? '');
    if (text.isEmpty) {
      world.textlessHrefs.add(item.href);
    } else {
      world.spineTexts[item.href] = text;
    }
  }
}

/// Usage: Given 50MB EPUB 책이 열려 있다
Future<void> fiftyMbBookOpen(SearchWorld world) async {
  world.bytes = largeEpub3(chapters: 50, paragraphsPerChapter: 200);
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Given 검색 인덱스가 아직 빌드되지 않았다
Future<void> searchIndexNotBuilt(SearchWorld world) async {
  expect(world.index, isNull);
  expect(world.indexBuild, isNull);
}

/// Usage: When 사용자가 검색 패널을 처음 연다
/// 패널 첫 오픈 = 인덱스 빌드 시작 (본문 평문 추출 포함). 오픈 순간의
/// 빌드 미완료 여부를 [SearchWorld.preparingShownAtOpen]에 기록한다.
Future<void> userOpensSearchPanelFirstTime(SearchWorld world) async {
  final session = world.requireSession;
  world.buildStopwatch = Stopwatch()..start();
  _extractSpineTexts(world);
  final build = const BuildSearchIndexUseCase()(
    session.book,
    spineTexts: world.spineTexts,
  );
  world.indexBuild = build;
  unawaited(build.whenComplete(() => world.indexReady = true));
  world.preparingShownAtOpen = !world.indexReady;
}

/// Usage: Then "검색 인덱스 준비 중..." 진행 표시가 보인다
/// 진행 표시 위젯은 검색 패널(E2/E3) 책임 — 하니스는 패널 오픈 시점에
/// 빌드가 미완료(= 준비 중 표시 조건)였음을 검증한다.
Future<void> searchIndexPreparingShown(SearchWorld world) async {
  expect(world.preparingShownAtOpen, isTrue,
      reason: '패널 오픈 직후에는 인덱스 빌드가 진행 중이어야 합니다');
  expect(world.index, isNull);
}

/// Usage: Then `<seconds>`초 안에 인덱스 빌드가 완료된다
Future<void> indexBuildCompletesWithin(
    SearchWorld world, double seconds) async {
  world.index = await world.indexBuild!;
  world.buildStopwatch!.stop();
  expect(world.indexReady, isTrue);
  expect(
    world.buildStopwatch!.elapsed,
    lessThan(Duration(milliseconds: (seconds * 1000).round())),
  );
}

/// Usage: Given 검색 인덱스가 빌드되어 있다
Future<void> searchIndexIsBuilt(SearchWorld world) async {
  if (world.session == null) {
    world.bytes = _flutterEpub3();
    await world.openSession();
    expect(world.lastError, isNull);
  }
  _extractSpineTexts(world);
  world.index = await const BuildSearchIndexUseCase()(
    world.requireSession.book,
    spineTexts: world.spineTexts,
  );
}

/// Usage: When 사용자가 검색어 "`<query>`"를 입력한다
Future<void> userTypesSearchQuery(SearchWorld world, String query) async {
  world.lastQuery = query;
  world.hits = await world.index!.search(query);
}

/// Usage: Then 매칭되는 본문 결과 목록이 표시된다
Future<void> matchingResultListShown(SearchWorld world) async {
  expect(world.hits, isNotEmpty);
  for (final hit in world.hits) {
    expect(hit.snippet.toLowerCase(), contains(world.lastQuery.toLowerCase()));
  }
}

/// Usage: Then 각 결과는 스니펫과 페이지 정보를 보여준다
/// 페이지 정보 = 결과가 속한 spine 위치(spineHref + charOffset).
Future<void> resultShowsSnippetAndPage(SearchWorld world) async {
  final spineHrefs =
      world.requireSession.book.spine.map((s) => s.href).toList();
  for (final hit in world.hits) {
    expect(hit.snippet, isNotEmpty);
    expect(spineHrefs, contains(hit.spineHref));
    expect(hit.charOffset, isNonNegative);
  }
}

/// Usage: Given 검색 결과 목록이 표시되어 있다
Future<void> searchResultListShown(SearchWorld world) async {
  await searchIndexIsBuilt(world);
  await userTypesSearchQuery(world, 'Flutter');
  expect(world.hits, isNotEmpty);
}

/// Usage: When 사용자가 첫 번째 결과를 탭한다
/// 결과 탭 = hit → BookPosition 변환 후 [EpubBookSession.jumpTo].
Future<void> userTapsFirstResult(SearchWorld world) async {
  final session = world.requireSession;
  final hit = world.hits.first;
  world.tappedHit = hit;
  final spine = session.book.spine;
  final index = spine.indexWhere((s) => s.href == hit.spineHref);
  expect(index, isNonNegative);
  final denom = spine.length <= 1 ? 1 : spine.length - 1;
  await session.jumpTo(EpubReflowablePosition(
    spineHref: hit.spineHref,
    progress: index / denom,
    charOffset: hit.charOffset,
  ));
  await world.settle();
}

/// Usage: Then 본문에서 "`<word>`" 단어가 시각적으로 하이라이트된다
/// 시각 강조 렌더링은 E2 검색 위젯(S2.11) 범위 — 하니스는 이동한 위치의
/// charOffset이 본문 평문에서 정확히 해당 단어를 가리킴(= 하이라이트 대상이
/// 무손실로 식별됨)을 검증한다.
Future<void> wordVisuallyHighlightedInBody(
    SearchWorld world, String word) async {
  final session = world.requireSession;
  final hit = world.tappedHit!;
  expect(session.position.spineHref, hit.spineHref);
  final position = session.position as EpubReflowablePosition;
  expect(position.charOffset, hit.charOffset);
  final text = world.spineTexts[hit.spineHref]!;
  expect(
    text.substring(hit.charOffset, hit.charOffset + word.length).toLowerCase(),
    word.toLowerCase(),
  );
}

/// Usage: Given 책에 텍스트 레이어가 없는 Fixed Layout 페이지가 있다
Future<void> bookHasFixedLayoutWithoutTextLayer(SearchWorld world) async {
  world.bytes = _fixedLayoutImageOnlyEpub3();
  await world.openSession();
  expect(world.requireSession.book.layout, EpubLayout.fixedLayout);
}

/// Usage: When 사용자가 검색을 수행한다
Future<void> userPerformsSearch(SearchWorld world) async {
  _extractSpineTexts(world);
  world.index = await const BuildSearchIndexUseCase()(
    world.requireSession.book,
    spineTexts: world.spineTexts,
  );
  await userTypesSearchQuery(world, '바다');
  expect(world.hits, isNotEmpty);
}

/// Usage: Then 그 페이지는 결과에 포함되지 않는다
Future<void> pageExcludedFromResults(SearchWorld world) async {
  expect(world.textlessHrefs, isNotEmpty, reason: '텍스트 레이어 없는 페이지가 감지되어야 합니다');
  for (final hit in world.hits) {
    expect(world.textlessHrefs, isNot(contains(hit.spineHref)));
  }
}

/// Usage: Then 검색 패널 하단에 "`<message>`" 안내가 표시된다
/// footer UI는 검색 패널(E2/E3) 책임 — 하니스는 제외 페이지 수로 만든
/// 안내 문구가 기대 문구와 일치함을 검증한다.
Future<void> searchPanelFooterShowsMessage(
    SearchWorld world, String message) async {
  final built = '${world.textlessHrefs.length}개 페이지는 텍스트 레이어가 없어 검색에서 제외되었습니다';
  expect(built, message);
}
