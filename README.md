# co-package

Dart and Flutter packages from Cocode for testing, demo data, file storage,
drawing, reading EPUBs, and embedding terminals.

[![CI](https://github.com/coco-de/co-package/actions/workflows/ci.yml/badge.svg)](https://github.com/coco-de/co-package/actions/workflows/ci.yml)

## Packages

| Package | Description |
| --- | --- |
| [`co_arc`](packages/co_arc/README.md) | Manage self-hosted GitHub Actions runners with a terminal UI, registration scripts, and reusable CI workflows. |
| [`co_bdd`](packages/co_bdd/README.md) | Generate Flutter widget tests and Patrol integration tests from shared Gherkin scenarios. |
| [`co_demo_prefs`](packages/co_demo_prefs/README.md) | Carry language and theme settings into embedded and standalone demos. |
| [`co_example_ui`](packages/co_example_ui/README.md) | Shared CoUI theme, catalog and settings for Flutter demos. |
| [`co_site_metadata`](packages/co_site_metadata/README.md) | Pure Dart route metadata, canonical URLs, sitemap, robots and LLM discovery documents. |
| [`co_faker`](packages/co_faker/README.md) | Pure Dart, deterministic, multilingual fake data generation. |
| [`co_demo_world`](packages/co_demo_world/README.md) | Deterministic demo worlds: business data fixed, co_faker display text re-projected per UI language, user edits kept across a live language switch. |
| [`co_golden`](packages/co_golden/README.md) | Golden matrix testing for Flutter — devices × themes × locales, strict layout diagnostics, Slang locale binding, JSON run manifests. |
| [`co_golden_gallery`](packages/co_golden_gallery/README.md) | Single-file HTML gallery for co_golden captures and golden PNG trees; images local, copied, or served from a bucket. |
| [`co_storage`](packages/co_storage/README.md) | File storage for Dart servers — one `Disk` API over S3, R2, MinIO, local disk and memory (a [dox_storage](packages/co_storage/FORK.md) fork), plus signed direct uploads whose storage keys never leave the server. |
| [`open_epub_engine`](packages/open_epub_engine/README.md) | Pure Dart EPUB 2/3 parser, object model, and CFI locator engine. |
| [`open_epub`](packages/open_epub/README.md) | Customizable EPUB reader widget for Flutter (reflowable + fixed layout). |
| [`open_board`](packages/open_board/README.md) | Flutter drawing & annotation widget (pen/lasso/text/image, multi-page, recording & replay). |
| [`co_xterm2`](packages/xterm2/README.md) | MIT terminal emulator fork with desktop IME composition fixes. |
| [`co_xterm3`](packages/xterm3/README.md) | AGPL-3.0-or-later terminal emulator fork with desktop IME composition fixes. |

## Live examples

The [Cocode playground](https://docs.cocode.im/co-package/) includes
[Open Board](https://docs.cocode.im/co-package/open-board/),
[Open EPUB](https://docs.cocode.im/co-package/open-epub/), and
[xterm2](https://docs.cocode.im/co-package/xterm2/). The examples share the latest
pinned CoUI theme, responsive navigation, bundled multilingual fonts, and
language/theme settings. The terminal uses a local browser demo shell.

See [build, verification and Pages deployment](tool/pages/README.md) for the
private CoUI read token or verified prebuilt deployment workflow.

## Depending on these packages

After a package has been published, install it with `dart pub add <package>`
or `flutter pub add <package>`. The [release guide](RELEASING.md) lists the
order for the first pub.dev releases and their prerequisites.

Existing Git releases can still be pinned by tag. For example:

```yaml
dependencies:
  co_faker:
    git:
      url: https://github.com/coco-de/co-package.git
      path: packages/co_faker
      ref: co_faker-v0.13.1
```

- **One ref per workspace.** Every package of a consuming workspace must use
  the same ref for the same git dependency. Two members pinning different
  tags (say `co_faker-v0.7.0` and `co_faker-v0.8.0`) make the workspace
  `pub get` fail with a version-solving error. Upgrade all members in one
  change, and enforce it with a CI check.
- Sibling packages released together share one release commit, so their tags
  from the same release point to the same tree.

## Reusable workflows

Service repositories call the shared CI workflows in
[`.github/workflows/`](.github/workflows/) with `workflow_call`. Pin the call to
a tag or a reviewed commit SHA instead of a moving ref such as `main`:

```yaml
uses: coco-de/co-package/.github/workflows/melos-ci.yml@<commit SHA>
```

See [`packages/co_arc/README.md`](packages/co_arc/README.md) for the runner setup.

## Contributing

Run the public checks from a clone with Flutter 3.50.1 and Python 3.9 or later.

```sh
python3 tool/pages/public_workspace.py verify
```

See the [contribution guide](CONTRIBUTING.md), the
[issue forms](https://github.com/coco-de/co-package/issues/new/choose), and the
[Code of Conduct](CODE_OF_CONDUCT.md). Report vulnerabilities through the
[private reporting form](https://github.com/coco-de/co-package/security/advisories/new).

### Workflow action pins

Every external `uses:` in `.github/workflows/` is pinned to a full commit SHA
with the release as a trailing comment (`uses: owner/repo@<sha> # v1.2.3`).
`python3 tool/check_action_pins.py` checks this locally and CI runs the same
check; Dependabot proposes the weekly updates.

### Graft code graph

This repository shares the Graft agent instructions in `AGENTS.md`. The
generated `graft/` graph stays local, so each contributor builds it after
cloning the repository:

```bash
npx --yes @nanonets/graft@0.18.0 build
```

The build needs no API key. Run the same command after large code changes, or
query the graph directly with `npx --yes @nanonets/graft@0.18.0 ask "<task>" --source`;
queries refresh changed files automatically. The pinned version keeps the
shared instructions and generated graph format consistent.

## License

The repository-level license is [BSD-3-Clause](LICENSE). Each package ships
its own `LICENSE`. `co_bdd`, `co_xterm2`, `open_board`, `open_epub`, and
`open_epub_engine` use MIT. `co_xterm3` uses AGPL-3.0-or-later and includes the
MIT notice for prior work. See [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES)
for bundled assets and third-party code.
