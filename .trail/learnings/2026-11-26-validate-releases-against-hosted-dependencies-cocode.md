---
title: Validate releases against hosted dependencies
author: Cocode
date: 2026-11-26
branch: goccd/prepare-pub-dev-opensource
cost: { minutes: 1, tokens: 9523 }
id: l-0fc07196
scope: repo
status: active
src: agent
touches:
  - ".github/workflows/publish.yaml"
---

## Decided

Validate each release using a temporary copy of the committed package. Its dependencies resolve the same way for consumers on pub.dev, while the source checkout can keep its local workspace and private design system pins for daily development.

## Tried and ruled out

The workspace resolved successfully, but validation outside it exposed unpublished siblings and private CoUI packages. Publishing through a checkout-wide resolution would hide those prerequisites during setup and can require private Git access on release runners.

## Watch out

A sibling package has to appear on pub.dev before a dependent can pass its first dry run. GitHub release tags alone do not make packages available. Keep the temporary workspace override out of the upload and validate the package from the commit that will be tagged.

In the code: `tool/pub_release.py` stages `git archive HEAD`, adds `pubspec_overrides.yaml` with an empty `resolution` for workspace members, and runs `dart pub publish --dry-run`. `.github/workflows/publish.yaml` invokes it for tag-based publishing. `RELEASING.md` records the first-release order.
