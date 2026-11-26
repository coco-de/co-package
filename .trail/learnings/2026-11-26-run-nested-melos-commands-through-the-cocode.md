---
title: Run nested Melos commands through the workspace dependency
author: Cocode
date: 2026-11-26
branch: goccd/prepare-pub-dev-opensource
id: l-fc17975f
scope: repo
status: active
src: agent
touches:
  - pubspec.yaml
  - tool/pages/public_workspace.py
---

## Decided

Resolve every Melos invocation through the workspace dependency. This gives contributors and GitHub Actions the same tool without a global installation.

## Tried and ruled out

The public workspace entry point used the declared Melos dependency, but its child scripts invoked a bare Melos executable. Local verification passed because the developer machine already had that executable on its PATH. The hosted CI runner resolved dependencies and then failed when the child command ran.

## Watch out

A local package dependency does not put its executable on PATH. Test the public checks without the global binary present. Chain the formatting commands so a check failure is carried through to CI.

In the code: `pubspec.yaml` invokes `dart run melos` for nested `run` and `exec` commands. `tool/pages/public_workspace.py` resolves the public workspace and runs those scripts. PR check `verify` exposed the hidden global dependency.
