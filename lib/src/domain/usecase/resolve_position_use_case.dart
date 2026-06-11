// Domain UseCase — open_epub 1.0
// Story: S1.21 (#37) — 위치 복원 + lossy fallback
// BDD: F1.2 (마지막 위치 복원), F1.3 (복원 실패 시 fallback)
//
// 저장된 BookPosition([target])을 현재 책([book])에 대해 해석한다. target의
// spineHref가 현재 spine에 존재하면 그대로 복원하고, 사라졌으면(또는 target이
// 없으면) 첫 linear spine의 시작 위치로 lossy fallback한다.

import '../../api/epub_book.dart';
import '../../api/epub_position.dart';

class ResolvePositionUseCase {
  const ResolvePositionUseCase();

  ResolvedPosition call(EpubBook book, EpubPosition? target) {
    if (target != null && _spineHrefs(book).contains(target.spineHref)) {
      return ResolvedPosition(position: target, wasFallback: false);
    }
    // target이 있었는데 spineHref가 사라진 경우만 '복원 실패'(진단 대상).
    // target이 애초에 없었으면 정상적인 첫 열람이므로 fallback이 아니다.
    return ResolvedPosition(
      position: _startPosition(book),
      wasFallback: target != null,
    );
  }

  Set<String> _spineHrefs(EpubBook book) => {
        for (final item in book.spine) item.href,
      };

  EpubPosition _startPosition(EpubBook book) {
    final href = _firstLinearHref(book);
    if (book.layout == EpubLayout.fixedLayout) {
      return EpubFixedPosition(spineHref: href, progress: 0, pageIndex: 0);
    }
    return EpubReflowablePosition(spineHref: href, progress: 0, charOffset: 0);
  }

  String _firstLinearHref(EpubBook book) {
    for (final item in book.spine) {
      if (item.linear) return item.href;
    }
    return book.spine.isNotEmpty ? book.spine.first.href : '';
  }
}

/// [ResolvePositionUseCase]의 결과 — 해석된 위치 + fallback 여부.
class ResolvedPosition {
  const ResolvedPosition({required this.position, required this.wasFallback});

  final EpubPosition position;

  /// 저장된 위치를 복원하지 못해 첫 페이지로 대체했으면 true.
  final bool wasFallback;
}
