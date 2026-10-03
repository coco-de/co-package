import 'demo_prefs.dart';

/// Version 1 of the iframe preview handshake — the sender (a cocode site) and
/// the receiver (a demo app) use the same values.
///
/// ```text
/// demo app → parent   {source: 'cocode-demo', type: 'ready', v: 1}
/// parent → demo app   {source: 'cocode-site', type: 'sync', v: 1,
///                      locale: 'en', theme: 'dark'}
/// ```
abstract final class DemoEmbedProtocol {
  /// The protocol version. Bump it when the shape changes; receivers drop
  /// versions they do not know.
  static const version = 1;

  /// The `source` of messages a demo app sends.
  static const appSource = 'cocode-demo';

  /// The `source` of messages a cocode site sends.
  static const siteSource = 'cocode-site';

  /// Demo app → parent: "ready to receive".
  static const readyType = 'ready';

  /// Parent → demo app: "this is the current language and theme".
  static const syncType = 'sync';

  /// When a demo app re-sends `ready` after boot, so the handshake completes
  /// even if the parent attaches its listener late or the first message lands
  /// on `about:blank`. The remaining retries stop at the first `sync`.
  static const readyRetryDelays = [
    Duration.zero,
    Duration(milliseconds: 150),
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
  ];

  /// The origins a demo app accepts messages from — the three cocode sites.
  static const defaultAllowedOrigins = {
    'https://demo.cocode.im',
    'https://docs.cocode.im',
    'https://cocode.im',
  };

  /// The body of a `ready` message.
  static Map<String, Object> readyMessage() => const {
    'source': appSource,
    'type': readyType,
    'v': version,
  };

  /// The body of a `sync` message. Fields without a value are left out.
  static Map<String, Object> syncMessage(DemoPrefs prefs) => {
    'source': siteSource,
    'type': syncType,
    'v': version,
    if (prefs.locale case final locale?) 'locale': locale.tag,
    if (prefs.theme case final theme?) 'theme': theme.name,
  };

  /// Whether a message from [origin] may be accepted — it must equal one of
  /// [allowed] exactly.
  ///
  /// With [allowLocalhost], `http://localhost` and `http://127.0.0.1` (any
  /// port) are accepted too. Turn it on only while testing against a local
  /// portal.
  static bool isAllowedOrigin(
    String origin, {
    Set<String> allowed = defaultAllowedOrigins,
    bool allowLocalhost = false,
  }) {
    if (allowed.contains(origin)) return true;
    if (!allowLocalhost) return false;
    return RegExp(
      r'^http://(localhost|127\.0\.0\.1)(:\d{1,5})?$',
    ).hasMatch(origin);
  }
}
