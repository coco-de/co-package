/// Page-order sorting shared by the nav module. Not exported by the barrel.
library;

import 'package:flutter/foundation.dart';

/// [items] sorted by the position of their page in [pageOrder] (stable), ties
/// broken by [then]. Items whose page is not in [pageOrder] come last.
List<T> noteNavSortByPage<T>(
  Iterable<T> items,
  List<String> pageOrder, {
  required String Function(T item) pageIdOf,
  int Function(T a, T b)? then,
}) {
  final rank = noteNavPageRanks(pageOrder);
  final unknown = pageOrder.length;
  final sorted = List<T>.of(items);
  mergeSort<T>(
    sorted,
    compare: (a, b) {
      final first = rank[pageIdOf(a)] ?? unknown;
      final second = rank[pageIdOf(b)] ?? unknown;
      if (first != second) return first.compareTo(second);

      return then?.call(a, b) ?? 0;
    },
  );

  return sorted;
}

/// Maps each page id of [pageOrder] to its 0-based position; the first
/// occurrence wins.
Map<String, int> noteNavPageRanks(List<String> pageOrder) {
  final ranks = <String, int>{};
  for (var index = 0; index < pageOrder.length; index++) {
    ranks.putIfAbsent(pageOrder[index], () => index);
  }

  return ranks;
}
