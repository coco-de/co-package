---
title: Preserve the SDK widget types during the Flutter upgrade
author: Cocode
date: 2026-11-26
branch: goccd/flutter-3.50.1
id: l-78961111
scope: repo
status: active
src: agent
touches:
  - packages/xterm2/example/pubspec.yaml
---

## Decided

Use one Flutter 3.50.1 pin for local tooling, CI, Pages, and publishing. Keep the SDK Material and Cupertino types where packages and the demos use them with their existing theme and localization providers.

## Tried and ruled out

The SDK upgrade resolved successfully, but the analyzer reported deprecations on legacy imports and the localization delegate. Switching to the standalone design packages would change the widget and inherited theme types used at integration boundaries. The analysis exceptions are limited to the imports and delegate references that need the legacy types.

## Watch out

The standalone terminal demo still needs the local demo preferences package before its first pub.dev release. Its path dependency and the shared theme's hosted constraint otherwise require the same package from two sources. Apply the path override in the standalone example so Pub resolves one source for the entire dependency graph.

In the code: `.fvmrc` sets Flutter 3.50.1. The workflow setup steps read that file. `packages/xterm2/example/pubspec.yaml` overrides `co_demo_prefs` for the demo only. `CONTRIBUTING.md` explains the scoped analyzer exceptions.
