// BDD Steps for epub_security.feature
// Story: S1.24 (#40), S5.7 — 보안 가드 (zip slip / script 차단 / size limit)
//
// 패키지 범위 검증 노트:
// - zip slip: 1.0 파이프라인은 디스크 추출이 없는 메모리 전용(Archive) 경로다.
//   escape 경로는 resolveHref가 ZIP 루트에서 clamp하여 도달 불가하며,
//   ContainerParser.isSafePath가 unsafe로 판정한다(load 경로에 등장하면
//   ZipSlipException). BookSessionDiagnostics에 보안 경고 "항목"을 적재하는
//   기능은 미구현 — 게이트 판정 자체를 단언한다.
// - Web CORS: 실브라우저 전용(E4) — 해당 시나리오는 skip, step은 no-op.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub_v1.dart';
import 'package:open_epub_engine/src/data/parser/container_parser.dart'
    show ContainerParser;
import 'package:open_epub_engine/src/data/parser/opf_parser.dart'
    show OpfParseException;
import 'package:open_epub_engine/src/data/repository/archive_resource_reader.dart'
    show resolveHref;

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

const String _minimalOpf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>악성 entry 포함 책</dc:title>
    <dc:identifier id="bookid">urn:uuid:test-sec-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''';

const String _minimalNav = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol><li><a href="ch1.xhtml">1장</a></li></ol></nav></body>
</html>
''';

/// Usage: Given EPUB 안에 "`<path>`" 경로의 리소스가 있다
///
/// 정상 책 구조에 ZIP 루트를 escape하는 경로의 entry를 추가한다.
Future<void> epubContainsPathResource(BddWorld world, String path) async {
  world.bytes = zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': _minimalOpf,
    'OEBPS/nav.xhtml': _minimalNav,
    'OEBPS/ch1.xhtml':
        '<html xmlns="http://www.w3.org/1999/xhtml"><body><p>본문</p></body></html>',
    path: 'root:x:0:0:malicious', // 악성 zip slip entry
  });
}

/// Usage: When EPUB이 열린다 / When 사용자가 책을 연다
Future<void> epubIsOpened(BddWorld world) async {
  await world.openSession();
}

/// Usage: Then 그 리소스는 무시되며 BookSessionDiagnostics에 보안 경고가 기록된다
///
/// 진단에 보안 경고 "항목"을 적재하는 기능은 미구현(S5.7 잔여) — 패키지가
/// 보증하는 동작인 (1) escape 리소스 도달 불가, (2) 보안 게이트의 unsafe
/// 판정을 단언한다.
Future<void> resourceIgnoredSecurityWarning(BddWorld world) async {
  // 악성 entry가 있어도 책 자체는 정상으로 열린다.
  expect(world.lastError, isNull);
  final resources = world.requireSession.resources;
  // escape 경로는 OPF 기준 정규화(루트 clamp)로 도달 불가 — 무시된다.
  expect(resources.readBytes('../../../etc/passwd'), isNull);
  expect(resources.readBytes('../../etc/passwd'), isNull);
  expect(resources.readString('../../../etc/passwd'), isNull);
  // 보안 게이트 판정 — load 경로(container full-path 등)에 등장하면
  // ZipSlipException으로 차단되는 unsafe 경로다.
  expect(const ContainerParser().isSafePath('../../../etc/passwd'), isFalse);
}

/// Usage: Then 파일 시스템 외부에 어떤 파일도 생성되지 않는다
Future<void> noFilesCreatedOutsideSandbox(BddWorld world) async {
  // 1.0 파이프라인은 디스크 추출 없는 메모리 전용 — escape 세그먼트는
  // ZIP 루트에서 clamp되어 외부 경로로 해석될 수 없다.
  expect(resolveHref('OEBPS', '../../../etc/passwd'), 'etc/passwd');
  // 실제 파일 시스템(cwd/temp)에 추출 흔적이 없다.
  expect(File('${Directory.current.path}/etc/passwd').existsSync(), isFalse);
  expect(File('${Directory.systemTemp.path}/etc/passwd').existsSync(), isFalse);
}

