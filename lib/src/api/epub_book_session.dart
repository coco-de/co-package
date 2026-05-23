// Public API — open_epub 1.0
// Status: SCAFFOLD STUB. Implementation deferred to Story S1.21, S1.22.
// BDD: F1, F10 (hot-swap), F11 (analytics)

import 'epub_analytics.dart';
import 'epub_position.dart';
import 'epub_source.dart';

/// EPUB 책 런타임 세션. open/jumpTo/page navigation/hot-swap/dispose 책임.
abstract class EpubBookSession implements EpubBookSessionAnalytics {
  static Future<EpubBookSession> open(
    EpubSource source, {
    EpubPosition? initialPosition,
    EpubSessionOptions options = const EpubSessionOptions(),
  }) {
    throw UnimplementedError('S1.21');
  }

  EpubPosition get position;
  Future<void> jumpTo(EpubPosition position);
  Future<void> nextPage();
  Future<void> previousPage();

  Future<void> swapSource(EpubSource newSource);

  Future<void> dispose();
}

class EpubSessionOptions {
  const EpubSessionOptions();
}
