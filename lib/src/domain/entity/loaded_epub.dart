// Domain Entity — open_epub 1.0
// Story: S1.21 (#37) — 책 열기 파이프라인 산출물

import '../../api/epub_book.dart';
import '../../data/compat/patch_catalog.dart' show BookSessionDiagnostics;

/// [OpenEpubUseCase]의 산출물 — 보정 완료된 [book] + 적용된 보정/이슈 진단.
class LoadedEpub {
  const LoadedEpub({required this.book, required this.diagnostics});

  final EpubBook book;
  final BookSessionDiagnostics diagnostics;
}
