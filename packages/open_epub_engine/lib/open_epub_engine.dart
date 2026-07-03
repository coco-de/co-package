/// open_epub_engine — pure-Dart EPUB 2/3 파서·모델·CFI 엔진.
///
/// open_epub(Flutter 리더)가 소비하는 파싱 계층으로, epubx/epub_view를 대체한다.
/// 커스텀 파서(OPF/NCX/nav)를 기반으로 vers-one/EpubReader 설계를 참고해 확장하고,
/// epub_pro의 CFI를 보충 매퍼로 채택한다. (ADR-008/010)
library;

// Schema — OPF
export 'src/schema/opf/package/epub_version.dart' show EpubVersion;