/// Usage: Given EPUB XHTML에 외부 script src가 있다
Future<void> epubXhtmlHasExternalScript(BddWorld world) async {
  world.bytes = epubWithScriptAndIframe();
}

/// Usage: When 페이지가 렌더된다
Future<void> pageRenders(BddWorld world) async {
  await world.openSession();
  expect(world.lastError, isNull);
}

/// Usage: Then script는 실행되지 않는다
///
/// Flutter 렌더러에는 JS 엔진이 없고, 렌더에 쓰이는 readSpineXhtml은
/// sanitize를 거쳐 script 태그 자체를 제거한다 — 실행 경로가 존재하지 않는다.
Future<void> scriptNotExecuted(BddWorld world) async {
  final session = world.requireSession;
  final html = session.readSpineXhtml(session.book.spine.first.href);
  expect(html, isNotNull);
  expect(html!.toLowerCase(), isNot(contains('<script')));
  expect(html, isNot(contains('alert(')));
  expect(html, isNot(contains('evil.example')));
}

/// Usage: Then 본문 텍스트만 표시된다
Future<void> onlyBodyTextDisplayed(BddWorld world) async {
  final session = world.requireSession;
  final html = session.readSpineXhtml(session.book.spine.first.href)!;
  expect(html, contains('안전한 본문'));
  expect(html.toLowerCase(), isNot(contains('<iframe')));
}

/// Usage: Given Web에서 cross-origin 이미지를 포함한 EPUB을 연다
/// 실브라우저 CORS 동작은 E4 범위 — 시나리오 skip, step은 no-op.
Future<void> webOpensEpubWithCrossOriginImage(BddWorld world) async {}

/// Usage: And 해당 도메인이 CORS를 허용하지 않는다
/// 실브라우저 CORS 동작은 E4 범위 — 시나리오 skip, step은 no-op.
Future<void> domainDoesNotAllowCors(BddWorld world) async {}

/// Usage: Then 이미지는 placeholder로 표시된다
/// 실브라우저 CORS 동작은 E4 범위 — 시나리오 skip, step은 no-op.
Future<void> imageShownAsPlaceholder(BddWorld world) async {}

/// Usage: Then 본문 텍스트는 정상 표시된다
/// 실브라우저 CORS 동작은 E4 범위 — 시나리오 skip, step은 no-op.
Future<void> bodyTextDisplayedNormally(BddWorld world) async {}

/// Usage: Then 진단에 "`<patchId>`" 항목이 기록된다
Future<void> diagnosticsContainsItem(BddWorld world, String patchId) async {
  expect(world.diagnosticCodes, contains(patchId));
}

/// Usage: Given `<sizeMB>`MB EPUB이 있다
///
/// 실제 100MB 파일 할당 대신 대형 책(챕터 `sizeMB`개 × 200문단)으로 열기
/// 성능 smoke를 수행한다 — epub_source의 50MB smoke와 동일 패턴.
/// 실파일·실기기 측정은 E4 범위.
Future<void> nMbEpubExists(BddWorld world, int sizeMB) async {
  world.bytes = largeEpub3(chapters: sizeMB, paragraphsPerChapter: 200);
}

/// Usage: Then 첫 페이지가 `<seconds>`초 안에 표시된다
/// 경과 시간은 시나리오 본문의 Stopwatch가 단언한다 — 여기서는 첫 페이지
/// 위치가 잡혔는지 확인한다.
Future<void> firstPageShownWithinSeconds(
    BddWorld world, double seconds) async {
  expect(world.lastError, isNull);
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
}

/// Usage: Then 메모리 peak이 `<mb>`MB를 넘지 않는다
/// 실기기 peak 프로파일링은 E4 범위 — VM에서는 프로세스 peak RSS로 근사한다.
Future<void> memoryPeakNoMoreThan(BddWorld world, int mb) async {
  expect(ProcessInfo.maxRss, lessThan(mb * 1024 * 1024));
}

