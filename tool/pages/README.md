# Example playground deployment

Live site: https://docs.cocode.im/co-package/

| Route | App |
| --- | --- |
| `open-board/` | Drawing, split canvas, recording/replay, EPUB annotation |
| `open-epub/` | Searchable sample library, reader, highlights/notes, fixed layout |
| `xterm2/` | Browser terminal with a local command shell |

All Flutter examples use `co_example_ui`, the CoUI release pinned in the root
pubspec, and bundled OFL fonts. The xterm2 example stays a standalone package to
preserve its independent library/CI; repeat its sibling overrides when upgrading.
`lang` and `theme` query parameters and the existing embed protocol remain supported.

## Build and verify

Use Flutter 3.47 or newer and a local Git login with read access to `coco-de/coui`:

```sh
bash tool/pages/build.sh
(cd packages/co_example_ui && flutter test --no-pub)
(cd packages/open_board/example && flutter test --no-pub)
(cd packages/open_epub/example && flutter test --no-pub)
(cd packages/xterm2/example && flutter test --no-pub)
(cd packages/co_golden_gallery && dart test)
```

`build/pages` contains only the three production builds and landing page. The
build script scans it for credentials. Serve its parent under `/co-package/`
when testing locally, because the apps use production base paths.

The six catalog goldens cover both apps at phone/desktop widths, light/dark
modes, Korean, English and Arabic RTL. The additional 320px/180% text test checks
that navigation remains usable. Update intentional redesigns with
`flutter test --update-goldens` in `packages/co_example_ui` and review the PNGs.

## GitHub Actions

Pages uses GitHub Actions, with deployment restricted to `main` and the existing
`github-pages` environment. `examples-pages.yml` supports:

1. **Source builds**: add repository secret `COUI_READ_TOKEN` with read-only
   `coco-de/coui` contents access. The workflow installs the dependency using a
   temporary Git HTTP header and removes it before artifact scanning/upload.
2. **Verified prebuilt site**: commit the contents of `build/pages` to the
   `gh-pages` artifact branch, then dispatch from `main`:

   ```sh
   gh workflow run examples-pages.yml --ref main -f prebuilt_ref=gh-pages
   ```

   This checks out only the static site, validates all three entry points,
   rescans credentials, and deploys through the same Pages artifact/OIDC path.
   Include `deployment.json` with the source commit and CoUI release for audit.

Without the read token, source builds explicitly report **skipped**, and never
replace the live site. Public package CI removes private-CoUI consumers from its
temporary workspace using `public_workspace.py`; the public library packages do
not gain a CoUI dependency. Credentials are never stored in the artifact branch.

## Verification on 2026-11-04

- CoUI Flutter 0.178.0 / core and web 0.176.0, release commit
  `ebf34ca7f8a57e7288b3fb5ee50f123f3d76afb6`; both pin checks pass.
- Production web builds: all three apps pass (Flutter 3.47.8).
- Analysis: shared UI, board/reader examples, and all terminal entrypoints pass.
- Tests: board 10, terminal 3, gallery 82, shared catalog 7; reader 26 pass.
- Six existing reader highlight-render assertions fail on this SDK, and reproduce
  with the original Material theme before this redesign. They are not suppressed:
  selected-text highlight, selection FAB, cover-first chapter alignment,
  persistence, list navigation, and deletion. Other reader tests pass.
- Reviewed browser paths: catalog navigation, drawing, reader content, sample
  search, local terminal commands, theme/language controls and mobile/RTL layouts.
- Native PTY/SSH/ZModem runtime behavior is not part of the browser deployment;
  their updated entrypoints and file picker integration are statically analyzed.
