# co_demo_prefs

Carries the visitor's **language and theme** from cocode sites
([demo.cocode.im](https://demo.cocode.im), cocode.im, docs.cocode.im) into the
demo apps they launch, so a demo opens in the language and theme the visitor
already picked — in a new tab (URL query) and in the portal's live preview
(iframe `postMessage` handshake).

Pure Dart plus `package:web`; no Flutter dependency. Demo apps (Flutter) use it
to receive, and sites (Jaspr server rendering) use the same code to build
links.

This README is the source of truth for **protocol v1**.

## Values

| Value | Allowed | Notes |
|---|---|---|
| locale | `ko` `en` `zh-Hans` `ja` `de` `fr` `es` `pt` `it` `ru` `ar` | BCP-47 tag. Receivers ignore case, `_`/`-` and region (`pt-BR` → `pt`). Chinese is Simplified only: `zh`, `zh-CN`, `zh-Hans` → `zh-Hans`; `zh-TW`, `zh-HK`, `zh-MO`, `zh-Hant` are rejected. `ar` is right to left. |
| theme | `light` `dark` | Anything else (including `system`) is ignored. |

An unknown or missing value is ignored: the app keeps what it would have used
anyway (saved preference, device setting, default).

## Transport 1 — URL query (new tab, iframe `src`)

```text
https://docs.cocode.im/crux-climbing/app/?lang=en&theme=dark#/climbs
```

- The query goes **before** `#`. Flutter's hash URL strategy keeps it while the
  app navigates, and `Uri.base.queryParameters` reads it.
- Receivers also read a query inside the fragment (`#/climbs?lang=en`) in case a
  hash router moved it; the value before `#` wins.
- Senders build the URL with `DemoPrefs.applyTo(href)`.

## Transport 2 — iframe handshake (live preview)

```text
demo app → parent   {source: 'cocode-demo', type: 'ready', v: 1}
parent → demo app   {source: 'cocode-site', type: 'sync', v: 1, locale: 'en', theme: 'dark'}
```

1. The demo app attaches a `message` listener, then posts `ready` to
   `window.parent` (target origin `'*'` — the message carries no data). It
   retries at 0, 150, 500 and 1500 ms and stops at the first `sync`.
2. The parent answers every `ready` from its own iframe
   (`event.source === iframe.contentWindow`, `event.origin` = the iframe's
   origin) with `sync`, posted to that origin only.
3. The parent posts `sync` again whenever the visitor changes the theme (or
   language) while the preview runs. The app applies it without restarting.
4. The app accepts a `sync` only when it comes from `window.parent` **and** an
   allowed origin (`https://demo.cocode.im`, `https://docs.cocode.im`,
   `https://cocode.im`; loopback origins only when `allowLocalhost` is on).

### Lessons built in

The handshake follows web.unibook.co.kr's landing page, minus its four defects:

| Defect there | Rule here |
|---|---|
| No origin check — any site could drive the app | Parent window + origin allowlist |
| Locale changed outside the app's locale state, so Arabic stayed left to right | Apply through the locale state that drives `MaterialApp.locale` |
| A new tab lost the choice | Transport 1 (URL query) |
| The production build pinned the theme, so the theme message did nothing | Demo builds must honour the received theme |

## Receiving in a demo app (Flutter)

```dart
import 'package:co_demo_prefs/co_demo_prefs.dart';

Future<void> bootstrap() async {
  // 1. First values, before runApp — no flash of the wrong language or theme.
  final initial = DemoPrefs.fromUri(Uri.base);
  if (initial.locale case final l?) LocaleSettings.setLocaleRaw(l.tag); // slang
  if (initial.theme case final t?) themeMode.value = t == DemoTheme.dark ? ThemeMode.dark : ThemeMode.light;

  // 2. Live changes while running inside the portal's preview.
  DemoEmbedSync(allowLocalhost: kDebugMode).start((prefs) {
    if (prefs.locale case final l?) LocaleSettings.setLocaleRaw(l.tag);
    if (prefs.theme case final t?) themeMode.value = t == DemoTheme.dark ? ThemeMode.dark : ThemeMode.light;
  });

  runApp(const App());
}
```

- Do **not** persist received values — they belong to the visit. The URL keeps
  them across reloads.
- Map a locale to Flutter with
  `Locale.fromSubtags(languageCode: l.languageCode, scriptCode: l.scriptCode)`.

## Sending from a site

- New tab / iframe `src`: `DemoPrefs(locale: …, theme: …).applyTo(demoUrl)`.
- Live preview: answer `ready` with `DemoEmbedProtocol.syncMessage(prefs)` (or
  the same JSON from JavaScript), as described above.
- Only add values to surfaces that implement this protocol. Static surfaces
  (golden galleries, docs) take none; Widgetbook reads its own fragment syntax
  (`#/?theme={name:…}&locale={name:…}`).
