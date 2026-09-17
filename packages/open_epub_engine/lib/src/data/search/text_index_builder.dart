// Data Search — open_epub 1.0
// Story: S1.19 (#35) — 검색 인덱스 빌더
// Story: S9.7 (#71) — search 시 toLowerCase 재계산 캐싱
// BDD: F7.1 (검색 인덱스 빌드 ≤ 3.0s)

import 'package:meta/meta.dart';

import '../../api/epub_book.dart';
import '../../domain/usecase/build_search_index_use_case.dart';

class TextIndexBuilder {
  const TextIndexBuilder();

  /// spine 순서대로 본문 평문([spineTexts])을 인덱싱한다.
  Future<BookSearchIndex> build(
    EpubBook book, {
    required Map<String, String> spineTexts,
  }) async {
    final entries = <_Entry>[];
    for (final item in book.spine) {
      final text = spineTexts[item.href];
      if (text != null && text.isNotEmpty) {
        entries.add(_Entry(item.href, text));
      }
    }
    return _InMemoryBookSearchIndex(entries);
  }
}

class _Entry {
  _Entry(this.spineHref, this.text) : lowerText = text.toLowerCase();
  final String spineHref;
  final String text;

  /// [text]의 소문자 변환 캐시. [text]는 build() 시점에 한 번 채워진 뒤 불변이므로
  /// 여기서 한 번만 변환하고, [_InMemoryBookSearchIndex.search]는 이 값을
  /// 재사용한다. search-as-you-type에서 글자 입력마다 O(전체 책 길이)의
  /// `toLowerCase()` 재계산이 반복되던 비용을 제거한다. (S9.7 #71)
  final String lowerText;
}

/// 대소문자 무시 부분일치 검색. 각 spine별 모든 출현 위치를 hit으로 반환한다.
class _InMemoryBookSearchIndex implements BookSearchIndex {
  _InMemoryBookSearchIndex(this._entries);

  final List<_Entry> _entries;

  @override
  Future<List<BookSearchHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final lowerQuery = q.toLowerCase();

    final hits = <BookSearchHit>[];
    for (final entry in _entries) {
      final haystack = entry.lowerText; // build 시점 캐시 재사용 (S9.7 #71)
      var from = 0;
      while (true) {
        final idx = haystack.indexOf(lowerQuery, from);
        if (idx < 0) break;
        hits.add(
          BookSearchHit(
            spineHref: entry.spineHref,
            charOffset: idx,
            snippet: _snippet(entry.text, idx, q.length),
          ),
        );
        from = idx + q.length;
      }
    }
    return hits;
  }

  String _snippet(String text, int idx, int len, {int ctx = 30}) {
    final start = (idx - ctx).clamp(0, text.length);
    final end = (idx + len + ctx).clamp(0, text.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    return '$prefix${text.substring(start, end)}$suffix';
  }
}

/// build() 시점에 캐시된 소문자 텍스트를 spine 순서대로 노출한다(테스트 전용).
/// [index]가 [TextIndexBuilder.build] 산출물이 아니면 빈 리스트. search()가 이
/// String 인스턴스를 재계산하지 않고 재사용함을 identity로 검증하는 데 쓴다.
/// (S9.7 #71)
@visibleForTesting
List<String> debugLoweredTexts(BookSearchIndex index) =>
    index is _InMemoryBookSearchIndex
        ? [for (final e in index._entries) e.lowerText]
        : const [];
