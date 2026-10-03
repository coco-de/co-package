import 'demo_embed_protocol.dart';
import 'demo_embed_sync_stub.dart'
    if (dart.library.js_interop) 'demo_embed_sync_web.dart';
import 'demo_prefs.dart';

/// Receives the language and theme from the parent page (a cocode site) while
/// a demo app runs inside an iframe preview.
///
/// [start] attaches a `message` listener and sends `ready` to the parent,
/// retrying at [DemoEmbedProtocol.readyRetryDelays]. Only `sync` messages that
/// come **from the parent window and an allowed origin** reach the callback as
/// [DemoPrefs]. Outside an iframe (a new tab, a direct visit) or off the web it
/// does nothing — read the values from the URL with [DemoPrefs.fromUri].
///
/// Received values are not persisted; they last as long as the preview. Apply
/// them through the app's locale and theme state — `MaterialApp.locale` has to
/// change for Arabic to lay out right to left.
abstract interface class DemoEmbedSync {
  /// Creates the iframe listener on the web and a no-op elsewhere.
  ///
  /// [allowedOrigins] are the origins messages are accepted from (the three
  /// cocode sites by default). Turn [allowLocalhost] on only while testing
  /// against a local portal (for example with `kDebugMode`).
  factory DemoEmbedSync({
    Set<String> allowedOrigins = DemoEmbedProtocol.defaultAllowedOrigins,
    bool allowLocalhost = false,
  }) => createDemoEmbedSync(
    allowedOrigins: allowedOrigins,
    allowLocalhost: allowLocalhost,
  );

  /// Attaches the listener and sends `ready`. Calling it twice attaches once.
  void start(void Function(DemoPrefs prefs) onSync);

  /// Removes the listener and cancels the remaining retries.
  void dispose();
}
