import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'demo_embed_protocol.dart';
import 'demo_embed_sync.dart';
import 'demo_prefs.dart';

/// On the web — handshakes with the parent when running inside an iframe.
DemoEmbedSync createDemoEmbedSync({
  required Set<String> allowedOrigins,
  required bool allowLocalhost,
}) => _WebDemoEmbedSync(
  allowedOrigins: allowedOrigins,
  allowLocalhost: allowLocalhost,
);

final class _WebDemoEmbedSync implements DemoEmbedSync {
  _WebDemoEmbedSync({
    required this.allowedOrigins,
    required this.allowLocalhost,
  });

  final Set<String> allowedOrigins;
  final bool allowLocalhost;

  final List<Timer> _retries = [];
  JSFunction? _listener;
  bool _started = false;
  bool _synced = false;

  @override
  void start(void Function(DemoPrefs prefs) onSync) {
    if (_started) return;
    _started = true;
    final parent = web.window.parent;
    // A top-level window (new tab, direct visit) has no parent — the values
    // already came from the URL.
    if (parent == null || parent.strictEquals(web.window).toDart) return;

    void handle(web.MessageEvent event) {
      final source = event.source;
      if (source == null || !source.strictEquals(parent).toDart) return;
      if (!DemoEmbedProtocol.isAllowedOrigin(
        event.origin,
        allowed: allowedOrigins,
        allowLocalhost: allowLocalhost,
      )) {
        return;
      }
      final prefs = DemoPrefs.fromMessage(event.data.dartify());
      if (prefs == null) return;
      _synced = true;
      _cancelRetries();
      onSync(prefs);
    }

    final listener = handle.toJS;
    _listener = listener;
    web.window.addEventListener('message', listener);

    for (final delay in DemoEmbedProtocol.readyRetryDelays) {
      _retries.add(Timer(delay, () => _postReady(parent)));
    }
  }

  void _postReady(web.Window parent) {
    if (_synced) return;
    // The signal carries no data, so the target origin is '*'. The parent's
    // origin is checked when its reply (`sync`) arrives.
    parent.postMessage(DemoEmbedProtocol.readyMessage().jsify(), '*'.toJS);
  }

  void _cancelRetries() {
    for (final timer in _retries) {
      timer.cancel();
    }
    _retries.clear();
  }

  @override
  void dispose() {
    _cancelRetries();
    final listener = _listener;
    if (listener != null) {
      web.window.removeEventListener('message', listener);
    }
    _listener = null;
  }
}
