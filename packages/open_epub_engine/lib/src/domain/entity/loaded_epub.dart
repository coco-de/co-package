// Domain Entity — open_epub 1.0
// Story: S1.21 (#37) — 책 열기 파이프라인 산출물

import '../../api/epub_book.dart';
import '../../data/compat/patch_catalog.dart' show BookSessionDiagnostics;
import 'epub_capabilities.dart';
import 'epub_navigation.dart';
import 'epub_rendition.dart';
import 'epub_resource.dart';

/// [OpenEpubUseCase]의 산출물 — 보정 완료된 [book] + 적용된 보정/이슈 진단
/// + 본문/이미지 접근용 리소스 reader.
class LoadedEpub {
  const LoadedEpub({
    required this.book,
    required this.diagnostics,
    this.resources = const EmptyEpubResourceReader(),
    this.navigation = EpubNavigation.empty,
    this.capabilities = BookCapabilities.defaults,
    this.renditions = const [],
  });

  final EpubBook book;
  final BookSessionDiagnostics diagnostics;
  final EpubResourceReader resources;

  /// toc 외 보조 내비게이션(landmarks / page-list). (S13.1, gap #2)
  final EpubNavigation navigation;

  /// 책의 읽기전용 능력 신호(PPD/writingMode/미디어오버레이). (S13.3, gap #3)
  final BookCapabilities capabilities;

  /// container.xml의 모든 rendition(복수 rootfile). (S13.4, gap #7)
  final List<EpubRendition> renditions;
}