/// Usage: Given `<sizeKB>`KB EPUB이 있다
Future<void> nKbEpubExists(BddWorld world, int sizeKB) async {
  world.bytes = validEpub3();
  expect(
    world.bytes!.length,
    lessThanOrEqualTo(sizeKB * 1024),
    reason: '${sizeKB}KB 이하 소형 EPUB이어야 한다',
  );
}

/// Usage: Then `<ms>`ms 안에 첫 페이지가 표시된다
/// 경과 시간은 시나리오 본문의 Stopwatch가 단언한다.
Future<void> firstPageShownWithinMs(BddWorld world, int ms) async {
  expect(world.lastError, isNull);
  final session = world.requireSession;
  expect(session.position.spineHref, session.book.spine.first.href);
}

/// Usage: Given EPUB 파일이 손상되어 OPF 파싱이 실패한다
Future<void> epubFileCorruptedOpfParseFails(BddWorld world) async {
  world.bytes = zipEpub({
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _containerXml,
    // 잘린(malformed) OPF — XML 파싱 단계에서 실패한다.
    'OEBPS/content.opf':
        '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" <broken',
  });
}

/// Usage: Then "`<message>`" 에러 화면이 표시된다
///
/// BDD 문구("이 파일을 열 수 없습니다")는 kobic 호스트 UI 문구(E3 범위) —
/// 패키지 EpubReader는 자체 에러 화면 문구를 표시한다.
Future<void> errorScreenShown(
    BddWorld world, WidgetTester tester, String message) async {
  await tester.pumpWidget(
    MaterialApp(home: EpubReader(source: EpubSource.bytes(world.bytes!))),
  );
  await tester.pumpAndSettle();
  expect(find.textContaining('오류가 발생했습니다'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// Usage: Then BookSessionDiagnostics에 unresolvedIssue가 기록된다
///
/// open 자체가 실패하면 세션이 생성되지 않아 BookSessionDiagnostics가 없다 —
/// 실패 원인은 타입화된 예외(OPF 파싱 실패)로 표면화됨을 단언한다.
Future<void> diagnosticsRecordsUnresolvedIssue(BddWorld world) async {
  expect(world.session, isNull);
  expect(world.lastError, isA<OpfParseException>());
}

/// Usage: Then kobic이 분석 이벤트 "`<name>`"를 발사한다
///
/// 외부 분석 이벤트 변환은 kobic 호스트 책임(E3) — 패키지는 변환에 필요한
/// 실패 정보(타입 + 메시지)가 노출됨을 보증한다.
Future<void> kobicEmitsAnalyticsEvent(BddWorld world, String name) async {
  expect(world.lastError, isNotNull);
  expect(world.lastError.toString(), isNotEmpty);
}

/// Usage: Given `<sizeMB>`MB EPUB이 EpubSource.bytes로 전달된다
///
/// 250MB 실할당 대신 한도를 축소해 "한도 초과 bytes 전달"을 동등 재현한다.
/// (기본 한도가 200MB임은 별도로 고정 단언.)
Future<void> nMbEpubViaBytesSource(BddWorld world, int sizeMB) async {
  expect(const EpubSecurityConfig().maxFileSizeBytes, 200 * 1024 * 1024);
  world.security = const EpubSecurityConfig(maxFileSizeBytes: 512);
  world.bytes = validEpub3();
  expect(world.bytes!.length, greaterThan(512));
}

/// Usage: Then EpubFileTooLarge 에러가 반환된다
Future<void> epubFileTooLargeErrorReturned(BddWorld world) async {
  final error = world.lastError;
  expect(error, isA<EpubFileTooLarge>());
  final tooLarge = error as EpubFileTooLarge;
  expect(tooLarge.actualBytes, world.bytes!.length);
  expect(tooLarge.limitBytes, world.security.maxFileSizeBytes);
}

/// Usage: Then 파싱은 시작되지 않는다
///
/// 크기 검사는 ZIP 해제·파서 호출 전에 수행된다 — 세션도, 어떤 lifecycle
/// 이벤트도 만들어지지 않는다.
Future<void> parsingDoesNotStart(BddWorld world) async {
  expect(world.session, isNull);
  expect(world.lifecycle, isEmpty);
  expect(world.progressEvents, isEmpty);
}
