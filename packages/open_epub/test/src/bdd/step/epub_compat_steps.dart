// BDD Steps for epub_compat.feature
// Story: S1.14~S1.18 (#30~#34) — 보정 카탈로그 + BookSessionDiagnostics
//
// 진단 패널/디버그 메뉴/클립보드 버튼 UI는 kobic 운영자 도구(E3) 범위 —
// 여기서는 패널이 소비하는 패키지 계약(BookSessionDiagnostics:
// appliedPatches의 patchId/description/severity/impact, toJson)을 검증한다.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub.dart';

import 'package:open_epub_engine/testing.dart';
import '_common_steps.dart';

/// "Copy to Clipboard" step이 복사한 JSON (시나리오 내 When → Then 전달).
String? _copiedDiagnosticsJson;

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

const String _navTwoChapters = '''
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
''';

/// spine 첫 항목이 cover인 책 (cover-skip 보정 트리거).
Uint8List _coverFirstSpineEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>표지 포함 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-compat-cover</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="cover"/>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>
''',
      'OEBPS/nav.xhtml': _navTwoChapters,
      'OEBPS/cover.xhtml': '<html><body>표지</body></html>',
      'OEBPS/ch1.xhtml': '<html><body>1장</body></html>',
      'OEBPS/ch2.xhtml': '<html><body>2장</body></html>',
    });

/// 목차가 존재하지 않는 spine(ghost.xhtml)을 가리키는 책
/// (broken-spine-href 보정 트리거 — OpfParser가 깨진 spine itemref를 이미
/// 걸러내므로, EpubBook 수준 보정은 "죽은 목차 링크 정리"로 발현된다).
Uint8List _deadTocLinkEpub3() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>죽은 목차 링크 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-compat-deadlink</dc:identifier>
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
        <li><a href="ghost.xhtml">유령 장</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
      'OEBPS/ch1.xhtml': '<html><body>1장</body></html>',
      'OEBPS/ch2.xhtml': '<html><body>2장</body></html>',
    });

/// Usage: Given 운영자가 디버그 메뉴에서 책을 열었다
/// 디버그 메뉴는 kobic 운영자 UI(E3) — 하니스에서는 보정이 발생하는 책
/// (sparse NCX + mimetype 누락)을 직접 연다.
Future<void> operatorOpenedBookViaDebugMenu(BddWorld world) async {
  world.bytes = sparseNcxEpub2();
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: When 운영자가 "Diagnostics" 메뉴를 탭한다
/// 패널 UI 대신, 패널의 데이터 소스인 session.diagnostics가 노출됨을 보증.
Future<void> operatorTapsDiagnostics(BddWorld world) async {
  expect(world.requireSession.diagnostics, isA<BookSessionDiagnostics>());
}

/// Usage: Then 적용된 보정 카드 목록이 표시된다
Future<void> appliedPatchCardsShown(BddWorld world) async {
  expect(world.requireSession.diagnostics.appliedPatches, isNotEmpty);
}

/// Usage: Then 각 카드는 patchId, description, severity, impact를 보여준다
Future<void> eachCardShowsPatchFields(BddWorld world) async {
  for (final patch in world.requireSession.diagnostics.appliedPatches) {
    expect(patch.patchId, isNotEmpty);
    expect(patch.description, isNotEmpty);
    expect(PatchSeverity.values, contains(patch.severity));
    expect(
      patch.toJson().keys,
      containsAll(['patchId', 'description', 'severity', 'impact']),
    );
  }
}

/// Usage: Given EPUB에 `<issue>` 문제가 있다
Future<void> epubHasIssue(BddWorld world, String issue) async {
  world.bytes = switch (issue) {
    'NCX 항목 30%만 있음' => sparseNcxEpub2(),
    'spine[0]에 cover 메타' => _coverFirstSpineEpub3(),
    'spine href가 OPF에 없음' => _deadTocLinkEpub3(),
    'mimetype 파일 누락' => swappedEpub3(),
    'NCX/nav 모두 빈' => noTocEpub3(),
    _ => fail('알 수 없는 issue: $issue'),
  };
}

/// Usage: When 책이 열린다
Future<void> bookIsOpened(BddWorld world) async {
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Then "`<patchId>`" 보정이 적용된다
Future<void> patchApplied(BddWorld world, String patchId) async {
  expect(world.diagnosticCodes, contains(patchId));
}

/// Usage: Then BookSessionDiagnostics에 `<patchId>`가 severity=`<severity>`로 기록된다
Future<void> diagnosticsRecordsPatchWithSeverity(
    BddWorld world, String patchId, String severity) async {
  final patch = world.requireSession.diagnostics.appliedPatches
      .singleWhere((p) => p.patchId == patchId);
  expect(patch.severity.name, severity);
}

/// Usage: Given 진단 패널이 열려 있다
Future<void> diagnosticsPanelOpen(BddWorld world) async {
  _copiedDiagnosticsJson = null;
  if (world.session == null) {
    world.bytes ??= sparseNcxEpub2();
    await world.openSession();
    expect(world.lastError, isNull);
  }
  expect(world.requireSession.diagnostics.appliedPatches, isNotEmpty);
}

/// Usage: When 운영자가 "Copy to Clipboard"를 탭한다
/// 클립보드 버튼은 운영자 패널 UI(E3) — 복사 payload를 만드는 패키지 계약
/// (diagnostics.toJson)을 실행한다.
Future<void> operatorTapsCopyToClipboard(BddWorld world) async {
  _copiedDiagnosticsJson = world.requireSession.diagnostics.toJson();
}

/// Usage: Then 진단 결과 JSON이 클립보드에 복사된다
Future<void> diagnosticsJsonCopiedToClipboard(BddWorld world) async {
  expect(_copiedDiagnosticsJson, isNotNull);
  final decoded = jsonDecode(_copiedDiagnosticsJson!) as Map<String, dynamic>;
  expect(decoded.keys, containsAll(['appliedPatches', 'unresolvedIssues']));
  final copiedIds = (decoded['appliedPatches'] as List)
      .cast<Map<String, dynamic>>()
      .map((p) => p['patchId']);
  expect(
    copiedIds,
    containsAll(
      world.requireSession.diagnostics.appliedPatches.map((p) => p.patchId),
    ),
  );
}
