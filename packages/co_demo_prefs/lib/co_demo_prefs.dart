/// Carries the visitor's language and theme from cocode sites into demo apps:
/// the URL for new tabs, messages for iframe previews.
///
/// The README is the source of truth for the protocol (values, URL keys,
/// message shapes, origins). A demo app sets its first values with
/// [DemoPrefs.fromUri] at startup and receives changes during a preview with
/// [DemoEmbedSync]. Senders (cocode sites) use the same shapes as
/// [DemoPrefs.applyTo] and [DemoEmbedProtocol.syncMessage].
library;

export 'src/demo_embed_protocol.dart';
export 'src/demo_embed_sync.dart';
export 'src/demo_locale.dart';
export 'src/demo_prefs.dart';
export 'src/demo_theme.dart';
