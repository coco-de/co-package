// Domain Repository Interface — open_epub 1.0
// Story: S1.20 (#36), S1.21 (#37), S1.18 (#34) — raw EPUB 조립 + raw-레벨 진단

import '../../api/epub_book.dart';
import '../../api/epub_source.dart';
import '../../data/compat/patch_catalog.dart' show AppliedPatch;
import '../entity/epub_capabilities.dart';
import '../entity/epub_navigation.dart';
import '../entity/epub_rendition.dart';
import '../entity/epub_resource.dart';

abstract class EpubRepository {
  /// EPUB을 ZIP 해제·파싱하여 보정 전 raw [EpubBook]을 조립한다.
  /// EpubBook 수준에서 감지 불가한 raw-레벨 보정(missing-mimetype,
  /// invalid-rendition-layout)은 [RawEpubLoad.patches]로 함께 반환한다.
  Future<RawEpubLoad> load(EpubSource source);
}

/// [EpubRepository.load]의 결과 — raw book + 조립 단계에서 감지된 보정 진단
/// + 본문/이미지 접근용 리소스 reader.
class RawEpubLoad {
  const RawEpubLoad({
    required this.book,
    this.patches = const [],
    this.resources = const EmptyEpubResourceReader(),
    this.navigation = EpubNavigation.empty,
    this.capabilities = BookCapabilities.defaults,
    this.renditions = const [],
  });

  final EpubBook book;
  final List<AppliedPatch> patches;
  final EpubResourceReader resources;

  /// toc 외 보조 내비게이션(landmarks / page-list). (S13.1, gap #2)
  final EpubNavigation navigation;

  /// 책의 읽기전용 능력 신호(PPD/writingMode/미디어오버레이). (S13.3, gap #3)
  final BookCapabilities capabilities;

  /// container.xml의 모든 rendition(복수 rootfile). 기본 rendition만 열린 상태.
  /// (S13.4, gap #7)
  final List<EpubRendition> renditions;
}
