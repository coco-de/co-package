---
title: Split first releases across the pub.dev creation windows
author: Cocode
date: 2026-11-26
branch: goccd/pub-dev-first-release-limits
id: l-cd3353e9
scope: repo
status: active
src: agent
touches:
  - RELEASING.md
  - tool/pub_release.py
---

## Decided

Track completed first releases by their version on pub.dev before retrying. Pace the remaining uploads on the same uploader account and preserve dependency order.

## Tried and ruled out

Sequential uploads verified successfully for the first four packages. The next archive reached pub.dev and the registry refused package creation because all four slots in its short window had been used. Repeating the upload immediately would reach the same limit.

## Watch out

Pub.dev counts new package creations per uploader in a rolling two-minute window and a rolling 24-hour window. Its production configuration permits four in two minutes and twelve in 24 hours. A wait for the short window can resume a batch. When the daily window is full, use the earliest completed creation time to determine the next slot and check the registry before uploading again.

In the code: `RELEASING.md` gives the dependency order and `tool/pub_release.py` stages the committed package. The limits are defined in pub.dev's `app/config/dartlang-pub.yaml` and `app/lib/service/rate_limit/rate_limit.dart`.
