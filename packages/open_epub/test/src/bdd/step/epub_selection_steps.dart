// BDD Steps for epub_selection.feature
// Story: S1.13 (#37) — Fixed Layout 텍스트 레이어 감지 (F5.5/F5.6)
//
// E1 패키지 범위의 selection 산출물은 DetectTextLayerUseCase(S1.13)뿐이다.
// 선택 제스처·컨텍스트 메뉴·하이라이트 영속(BookHighlight start/end/color)·
// 메모 UI는 kobic 호스트 E3(S3.13 EpubHighlightPage, S3.2/S3.5 highlight
// 영속) 범위 — 해당 step은 명확한 사유로 fail-fast 하고, widget_test에서
// 시나리오 단위로 skip 처리한다.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_epub/open_epub_v1.dart';
import 'package:open_epub_engine/src/domain/entity/text_layer_verdict.dart';
import 'package:open_epub_engine/src/domain/usecase/detect_text_layer_use_case.dart';

import '../../../unit/_fixtures/epub_fixtures.dart';
import '_common_steps.dart';

/// feature 전용 상태 (선택 대상 페이지 XHTML + 텍스트 레이어 판정 결과).
/// [BddWorld]는 공유 인프라라 수정하지 않고 Expando로 부착한다.
class _SelectionState {
  String? pageXhtml;
  TextLayerVerdict? verdict;
}

final Expando<_SelectionState> _selectionState =
    Expando('epub_selection state');

_SelectionState _stateOf(BddWorld world) =>
    _selectionState[world] ??= _SelectionState();

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

const String _fxlNavXhtml = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol><li><a href="p1.xhtml">1쪽</a></li></ol>
    </nav>
  </body>
</html>
''';

String _fxlOpf(String title, String uuid, String extraManifest) => '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"
    unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:identifier id="bookid">urn:uuid:$uuid</dc:identifier>
    <meta property="rendition:layout">pre-paginated</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml"
        properties="nav"/>
    <item id="p1" href="p1.xhtml" media-type="application/xhtml+xml"/>
    $extraManifest
  </manifest>
  <spine><itemref idref="p1"/></spine>
</package>
''';

/// 가시 텍스트 ≥ 50자(RFC-2 기준 충족) 텍스트 레이어를 가진 FXL 1페이지 책.
Uint8List _textRichFixedLayoutEpub() => zipEpub({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': _fxlOpf('텍스트 레이어 FXL 책', 'test-sel-0001', ''),
      'OEBPS/nav.xhtml': _fxlNavXhtml,
      'OEBPS/p1.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><meta name="viewport" content="width=600, height=800"/></head>
  <body>
    <p>이 페이지는 고정 레이아웃 위에 그려진 본문이지만, 충분히 긴 가시
    텍스트 레이어를 함께 갖고 있어서 사용자가 단어와 문장을 직접 선택할 수
    있어야 한다.</p>
  </body>
</html>
''',
    });

/// 이미지만 있고 가시 텍스트가 0자인(image-only) FXL 1페이지 책.
Uint8List _imageOnlyFixedLayoutEpub() => zipEpubBinary({
      'mimetype': 'application/epub+zip',
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': _fxlOpf(
        '이미지 온리 FXL 책',
        'test-sel-0002',
        '<item id="i1" href="img/pic.png" media-type="image/png"/>',
      ),
      'OEBPS/nav.xhtml': _fxlNavXhtml,
      'OEBPS/p1.xhtml': '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><meta name="viewport" content="width=600, height=800"/></head>
  <body><img src="img/pic.png" alt=""/></body>
</html>
''',
      'OEBPS/img/pic.png': onePixelPng(),
    });

/// 현재 spine 첫 페이지의 (sanitize 적용된) XHTML을 읽어 feature 상태에 담는다.
void _captureFirstPageXhtml(BddWorld world) {
  final session = world.requireSession;
  final xhtml = session.readSpineXhtml(session.book.spine.first.href);
  expect(xhtml, isNotNull, reason: '첫 spine 페이지 XHTML을 읽을 수 있어야 합니다');
  _stateOf(world).pageXhtml = xhtml;
}

