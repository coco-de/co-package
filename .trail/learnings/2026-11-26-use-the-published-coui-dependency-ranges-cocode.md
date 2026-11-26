---
title: Use the published CoUI dependency ranges for release checks
author: Cocode
date: 2026-11-26
branch: goccd/pub-dev-first-release-limits
id: l-891c2bfc
scope: repo
status: active
src: agent
touches:
  - pubspec.yaml
  - packages/co_example_ui/pubspec.yaml
  - packages/co_golden_gallery/pubspec.yaml
---

## Decided

Resolve the examples and the public archives against the same CoUI releases from pub.dev. The shared example theme starts as a prerelease because the hosted Flutter dependency is a prerelease.

## Tried and ruled out

The release checker previously skipped these packages while CoUI was absent. When CoUI appeared on pub.dev, the old ranges still had no matching versions, so both archive checks failed. The hosted versions resolve and analyze, and the three production demos build without Git authentication.

## Watch out

Dependency existence does not establish that its versions satisfy a range. The hosted Flutter version also changes the catalog palette, so refresh and verify the screenshots when adopting that theme. The standalone terminal demo still overrides the local demo preferences package.

In the code: `packages/co_example_ui/pubspec.yaml` uses `coui_flutter ^0.194.2-beta.1` and version `0.1.0-beta.1`. `packages/co_golden_gallery/pubspec.yaml` uses `coui_web ^0.192.0`. The root workspace and Pages workflow resolve them without private Git overrides.
