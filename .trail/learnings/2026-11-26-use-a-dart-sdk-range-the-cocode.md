---
title: Use a Dart SDK range the registry accepts on upload
author: Cocode
date: 2026-11-26
branch: goccd/pub-dev-first-release-limits
id: l-8551c86b
scope: repo
status: active
src: agent
touches:
  - packages/co_bdd/pubspec.yaml
  - packages/open_board/pubspec.yaml
---

## Decided

Use a Dart 3 upper bound for the packages whose SDK range included Dart 4. This keeps the supported Dart 3 releases and meets the pub.dev upload validation.

## Tried and ruled out

The full release dry run passed for both packages. During the real upload the registry rejected Open Board because the declared range included Dart 4, which has no supported release. The same range was present in the BDD package. Repeating the upload with that manifest would give the same result.

## Watch out

`dart pub publish --dry-run` checks the package locally. Registry-side validation can still reject the upload. Keep unrelated dependency version ranges separate from the SDK range.

In the code: `packages/open_board/pubspec.yaml` and `packages/co_bdd/pubspec.yaml` declare `environment.sdk` as `>=3.10.0 <4.0.0`.