/// "사용자가 선택을 시도한다"의 패키지 레벨 동작 — 텍스트 레이어 판정(S1.13).
Future<void> _detectTextLayer(BddWorld world) async {
  final state = _stateOf(world);
  expect(state.pageXhtml, isNotNull,
      reason: '판정 대상 페이지가 준비되어 있어야 합니다 (Given 선행 필요)');
  state.verdict = await const DetectTextLayerUseCase()(state.pageXhtml!);
}

TextLayerVerdict _requireVerdict(BddWorld world) {
  final verdict = _stateOf(world).verdict;
  expect(verdict, isNotNull,
      reason: '텍스트 레이어 판정이 선행되어야 합니다 (When 선행 필요)');
  return verdict!;
}

/// Usage: Given Reflowable EPUB이 열려 있다
Future<void> reflowableEpubOpen(BddWorld world) async {
  world.bytes = validEpub3();
  await world.openSession();
  expect(world.lastError, isNull);
  expect(world.requireSession.book.layout, EpubLayout.reflowable);
}

/// Usage: When 사용자가 본문 텍스트를 길게 눌러 단어를 선택한다
Future<void> userLongPressesSelectWord(BddWorld world) async {
  throw UnimplementedError(
      '텍스트 선택 제스처(길게 누르기) 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: Then 선택 영역에 컨텍스트 메뉴(Highlight/Copy/Note)가 표시된다
Future<void> contextMenuShown(BddWorld world) async {
  throw UnimplementedError(
      '선택 컨텍스트 메뉴 UI 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: Given 사용자가 텍스트 "`<text>`"를 선택했다
Future<void> userHasSelectedText(BddWorld world, String text) async {
  throw UnimplementedError(
      '텍스트 선택(범위 지정) 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: When 사용자가 컨텍스트 메뉴에서 "Highlight" `<color>`색을 탭한다
Future<void> userTapsHighlightColor(BddWorld world, String color) async {
  throw UnimplementedError(
      '하이라이트 색상 선택 UI 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: Then 해당 텍스트에 `<color>`색 하이라이트가 시각화된다
Future<void> textHighlightedWithColor(BddWorld world, String color) async {
  throw UnimplementedError(
      '하이라이트 시각화 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: Then BookHighlight가 BookPosition start, end와 color=`<color>`로 저장된다
/// 패키지는 recordHighlight() analytics 신호만 제공 — start/end/color 영속은
/// kobic 호스트 E3(S3.2/S3.5/S3.8) 범위.
Future<void> bookHighlightStoredWithColor(BddWorld world, String color) async {
  throw UnimplementedError(
      'BookHighlight(start/end/color) 영속 미구현 — E3(S3.2/S3.5/S3.8) 범위');
}

/// Usage: Given "`<text>`"에 노란 하이라이트가 적용되어 있다
Future<void> yellowHighlightAppliedTo(BddWorld world, String text) async {
  throw UnimplementedError(
      '하이라이트 적용/영속 미구현 — E3(S3.13/S3.5) 범위');
}

/// Usage: When 사용자가 하이라이트를 탭하여 "Note" 액션을 선택한다
Future<void> userTapsHighlightNote(BddWorld world) async {
  throw UnimplementedError('메모 액션 UI 미구현 — E3(S3.13) 범위');
}

/// Usage: And "`<note>`"라고 입력한다
Future<void> userInputsNote(BddWorld world, String note) async {
  throw UnimplementedError('메모 입력 UI 미구현 — E3(S3.13) 범위');
}

/// Usage: Then 메모가 하이라이트와 연결되어 저장된다
Future<void> noteLinkedToHighlight(BddWorld world) async {
  throw UnimplementedError('메모-하이라이트 연결 영속 미구현 — E3(S3.5/S3.8) 범위');
}

/// Usage: Then 하이라이트 목록에서 메모 미리보기가 표시된다
Future<void> highlightListShowsNotePreview(BddWorld world) async {
  throw UnimplementedError(
      '하이라이트 목록 화면 미구현 — E3(S3.13 EpubHighlightPage) 범위');
}

/// Usage: Given 노란색 하이라이트가 적용되어 있다
Future<void> yellowHighlightExists(BddWorld world) async {
  throw UnimplementedError(
      '하이라이트 적용/영속 미구현 — E3(S3.13/S3.5) 범위');
}

/// Usage: When 사용자가 하이라이트를 탭하여 "Delete"를 선택한다
Future<void> userTapsHighlightDelete(BddWorld world) async {
  throw UnimplementedError('하이라이트 삭제 UI 미구현 — E3(S3.13) 범위');
}

/// Usage: Then 해당 하이라이트가 시각적으로 제거된다
Future<void> highlightVisuallyRemoved(BddWorld world) async {
  throw UnimplementedError(
      '하이라이트 시각화/제거 미구현 — E3(S3.13) 범위');
}

/// Usage: Then 데이터 저장소에서도 삭제된다
Future<void> dataStoreAlsoDeletes(BddWorld world) async {
  throw UnimplementedError(
      '하이라이트 데이터 저장소 미구현 — E3(S3.2/S3.5/S3.8) 범위');
}

/// Usage: Given Fixed Layout 페이지의 텍스트 레이어가 `<n>`자 이상 가시 텍스트를 갖는다
Future<void> fixedLayoutTextLayerHasNChars(BddWorld world, int n) async {
  world.bytes = _textRichFixedLayoutEpub();
  await world.openSession();
  expect(world.lastError, isNull);
  expect(world.requireSession.book.layout, EpubLayout.fixedLayout);
  _captureFirstPageXhtml(world);
  // 전제 검증: 페이지 가시 텍스트가 n자 이상이다.
  final verdict =
      const DetectTextLayerUseCase().detect(_stateOf(world).pageXhtml!);
  expect(verdict.visibleCharCount, greaterThanOrEqualTo(n));
}

/// Usage: When 사용자가 텍스트를 선택한다
/// 선택 시도 시 패키지가 수행하는 계약 = 텍스트 레이어 판정(S1.13).
Future<void> userSelectsText(BddWorld world) => _detectTextLayer(world);

/// Usage: Then 선택이 활성화되고 컨텍스트 메뉴가 표시된다
/// 컨텍스트 메뉴 렌더링은 호스트 UI(E3) — 패키지 계약은 판정이 available
/// (`text:N`, N≥50)을 반환해 선택을 활성화하는 것이다.
Future<void> selectionEnabledAndContextMenuShown(BddWorld world) async {
  final verdict = _requireVerdict(world);
  expect(verdict.isAvailable, isTrue);
  expect(verdict.hasSelectableText, isTrue);
  expect(verdict.reason, startsWith('text:'));
}

/// Usage: Given Fixed Layout 페이지가 이미지만 있고 텍스트 레이어가 없다
Future<void> fixedLayoutPageImageOnly(BddWorld world) async {
  world.bytes = _imageOnlyFixedLayoutEpub();
  await world.openSession();
  expect(world.lastError, isNull);
  expect(world.requireSession.book.layout, EpubLayout.fixedLayout);
  _captureFirstPageXhtml(world);
}

/// Usage: When 사용자가 길게 누른다
/// 길게 누르기 시 패키지가 수행하는 계약 = 텍스트 레이어 판정(S1.13).
Future<void> userLongPresses(BddWorld world) => _detectTextLayer(world);

/// Usage: Then 컨텍스트 메뉴는 표시되지 않는다
/// 패키지 계약: 판정이 unavailable → 선택(컨텍스트 메뉴) 비활성화.
Future<void> contextMenuNotShown(BddWorld world) async {
  final verdict = _requireVerdict(world);
  expect(verdict.isUnavailable, isTrue);
  expect(verdict.hasSelectableText, isFalse);
}

/// Usage: Then toast 메시지 "`<message>`"가 표시된다
/// toast 렌더링은 호스트 UI(E3) — 패키지는 toast의 근거인 `image-only`
/// 판정(reason)을 보증한다.
Future<void> toastMessageShown(BddWorld world, String message) async {
  final verdict = _requireVerdict(world);
  expect(verdict.reason, 'image-only');
  expect(verdict.visibleCharCount, 0);
  expect(message, '이 페이지는 텍스트 선택을 지원하지 않습니다');
}
