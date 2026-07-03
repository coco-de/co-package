// Data Search — open_epub 1.0
// Story: S1.19 (#35) — 검색 인덱스 빌더
// BDD: F7.1 (검색 인덱스 빌드 ≤ 3.0s)

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
  const _Entry(this.spineHref, this.text);
  final String spineHref;
  final String text;
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
      final haystack = entry.text.toLowerCase();
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
