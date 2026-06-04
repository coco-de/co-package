// Domain Repository Interface — open_epub 1.0
// Story: S1.20 (#36), S1.21 (#37), S1.18 (#34) — raw EPUB 조립 + raw-레벨 진단

import '../../api/epub_book.dart';
import '../../api/epub_source.dart';
import '../../data/compat/patch_catalog.dart' show AppliedPatch;

abstract class EpubRepository {
  /// EPUB을 ZIP 해제·파싱하여 보정 전 raw [EpubBook]을 조립한다.
  /// EpubBook 수준에서 감지 불가한 raw-레벨 보정(missing-mimetype,
  /// invalid-rendition-layout)은 [RawEpubLoad.patches]로 함께 반환한다.
  Future<RawEpubLoad> load(EpubSource source);
}

/// [EpubRepository.load]의 결과 — raw book + 조립 단계에서 감지된 보정 진단.
class RawEpubLoad {
  const RawEpubLoad({required this.book, this.patches = const []});

  final EpubBook book;
  final List<AppliedPatch> patches;
}
