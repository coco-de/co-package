/// open_epub_engine — pure-Dart EPUB 2/3 파서·모델·CFI 엔진.
///
/// open_epub(Flutter 리더)가 소비하는 파싱 계층으로, epubx/epub_view를 대체한다.
/// 커스텀 파서(OPF/NCX/nav)를 기반으로 vers-one/EpubReader 설계를 참고해 확장하고,
/// epub_pro의 CFI를 보충 매퍼로 채택한다. (ADR-008/010)
///
/// S10.3(#80)에서 open_epub 1.0의 순수-Dart 레이어(api·domain·data)를 이 패키지로
/// 추출했다. Flutter 렌더/위젯/컨트롤러는 open_epub에 잔류한다.
library;

// ── Schema (OPF/NCX/nav 모델) ──────────────────────────────────────────────
export 'src/schema/opf/package/epub_version.dart' show EpubVersion;

// ── API (공개 진입 표면) ───────────────────────────────────────────────────
export 'src/api/epub_analytics.dart';
export 'src/api/epub_book.dart';
export 'src/api/epub_book_session.dart';
export 'src/api/epub_position.dart';
export 'src/api/epub_security_config.dart';
export 'src/api/epub_source.dart';

// ── Domain — Entity ────────────────────────────────────────────────────────
export 'src/domain/entity/epub_failure.dart';
export 'src/domain/entity/epub_highlight.dart';
export 'src/domain/entity/epub_metadata.dart';
export 'src/domain/entity/epub_outline.dart';
export 'src/domain/entity/epub_resource.dart';
export 'src/domain/entity/epub_selection.dart';
export 'src/domain/entity/epub_spine_item.dart';
export 'src/domain/entity/loaded_epub.dart';
export 'src/domain/entity/text_layer_verdict.dart';

// ── Domain — Repository 계약 ───────────────────────────────────────────────
export 'src/domain/repository/epub_repository.dart';

// ── Domain — UseCase ───────────────────────────────────────────────────────
export 'src/domain/usecase/apply_patches_use_case.dart';
export 'src/domain/usecase/build_search_index_use_case.dart';
export 'src/domain/usecase/detect_text_layer_use_case.dart';
export 'src/domain/usecase/open_epub_use_case.dart';
export 'src/domain/usecase/resolve_position_use_case.dart';

// ── Data — Parser ──────────────────────────────────────────────────────────
export 'src/data/parser/container_parser.dart';
export 'src/data/parser/nav_parser.dart';
export 'src/data/parser/ncx_parser.dart';
export 'src/data/parser/opf_parser.dart';

// ── Data — Codec / Compat / Search / Security / Text / Repository ──────────
export 'src/data/codec/book_position_codec.dart';
export 'src/data/compat/patch_catalog.dart';
export 'src/data/repository/epub_repository_impl.dart';
export 'src/data/search/text_index_builder.dart';
export 'src/data/security/html_sanitizer.dart';
export 'src/data/text/search_highlighter.dart';
export 'src/data/text/spine_text_extractor.dart';
