// Story: S6.1 (#237) — 1.0 공개 API 표면 동결 가드.
//
// 이 테스트는 메인 배럴(open_epub_engine.dart)이 노출하기로 **확정한** 공개 타입을
// 참조한다. 어떤 공개 타입이 배럴에서 실수로 제거되면 이 파일이 컴파일되지 않아
// CI가 회귀를 차단한다(semver 계약 동결). 반대로, 의도적으로 내부화한 타입
// (EpubRepositoryImpl, OpenEpubUseCase, ResolvePositionUseCase, ResolvedPosition,
// ApplyPatchesUseCase, ApplyPatchesResult)은 여기서 참조하지 않는다 — 배럴로
// 노출되면 안 되며, 참조 시 컴파일 실패로 드러난다.

import 'package:open_epub_engine/open_epub_engine.dart';
import 'package:test/test.dart';

/// 1.0 공개 API 표면(대표 타입). 배럴에서 export가 사라지면 컴파일이 깨진다.
const List<Type> _frozenPublicApi = <Type>[
  // Schema
  EpubVersion,
  EpubVersionDetection,
  // API 진입점
  EpubBookSession,
  EpubSessionOptions,
  EpubSource,
  EpubSecurityConfig,
  // Domain — Entity
  EpubBook,
  EpubMetadata,
  EpubLayout,
  EpubSpread,
  BookCapabilities,
  EpubPageProgression,
  EpubWritingMode,
  EpubMediaOverlay,
  EpubMediaPar,
  EpubOutline,
  EpubOutlineItem,
  EpubSpineItem,
  EpubResource,
  EpubResourceReader,
  EpubSelection,
  EpubHighlight,
  EpubRendition,
  EpubFailure,
  LoadedEpub,
  TextLayerVerdict,
  // Domain — Repository 계약 (구현 EpubRepositoryImpl은 비공개)
  EpubRepository,
  // Domain — UseCase (소비자 진입 유스케이스만 공개)
  BuildSearchIndexUseCase,
  BookSearchIndex,
  BookSearchHit,
  DetectTextLayerUseCase,
  // Data — Parser (헤드리스 재사용 표면)
  ContainerParser,
  NavParser,
  NcxParser,
  OpfParser,
  SmilParser,
  // Data — Codec / Search / Security / Text
  BookPositionCodec,
  TextIndexBuilder,
  EncryptionParser,
  HtmlSanitizer,
  SearchHighlighter,
  SpineTextExtractor,
  // CFI 어댑터 (이식 프리미티브는 비공개)
  EpubCfiMapper,
  BookCfiParts,
];

void main() {
  test('1.0 공개 API 표면이 배럴로 노출된다 (S6.1 #237 동결 가드)', () {
    // 참조만으로 컴파일 가드가 성립한다. 런타임 단언은 표면 크기의 최소치만 확인.
    expect(_frozenPublicApi, isNotEmpty);
    expect(_frozenPublicApi.toSet(), hasLength(_frozenPublicApi.length),
        reason: '동결 목록에 중복 타입이 없어야 한다');
  });
}
