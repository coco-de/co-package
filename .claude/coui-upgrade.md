# co-package CoUI upgrade profile

- Platform: Flutter web examples (not Jaspr apps); gallery uses coui_web.
- Shared UI: packages/co_example_ui. Example packages: open_board/example,
  open_epub/example, and standalone xterm2/example.
- Release: coui_flutter 0.178.0, core/web 0.176.0, all pinned to
  ebf34ca7f8a57e7288b3fb5ee50f123f3d76afb6.
- Overrides: root pubspec.yaml (all three siblings); xterm2/example/pubspec.yaml
  (flutter/core, same commit). Gallery consumes the root overrides.
- SDK: Flutter >=3.47.0; CI 3.47.0; local verification 3.47.8 / Dart 3.13.7.
- Authentication: local Git credential helper; Actions optional COUI_READ_TOKEN,
  read-only access to coco-de/coui. No credential is embedded in site artifacts.
- Scaling: 1.0 on every platform. Shared CoUI and Material palettes derive from
  CoreThemePresets. No restoration of old Material default sizing is intended.
- Fonts: bundled Pretendard regular/semibold in co_example_ui, OFL license beside
  font assets; Noto Sans Arabic is bundled for RTL; terminal keeps its Cascadia Mono font and Pretendard fallback.
- User direction: update every example to the latest CoUI, improve all UI/UX,
  and deploy GitHub Pages. This authorizes the redesigned look and deployment.
- Baseline: existing locale/theme tests passed before the migration (20 tests).
  No prior example goldens existed. New catalog captures cover mobile/desktop,
  both themes, and RTL; screenshots are reviewed for intentional redesign.
- Known baseline failures: six highlight-render assertions in
  open_epub/example/test/highlight_demo_test.dart reproduce with the original
  theme; kept enabled. Details: tool/pages/README.md.
- Tests: flutter test --no-pub in both reader and board examples; shared UI
  layout/golden tests; terminal shell and widget tests in xterm2/example.
- Analyze: shared UI and both workspace examples, plus standalone terminal lib.
- Builds: bash tool/pages/build.sh (all three production web builds and scan).
- Gallery: dart test in packages/co_golden_gallery after the web sibling update.
- Public CI excludes private consumers with tool/pages/public_workspace.py.
  Authenticated source build or prebuilt static deployment: tool/pages/README.md.
- After pins: run coui_pin.py check for root and terminal, run all example
  verification, refresh graft. No generated icon bundle is used by the apps.
- Formatting: only changed Dart files; open_board follows its existing DCM style.
