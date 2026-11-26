---
title: Give Melos the same public package list as Pub
author: Cocode
date: 2026-11-26
branch: goccd/prepare-pub-dev-opensource
id: l-ab4cafc2
scope: repo
status: active
src: agent
touches:
  - tool/pages/public_workspace.py
  - ".github/workflows/ci.yml"
---

## Decided

Keep contributor setup in a Git-ignored Pub override so it does not create an unrelated edit to the dependency manifest. Pass the same package exclusions explicitly to the verification commands.

## Tried and ruled out

Dart accepted the workspace and dependency override, but Melos still discovered the full set from the main manifest. Running the regular verification scripts from that configuration alone can include packages requiring private CoUI access. The filtered run passed in a fresh checkout and left the tracked manifest byte-for-byte the same.

## Watch out

The exclusions have to reach nested Melos commands in the verification script. A successful dependency fetch describes Pub's view of the workspace. It does not establish which packages Melos will run against.

In the code: `tool/pages/public_workspace.py` creates `pubspec_overrides.yaml` and calls `dart run melos run` with an `--ignore` option for each excluded member. `.github/workflows/ci.yml` uses the same tool as contributors.
