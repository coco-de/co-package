import 'demo_embed_sync.dart';
import 'demo_prefs.dart';

/// Off the web there is no iframe, so nothing happens.
DemoEmbedSync createDemoEmbedSync({
  required Set<String> allowedOrigins,
  required bool allowLocalhost,
}) => const _NoopDemoEmbedSync();

final class _NoopDemoEmbedSync implements DemoEmbedSync {
  const _NoopDemoEmbedSync();

  @override
  void start(void Function(DemoPrefs prefs) onSync) {}

  @override
  void dispose() {}
}
